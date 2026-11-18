#include "agent.h"

#include <PolkitQt1/Details>

#include <QStringList>
#include <unistd.h>
#include <pwd.h>

namespace {
// « unix-user:haito » → « haito » ; nom complet (GECOS) si disponible.
QString displayName(const PolkitQt1::Identity &id)
{
    const QString user = id.toString().section(QLatin1Char(':'), 1);
    if (const passwd *pw = getpwnam(user.toLocal8Bit().constData())) {
        const QString full = QString::fromLocal8Bit(pw->pw_gecos).section(QLatin1Char(','), 0, 0).trimmed();
        if (!full.isEmpty())
            return full;
    }
    return user;
}
}

Agent::Agent(QObject *parent)
    : PolkitQt1::Agent::Listener(parent)
{
}

void Agent::initiateAuthentication(const QString &, const QString &message, const QString &,
                                   const PolkitQt1::Details &, const QString &cookie,
                                   const PolkitQt1::Identity::List &identities, PolkitQt1::Agent::AsyncResult *result)
{
    if (m_result) {   // une demande à la fois
        result->setError(QStringLiteral("Une autre demande est en cours."));
        result->setCompleted();
        return;
    }
    if (identities.isEmpty()) {
        result->setError(QStringLiteral("Aucun compte autorisé."));
        result->setCompleted();
        return;
    }
    // Compte proposé : l'utilisateur courant s'il fait partie des comptes autorisés.
    m_identity = identities.first();
    const QString me = QStringLiteral("unix-user:") + QString::fromLocal8Bit(getpwuid(getuid())->pw_name);
    for (const PolkitQt1::Identity &id : identities)
        if (id.toString() == me)
            m_identity = id;
    m_result = result;
    m_cookie = cookie;
    m_message = message;
    m_userName = displayName(m_identity);
    m_prompt.clear();
    m_error.clear();
    m_gained = m_cancelled = false;
    m_attempts = 0;
    startSession();
    Q_EMIT changed();
}

void Agent::startSession()
{
    if (m_session)
        m_session->deleteLater();
    m_session = new PolkitQt1::Agent::Session(m_identity, m_cookie, m_result, this);
    connect(m_session, &PolkitQt1::Agent::Session::request, this, [this](const QString &request, bool) {
        m_prompt = request;
        m_busy = false;
        Q_EMIT changed();
    });
    connect(m_session, &PolkitQt1::Agent::Session::showError, this, [this](const QString &text) { m_error = text; Q_EMIT changed(); });
    connect(m_session, &PolkitQt1::Agent::Session::completed, this, [this](bool gained) {
        m_gained = gained;
        m_busy = false;
        if (!gained && !m_cancelled && ++m_attempts < 3) {
            // Mauvais mot de passe : nouvelle tentative (trois au plus).
            m_error = tr("Mot de passe incorrect. Réessayez.");
            startSession();
            Q_EMIT changed();
            return;
        }
        finish();
    });
    m_session->initiate();
}

void Agent::submit(const QString &password)
{
    if (!m_session)
        return;
    m_busy = true;
    m_error.clear();
    Q_EMIT changed();
    m_session->setResponse(password);
}

void Agent::cancel()
{
    m_cancelled = true;
    if (m_session)
        m_session->cancel();
    finish();
}

void Agent::cancelAuthentication()
{
    cancel();
}

bool Agent::initiateAuthenticationFinish()
{
    return true;
}

void Agent::finish()
{
    if (!m_result)
        return;
    if (!m_gained && !m_cancelled)
        m_result->setError(QStringLiteral("Mot de passe incorrect."));
    m_result->setCompleted();
    m_result = nullptr;
    if (m_session)
        m_session->deleteLater();
    m_busy = false;
    Q_EMIT changed();
}
