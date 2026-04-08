#ifndef TRICOUNTAPI_H
#define TRICOUNTAPI_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonObject>
#include <QJsonDocument>
#include <QUrl>
#include <QtQml/qqml.h>

class TricountApi : public QObject
{
    Q_OBJECT
    // Export du module pour le moteur QML
    QML_ELEMENT
    QML_NAMED_ELEMENT(TricountApi)

public:
    explicit TricountApi(QObject *parent = nullptr);

    // Méthodes appelables depuis QML
    Q_INVOKABLE void loadGroups();
    Q_INVOKABLE void createGroup(const QString &groupName);
    Q_INVOKABLE void loadExpenses(int groupId);
    Q_INVOKABLE void createExpense(int groupId, int payerId,
                                   const QString &description,
                                   double amount, const QString &date);

signals:
    void groupsLoaded(QVariantList groups);
    void groupCreated(int groupId, const QString &groupName);
    void expensesLoaded(QVariantList expenses, double totalAmount);
    void expenseCreated(int expenseId, const QString &description, double amount);
    void requestFailed(const QString &errorMessage);

private:
    QNetworkAccessManager *m_manager;

    // Adresse locale du seveur pour l'API
    const QString m_base{"http://192.168.1.19:8080"};
};

#endif // TRICOUNTAPI_H
