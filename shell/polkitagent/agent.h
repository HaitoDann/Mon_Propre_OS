#pragma once

#include <PolkitQt1/Agent/Listener>
#include <PolkitQt1/Agent/Session>
#include <PolkitQt1/Identity>

#include <QPointer>

// Agent d'authentification polkit de VinX (ADR 0028) : demande le mot de passe administrateur dans
// une fenêtre VinX à la place de celle de KDE. Exposé au QML (propriétés et actions).
class Agent : public PolkitQt1::Agent::Listener
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString userName READ userName NOTIFY changed)
    Q_PROPERTY(QString prompt READ prompt NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)

public:
    explicit Agent(QObject *parent = nullptr);
    bool active() const { return m_result != nullptr; }
    QString message() const { return m_message; }
    QString userName() const { return m_userName; }
    QString prompt() const { return m_prompt; }
    QString error() const { return m_error; }
    bool busy() const { return m_busy; }

    Q_INVOKABLE void submit(const QString &password);
    Q_INVOKABLE void cancel();

public Q_SLOTS:
    void initiateAuthentication(const QString &actionId, const QString &message, const QString &iconName,
                                const PolkitQt1::Details &details, const QString &cookie,
                                const PolkitQt1::Identity::List &identities, PolkitQt1::Agent::AsyncResult *result) override;
    bool initiateAuthenticationFinish() override;
    void cancelAuthentication() override;

Q_SIGNALS:
    void changed();

private:
    void startSession();
    void finish();

    QPointer<PolkitQt1::Agent::Session> m_session;
    PolkitQt1::Agent::AsyncResult *m_result = nullptr;
    PolkitQt1::Identity m_identity;
    QString m_cookie, m_message, m_userName, m_prompt, m_error;
    bool m_busy = false, m_gained = false, m_cancelled = false;
    int m_attempts = 0;
};
