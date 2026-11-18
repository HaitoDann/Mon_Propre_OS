#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Actions de session (systemd-logind) et lancement d'applications.
class Session : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString userName READ userName CONSTANT)
    Q_PROPERTY(QString osName READ osName CONSTANT)

public:
    explicit Session(QObject *parent = nullptr);
    QString userName() const;
    QString osName() const;

    Q_INVOKABLE void lock();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void reboot();
    Q_INVOKABLE void powerOff();
    // Lance un programme (ex. « systemsettings »). Renvoie false s'il est introuvable.
    Q_INVOKABLE bool launch(const QString &program, const QStringList &arguments = {});
    Q_INVOKABLE bool fileExists(const QString &path) const;
    // Déclenche un raccourci global de KWin (ex. « Overview », « Window Close »).
    Q_INVOKABLE void invokeKWinShortcut(const QString &name);
    // Fonds d'écran installés : [{ name, path, preview }] (paquets /usr/share/wallpapers/*).
    Q_INVOKABLE QVariantList wallpapers() const;
    // Accent le plus proche de la teinte dominante d'une image ({id, fill} de Theme.accents ; ADR 0021).
    Q_INVOKABLE QString pickAccent(const QString &imagePath, const QVariantList &accents, const QString &neutral) const;
    Q_INVOKABLE QString kernelVersion() const;
    // Appel D-Bus de session sans réponse attendue (ex. renommer un bureau virtuel dans KWin).
    Q_INVOKABLE void callDBus(const QString &service, const QString &path, const QString &interface,
                              const QString &method, const QVariantList &arguments = {}) const;
    Q_INVOKABLE QString hostName() const;
    // Exécute une commande courte et renvoie sa sortie standard (vide en cas d'échec ;
    // délai maximal 3 s). Réservé aux lectures rapides (timedatectl show…).
    // Exécute une commande courte (5 s au plus) ; vrai si elle a réussi.
    Q_INVOKABLE bool run(const QString &program, const QStringList &arguments = {}) const;
    Q_INVOKABLE QString capture(const QString &program, const QStringList &arguments = {}) const;
    // Variable d'environnement (ex. VINX_TASKS_BACKEND=preview pour les tests).
    Q_INVOKABLE QString environment(const QString &name) const { return qEnvironmentVariable(name.toLocal8Bit().constData()); }

private:
    void callManager(const QString &method);
    void callSession(const QString &method);
};
