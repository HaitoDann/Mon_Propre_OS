#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QStringList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class QDBusMessage;

// Serveur de notifications (org.freedesktop.Notifications) et historique.
// Modèle QML : summary, body, appName, appIcon, time, id.
class Notifications : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool serving READ serving CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool doNotDisturb READ doNotDisturb WRITE setDoNotDisturb NOTIFY doNotDisturbChanged)
    // Incrémenté à chaque changement de l'historique (liaisons QML : groups()).
    Q_PROPERTY(int revision READ revision NOTIFY changed)

public:
    enum Role { IdRole = Qt::UserRole + 1, SummaryRole, BodyRole, AppNameRole, AppIconRole, TimeRole,
                ActionsRole, HasDefaultRole, UrgencyRole, DesktopEntryRole };

    explicit Notifications(QObject *parent = nullptr);

    bool serving() const { return m_serving; }
    int count() const { return m_items.size(); }
    bool doNotDisturb() const { return m_dnd; }
    int revision() const { return m_revision; }
    void setDoNotDisturb(bool on);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Ajout direct (shell, aperçu, tests) ; renvoie l'identifiant.
    Q_INVOKABLE uint notify(const QString &appName, const QString &summary, const QString &body = {}, const QString &appIcon = {});
    Q_INVOKABLE void dismiss(uint id);
    Q_INVOKABLE void clear();
    // Détail d'une notification : { id, appName, summary, body, appIcon, actions: [{key,label}],
    // hasDefault, urgency (0 basse, 1 normale, 2 critique), desktopEntry, time }.
    Q_INVOKABLE QVariantMap get(uint id) const;
    // Historique regroupé par application, groupes du plus récent au plus ancien :
    // [{ appName, appIcon, count, items: [détails…] }].
    Q_INVOKABLE QVariantList groups() const;
    // Action choisie par l'utilisateur (bouton, ou « default » pour un clic sur la notification).
    Q_INVOKABLE void invokeAction(uint id, const QString &key);
    // Clic sur une notification : action par défaut si elle existe, sinon ouverture de l'application.
    Q_INVOKABLE void activate(uint id);
    Q_INVOKABLE void dismissApp(const QString &appName);
    // Ajout avec actions et indications (aperçu, tests).
    Q_INVOKABLE uint notifyFull(const QString &appName, const QString &summary, const QString &body,
                                const QStringList &actions, const QVariantMap &hints);

    // Interface D-Bus (appelée par l'adaptateur).
    uint dbusNotify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary,
                    const QString &body, const QStringList &actions, const QVariantMap &hints, int timeout);
    void dbusClose(uint id);

Q_SIGNALS:
    void countChanged();
    void doNotDisturbChanged();
    // Nouvelle notification à afficher en bulle (non émis en mode Ne pas déranger, sauf urgence).
    // Détail : get(id).
    void popup(uint id);
    void closed(uint id, uint reason);
    void actionInvoked(uint id, const QString &key);
    // Clic sur une notification sans action par défaut : ouvrir l'application (desktop-entry).
    void launchRequested(const QString &desktopEntry);
    void changed();

private:
    struct Item {
        uint id;
        QString appName, appIcon, summary, body;
        QDateTime time;
        QStringList actions;      // paires clé, libellé (spécification)
        int urgency = 1;
        QString desktopEntry;
        bool resident = false;
    };
    int rowOf(uint id) const;
    QVariantMap toMap(const Item &it) const;
    void removeRow(int row, uint reason);
    void bump();

    QList<Item> m_items;   // plus récentes en premier
    uint m_nextId = 1;
    bool m_dnd = false;
    bool m_serving = false;
    int m_revision = 0;
};
