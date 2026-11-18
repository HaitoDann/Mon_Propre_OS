#include "appmain.h"

int main(int argc, char *argv[])
{
    const QCommandLineOption step(QStringLiteral("step"), QStringLiteral("Étape affichée au démarrage (0 à 3, captures)."), QStringLiteral("n"));
    return vinxAppMain(argc, argv, "vinx-welcome", "org.vinx.welcome", "qrc:/qt/qml/Vinx/Welcome/Main.qml", {step}, {QStringLiteral("startStep")});
}
