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

public:
    enum Role { IdRole = Qt::UserRole + 1, SummaryRole, BodyRole, AppNameRole, AppIconRole, TimeRole };

    explicit Notifications(QObject *parent = nullptr);

    bool serving() const { return m_serving; }
    int count() const { return m_items.size(); }
    bool doNotDisturb() const { return m_dnd; }
    void setDoNotDisturb(bool on);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Ajout direct (shell, aperçu, tests) ; renvoie l'identifiant.
    Q_INVOKABLE uint notify(const QString &appName, const QString &summary, const QString &body = {}, const QString &appIcon = {});
    Q_INVOKABLE void dismiss(uint id);
    Q_INVOKABLE void clear();

    // Interface D-Bus (appelée par l'adaptateur).
    uint dbusNotify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary,
                    const QString &body, const QStringList &actions, const QVariantMap &hints, int timeout);
    void dbusClose(uint id);

Q_SIGNALS:
    void countChanged();
    void doNotDisturbChanged();
    // Nouvelle notification à afficher en bulle (non émis en mode Ne pas déranger, sauf urgence).
    void popup(uint id, const QString &appName, const QString &summary, const QString &body, const QString &appIcon);
    void closed(uint id, uint reason);

private:
    struct Item {
        uint id;
        QString appName, appIcon, summary, body;
        QDateTime time;
    };
    int rowOf(uint id) const;

    QList<Item> m_items;   // plus récentes en premier
    uint m_nextId = 1;
    bool m_dnd = false;
    bool m_serving = false;
};
