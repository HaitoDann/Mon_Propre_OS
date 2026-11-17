#pragma once
#include "termtheme.h"

#include <QFileSystemWatcher>
#include <QTabWidget>
#include <QWidget>

class QTermWidget;
class QToolButton;

// Fenêtre du Terminal VinX : onglets de QTermWidget aux couleurs de VinX.
class TerminalWindow : public QWidget
{
    Q_OBJECT
public:
    explicit TerminalWindow(const QString &workingDirectory = {}, QWidget *parent = nullptr);
    QTermWidget *newTab(const QString &workingDirectory = {});
    QTermWidget *current() const;

private:
    void applyAppearance();
    void updateTitle();
    void closeTab(int index);
    void showContextMenu(QTermWidget *term, const QPoint &pos);
    void addShortcut(const QKeySequence &keys, const std::function<void()> &action);

    QTabWidget *m_tabs = nullptr;
    QToolButton *m_add = nullptr;
    QFileSystemWatcher m_watcher;
    QString m_iniPath;
    termtheme::Appearance m_appearance;
};
