#include "tricountapi.h"
#include <QJsonArray>

TricountApi::TricountApi(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
{}

// Helper pour configurer les headers JSON
static QNetworkRequest jsonRequest(const QUrl &url)
{
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    return req;
}

void TricountApi::loadGroups()
{
    QNetworkReply *reply = m_manager->get(QNetworkRequest(QUrl(m_base + "/api/groups")));

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("Erreur réseau : " + reply->errorString());
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isNull() || !doc.isObject()) {
            emit requestFailed("Réponse JSON invalide.");
            return;
        }

        const QJsonArray arr = doc.object()["groups"].toArray();
        QVariantList list;

        for (const QJsonValue &v : arr) {
            const QJsonObject obj = v.toObject();
            QVariantMap m;
            m["group_id"]   = obj["group_id"].toInt();
            m["group_name"] = obj["group_name"].toString();
            list.append(m);
        }
        emit groupsLoaded(list);
    });
}

void TricountApi::createGroup(const QString &groupName)
{
    const QString trimmed = groupName.trimmed();
    if (trimmed.isEmpty()) {
        emit requestFailed("Le nom du groupe est obligatoire.");
        return;
    }

    QJsonObject payload;
    payload["group_name"] = trimmed;
    const QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    QNetworkReply *reply = m_manager->post(jsonRequest(QUrl(m_base + "/api/groups/create")), body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("Impossible de créer le groupe : " + reply->errorString());
            return;
        }

        const QJsonDocument doc  = QJsonDocument::fromJson(reply->readAll());
        const QJsonObject   json = doc.object();
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        // 201 Created attendu
        if (status == 201) {
            emit groupCreated(json["group_id"].toInt(), json["group_name"].toString());
        } else {
            emit requestFailed(json["message"].toString("Erreur serveur inconnue."));
        }
    });
}

void TricountApi::loadExpenses(int groupId)
{
    const QUrl url(m_base + "/api/groups/" + QString::number(groupId) + "/expenses");
    QNetworkReply *reply = m_manager->get(QNetworkRequest(url));

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("Erreur lors de la récupération des dépenses : " + reply->errorString());
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isNull() || !doc.isObject()) {
            emit requestFailed("Format de données corrompu.");
            return;
        }

        const QJsonObject root  = doc.object();
        const QJsonArray  arr   = root["expenses"].toArray();
        const double      total = root["total_amount"].toDouble();

        QVariantList list;
        for (const QJsonValue &v : arr) {
            const QJsonObject obj = v.toObject();
            QVariantMap m;
            m["expense_id"]  = obj["expense_id"].toInt();
            m["description"] = obj["description"].toString();
            m["amount"]      = obj["amount"].toDouble();
            m["date"]        = obj["date"].toString();
            m["payer_id"]    = obj["payer_id"].toInt();
            m["payer_name"]  = obj["payer_name"].toString();
            list.append(m);
        }
        emit expensesLoaded(list, total);
    });
}

void TricountApi::createExpense(int groupId, int payerId,
                                const QString &description,
                                double amount, const QString &date)
{
    QJsonObject payload;
    payload["group_id"]    = groupId;
    payload["payer_id"]    = payerId;
    payload["description"] = description.trimmed();
    payload["amount"]      = amount;
    payload["date"]        = date;

    const QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    QNetworkReply *reply = m_manager->post(jsonRequest(QUrl(m_base + "/api/expenses/create")), body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("Erreur réseau lors de l'ajout.");
            return;
        }

        const QJsonDocument doc  = QJsonDocument::fromJson(reply->readAll());
        const QJsonObject   json = doc.object();
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        if (status == 201) {
            emit expenseCreated(json["expense_id"].toInt(),
                                json["description"].toString(),
                                json["amount"].toDouble());
        } else {
            emit requestFailed(json["message"].toString("Erreur lors de l'enregistrement."));
        }
    });
}
