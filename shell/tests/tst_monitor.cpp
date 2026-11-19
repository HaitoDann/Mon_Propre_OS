#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

#include "procparse.h"
#include "processmodel.h"

// Moniteur système (ADR 0035) : lecture de /proc et regroupement par application.
class TestMonitor : public QObject
{
    Q_OBJECT

    QTemporaryDir m_dir;

    void write(const QString &rel, const QByteArray &content)
    {
        const QString path = m_dir.path() + QLatin1Char('/') + rel;
        QDir().mkpath(QFileInfo(path).absolutePath());
        QFile f(path);
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write(content);
    }
    void process(int pid, int ppid, int uid, const QByteArray &comm, const QByteArray &exe, const QByteArray &cgroup)
    {
        const QString d = QStringLiteral("proc/%1/").arg(pid);
        write(d + QStringLiteral("stat"), QByteArray::number(pid) + " (" + comm + ") S " + QByteArray::number(ppid)
                  + " 1 1 0 -1 0 0 0 0 0 100 50 0 0 20 0 1 0 100 1000 256 0\n");
        write(d + QStringLiteral("status"), "Name:\t" + comm + "\nUid:\t" + QByteArray::number(uid) + "\t0\t0\t0\n");
        write(d + QStringLiteral("cmdline"), exe + '\0');
        write(d + QStringLiteral("cgroup"), "0::" + cgroup + "\n");
        if (!exe.isEmpty())
            QFile::link(QString::fromUtf8(exe), m_dir.path() + QLatin1Char('/') + d + QStringLiteral("exe"));
    }

private Q_SLOTS:
    void parseStat()
    {
        const auto s = ProcParse::parseStat("1234 (Web Content (x)) S 1200 1 1 0 -1 0 0 0 0 0 300 45 0 0 20 5 1 0 100 1000 512 0\n");
        QVERIFY(s.ok);
        QCOMPARE(s.comm, QStringLiteral("Web Content (x)"));
        QCOMPARE(s.ppid, 1200);
        QCOMPARE(s.ticks, quint64(345));
        QCOMPARE(s.nice, 5);
        QCOMPARE(s.rssPages, qint64(512));
        QVERIFY(!ProcParse::parseStat("garbage").ok);
    }

    void parseSystem()
    {
        const auto cpu = ProcParse::parseCpu("cpu  100 0 50 800 50 0 0 0 0 0\ncpu0 1 2 3\n");
        QCOMPARE(cpu.total, quint64(1000));
        QCOMPARE(cpu.idle, quint64(850));
        const auto mem = ProcParse::parseMeminfo("MemTotal:  16000 kB\nMemFree: 10 kB\nMemAvailable:  6000 kB\n");
        QCOMPARE(mem.totalKb, qint64(16000));
        QCOMPARE(mem.availableKb, qint64(6000));
        const auto net = ProcParse::parseNetDev("h\nh\n    lo: 500 1 0 0 0 0 0 0 500 1 0 0 0 0 0 0\nwlp2s0: 1000 5 0 0 0 0 0 0 200 3 0 0 0 0 0 0\n");
        QCOMPARE(net.in, quint64(1000));
        QCOMPARE(net.out, quint64(200));
        const auto disk = ProcParse::parseDiskstats(" 259 0 nvme0n1 1 0 10 0 1 0 4 0 0 0 0\n 259 1 nvme0n1p1 1 0 999 0 1 0 999 0\n 7 0 loop0 1 0 999 0 1 0 999 0\n");
        QCOMPARE(disk.in, quint64(10 * 512));
        QCOMPARE(disk.out, quint64(4 * 512));
        const auto io = ProcParse::parseIo("rchar: 5\nread_bytes: 4096\nwrite_bytes: 8192\n");
        QCOMPARE(io.in, quint64(4096));
        QCOMPARE(io.out, quint64(8192));
        QCOMPARE(ProcParse::uid("Name:\tx\nUid:\t1000\t1000\t1000\t1000\n"), qint64(1000));
        QCOMPARE(ProcParse::commandLine(QByteArray("rsync\0-a\0x\0", 11)), QStringLiteral("rsync -a x"));
    }

    void appIdFromCgroup_data()
    {
        QTest::addColumn<QByteArray>("cgroup");
        QTest::addColumn<QString>("id");
        QTest::newRow("scope") << QByteArray("0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-thunderbird-4f2a9c.scope") << "thunderbird";
        QTest::newRow("service") << QByteArray("0::/user.slice/user@1000.service/app.slice/app-org.kde.okular@a1b2.service") << "org.kde.okular";
        QTest::newRow("échappé") << QByteArray("0::/app.slice/app-firefox\\x2desr-12ab.scope") << "firefox-esr";
        QTest::newRow("flatpak") << QByteArray("0::/app.slice/app-flatpak-org.gimp.GIMP-3141.scope") << "org.gimp.GIMP";
        QTest::newRow("session") << QByteArray("0::/user.slice/user@1000.service/session.slice/plasma-kwin_wayland.service") << "";
        QTest::newRow("système") << QByteArray("0::/system.slice/NetworkManager.service") << "";
    }
    void appIdFromCgroup()
    {
        QFETCH(QByteArray, cgroup);
        QFETCH(QString, id);
        QCOMPARE(ProcParse::appIdFromCgroup(cgroup), id);
    }

    void execProgram()
    {
        QCOMPARE(ProcParse::execProgram({QStringLiteral("/usr/lib/firefox-esr/firefox-esr"), QStringLiteral("%u")}), QStringLiteral("firefox-esr"));
        QCOMPARE(ProcParse::execProgram({QStringLiteral("env"), QStringLiteral("A=1"), QStringLiteral("gimp")}), QStringLiteral("gimp"));
        QCOMPARE(ProcParse::execProgram({QStringLiteral("/usr/bin/flatpak"), QStringLiteral("run"), QStringLiteral("--branch=stable"), QStringLiteral("org.gimp.GIMP")}), QStringLiteral("org.gimp.GIMP"));
        // Lanceur de Calamares : « sh -c "pkexec calamares" » ne doit pas capter tous les scripts sh.
        QCOMPARE(ProcParse::execProgram({QStringLiteral("sh"), QStringLiteral("-c"), QStringLiteral("pkexec calamares")}), QStringLiteral("calamares"));
        QCOMPARE(ProcParse::execProgram({QStringLiteral("/bin/bash")}), QString());
        QCOMPARE(ProcParse::execProgram({QStringLiteral("sudo"), QStringLiteral("-E"), QStringLiteral("/usr/bin/gparted")}), QStringLiteral("gparted"));
    }

    // Faux /proc : navigateur et ses onglets, LibreOffice (lanceur oosplash), une application dans
    // son unité systemd, le shell du terminal, un service système et un processus du bureau.
    void grouping()
    {
        QVERIFY(m_dir.isValid());
        const QByteArray session = "/user.slice/user@1000.service/session.slice/vinx.service";
        process(1, 0, 0, "systemd", "", "/init.scope");
        process(400, 1, 0, "NetworkManager", "", "/system.slice/NetworkManager.service");
        process(900, 1, 1000, "systemd", "/usr/lib/systemd/systemd", "/user.slice/user@1000.service/init.scope");
        process(960, 900, 1000, "vinx-shell", "/usr/bin/vinx-shell", session);
        process(1200, 900, 1000, "firefox-esr", "/usr/lib/firefox-esr/firefox-esr", session);
        process(1210, 1200, 1000, "Isolated Web Co", "/usr/lib/firefox-esr/firefox-esr", session);
        process(1300, 900, 1000, "oosplash", "/usr/lib/libreoffice/program/oosplash", session);
        process(1301, 1300, 1000, "soffice.bin", "/usr/lib/libreoffice/program/soffice.bin", session);
        process(1400, 900, 1000, "thunderbird", "/usr/lib/thunderbird/thunderbird", "/user.slice/user@1000.service/app.slice/app-thunderbird-4f2a.scope");
        process(1500, 900, 1000, "vinx-terminal", "/usr/bin/vinx-terminal", session);
        process(1510, 1500, 1000, "bash", "/usr/bin/bash", session);
        process(3, 2, 0, "kworker/0:1", "", "/");
        write(QStringLiteral("proc/stat"), "cpu  100 0 0 900 0 0 0 0\n");
        write(QStringLiteral("proc/meminfo"), "MemTotal: 8000000 kB\nMemAvailable: 4000000 kB\n");
        const QByteArray entry = "[Desktop Entry]\nType=Application\n";
        write(QStringLiteral("share/applications/firefox-esr.desktop"), entry + "Name=Firefox ESR\nExec=/usr/lib/firefox-esr/firefox-esr %u\n");
        write(QStringLiteral("share/applications/libreoffice-startcenter.desktop"), entry + "Name=LibreOffice\nExec=libreoffice %U\n");
        write(QStringLiteral("share/applications/thunderbird.desktop"), entry + "Name=Thunderbird\nExec=thunderbird %u\n");
        write(QStringLiteral("share/applications/org.vinx.terminal.desktop"), entry + "Name=Terminal\nExec=vinx-terminal\n");
        qputenv("VINX_PROC_ROOT", (m_dir.path() + QStringLiteral("/proc")).toUtf8());
        qputenv("VINX_PROC_UID", "1000");
        qputenv("XDG_DATA_DIRS", (m_dir.path() + QStringLiteral("/share")).toUtf8());
        qputenv("XDG_DATA_HOME", (m_dir.path() + QStringLiteral("/none")).toUtf8());

        ProcessModel model;
        model.setSortColumn(ProcessModel::Name);
        QStringList names;
        for (int i = 0; i < model.rowCount(); ++i)
            names << model.data(model.index(i), ProcessModel::NameRole).toString();
        // Par nom, « Services du système » toujours en dernier ; les fils du noyau sont ignorés.
        QCOMPARE(names, (QStringList{QStringLiteral("Firefox ESR"), QStringLiteral("LibreOffice"), QStringLiteral("Terminal"),
                                     QStringLiteral("Thunderbird"), QStringLiteral("Services du système")}));
        QCOMPARE(model.processCount(), 11);
        auto count = [&](const QString &key) { return model.data(model.index(model.indexOf(key)), ProcessModel::CountRole).toInt(); };
        QCOMPARE(count(QStringLiteral("app:firefox-esr")), 2);
        QCOMPARE(count(QStringLiteral("app:libreoffice-startcenter")), 2);
        QCOMPARE(count(QStringLiteral("app:org.vinx.terminal")), 2);
        QCOMPARE(count(QStringLiteral("system")), 4);   // systemd ×2, NetworkManager, vinx-shell ; pas le noyau
        QCOMPARE(model.memTotal(), 8000000.0 * 1024);

        // Dépliage : les processus suivent leur application.
        model.setExpanded(QStringLiteral("app:firefox-esr"), true);
        QCOMPARE(model.data(model.index(1), ProcessModel::KindRole).toInt(), 1);
        QCOMPARE(model.rowCount(), 7);
        // Recherche par processus : l'application apparaît, dépliée sur le processus trouvé.
        model.setExpanded(QStringLiteral("app:firefox-esr"), false);
        model.setFilter(QStringLiteral("bash"));
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.data(model.index(0), ProcessModel::NameRole).toString(), QStringLiteral("Terminal"));
        QCOMPARE(model.data(model.index(1), ProcessModel::PidRole).toInt(), 1510);
        // Actions : jamais sur les processus des autres utilisateurs.
        QVERIFY(!model.canAct(QStringLiteral("pid:400")));
        QVERIFY(model.canAct(QStringLiteral("pid:1510")));
        QCOMPARE(model.command(QStringLiteral("app:org.vinx.terminal")), QStringLiteral("/usr/bin/vinx-terminal"));
    }
};

QTEST_GUILESS_MAIN(TestMonitor)
#include "tst_monitor.moc"
