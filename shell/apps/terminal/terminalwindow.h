#pragma once
#include "termtheme.h"

#include <QFileSystemWatcher>
#include <QTimer>
#include <QWidget>
#include <functional>

class QTermWidget;
class QTabBar;
class QStackedWidget;
class QSplitter;
class QToolButton;
class QTreeView;
class QFileSystemModel;
class QLabel;

// Fenêtre du Terminal VinX (ADR 0025) : onglets de QTermWidget, toujours sombre, et à gauche
// l'arborescence du dossier courant (comme MobaXterm) : double-clic sur un dossier = « cd »,
// sur un fichier = ouverture avec l'application par défaut.
class TerminalWindow : public QWidget
{
    Q_OBJECT
public:
    explicit TerminalWindow(const QString &workingDirectory = {}, QWidget *parent = nullptr);
    QTermWidget *newTab(const QString &workingDirectory = {});
    QTermWidget *current() const;

private:
    QWidget *buildTree();
    void applyAppearance();
    void updateTitle();
    void closeTab(int index);
    void showContextMenu(QTermWidget *term, const QPoint &pos);
    void showTreeMenu(const QPoint &pos);
    void addShortcut(const QKeySequence &keys, const std::function<void()> &action);
    void followDirectory();
    void setTreeRoot(const QString &dir);
    void changeDirectory(const QString &dir);
    void setTreeVisible(bool visible);
    bool eventFilter(QObject *watched, QEvent *event) override;
    void copyInto(const QList<QUrl> &urls, const QString &dir);
    void markActivity(QTermWidget *term, bool active);

    QTabBar *m_tabBar = nullptr;
    QStackedWidget *m_stack = nullptr;
    QSplitter *m_split = nullptr;
    QToolButton *m_treeButton = nullptr;
    QWidget *m_treePanel = nullptr;
    QTreeView *m_tree = nullptr;
    QFileSystemModel *m_model = nullptr;
    QLabel *m_crumb = nullptr;
    QLabel *m_status = nullptr;
    QString m_dir;
    QTimer m_follow;
    QFileSystemWatcher m_watcher;
    QString m_iniPath;
    termtheme::Appearance m_appearance;
};
