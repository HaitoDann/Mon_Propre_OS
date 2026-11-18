#include "processmodel.h"
#include "desktopentry.h"
#include "procparse.h"

#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>

#include <algorithm>
#include <csignal>
#include <sys/resource.h>
#include <unistd.h>

namespace {
constexpr int kHistory = 60;
constexpr int kIntervalMs = 2000;
const QString kSystemKey = QStringLiteral("system");

// Racine de /proc ; VINX_PROC_ROOT permet les tests et les captures avec un faux /proc.
QString procRoot()
{
    static const QString root = qEnvironmentVariableIsSet("VINX_PROC_ROOT") ? qEnvironmentVariable("VINX_PROC_ROOT")
                                                                            : QStringLiteral("/proc");
    return root;
}

QByteArray readProc(const QString &rel)
{
    QFile f(procRoot() + QLatin1Char('/') + rel);
    return f.open(QIODevice::ReadOnly) ? f.readAll() : QByteArray();
}

// Processus de la session graphique qui lancent les applications : on ne remonte pas au-delà
// pour trouver l'application d'un processus.
bool isSessionRoot(const QString &comm)
{
    static const QSet<QString> roots = {
        QStringLiteral("systemd"), QStringLiteral("kwin_wayland"), QStringLiteral("kwin_wayland_wr"),
        QStringLiteral("vinx-shell"), QStringLiteral("vinx-session"), QStringLiteral("startplasma-way"),
        QStringLiteral("plasma_session"), QStringLiteral("ksmserver"), QStringLiteral("kded6"),
        QStringLiteral("sddm"), QStringLiteral("sddm-helper"), QStringLiteral("login"), QStringLiteral("sshd"),
        QStringLiteral("dbus-daemon"), QStringLiteral("dbus-broker"), QStringLiteral("Xwayland")};
    return roots.contains(comm);
}
}

ProcessModel::ProcessModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_hz = qMax(1L, sysconf(_SC_CLK_TCK));
    m_cores = qMax(1L, sysconf(_SC_NPROCESSORS_ONLN));
    m_uid = qEnvironmentVariableIsSet("VINX_PROC_UID") ? qEnvironmentVariableIntValue("VINX_PROC_UID") : qint64(getuid());
    for (int i = 0; i < kHistory; ++i) {
        m_cpuHist.append(0.0);
        m_memHist.append(0.0);
        m_diskHist.append(0.0);
        m_netHist.append(0.0);
    }
    scanDesktopFiles();
    m_clock.start();
    m_timer.setInterval(kIntervalMs);
    connect(&m_timer, &QTimer::timeout, this, &ProcessModel::refresh);
    m_timer.start();
    refresh();
}

int ProcessModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant ProcessModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size())
        return {};
    const Row &r = m_rows.at(index.row());
    switch (role) {
    case KeyRole: return r.key;
    case KindRole: return r.kind;
    case Qt::DisplayRole:
    case NameRole: return r.name;
    case IconRole: return r.icon;
    case CountRole: return r.count;
    case CpuRole: return r.cpu;
    case MemoryRole: return r.mem;
    case DiskRole: return r.disk;
    case PidRole: return r.pid;
    case ExpandedRole: return r.expanded;
    case OwnRole: return r.own;
    case CommandRole: return r.command;
    case LowPriorityRole: return r.low;
    case SystemRole: return r.system;
    }
    return {};
}

QHash<int, QByteArray> ProcessModel::roleNames() const
{
    return {{KeyRole, "key"}, {KindRole, "kind"}, {NameRole, "name"}, {IconRole, "icon"}, {CountRole, "count"},
            {CpuRole, "cpu"}, {MemoryRole, "memory"}, {DiskRole, "disk"}, {PidRole, "pid"},
            {ExpandedRole, "expanded"}, {OwnRole, "own"}, {CommandRole, "command"},
            {LowPriorityRole, "lowPriority"}, {SystemRole, "system"}};
}

void ProcessModel::setSortColumn(int c)
{
    if (c == m_sort)
        return;
    m_sort = c;
    Q_EMIT sortChanged();
    rebuild();
}

void ProcessModel::setFilter(const QString &f)
{
    if (f == m_filter)
        return;
    m_filter = f;
    Q_EMIT filterChanged();
    rebuild();
}

void ProcessModel::setPaused(bool p)
{
    if (p == m_paused)
        return;
    m_paused = p;
    p ? m_timer.stop() : m_timer.start();
    Q_EMIT pausedChanged();
}

// ---------- Applications installées ----------

void ProcessModel::scanDesktopFiles()
{
    const auto dirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    for (const QString &dir : dirs) {
        const auto files = QDir(dir).entryList({QStringLiteral("*.desktop")}, QDir::Files);
        for (const QString &file : files) {
            const QString id = file.chopped(8);
            if (m_appsById.contains(id))
                continue;   // le premier dossier XDG (utilisateur) l'emporte
            QFile f(dir + QLatin1Char('/') + file);
            if (!f.open(QIODevice::ReadOnly))
                continue;
            const DesktopEntry e = parseDesktopEntry(f.readAll());
            if (!e.valid)
                continue;
            m_appsById.insert(id, {id, e.name, e.icon, e.hidden});
            const QString program = ProcParse::execProgram(desktopExecArguments(e.exec));
            if (!program.isEmpty() && !e.hidden && !m_appByProgram.contains(program))
                m_appByProgram.insert(program, id);
        }
    }
}

ProcessModel::AppInfo ProcessModel::appFor(const QString &desktopId) const
{
    if (m_appsById.contains(desktopId))
        return m_appsById.value(desktopId);
    for (auto it = m_appsById.cbegin(); it != m_appsById.cend(); ++it) {
        if (it.key().compare(desktopId, Qt::CaseInsensitive) == 0)
            return it.value();
    }
    return {};
}

// Clé de regroupement : unité systemd de l'application, sinon le premier ancêtre lancé par la
// session (le navigateur pour ses onglets, le terminal pour son shell…), sinon « système ».
QString ProcessModel::groupKeyFor(const Proc &p) const
{
    if (p.uid != m_uid)
        return kSystemKey;
    if (!p.cgApp.isEmpty())
        return QStringLiteral("app:") + p.cgApp;
    const Proc *root = &p;
    QSet<int> seen;
    while (true) {
        auto it = m_procs.constFind(root->ppid);
        if (it == m_procs.cend() || it->pid <= 1 || it->uid != m_uid || isSessionRoot(it->comm) || seen.contains(it->pid))
            break;
        if (!it->cgApp.isEmpty())
            return QStringLiteral("app:") + it->cgApp;
        seen.insert(root->pid);
        root = &it.value();
    }
    return QStringLiteral("root:") + QString::number(root->pid);
}

// Application d'un processus racine : nom du programme, nom court, premier argument
// (« python3 script.py »), et quelques programmes connus sous un autre nom que leur lanceur.
ProcessModel::AppInfo ProcessModel::appForRoot(const Proc &p) const
{
    static const QHash<QString, QString> aliases = {
        {QStringLiteral("soffice.bin"), QStringLiteral("libreoffice-startcenter")},
        {QStringLiteral("oosplash"), QStringLiteral("libreoffice-startcenter")},
        {QStringLiteral("libreoffice"), QStringLiteral("libreoffice-startcenter")}};
    const QStringList argv = p.cmdline.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    QStringList candidates = {p.exe.section(QLatin1Char('/'), -1), p.comm};
    if (!argv.isEmpty())
        candidates << argv.first().section(QLatin1Char('/'), -1);
    static const QRegularExpression interpreter(QStringLiteral("^(python[0-9.]*|perl|ruby|sh|bash|node|java|gjs)$"));
    if (argv.size() > 1 && interpreter.match(candidates.first()).hasMatch())
        candidates.prepend(argv.at(1).section(QLatin1Char('/'), -1));
    for (const QString &c : std::as_const(candidates)) {
        if (c.isEmpty())
            continue;
        for (const QString &id : {aliases.value(c), m_appByProgram.value(c), c}) {
            if (id.isEmpty())
                continue;
            const AppInfo app = appFor(id);
            if (!app.name.isEmpty() && !app.hidden)
                return app;
        }
    }
    return {};
}

// ---------- Mesures ----------

void ProcessModel::refresh()
{
    const qint64 now = m_clock.elapsed();
    const double dt = m_lastMs > 0 ? qMax<qint64>(1, now - m_lastMs) / 1000.0 : 0;
    m_lastMs = now;
    const long pageSize = sysconf(_SC_PAGESIZE);

    QHash<int, Proc> procs;
    const auto entries = QDir(procRoot()).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &name : entries) {
        bool numeric = false;
        const int pid = name.toInt(&numeric);
        if (!numeric)
            continue;
        const ProcParse::Stat st = ProcParse::parseStat(readProc(name + QLatin1String("/stat")));
        if (!st.ok || st.ppid == 2 || pid == 2)
            continue;   // fils du noyau
        Proc p;
        p.pid = pid;
        p.ppid = st.ppid;
        p.comm = st.comm;
        p.ticks = st.ticks;
        p.nice = st.nice;
        p.uid = ProcParse::uid(readProc(name + QLatin1String("/status")));
        p.cmdline = ProcParse::commandLine(readProc(name + QLatin1String("/cmdline")));
        p.cgApp = ProcParse::appIdFromCgroup(readProc(name + QLatin1String("/cgroup")));
        p.mem = st.rssPages * pageSize;
        if (p.uid == m_uid) {
            p.exe = QFileInfo(procRoot() + QLatin1Char('/') + name + QLatin1String("/exe")).symLinkTarget();
            // Mémoire proportionnelle (PSS) : la mémoire partagée entre processus n'est comptée qu'une fois.
            const qint64 pss = ProcParse::field(readProc(name + QLatin1String("/smaps_rollup")), "Pss");
            if (pss >= 0)
                p.mem = pss * 1024;
            const ProcParse::Counters io = ProcParse::parseIo(readProc(name + QLatin1String("/io")));
            p.ioRead = io.in;
            p.ioWrite = io.out;
        }
        const auto old = m_procs.constFind(pid);
        if (dt > 0 && old != m_procs.cend() && old->comm == p.comm) {
            p.cpu = qBound(0.0, double(p.ticks - qMin(p.ticks, old->ticks)) / (dt * m_hz * m_cores) * 100.0, 100.0);
            p.rd = double(p.ioRead - qMin(p.ioRead, old->ioRead)) / dt;
            p.wr = double(p.ioWrite - qMin(p.ioWrite, old->ioWrite)) / dt;
        }
        procs.insert(pid, p);
    }
    m_procs = procs;

    // Machine entière.
    const ProcParse::CpuTimes cpu = ProcParse::parseCpu(readProc(QStringLiteral("stat")));
    if (m_cpuTotal > 0 && cpu.total > m_cpuTotal)
        m_cpu = 100.0 * (1.0 - double(cpu.idle - qMin(cpu.idle, m_cpuIdle)) / double(cpu.total - m_cpuTotal));
    m_cpuTotal = cpu.total;
    m_cpuIdle = cpu.idle;
    const ProcParse::Memory mem = ProcParse::parseMeminfo(readProc(QStringLiteral("meminfo")));
    m_memTotal = mem.totalKb * 1024.0;
    m_memUsed = (mem.totalKb - mem.availableKb) * 1024.0;
    const ProcParse::Counters disk = ProcParse::parseDiskstats(readProc(QStringLiteral("diskstats")));
    const ProcParse::Counters net = ProcParse::parseNetDev(readProc(QStringLiteral("net/dev")));
    if (dt > 0) {
        m_disk = {double(disk.in - qMin(disk.in, m_diskBytes.first)) / dt, double(disk.out - qMin(disk.out, m_diskBytes.second)) / dt};
        m_net = {double(net.in - qMin(net.in, m_netBytes.first)) / dt, double(net.out - qMin(net.out, m_netBytes.second)) / dt};
    }
    m_diskBytes = {disk.in, disk.out};
    m_netBytes = {net.in, net.out};
    push(m_cpuHist, m_cpu);
    push(m_memHist, m_memTotal > 0 ? 100.0 * m_memUsed / m_memTotal : 0);
    push(m_diskHist, m_disk.first + m_disk.second);
    push(m_netHist, m_net.first + m_net.second);

    // Regroupement.
    m_groups.clear();
    QHash<QString, AppInfo> resolved;
    for (auto it = m_procs.begin(); it != m_procs.end(); ++it) {
        QString key = groupKeyFor(it.value());
        auto cached = resolved.constFind(key);
        if (cached == resolved.cend()) {
            AppInfo info;
            if (key.startsWith(QLatin1String("app:")))
                info = appFor(key.mid(4));
            else if (key.startsWith(QLatin1String("root:")))
                info = appForRoot(m_procs.value(key.mid(5).toInt()));
            cached = resolved.insert(key, info);
        }
        const AppInfo app = cached.value();
        if (key != kSystemKey && (app.name.isEmpty() || app.hidden))
            key = kSystemKey;   // pas une application visible : service du bureau ou du système
        else if (key != kSystemKey)
            key = QStringLiteral("app:") + app.id;
        it->group = key;
        Group &g = m_groups[key];
        if (g.key.isEmpty()) {
            g.key = key;
            g.system = key == kSystemKey;
            g.name = g.system ? tr("Services du système") : app.name;
            g.icon = g.system ? QString() : app.icon;
        }
        g.pids.append(it->pid);
    }
    rebuild();
    Q_EMIT statsChanged();
}

void ProcessModel::push(QVariantList &h, double v)
{
    h.removeFirst();
    h.append(v);
}

// ---------- Lignes affichées ----------

void ProcessModel::rebuild()
{
    const QString needle = m_filter.trimmed();
    auto procMatches = [&](const Proc &p) {
        return p.comm.contains(needle, Qt::CaseInsensitive) || p.cmdline.contains(needle, Qt::CaseInsensitive)
            || QString::number(p.pid) == needle;
    };
    auto value = [this](const Row &r) {
        switch (m_sort) {
        case Memory: return r.mem;
        case Disk: return r.disk;
        default: return r.cpu;
        }
    };
    auto less = [&](const Row &a, const Row &b) {
        if (m_sort == Name) {
            const int c = a.name.compare(b.name, Qt::CaseInsensitive);
            return c != 0 ? c < 0 : a.key < b.key;
        }
        const double va = value(a), vb = value(b);
        return va != vb ? va > vb : a.key < b.key;   // stable : pas de lignes qui sautent à égalité
    };

    QList<Row> groups;
    QHash<QString, QList<Row>> children;
    for (const Group &g : std::as_const(m_groups)) {
        Row row;
        row.key = g.key;
        row.name = g.name;
        row.icon = g.icon;
        row.system = g.system;
        row.count = g.pids.size();
        row.own = !g.system;
        bool match = needle.isEmpty() || g.name.contains(needle, Qt::CaseInsensitive);
        QList<Row> kids;
        bool allLow = true;
        for (int pid : g.pids) {
            const Proc &p = m_procs[pid];
            row.cpu += p.cpu;
            row.mem += p.mem;
            row.disk += p.rd + p.wr;
            allLow = allLow && p.nice > 0;
            const bool m = needle.isEmpty() || procMatches(p);
            match = match || m;
            Row k;
            k.kind = 1;
            k.key = QStringLiteral("pid:") + QString::number(p.pid);
            k.name = p.comm;
            k.pid = p.pid;
            k.cpu = p.cpu;
            k.mem = p.mem;
            k.disk = p.rd + p.wr;
            k.own = p.uid == m_uid;
            k.low = p.nice > 0;
            k.command = p.cmdline.isEmpty() ? p.comm : p.cmdline;
            if (needle.isEmpty() || m || g.name.contains(needle, Qt::CaseInsensitive))
                kids.append(k);
        }
        row.low = allLow;
        if (!match)
            continue;
        std::sort(kids.begin(), kids.end(), less);
        children.insert(g.key, kids);
        groups.append(row);
    }
    std::sort(groups.begin(), groups.end(), [&](const Row &a, const Row &b) {
        if (a.system != b.system)
            return b.system;   // « Services du système » toujours en dernier
        return less(a, b);
    });

    QList<Row> rows;
    for (const Row &g : std::as_const(groups)) {
        rows.append(g);
        // Une recherche qui ne trouve que des processus déplie leur application.
        const bool open = m_expanded.contains(g.key)
            || (!needle.isEmpty() && !g.name.contains(needle, Qt::CaseInsensitive));
        rows.last().expanded = open;
        if (open)
            rows.append(children.value(g.key));
    }
    applyRows(rows);
}

// Met la liste à jour par insertions, déplacements et suppressions : la vue garde sa position.
void ProcessModel::applyRows(const QList<Row> &target)
{
    QSet<QString> wanted;
    for (const Row &r : target)
        wanted.insert(r.key);
    for (int i = m_rows.size() - 1; i >= 0; --i) {
        if (!wanted.contains(m_rows.at(i).key)) {
            beginRemoveRows({}, i, i);
            m_rows.removeAt(i);
            endRemoveRows();
        }
    }
    for (int i = 0; i < target.size(); ++i) {
        const QString &key = target.at(i).key;
        if (i < m_rows.size() && m_rows.at(i).key == key) {
            m_rows[i] = target.at(i);
            continue;
        }
        int from = -1;
        for (int j = i + 1; j < m_rows.size(); ++j) {
            if (m_rows.at(j).key == key) {
                from = j;
                break;
            }
        }
        if (from >= 0) {
            beginMoveRows({}, from, from, {}, i);
            m_rows.move(from, i);
            endMoveRows();
            m_rows[i] = target.at(i);
        } else {
            beginInsertRows({}, i, i);
            m_rows.insert(i, target.at(i));
            endInsertRows();
        }
    }
    if (!m_rows.isEmpty())
        Q_EMIT dataChanged(index(0), index(m_rows.size() - 1));
}

void ProcessModel::toggleExpanded(const QString &key)
{
    const int row = indexOf(key);
    setExpanded(key, !(row >= 0 && m_rows.at(row).expanded));
}

void ProcessModel::setExpanded(const QString &key, bool expanded)
{
    const int row = indexOf(key);
    if (!m_groups.contains(key) || (row >= 0 && m_rows.at(row).expanded == expanded))
        return;
    expanded ? (void)m_expanded.insert(key) : (void)m_expanded.remove(key);
    rebuild();
}

int ProcessModel::indexOf(const QString &key) const
{
    for (int i = 0; i < m_rows.size(); ++i) {
        if (m_rows.at(i).key == key)
            return i;
    }
    return -1;
}

// ---------- Actions ----------

QList<int> ProcessModel::pidsFor(const QString &key) const
{
    QList<int> pids;
    if (key.startsWith(QLatin1String("pid:"))) {
        const int pid = key.mid(4).toInt();
        if (m_procs.contains(pid))
            pids.append(pid);
    } else {
        pids = m_groups.value(key).pids;
    }
    pids.erase(std::remove_if(pids.begin(), pids.end(), [this](int pid) { return m_procs.value(pid).uid != m_uid; }), pids.end());
    return pids;
}

bool ProcessModel::signalKey(const QString &key, int sig)
{
    const QList<int> pids = pidsFor(key);
    bool ok = !pids.isEmpty();
    for (int pid : pids)
        ok = ::kill(pid, sig) == 0 && ok;
    return ok;
}

bool ProcessModel::close(const QString &key) { return signalKey(key, SIGTERM); }

bool ProcessModel::forceClose(const QString &key)
{
    const bool ok = signalKey(key, SIGKILL);
    QTimer::singleShot(300, this, &ProcessModel::refresh);
    return ok;
}

bool ProcessModel::isRunning(const QString &key) const
{
    const QList<int> pids = pidsFor(key);
    return std::any_of(pids.cbegin(), pids.cend(), [](int pid) { return ::kill(pid, 0) == 0; });
}

bool ProcessModel::lowerPriority(const QString &key)
{
    const QList<int> pids = pidsFor(key);
    bool ok = !pids.isEmpty();
    for (int pid : pids)
        ok = setpriority(PRIO_PROCESS, id_t(pid), 10) == 0 && ok;
    refresh();
    return ok;
}

QString ProcessModel::location(const QString &key) const
{
    const QList<int> pids = pidsFor(key);
    for (int pid : pids) {
        const QString exe = m_procs.value(pid).exe;
        if (!exe.isEmpty())
            return QFileInfo(exe).absolutePath();
    }
    return {};
}

QString ProcessModel::command(const QString &key) const
{
    const QList<int> pids = pidsFor(key);
    if (pids.isEmpty())
        return {};
    // Pour une application : la commande de son processus le plus ancien (le plus petit numéro).
    const int pid = *std::min_element(pids.cbegin(), pids.cend());
    const Proc p = m_procs.value(pid);
    return p.cmdline.isEmpty() ? p.comm : p.cmdline;
}

void ProcessModel::copyText(const QString &text) const
{
    QGuiApplication::clipboard()->setText(text);
}

QString ProcessModel::name(const QString &key) const
{
    if (key.startsWith(QLatin1String("pid:")))
        return m_procs.value(key.mid(4).toInt()).comm;
    return m_groups.value(key).name;
}
