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
        connect(parent, &Notifications::actionInvoked, this, &NotificationsAdaptor::ActionInvoked);
    }

public Q_SLOTS:
    QStringList GetCapabilities() { return {QStringLiteral("body"), QStringLiteral("actions"), QStringLiteral("persistence")}; }
    uint Notify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary,
                const QString &body, const QStringList &actions, const QVariantMap &hints, int timeout)
    {
        return m_n->dbusNotify(appName, replacesId, appIcon, summary, body, actions, hints, timeout);
    }
    void CloseNotification(uint id) { m_n->dbusClose(id); }
    QString GetServerInformation(QString &vendor, QString &version, QString &specVersion)
    {
        vendor = QStringLiteral("VinX OS");
        version = QStringLiteral("0.6");
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
    if (qEnvironmentVariableIntValue("VINX_SHELL_PROCESS") != 1)
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
    case ActionsRole: return toMap(it).value(QStringLiteral("actions"));
    case HasDefaultRole: return it.actions.contains(QStringLiteral("default"));
    case UrgencyRole: return it.urgency;
    case DesktopEntryRole: return it.desktopEntry;
    }
    return {};
}

QVariantMap Notifications::toMap(const Item &it) const
{
    QVariantList actions;
    for (int i = 0; i + 1 < it.actions.size(); i += 2)
        if (it.actions.at(i) != QLatin1String("default"))
            actions.append(QVariantMap{{QStringLiteral("key"), it.actions.at(i)}, {QStringLiteral("label"), it.actions.at(i + 1)}});
    return {{QStringLiteral("id"), it.id}, {QStringLiteral("appName"), it.appName}, {QStringLiteral("summary"), it.summary},
            {QStringLiteral("body"), it.body}, {QStringLiteral("appIcon"), it.appIcon}, {QStringLiteral("actions"), actions},
            {QStringLiteral("hasDefault"), it.actions.contains(QStringLiteral("default"))}, {QStringLiteral("urgency"), it.urgency},
            {QStringLiteral("desktopEntry"), it.desktopEntry}, {QStringLiteral("time"), it.time}};
}

QVariantMap Notifications::get(uint id) const
{
    const int row = rowOf(id);
    return row < 0 ? QVariantMap() : toMap(m_items.at(row));
}

QVariantList Notifications::groups() const
{
    QStringList order;                      // applications, de la plus récente à la plus ancienne
    QHash<QString, QVariantList> items;
    QHash<QString, QString> icons;
    for (const Item &it : m_items) {        // m_items : plus récentes en premier
        const QString key = it.appName.isEmpty() ? tr("Système") : it.appName;
        if (!items.contains(key)) {
            order.append(key);
            icons.insert(key, it.appIcon);
        }
        items[key].append(toMap(it));
    }
    QVariantList out;
    for (const QString &key : order)
        out.append(QVariantMap{{QStringLiteral("appName"), key}, {QStringLiteral("appIcon"), icons.value(key)},
                               {QStringLiteral("count"), items.value(key).size()}, {QStringLiteral("items"), items.value(key)}});
    return out;
}

void Notifications::bump()
{
    ++m_revision;
    Q_EMIT changed();
}

QHash<int, QByteArray> Notifications::roleNames() const
{
    return {{IdRole, "id"}, {SummaryRole, "summary"}, {BodyRole, "body"}, {AppNameRole, "appName"},
            {AppIconRole, "appIcon"}, {TimeRole, "time"}, {ActionsRole, "actions"}, {HasDefaultRole, "hasDefault"},
            {UrgencyRole, "urgency"}, {DesktopEntryRole, "desktopEntry"}};
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

uint Notifications::notifyFull(const QString &appName, const QString &summary, const QString &body,
                               const QStringList &actions, const QVariantMap &hints)
{
    return dbusNotify(appName, 0, QString(), summary, body, actions, hints, -1);
}

uint Notifications::dbusNotify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary,
                               const QString &body, const QStringList &actions, const QVariantMap &hints, int)
{
    // Corps : on retire le balisage HTML éventuel pour un affichage sobre.
    QString plain = body;
    plain.remove(QRegularExpression(QStringLiteral("<[^>]*>")));

    const int existing = replacesId ? rowOf(replacesId) : -1;
    const uint id = existing >= 0 ? replacesId : m_nextId++;
    Item item{id, appName, appIcon, summary, plain, QDateTime::currentDateTime()};
    item.actions = actions;
    item.urgency = hints.contains(QStringLiteral("urgency")) ? hints.value(QStringLiteral("urgency")).toInt() : 1;
    item.desktopEntry = hints.value(QStringLiteral("desktop-entry")).toString();
    item.resident = hints.value(QStringLiteral("resident")).toBool();
    if (item.appIcon.isEmpty())
        item.appIcon = hints.value(QStringLiteral("image-path")).toString();
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
    bump();
    if (!m_dnd || item.urgency == 2)
        Q_EMIT popup(id);
    return id;
}

void Notifications::removeRow(int row, uint reason)
{
    const uint id = m_items.at(row).id;
    beginRemoveRows({}, row, row);
    m_items.removeAt(row);
    endRemoveRows();
    Q_EMIT countChanged();
    bump();
    Q_EMIT closed(id, reason);
}

void Notifications::dbusClose(uint id)
{
    const int row = rowOf(id);
    if (row >= 0)
        removeRow(row, 3);   // 3 = fermée par CloseNotification
}

void Notifications::dismiss(uint id)
{
    const int row = rowOf(id);
    if (row >= 0)
        removeRow(row, 2);   // 2 = fermée par l'utilisateur
}

void Notifications::dismissApp(const QString &appName)
{
    for (int row = m_items.size() - 1; row >= 0; --row)
        if (m_items.at(row).appName == appName || (appName == tr("Système") && m_items.at(row).appName.isEmpty()))
            removeRow(row, 2);
}

void Notifications::invokeAction(uint id, const QString &key)
{
    const int row = rowOf(id);
    if (row < 0)
        return;
    Q_EMIT actionInvoked(id, key);
    // Sauf notification « résidente », une action la retire (spécification).
    if (!m_items.at(row).resident)
        removeRow(row, 2);
}

void Notifications::activate(uint id)
{
    const int row = rowOf(id);
    if (row < 0)
        return;
    const Item it = m_items.at(row);
    if (it.actions.contains(QStringLiteral("default"))) {
        invokeAction(id, QStringLiteral("default"));
        return;
    }
    if (!it.desktopEntry.isEmpty())
        Q_EMIT launchRequested(it.desktopEntry);
    removeRow(row, 2);
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
    bump();
    for (const Item &it : items)
        Q_EMIT closed(it.id, 2);
}

#include "notifications.moc"
