#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QUrl>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

#include "folderentry.h"

#ifdef VINX_HAVE_KIO
class KCoreDirLister;
#endif

// Contenu d'un dossier pour le QML. Moteur KIO (dossiers locaux, corbeille, réseau,
// périphériques) si disponible à la compilation, sinon lecture locale (QDir).
class FolderModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString title READ title NOTIFY urlChanged)
    Q_PROPERTY(bool canGoUp READ canGoUp NOTIFY urlChanged)

public:
    enum Roles { NameRole = Qt::UserRole + 1, UrlRole, PathRole, IsDirRole, SizeRole, SizeTextRole,
                 ModifiedRole, MimeTypeRole, IconNameRole, IsImageRole };

    explicit FolderModel(QObject *parent = nullptr);
    ~FolderModel() override;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QUrl url() const { return m_url; }
    void setUrl(const QUrl &url);
    bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool v);
    QString filter() const { return m_filter; }
    void setFilter(const QString &f);
    int count() const { return int(m_visible.size()); }
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }
    QString title() const;
    bool canGoUp() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QUrl parentUrl() const;
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE int indexOfName(const QString &name) const;
    // Fil d'Ariane : [{ name, url }] du dossier racine au dossier courant.
    Q_INVOKABLE QVariantList breadcrumb() const;
    // Emplacements de la barre latérale : [{ name, url, icon, section }].
    Q_INVOKABLE static QVariantList places();
    // Convertit un texte saisi (« ~/Documents », « /tmp », « smb://… ») en URL.
    Q_INVOKABLE static QUrl urlFromText(const QString &text);
    Q_INVOKABLE static QString formatSize(qint64 bytes);
    Q_INVOKABLE static bool kioAvailable();

Q_SIGNALS:
    void urlChanged();
    void showHiddenChanged();
    void filterChanged();
    void countChanged();
    void loadingChanged();
    void errorChanged();

private:
    void setEntries(QList<FolderEntry> entries);
    void applyFilter();
    void setLoading(bool v);
    void setError(const QString &e);
    void listLocal();

    QUrl m_url;
    bool m_showHidden = false;
    QString m_filter;
    bool m_loading = false;
    QString m_error;
    QList<FolderEntry> m_all;
    QList<FolderEntry> m_visible;
    QFileSystemWatcher m_watcher;
#ifdef VINX_HAVE_KIO
    KCoreDirLister *m_lister = nullptr;
#endif
};
