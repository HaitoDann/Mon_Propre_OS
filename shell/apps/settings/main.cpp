#include "appmain.h"

int main(int argc, char *argv[])
{
    const QCommandLineOption page(QStringLiteral("page"), QStringLiteral("Page : appearance, wallpaper, desktop, dock, network, sound, notifications, accessibility, keyboard, datetime, updates, about."), QStringLiteral("page"));
    return vinxAppMain(argc, argv, "vinx-settings", "org.vinx.settings", "qrc:/qt/qml/Vinx/Settings/Main.qml", {page}, {QStringLiteral("startPage")});
}
