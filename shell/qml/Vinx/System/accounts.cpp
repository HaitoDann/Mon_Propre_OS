#include "accounts.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusPendingCallWatcher>
#include <QDBusReply>
#include <QRegularExpression>
#include <crypt.h>
#include <unistd.h>

namespace {
const QString kService = QStringLiteral("org.freedesktop.Accounts");
const QString kPath = QStringLiteral("/org/freedesktop/Accounts");
const QString kIface = QStringLiteral("org.freedesktop.Accounts");
const QString kUserIface = QStringLiteral("org.freedesktop.Accounts.User");
}

Accounts::Accounts(QObject *parent)
    : QObject(parent)
{
    refresh();
}

void Accounts::call(const QString &path, const QString &iface, const QString &method, const QVariantList &args,
                    std::function<void(bool, const QVariantList &)> done)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(kService, path, iface, method);
    msg.setArguments(args);
    msg.setInteractiveAuthorizationAllowed(true);   // fenêtre polkit (mot de passe administrateur)
    auto *w = new QDBusPendingCallWatcher(QDBusConnection::systemBus().asyncCall(msg, 120000), this);
    connect(w, &QDBusPendingCallWatcher::finished, this, [w, done] {
        const QDBusMessage reply = w->reply();
        w->deleteLater();
        done(reply.type() == QDBusMessage::ReplyMessage, reply.arguments());
    });
}

void Accounts::refresh()
{
    call(kPath, kIface, QStringLiteral("ListCachedUsers"), {}, [this](bool ok, const QVariantList &out) {
        m_available = ok;
        QVariantList users;
        if (ok && !out.isEmpty()) {
            const auto paths = qdbus_cast<QList<QDBusObjectPath>>(out.first());
            for (const QDBusObjectPath &p : paths) {
                QDBusInterface u(kService, p.path(), kUserIface, QDBusConnection::systemBus());
                if (!u.isValid() || u.property("SystemAccount").toBool())
                    continue;
                const qlonglong uid = u.property("Uid").toLongLong();
                users.append(QVariantMap{
                    {QStringLiteral("path"), p.path()},
                    {QStringLiteral("uid"), uid},
                    {QStringLiteral("userName"), u.property("UserName").toString()},
                    {QStringLiteral("realName"), u.property("RealName").toString()},
                    {QStringLiteral("admin"), u.property("AccountType").toInt() == 1},
                    {QStringLiteral("current"), uid == qlonglong(getuid())},
                });
            }
        }
        m_users = users;
        Q_EMIT changed();
    });
}

QString Accounts::hashPassword(const QString &password)
{
    // yescrypt (méthode par défaut de Debian), sel aléatoire fourni par libxcrypt.
    const char *salt = crypt_gensalt("$y$", 0, nullptr, 0);
    if (!salt)
        salt = crypt_gensalt("$6$", 0, nullptr, 0);
    struct crypt_data data = {};
    const char *hash = salt ? crypt_r(password.toUtf8().constData(), salt, &data) : nullptr;
    return hash && hash[0] != '*' ? QString::fromLatin1(hash) : QString();
}

void Accounts::createUser(const QString &userName, const QString &realName, bool admin, const QString &password)
{
    if (!validUserName(userName) || password.isEmpty() || m_busy)
        return;
    m_busy = true;
    Q_EMIT changed();
    call(kPath, kIface, QStringLiteral("CreateUser"), {userName, realName, admin ? 1 : 0}, [=](bool ok, const QVariantList &out) {
        if (!ok || out.isEmpty()) {
            m_busy = false;
            Q_EMIT finished(false, tr("Impossible de créer le compte « %1 ».").arg(userName));
            refresh();
            return;
        }
        const QString path = qvariant_cast<QDBusObjectPath>(out.first()).path();
        call(path, kUserIface, QStringLiteral("SetPassword"), {hashPassword(password), QString()}, [=](bool okPw, const QVariantList &) {
            m_busy = false;
            Q_EMIT finished(okPw, okPw ? tr("Le compte de %1 est prêt.").arg(realName.isEmpty() ? userName : realName)
                                       : tr("Compte créé, mais le mot de passe n'a pas pu être enregistré."));
            refresh();
        });
    });
}

void Accounts::setPassword(const QString &path, const QString &password)
{
    if (password.isEmpty())
        return;
    call(path, kUserIface, QStringLiteral("SetPassword"), {hashPassword(password), QString()}, [this](bool ok, const QVariantList &) {
        Q_EMIT finished(ok, ok ? tr("Mot de passe modifié.") : tr("Le mot de passe n'a pas été modifié."));
    });
}

void Accounts::setAdmin(const QString &path, bool admin)
{
    call(path, kUserIface, QStringLiteral("SetAccountType"), {admin ? 1 : 0}, [this](bool ok, const QVariantList &) {
        if (!ok)
            Q_EMIT finished(false, tr("Le type de compte n'a pas été modifié."));
        refresh();
    });
}

void Accounts::deleteUser(qlonglong uid, bool removeFiles)
{
    if (uid == qlonglong(getuid()))
        return;   // jamais son propre compte
    call(kPath, kIface, QStringLiteral("DeleteUser"), {uid, removeFiles}, [this](bool ok, const QVariantList &) {
        Q_EMIT finished(ok, ok ? tr("Compte supprimé.") : tr("Le compte n'a pas été supprimé."));
        refresh();
    });
}

bool Accounts::validUserName(const QString &name)
{
    static const QRegularExpression re(QStringLiteral("^[a-z_][a-z0-9_-]{0,31}$"));
    return re.match(name).hasMatch() && name != QLatin1String("root");
}

QString Accounts::suggestUserName(const QString &realName)
{
    QString n = realName.trimmed().section(QLatin1Char(' '), 0, 0).normalized(QString::NormalizationForm_D).toLower();
    QString out;
    for (const QChar c : n)
        if ((c >= QLatin1Char('a') && c <= QLatin1Char('z')) || (c >= QLatin1Char('0') && c <= QLatin1Char('9')) || c == QLatin1Char('-'))
            out += c;
    if (!out.isEmpty() && out.at(0).isDigit())
        out.prepend(QLatin1Char('u'));
    return out.left(32);
}
