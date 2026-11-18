#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// Service D-Bus org.vinx.Shell (/Shell) publié par vinx-shell : permet à KWin
// (touche Méta seule) et aux applications VinX de piloter le shell.
class ShellService : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_CLASSINFO("D-Bus Interface", "org.vinx.Shell")
    Q_PROPERTY(bool registered READ registered CONSTANT)

public:
    explicit ShellService(QObject *parent = nullptr);
    bool registered() const { return m_registered; }

public Q_SLOTS:
    Q_SCRIPTABLE void toggleSearch() { Q_EMIT searchRequested(); }
    // name : « search », « control », « calendar », « system », « clipboard ».
    Q_SCRIPTABLE void togglePanel(const QString &name) { Q_EMIT panelRequested(name); }
    Q_SCRIPTABLE void reloadPreferences() { Q_EMIT preferencesReloadRequested(); }
    // Capture d'écran VinX : le shell garde l'image dans le presse-papiers (ADR 0036, 0037).
    Q_SCRIPTABLE void copyImageFile(const QString &path) { Q_EMIT imageCopyRequested(path); }

Q_SIGNALS:
    void searchRequested();
    void preferencesReloadRequested();
    void panelRequested(const QString &name);
    void imageCopyRequested(const QString &path);

private:
    bool m_registered = false;
};
