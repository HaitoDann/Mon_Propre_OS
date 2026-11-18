#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// Services D-Bus de KDE que plasmashell assurait et que vinx-shell reprend (ADR 0028) :
//  - org.kde.osdService (/org/kde/osdService) : bulles de volume, luminosité, micro… (plasma-pa,
//    powerdevil, kded les appellent quand on appuie sur les touches du clavier) ;
//  - org.kde.LogoutPrompt (/LogoutPrompt) : demande d'extinction, de redémarrage ou de fermeture
//    de session (bouton d'alimentation, applications KDE).
// Publiés seulement par le processus vinx-shell (VINX_SHELL_PROCESS=1).
class OsdAdaptor;
class LogoutAdaptor;

class DesktopPrompts : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool osdRegistered READ osdRegistered CONSTANT)
    Q_PROPERTY(bool logoutRegistered READ logoutRegistered CONSTANT)
public:
    explicit DesktopPrompts(QObject *parent = nullptr);
    bool osdRegistered() const { return m_osd; }
    bool logoutRegistered() const { return m_logout; }

Q_SIGNALS:
    // kind : « volume », « microphone », « brightness », « keyboard », « text » ; percent : -1 si sans jauge.
    void osd(const QString &kind, const QString &icon, int percent, const QString &text);
    // action : « logout », « poweroff », « reboot » ou « all » (choix proposé).
    void logoutRequested(const QString &action);

private:
    friend class OsdAdaptor;
    friend class LogoutAdaptor;
    bool m_osd = false, m_logout = false;
};

class OsdAdaptor : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.osdService")
public:
    explicit OsdAdaptor(DesktopPrompts *owner) : QObject(owner), m_owner(owner) {}
public Q_SLOTS:
    void brightnessChanged(int percent) { emitOsd(QStringLiteral("brightness"), QStringLiteral("brightness"), percent); }
    void keyboardBrightnessChanged(int percent) { emitOsd(QStringLiteral("keyboard"), QStringLiteral("keyboard"), percent); }
    void volumeChanged(int percent) { volumeChanged(percent, 100); }
    void volumeChanged(int percent, int maximumPercent);
    void microphoneVolumeChanged(int percent) { emitOsd(QStringLiteral("microphone"), QStringLiteral("volume"), percent); }
    void mediaPlayerVolumeChanged(int percent, const QString &playerName, const QString &) { emitOsd(QStringLiteral("volume"), QStringLiteral("volume"), percent, playerName); }
    void kbdLayoutChanged(const QString &layout) { emitOsd(QStringLiteral("text"), QStringLiteral("keyboard"), -1, layout); }
    void kbdLayoutChanged(const QString &shortName, const QString &longName) { emitOsd(QStringLiteral("text"), QStringLiteral("keyboard"), -1, longName.isEmpty() ? shortName : longName); }
    void virtualDesktopChanged(const QString &name) { emitOsd(QStringLiteral("text"), QStringLiteral("grid"), -1, name); }
    void showText(const QString &, const QString &text) { emitOsd(QStringLiteral("text"), QStringLiteral("info"), -1, text); }
    void powerManagementInhibitedChanged(bool inhibited);
    void powerProfileChanged(const QString &profile);
private:
    void emitOsd(const QString &kind, const QString &icon, int percent, const QString &text = {}) { Q_EMIT m_owner->osd(kind, icon, percent, text); }
    DesktopPrompts *m_owner;
};

class LogoutAdaptor : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.LogoutPrompt")
public:
    explicit LogoutAdaptor(DesktopPrompts *owner) : QObject(owner), m_owner(owner) {}
public Q_SLOTS:
    void promptLogout() { Q_EMIT m_owner->logoutRequested(QStringLiteral("logout")); }
    void promptShutDown() { Q_EMIT m_owner->logoutRequested(QStringLiteral("poweroff")); }
    void promptReboot() { Q_EMIT m_owner->logoutRequested(QStringLiteral("reboot")); }
    void promptAll() { Q_EMIT m_owner->logoutRequested(QStringLiteral("all")); }
private:
    DesktopPrompts *m_owner;
};
