#include <QCoreApplication>
#include <QHttpServer>
#include <QHttpServerRequest>
#include <QHttpServerResponse>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTcpServer>
#include <QHostAddress>

// Initialisation de la connexion MySQL
bool setupDatabase()
{
    QSqlDatabase db = QSqlDatabase::addDatabase("QMYSQL");
    db.setHostName("127.0.0.1");
    db.setPort(3306);
    db.setDatabaseName("tricount_db");
    db.setUserName("tricount_user");
    db.setPassword("StrongPass_2026!");

    if (!db.open()) {
        qCritical() << "[DB] Pas possible de se connecter :" << db.lastError().text();
        return false;
    }
    qInfo() << "[DB] MySQL connecté.";
    return true;
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    if (!setupDatabase()) return EXIT_FAILURE;

    QHttpServer server;

    // Création d'un nouveau groupe (besoin d'un group_name en JSON)
    server.route("/api/groups/create",
                 QHttpServerRequest::Method::Post,
                 [](const QHttpServerRequest &req) {
                     qInfo() << "[API] Création de groupe demandée";

                     const QJsonDocument doc = QJsonDocument::fromJson(req.body());
                     if (doc.isNull() || !doc.isObject()) {
                         return QHttpServerResponse(QJsonObject{{"status", "error"}, {"message", "Payload invalide"}},
                                                    QHttpServerResponder::StatusCode::BadRequest);
                     }

                     const QString name = doc.object()["group_name"].toString().trimmed();
                     if (name.isEmpty()) {
                         return QHttpServerResponse(QJsonObject{{"status", "error"}, {"message", "Nom requis"}},
                                                    QHttpServerResponder::StatusCode::BadRequest);
                     }

                     QSqlQuery query;
                     query.prepare("INSERT INTO tricount_groups (group_name) VALUES (:name)");
                     query.bindValue(":name", name);

                     if (!query.exec()) {
                         qCritical() << "[DB] Erreur insert groupe :" << query.lastError().text();
                         return QHttpServerResponse(QHttpServerResponder::StatusCode::InternalServerError);
                     }

                     QJsonObject res;
                     res["status"] = "success";
                     res["group_id"] = query.lastInsertId().toInt();
                     res["group_name"] = name;

                     return QHttpServerResponse(res, QHttpServerResponder::StatusCode::Created);
                 });

    // Récupérer la liste complète des groupes
    server.route("/api/groups",
                 QHttpServerRequest::Method::Get,
                 [](const QHttpServerRequest &req) {
                     Q_UNUSED(req)

                     QSqlQuery query("SELECT group_id, group_name FROM tricount_groups ORDER BY group_id");
                     QJsonArray arr;
                     while (query.next()) {
                         QJsonObject g;
                         g["group_id"] = query.value(0).toInt();
                         g["group_name"] = query.value(1).toString();
                         arr.append(g);
                     }

                     return QHttpServerResponse(QJsonObject{{"status", "success"}, {"groups", arr}});
                 });

    // Détail des dépenses d'un groupe avec jointure sur l'utilisateur
    server.route("/api/groups/<arg>/expenses",
                 QHttpServerRequest::Method::Get,
                 [](int groupId, const QHttpServerRequest &req) {
                     Q_UNUSED(req)

                     QSqlQuery query;
                     query.prepare(
                         "SELECT e.expense_id, e.description, e.amount, e.date, "
                         "u.user_id, u.username "
                         "FROM expenses e "
                         "JOIN users u ON u.user_id = e.payer_id "
                         "WHERE e.group_id = :gid "
                         "ORDER BY e.date DESC"
                         );
                     query.bindValue(":gid", groupId);

                     if (!query.exec()) {
                         return QHttpServerResponse(QHttpServerResponder::StatusCode::InternalServerError);
                     }

                     QJsonArray arr;
                     while (query.next()) {
                         QJsonObject e;
                         e["expense_id"] = query.value(0).toInt();
                         e["description"] = query.value(1).toString();
                         e["amount"] = query.value(2).toDouble();
                         e["date"] = query.value(3).toDate().toString("yyyy-MM-dd");
                         e["payer_id"] = query.value(4).toInt();
                         e["payer_name"] = query.value(5).toString();
                         arr.append(e);
                     }

                     // On récupère le total au passage pour éviter au front de recalculer
                     QSqlQuery totals;
                     totals.prepare("SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE group_id = :gid");
                     totals.bindValue(":gid", groupId);
                     totals.exec();
                     totals.next();

                     QJsonObject response;
                     response["status"] = "success";
                     response["expenses"] = arr;
                     response["total_amount"] = totals.value(0).toDouble();
                     return QHttpServerResponse(response);
                 });

    // Ajout d'une dépense
    server.route("/api/expenses/create",
                 QHttpServerRequest::Method::Post,
                 [](const QHttpServerRequest &req) {
                     const QJsonObject json = QJsonDocument::fromJson(req.body()).object();

                     // Check rapide des champs obligatoires
                     if (json["description"].toString().isEmpty() || json["amount"].toDouble() <= 0) {
                         return QHttpServerResponse(QHttpServerResponder::StatusCode::BadRequest);
                     }

                     QSqlQuery query;
                     query.prepare(
                         "INSERT INTO expenses (group_id, payer_id, description, amount, date) "
                         "VALUES (:gid, :pid, :desc, :amt, :dt)"
                         );
                     query.bindValue(":gid",  json["group_id"].toInt());
                     query.bindValue(":pid",  json["payer_id"].toInt());
                     query.bindValue(":desc", json["description"].toString().trimmed());
                     query.bindValue(":amt",  json["amount"].toDouble());
                     query.bindValue(":dt",   json["date"].toString());

                     if (!query.exec()) {
                         return QHttpServerResponse(QHttpServerResponder::StatusCode::InternalServerError);
                     }

                     return QHttpServerResponse(QJsonObject{{"status", "success"}}, QHttpServerResponder::StatusCode::Created);
                 });

    // Lancement sur le port 8080 par défaut
    auto tcpServer = std::make_unique<QTcpServer>();
    if (!tcpServer->listen(QHostAddress::Any, 8080)) {
        qCritical() << "Port 8080 déjà utilisé ?";
        return EXIT_FAILURE;
    }

    server.bind(tcpServer.release());
    qInfo() << "Serveur API lancé sur le port 8080...";

    return app.exec();
}
