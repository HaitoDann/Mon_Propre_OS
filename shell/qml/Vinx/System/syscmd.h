#pragma once

#include <QObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QTimer>
#include <functional>

// Lance une commande sans bloquer l'interface ; rappel (réussite, sortie, erreurs).
// Sortie en anglais (LANG=C) pour une analyse stable ; l'interface reste en français.
inline void runCommand(QObject *ctx, const QString &program, const QStringList &args,
                       std::function<void(bool, const QString &, const QString &)> done, int timeoutMs = 60000)
{
    auto *p = new QProcess(ctx);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("LANG"), QStringLiteral("C.UTF-8"));
    env.insert(QStringLiteral("LC_ALL"), QStringLiteral("C.UTF-8"));
    p->setProcessEnvironment(env);
    QObject::connect(p, &QProcess::finished, ctx, [p, done](int code, QProcess::ExitStatus st) {
        p->deleteLater();
        done(st == QProcess::NormalExit && code == 0, QString::fromUtf8(p->readAllStandardOutput()),
             QString::fromUtf8(p->readAllStandardError()));
    });
    QObject::connect(p, &QProcess::errorOccurred, ctx, [p, done](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) {
            p->deleteLater();
            done(false, {}, QStringLiteral("commande introuvable"));
        }
    });
    if (timeoutMs > 0)
        QTimer::singleShot(timeoutMs, p, [p] { if (p->state() != QProcess::NotRunning) p->kill(); });
    p->start(program, args);
}

inline bool hasCommand(const QString &name) { return !QStandardPaths::findExecutable(name).isEmpty(); }

// Outil administrateur VinX (pkexec + polkit org.vinx.admin).
inline const QString &vinxAdmin()
{
    static const QString path = QStringLiteral("/usr/lib/vinx/vinx-admin");
    return path;
}
