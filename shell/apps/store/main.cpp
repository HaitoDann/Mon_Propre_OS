#include "appmain.h"

int main(int argc, char *argv[])
{
    const QCommandLineOption page(QStringLiteral("page"), QStringLiteral("Onglet : discover, search, installed, updates."), QStringLiteral("page"));
    const QCommandLineOption search(QStringLiteral("search"), QStringLiteral("Recherche à lancer (« debian: » pour le dépôt Debian)."), QStringLiteral("texte"));
    return vinxAppMain(argc, argv, "vinx-store", "org.vinx.store", "qrc:/qt/qml/Vinx/Store/Main.qml", {page, search},
                       {QStringLiteral("startPage"), QStringLiteral("startQuery")});
}
