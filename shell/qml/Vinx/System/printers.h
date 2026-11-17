#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Imprimantes (CUPS) : liste, détection des imprimantes réseau sans pilote, ajout, défaut, test.
class Printers : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(QVariantList printers READ printers NOTIFY changed)       // [{ name, status, isDefault }]
    Q_PROPERTY(QVariantList discovered READ discovered NOTIFY changed)   // [{ name, uri }] non encore ajoutées
    Q_PROPERTY(bool searching READ searching NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)

public:
    explicit Printers(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QVariantList printers() const { return m_printers; }
    QVariantList discovered() const;
    bool searching() const { return m_searching; }
    bool busy() const { return m_busy; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void discover();
    Q_INVOKABLE void add(const QString &displayName, const QString &uri);
    Q_INVOKABLE void remove(const QString &name);
    Q_INVOKABLE void setDefault(const QString &name);
    Q_INVOKABLE void printTestPage(const QString &name);
    Q_INVOKABLE void cancelJobs(const QString &name);

Q_SIGNALS:
    void changed();
    void finished(bool success, const QString &message);

private:
    void admin(const QStringList &args, const QString &okMessage, const QString &failMessage);
    bool m_available = false;
    bool m_searching = false;
    bool m_busy = false;
    QVariantList m_printers, m_found;
};
