#pragma once

#include <QDateTime>
#include <functional>
#include <QObject>
#include <QProcess>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Mises à jour du système : paquets Debian (via PackageKit, authentification polkit) et
// applications Flatpak (installations système et utilisateur).
class Updates : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool checking READ checking NOTIFY stateChanged)
    Q_PROPERTY(bool applying READ applying NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(QVariantList system READ system NOTIFY listChanged)       // [{ name, version, from }]
    Q_PROPERTY(QVariantList apps READ apps NOTIFY listChanged)           // [{ id, name, version }]
    Q_PROPERTY(int count READ count NOTIFY listChanged)
    Q_PROPERTY(QDateTime lastCheck READ lastCheck NOTIFY listChanged)
    Q_PROPERTY(bool packageKitAvailable READ packageKitAvailable CONSTANT)

public:
    explicit Updates(QObject *parent = nullptr);
    bool checking() const { return m_step == Check; }
    bool applying() const { return m_step == Apply; }
    QString status() const { return m_status; }
    QVariantList system() const { return m_system; }
    QVariantList apps() const { return m_apps; }
    int count() const { return int(m_system.size() + m_apps.size()); }
    QDateTime lastCheck() const { return m_lastCheck; }
    bool packageKitAvailable() const { return m_pkcon; }

    Q_INVOKABLE void check();
    Q_INVOKABLE void applyAll();

Q_SIGNALS:
    void stateChanged();
    void listChanged();
    void finished(bool success, const QString &message);

private:
    enum Step { Idle, Check, Apply };
    void run(const QString &program, const QStringList &args, std::function<void(bool, const QString &)> done);
    void setStatus(const QString &s);
    void end(bool ok, const QString &message);
    void applied(bool ok);

    Step m_step = Idle;
    QString m_status;
    QVariantList m_system, m_apps;
    QDateTime m_lastCheck;
    bool m_pkcon = false, m_flatpak = false;
};
