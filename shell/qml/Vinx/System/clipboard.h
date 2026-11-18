#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

#include "cliphistory.h"

class QMimeData;

// Historique du presse-papiers (ADR 0037), tenu par vinx-shell et affiché par Méta+V.
// Sous Wayland, le shell n'a jamais le focus : KSystemClipboard (KDE, protocole data-control)
// lui permet de suivre et de remplir le presse-papiers. Sans KDE : presse-papiers de Qt.
// Rien ne quitte l'ordinateur ; seuls les éléments épinglés sont écrits sur le disque.
class Clipboard : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)

public:
    explicit Clipboard(QObject *parent = nullptr);
    QVariantList items() const;

    Q_INVOKABLE void activate(const QString &id);   // remettre dans le presse-papiers
    Q_INVOKABLE void setPinned(const QString &id, bool pinned);
    Q_INVOKABLE void remove(const QString &id);
    Q_INVOKABLE void clear();
    Q_INVOKABLE void copyImageFile(const QString &path);   // capture d'écran VinX (ADR 0036)
    Q_INVOKABLE void copyText(const QString &text);

    // Lecture d'un contenu copié ; publique pour les tests.
    void capture(const QMimeData *data);

Q_SIGNALS:
    void itemsChanged();

private Q_SLOTS:
    void onChanged();

private:
    const QMimeData *current() const;
    void publish(const ClipItem &item);
    void savePinned() const;
    void loadPinned();
    QString storeDir() const;

    ClipHistory m_history;
    bool m_publishing = false;
    bool m_secret = false;   // dernier contenu copié = mot de passe : ne pas le restaurer
};
