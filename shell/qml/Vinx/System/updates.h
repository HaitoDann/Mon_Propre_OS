#pragma once

#include <QDateTime>
#include <QFileSystemWatcher>
#include <QTimer>
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
    // Installation en arrière-plan (vinx-update, détachée) : suivie en direct par tous les processus.
    Q_PROPERTY(int progress READ progress NOTIFY stateChanged)          // 0-100, -1 hors installation
    Q_PROPERTY(QString stepLabel READ stepLabel NOTIFY stateChanged)

public:
    explicit Updates(QObject *parent = nullptr);
    bool checking() const { return m_step == Check; }
    bool applying() const { return m_step == Apply || m_bgRunning; }
    int progress() const { return m_bgRunning ? m_bgPercent : -1; }
    QString stepLabel() const;
    QString status() const { return m_status; }
    QVariantList system() const { return m_system; }
    QVariantList apps() const { return m_apps; }
    int count() const { return int(m_system.size() + m_apps.size()); }
    QDateTime lastCheck() const { return m_lastCheck; }
    bool packageKitAvailable() const { return m_pkcon; }

    Q_INVOKABLE void check();
    // Versions : { vinxOs, desktop, debian, kernel } (chaînes ; vide si inconnue).
    Q_INVOKABLE QVariantMap versions() const;
    // Opérations passées (journal d'APT), la plus récente d'abord.
    Q_INVOKABLE QVariantList history() const;
    // appsOnly : seulement les applications Flatpak (aucun mot de passe ; mises à jour automatiques).
    Q_INVOKABLE void applyAll(bool appsOnly = false);

Q_SIGNALS:
    void stateChanged();
    void listChanged();
    void finished(bool success, const QString &message);

private:
    enum Step { Idle, Check, Apply };
    void run(const QString &program, const QStringList &args, std::function<void(bool, const QString &)> done);
    void setStatus(const QString &s);
    void end(bool ok, const QString &message);

    Step m_step = Idle;
    QString m_status;
    QVariantList m_system, m_apps;
    QDateTime m_lastCheck;
    bool m_pkcon = false, m_flatpak = false;
    void readStatus();
    QFileSystemWatcher m_watcher;
    QTimer m_poll;
    bool m_bgRunning = false;
    int m_bgPercent = 0;
    QString m_bgStep;
};
