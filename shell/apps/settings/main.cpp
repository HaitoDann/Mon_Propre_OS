#include "appmain.h"

int main(int argc, char *argv[])
{
    const QCommandLineOption page(QStringLiteral("page"), QStringLiteral("Page : appearance, wallpaper, desktop, dock, notifications, about."), QStringLiteral("page"));
    return vinxAppMain(argc, argv, "vinx-settings", "org.vinx.settings", "qrc:/qt/qml/Vinx/Settings/Main.qml", {page}, {QStringLiteral("startPage")});
}
