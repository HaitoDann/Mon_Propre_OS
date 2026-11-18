#include "office.h"
#include "officeparse.h"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <QFileInfo>
#include <QSaveFile>
#include <QStandardPaths>
#include <unistd.h>

Office::Office(QObject *parent)
    : QObject(parent)
{
    refresh();
}

QString Office::profilePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/libreoffice/4/user/registrymodifications.xcu");
}

bool Office::libreOfficeInstalled() const
{
    return !QStandardPaths::findExecutable(QStringLiteral("libreoffice")).isEmpty()
        || !QStandardPaths::findExecutable(QStringLiteral("soffice")).isEmpty();
}

void Office::refresh()
{
    QFile f(profilePath());
    const QString xcu = f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()) : QString();
    // Sans réglage personnel : le défaut de VinX (Microsoft Office, fichier vinx-msformats.xcd).
    const QString fmt = office::readFormat(xcu);
    m_format = fmt.isEmpty() ? QStringLiteral("msoffice") : fmt;
    // Polices métriquement compatibles (mise en page identique à Word / Excel).
    m_missing.clear();
    QProcess fc;
    fc.start(QStringLiteral("fc-list"), {QStringLiteral(":"), QStringLiteral("family")});
    const QString families = fc.waitForFinished(3000) ? QString::fromUtf8(fc.readAllStandardOutput()) : QString();
    if (!families.isEmpty())
        for (const char *name : {"Carlito", "Caladea", "Liberation Sans", "Liberation Serif"})
            if (!families.contains(QLatin1String(name)))
                m_missing << QLatin1String(name);
    Q_EMIT changed();
}

bool Office::libreOfficeRunning() const
{
    QProcess p;
    p.start(QStringLiteral("pgrep"), {QStringLiteral("-u"), QString::number(getuid()), QStringLiteral("-f"), QStringLiteral("soffice.bin")});
    return p.waitForFinished(2000) && p.exitCode() == 0;
}

bool Office::setFormat(const QString &format)
{
    QFile in(profilePath());
    const QString xcu = in.open(QIODevice::ReadOnly) ? QString::fromUtf8(in.readAll()) : QString();
    in.close();
    QDir().mkpath(QFileInfo(profilePath()).absolutePath());
    QSaveFile out(profilePath());
    if (!out.open(QIODevice::WriteOnly))
        return false;
    out.write(office::writeFormat(xcu, format).toUtf8());
    if (!out.commit())
        return false;
    refresh();
    return true;
}
