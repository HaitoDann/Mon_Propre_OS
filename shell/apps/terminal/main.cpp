// Terminal VinX (ADR 0025) : remplace Konsole dans la session VinX.
//   vinx-terminal [--workdir DOSSIER] [-e COMMANDE…]
#include "terminalwindow.h"

#include <qtermwidget.h>

#include <QApplication>
#include <QCommandLineParser>
#include <QFontDatabase>

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("vinx-terminal"));
    QApplication::setApplicationDisplayName(QObject::tr("Terminal"));
    QApplication::setDesktopFileName(QStringLiteral("org.vinx.terminal"));
    QApplication::setFont(QFont(QStringLiteral("IBM Plex Sans"), 10));

    QCommandLineParser parser;
    parser.addHelpOption();
    const QCommandLineOption workdir({QStringLiteral("workdir"), QStringLiteral("w")}, QObject::tr("Dossier de départ."), QObject::tr("dossier"));
    const QCommandLineOption exec(QStringLiteral("e"), QObject::tr("Commande à exécuter (le reste de la ligne)."));
    parser.addOptions({workdir, exec});
    parser.parse(app.arguments());

    TerminalWindow window(parser.value(workdir));
    // -e COMMANDE ARGS… : lancée dans le shell (compatibilité avec les « terminaux » de xdg-terminal-exec / KDE).
    const QStringList rest = parser.positionalArguments();
    if (parser.isSet(exec) && !rest.isEmpty() && window.current()) {
        QStringList quoted;
        for (const QString &a : rest)
            quoted << QLatin1Char('\'') + QString(a).replace(QLatin1Char('\''), QStringLiteral("'\\''")) + QLatin1Char('\'');
        window.current()->sendText(QStringLiteral("exec ") + quoted.join(QLatin1Char(' ')) + QLatin1Char('\n'));
    }
    window.show();
    return app.exec();
}
