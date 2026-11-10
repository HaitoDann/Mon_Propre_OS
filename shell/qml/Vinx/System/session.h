#pragma once

#include <QObject>
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

private:
    void callManager(const QString &method);
    void callSession(const QString &method);
};
