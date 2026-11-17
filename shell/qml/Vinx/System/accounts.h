#pragma once

#include <QObject>
#include <QVariantList>
#include <functional>
#include <QtQml/qqmlregistration.h>

// Comptes utilisateurs (service AccountsService, org.freedesktop.Accounts) : liste, création,
// mot de passe, type de compte, suppression. Les droits administrateur sont demandés par polkit.
class Accounts : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(QVariantList users READ users NOTIFY changed)   // [{ path, uid, userName, realName, admin, current }]
    Q_PROPERTY(bool busy READ busy NOTIFY changed)

public:
    explicit Accounts(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QVariantList users() const { return m_users; }
    bool busy() const { return m_busy; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void createUser(const QString &userName, const QString &realName, bool admin, const QString &password);
    Q_INVOKABLE void setPassword(const QString &path, const QString &password);
    Q_INVOKABLE void setAdmin(const QString &path, bool admin);
    Q_INVOKABLE void deleteUser(qlonglong uid, bool removeFiles);
    // « Marie Dupont » → « marie » ; vide si impossible.
    Q_INVOKABLE static QString suggestUserName(const QString &realName);
    Q_INVOKABLE static bool validUserName(const QString &name);

    static QString hashPassword(const QString &password);

Q_SIGNALS:
    void changed();
    void finished(bool success, const QString &message);

private:
    void call(const QString &path, const QString &iface, const QString &method, const QVariantList &args,
              std::function<void(bool, const QVariantList &)> done);
    bool m_available = false;
    bool m_busy = false;
    QVariantList m_users;
};
