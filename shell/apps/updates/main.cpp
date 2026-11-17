#include "appmain.h"

int main(int argc, char *argv[])
{
    const QCommandLineOption page(QStringLiteral("page"), QStringLiteral("Page : overview, history, settings."), QStringLiteral("page"));
    return vinxAppMain(argc, argv, "vinx-updates", "org.vinx.updates", "qrc:/qt/qml/Vinx/Updates/Main.qml", {page}, {QStringLiteral("startPage")});
}
