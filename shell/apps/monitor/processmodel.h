#pragma once

#include <QAbstractListModel>
#include <QElapsedTimer>
#include <QHash>
#include <QSet>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Moniteur système (ADR 0035) : processus regroupés par application, totaux de la machine.
// Liste « à plat » : une ligne par application, suivie de ses processus quand elle est dépliée.
// Rafraîchie toutes les deux secondes sans réinitialiser la vue (déplacements de lignes).
class ProcessModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int sortColumn READ sortColumn WRITE setSortColumn NOTIFY sortChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(double cpu READ cpu NOTIFY statsChanged)
    Q_PROPERTY(double memUsed READ memUsed NOTIFY statsChanged)
    Q_PROPERTY(double memTotal READ memTotal NOTIFY statsChanged)
    Q_PROPERTY(double diskRead READ diskRead NOTIFY statsChanged)
    Q_PROPERTY(double diskWrite READ diskWrite NOTIFY statsChanged)
    Q_PROPERTY(double netIn READ netIn NOTIFY statsChanged)
    Q_PROPERTY(double netOut READ netOut NOTIFY statsChanged)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY statsChanged)
    Q_PROPERTY(QVariantList memHistory READ memHistory NOTIFY statsChanged)
    Q_PROPERTY(QVariantList diskHistory READ diskHistory NOTIFY statsChanged)
    Q_PROPERTY(QVariantList netHistory READ netHistory NOTIFY statsChanged)
    Q_PROPERTY(int processCount READ processCount NOTIFY statsChanged)

public:
    enum Column { Name, Cpu, Memory, Disk };
    Q_ENUM(Column)
    enum Role {
        KeyRole = Qt::UserRole + 1, KindRole, NameRole, IconRole, CountRole, CpuRole, MemoryRole,
        DiskRole, PidRole, ExpandedRole, OwnRole, CommandRole, LowPriorityRole, SystemRole
    };

    explicit ProcessModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int sortColumn() const { return m_sort; }
    void setSortColumn(int c);
    QString filter() const { return m_filter; }
    void setFilter(const QString &f);
    bool paused() const { return m_paused; }
    void setPaused(bool p);

    double cpu() const { return m_cpu; }
    double memUsed() const { return m_memUsed; }
    double memTotal() const { return m_memTotal; }
    double diskRead() const { return m_disk.first; }
    double diskWrite() const { return m_disk.second; }
    double netIn() const { return m_net.first; }
    double netOut() const { return m_net.second; }
    QVariantList cpuHistory() const { return m_cpuHist; }
    QVariantList memHistory() const { return m_memHist; }
    QVariantList diskHistory() const { return m_diskHist; }
    QVariantList netHistory() const { return m_netHist; }
    int processCount() const { return m_procs.size(); }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggleExpanded(const QString &key);
    Q_INVOKABLE void setExpanded(const QString &key, bool expanded);
    Q_INVOKABLE int indexOf(const QString &key) const;
    // Actions sur une ligne (application ou processus) ; seulement les processus de l'utilisateur.
    Q_INVOKABLE bool close(const QString &key);        // SIGTERM : fermeture propre
    Q_INVOKABLE bool forceClose(const QString &key);   // SIGKILL
    Q_INVOKABLE bool isRunning(const QString &key) const;
    Q_INVOKABLE bool canAct(const QString &key) const { return !pidsFor(key).isEmpty(); }
    Q_INVOKABLE bool lowerPriority(const QString &key);
    Q_INVOKABLE QString location(const QString &key) const;   // dossier du programme
    Q_INVOKABLE QString command(const QString &key) const;
    Q_INVOKABLE void copyText(const QString &text) const;
    Q_INVOKABLE QString name(const QString &key) const;

Q_SIGNALS:
    void sortChanged();
    void filterChanged();
    void pausedChanged();
    void statsChanged();

private:
    struct Proc {
        int pid = 0, ppid = 0;
        qint64 uid = -1;
        QString comm, exe, cmdline, cgApp, group;
        quint64 ticks = 0, ioRead = 0, ioWrite = 0;
        qint64 mem = 0;
        int nice = 0;
        double cpu = 0, rd = 0, wr = 0;
    };
    struct Group {
        QString key, name, icon;
        bool system = false;
        QList<int> pids;
    };
    struct Row {
        QString key, name, icon, command;
        int kind = 0;   // 0 application, 1 processus
        int count = 0, pid = 0;
        double cpu = 0, mem = 0, disk = 0;
        bool own = false, low = false, system = false, expanded = false;
    };
    struct AppInfo {
        QString id, name, icon;
        bool hidden = false;
    };

    void scanDesktopFiles();
    AppInfo appFor(const QString &desktopId) const;
    AppInfo appForRoot(const Proc &p) const;
    QString groupKeyFor(const Proc &p) const;
    void rebuild();
    void applyRows(const QList<Row> &rows);
    QList<int> pidsFor(const QString &key) const;
    bool signalKey(const QString &key, int sig);
    static void push(QVariantList &h, double v);

    QTimer m_timer;
    QElapsedTimer m_clock;
    qint64 m_lastMs = 0;
    long m_hz = 100;
    int m_cores = 1;
    qint64 m_uid = -1;
    int m_sort = Cpu;
    QString m_filter;
    bool m_paused = false;

    QHash<int, Proc> m_procs;
    QHash<QString, Group> m_groups;
    QList<Row> m_rows;
    QSet<QString> m_expanded;
    QHash<QString, AppInfo> m_appsById;     // identifiant .desktop → application
    QHash<QString, QString> m_appByProgram; // nom du programme lancé → identifiant

    quint64 m_cpuTotal = 0, m_cpuIdle = 0;
    QPair<quint64, quint64> m_diskBytes, m_netBytes;
    double m_cpu = 0, m_memUsed = 0, m_memTotal = 0;
    QPair<double, double> m_disk, m_net;
    QVariantList m_cpuHist, m_memHist, m_diskHist, m_netHist;
};
