// vinx-window-theme : écrit le thème de fenêtre VinX (Aurorae) et demande à KWin de le recharger.
//   vinx-window-theme [--accent #RRGGBB] [--ink #RRGGBB] [--dark] [--output DOSSIER] [--reconfigure]
// Sans --output : ~/.local/share/aurorae/themes/VinX (prioritaire sur le thème installé).
#include "auroraetheme.h"

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDir>
#include <QProcess>
#include <QFile>
#include <QSaveFile>
#include <QStandardPaths>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Thème de fenêtre VinX OS (KWin Aurorae)"));
    parser.addHelpOption();
    const QCommandLineOption accent(QStringLiteral("accent"), QStringLiteral("Couleur d'accent."), QStringLiteral("couleur"), QStringLiteral("#10DD8C"));
    const QCommandLineOption ink(QStringLiteral("ink"), QStringLiteral("Encre posée sur l'accent."), QStringLiteral("couleur"), QStringLiteral("#06130D"));
    const QCommandLineOption dark(QStringLiteral("dark"), QStringLiteral("Thème sombre."));
    const QCommandLineOption output(QStringLiteral("output"), QStringLiteral("Dossier du thème."), QStringLiteral("dossier"));
    const QCommandLineOption reconfigure(QStringLiteral("reconfigure"), QStringLiteral("Demande à KWin de recharger la décoration."));
    parser.addOptions({accent, ink, dark, output, reconfigure});
    parser.process(app);

    windowtheme::Colors colors;
    colors.accent = QColor(parser.value(accent));
    colors.accentInk = QColor(parser.value(ink));
    colors.dark = parser.isSet(dark);
    if (!colors.accent.isValid() || !colors.accentInk.isValid()) {
        qCritical("vinx-window-theme : couleur invalide");
        return 2;
    }
    const QString dir = parser.isSet(output) ? parser.value(output)
        : QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/aurorae/themes/VinX");
    if (!QDir().mkpath(dir)) {
        qCritical("vinx-window-theme : impossible de créer %s", qUtf8Printable(dir));
        return 1;
    }
    const auto files = windowtheme::themeFiles(colors);
    for (auto it = files.cbegin(); it != files.cend(); ++it) {
        QSaveFile f(dir + QLatin1Char('/') + it.key());
        if (!f.open(QIODevice::WriteOnly) || f.write(it.value()) != it.value().size() || !f.commit()) {
            qCritical("vinx-window-theme : écriture impossible de %s", qUtf8Printable(f.fileName()));
            return 1;
        }
    }
    // Pastilles des applications GTK à barre de titre intégrée (Firefox, Thunderbird).
    if (!parser.isSet(output)) {
        const QString block = windowtheme::gtkCss(colors);
        for (const char *dirName : {"gtk-3.0", "gtk-4.0"}) {
            const QString cssDir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QLatin1Char('/') + QLatin1String(dirName);
            QDir().mkpath(cssDir);
            QFile in(cssDir + QStringLiteral("/gtk.css"));
            const QString existing = in.open(QIODevice::ReadOnly) ? QString::fromUtf8(in.readAll()) : QString();
            in.close();
            const QString merged = windowtheme::mergeGtkCss(existing, block);
            if (merged != existing) {
                QSaveFile out(in.fileName());
                if (out.open(QIODevice::WriteOnly)) {
                    out.write(merged.toUtf8());
                    out.commit();
                }
            }
        }
    }
    if (parser.isSet(reconfigure)) {
        // Plasma réécrit Breeze dans kwinrc à l'ouverture de session (après vinx-session) : on impose
        // la décoration VinX ici, une fois la session démarrée (ADR 0024).
        const QList<QPair<QString, QString>> keys = {
            {QStringLiteral("library"), QStringLiteral("org.kde.kwin.aurorae")},
            {QStringLiteral("theme"), QStringLiteral("__aurorae__svg__VinX")},
            {QStringLiteral("ButtonsOnLeft"), QString()},
            {QStringLiteral("ButtonsOnRight"), QStringLiteral("IAX")},
        };
        for (const auto &kv : keys)
            QProcess::execute(QStringLiteral("kwriteconfig6"), {QStringLiteral("--file"), QStringLiteral("kwinrc"),
                              QStringLiteral("--group"), QStringLiteral("org.kde.kdecoration2"),
                              QStringLiteral("--key"), kv.first, kv.second});
        // Aurorae garde ses SVG en cache : KWin les relit à la reconfiguration.
        QDBusConnection::sessionBus().call(QDBusMessage::createMethodCall(
            QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"), QStringLiteral("org.kde.KWin"), QStringLiteral("reconfigure")),
            QDBus::NoBlock);
    }
    return 0;
}
