#pragma once

#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

// Applications installées (fichiers .desktop des dossiers XDG).
class Applications : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Applications(QObject *parent = nullptr);

    // { name, icon, exec, valid } pour « firefox-esr » ou « firefox-esr.desktop ».
    Q_INVOKABLE QVariantMap info(const QString &desktopId) const;
    Q_INVOKABLE bool launch(const QString &desktopId) const;
};
