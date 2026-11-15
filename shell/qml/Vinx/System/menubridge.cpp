#include "menubridge.h"

#include <QAction>
#include <QMenu>

MenuBridge::MenuBridge(QObject *parent)
    : QObject(parent)
{
}

QString MenuBridge::plainText(const QString &text)
{
    QString out = text;
    out.replace(QLatin1String("&&"), QStringLiteral("\u0001"));
    out.remove(QLatin1Char('&'));
    out.replace(QStringLiteral("\u0001"), QStringLiteral("&"));
    return out;
}

QVariantList MenuBridge::items(QObject *object) const
{
    auto *action = qobject_cast<QAction *>(object);
    auto *menu = action ? action->menu<QMenu *>() : qobject_cast<QMenu *>(object);
    if (!menu)
        return {};
    // L'importeur DBusMenu met le contenu à jour quand le menu va s'afficher.
    Q_EMIT menu->aboutToShow();

    QVariantList out;
    for (QAction *a : menu->actions()) {
        if (!a->isVisible())
            continue;
        out.append(QVariantMap{
            {QStringLiteral("text"), plainText(a->text())},
            {QStringLiteral("enabled"), a->isEnabled()},
            {QStringLiteral("checkable"), a->isCheckable()},
            {QStringLiteral("checked"), a->isChecked()},
            {QStringLiteral("separator"), a->isSeparator()},
            {QStringLiteral("submenu"), a->menu<QMenu *>() != nullptr},
            {QStringLiteral("shortcut"), a->shortcut().toString(QKeySequence::NativeText)},
            {QStringLiteral("action"), QVariant::fromValue<QObject *>(a)},
        });
    }
    return out;
}

void MenuBridge::trigger(QObject *object) const
{
    if (auto *action = qobject_cast<QAction *>(object))
        action->trigger();
}
