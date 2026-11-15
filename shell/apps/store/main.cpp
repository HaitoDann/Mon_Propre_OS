#include "appmain.h"

int main(int argc, char *argv[])
{
    const QCommandLineOption page(QStringLiteral("page"), QStringLiteral("Onglet : discover, search, installed, updates."), QStringLiteral("page"));
    return vinxAppMain(argc, argv, "vinx-store", "org.vinx.store", "qrc:/qt/qml/Vinx/Store/Main.qml", {page}, {QStringLiteral("startPage")});
}
