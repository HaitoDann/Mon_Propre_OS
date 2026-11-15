#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Passerelle entre les menus d'application exportés en DBusMenu (QAction / QMenu, via le
// modèle AppMenuModel de KDE) et les menus VinX en QML.
class MenuBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit MenuBridge(QObject *parent = nullptr);

    // Entrées du sous-menu d'une action : [{ text, enabled, checkable, checked, separator,
    // submenu, shortcut, action }]. Demande aussi à l'application de mettre le menu à jour.
    Q_INVOKABLE QVariantList items(QObject *action) const;
    Q_INVOKABLE void trigger(QObject *action) const;
    // Libellé sans accélérateur (« &Fichier » → « Fichier »).
    Q_INVOKABLE static QString plainText(const QString &text);
};
