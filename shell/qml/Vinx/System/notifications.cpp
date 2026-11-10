#include "notifications.h"

#include <QDBusAbstractAdaptor>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QRegularExpression>

namespace {
constexpr int kMaxHistory = 50;
}

// Adaptateur D-Bus conforme à la spécification Desktop Notifications 1.2.
class NotificationsAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")

public:
    explicit NotificationsAdaptor(Notifications *parent)
        : QDBusAbstractAdaptor(parent), m_n(parent)
    {
        connect(parent, &Notifications::closed, this, &NotificationsAdaptor::NotificationClosed);
    }

public Q_SLOTS:
    QStringList GetCapabilities() { return {QStringLiteral("body"), QStringLiteral("persistence")}; }
    uint Notify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary,
                const QString &body, const QStringList &actions, const QVariantMap &hints, int timeout)
    {
        return m_n->dbusNotify(appName, replacesId, appIcon, summary, body, actions, hints, timeout);
    }
    void CloseNotification(uint id) { m_n->dbusClose(id); }
    QString GetServerInformation(QString &vendor, QString &version, QString &specVersion)
    {
        vendor = QStringLiteral("VinX OS");
        version = QStringLiteral("0.4");
        specVersion = QStringLiteral("1.2");
        return QStringLiteral("vinx-shell");
    }

Q_SIGNALS:
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString &actionKey);

private:
    Notifications *m_n;
};

Notifications::Notifications(QObject *parent)
    : QAbstractListModel(parent)
{
    // Le serveur n'est publié que dans le processus vinx-shell (pas dans les applications ni les tests).
    if (qEnvironmentVariableIntValue("VINX_NOTIFICATION_SERVER") != 1)
        return;
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected())
        return;
    new NotificationsAdaptor(this);
    if (bus.registerObject(QStringLiteral("/org/freedesktop/Notifications"), this)
        && bus.registerService(QStringLiteral("org.freedesktop.Notifications")))
        m_serving = true;
    else
        qWarning("vinx-shell : un autre serveur de notifications est actif");
}

void Notifications::setDoNotDisturb(bool on)
{
    if (on == m_dnd)
        return;
    m_dnd = on;
    Q_EMIT doNotDisturbChanged();
}

int Notifications::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QVariant Notifications::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.size())
        return {};
    const Item &it = m_items.at(index.row());
    switch (role) {
    case IdRole: return it.id;
    case SummaryRole: return it.summary;
    case BodyRole: return it.body;
    case AppNameRole: return it.appName;
    case AppIconRole: return it.appIcon;
    case TimeRole: return it.time;
    }
    return {};
}

QHash<int, QByteArray> Notifications::roleNames() const
{
    return {{IdRole, "id"}, {SummaryRole, "summary"}, {BodyRole, "body"},
            {AppNameRole, "appName"}, {AppIconRole, "appIcon"}, {TimeRole, "time"}};
}

int Notifications::rowOf(uint id) const
{
    for (int i = 0; i < m_items.size(); ++i)
        if (m_items.at(i).id == id)
            return i;
    return -1;
}

uint Notifications::notify(const QString &appName, const QString &summary, const QString &body, const QString &appIcon)
{
    return dbusNotify(appName, 0, appIcon, summary, body, {}, {}, -1);
}

uint Notifications::dbusNotify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary,
                               const QString &body, const QStringList &, const QVariantMap &hints, int)
{
    // Corps : on retire le balisage HTML éventuel pour un affichage sobre.
    QString plain = body;
    plain.remove(QRegularExpression(QStringLiteral("<[^>]*>")));

    const int existing = replacesId ? rowOf(replacesId) : -1;
    const uint id = existing >= 0 ? replacesId : m_nextId++;
    const Item item{id, appName, appIcon, summary, plain, QDateTime::currentDateTime()};
    if (existing >= 0) {
        m_items[existing] = item;
        Q_EMIT dataChanged(index(existing), index(existing));
    } else {
        beginInsertRows({}, 0, 0);
        m_items.prepend(item);
        endInsertRows();
        if (m_items.size() > kMaxHistory) {
            beginRemoveRows({}, kMaxHistory, m_items.size() - 1);
            m_items.erase(m_items.begin() + kMaxHistory, m_items.end());
            endRemoveRows();
        }
        Q_EMIT countChanged();
    }
    const bool critical = hints.value(QStringLiteral("urgency")).toInt() == 2;
    if (!m_dnd || critical)
        Q_EMIT popup(id, appName, summary, plain, appIcon);
    return id;
}

void Notifications::dbusClose(uint id)
{
    const int row = rowOf(id);
    if (row < 0)
        return;
    beginRemoveRows({}, row, row);
    m_items.removeAt(row);
    endRemoveRows();
    Q_EMIT countChanged();
    Q_EMIT closed(id, 3);   // 3 = fermée par CloseNotification
}

void Notifications::dismiss(uint id)
{
    const int row = rowOf(id);
    if (row < 0)
        return;
    beginRemoveRows({}, row, row);
    m_items.removeAt(row);
    endRemoveRows();
    Q_EMIT countChanged();
    Q_EMIT closed(id, 2);   // 2 = fermée par l'utilisateur
}

void Notifications::clear()
{
    if (m_items.isEmpty())
        return;
    const auto items = m_items;
    beginResetModel();
    m_items.clear();
    endResetModel();
    Q_EMIT countChanged();
    for (const Item &it : items)
        Q_EMIT closed(it.id, 2);
}

#include "notifications.moc"
