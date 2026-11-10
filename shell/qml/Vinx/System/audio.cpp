#include "audio.h"
#include "wpctl.h"

#include <QProcess>
#include <QStandardPaths>

namespace {
const QString kSink = QStringLiteral("@DEFAULT_AUDIO_SINK@");
}

Audio::Audio(QObject *parent)
    : QObject(parent)
{
    m_poll.setInterval(4000);   // suit les changements faits par d'autres applications
    connect(&m_poll, &QTimer::timeout, this, &Audio::refresh);
    if (!QStandardPaths::findExecutable(QStringLiteral("wpctl")).isEmpty()) {
        m_poll.start();
        refresh();
    }
}

void Audio::refresh()
{
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p] {
        const WpctlVolume v = parseWpctlVolume(QString::fromUtf8(p->readAllStandardOutput()));
        p->deleteLater();
        if (v.ok != m_available || !qFuzzyCompare(1 + v.volume, 1 + m_volume) || v.muted != m_muted) {
            m_available = v.ok;
            m_volume = v.volume;
            m_muted = v.muted;
            Q_EMIT changed();
        }
    });
    p->start(QStringLiteral("wpctl"), {QStringLiteral("get-volume"), kSink});
}

void Audio::run(const QStringList &args)
{
    QProcess::startDetached(QStringLiteral("wpctl"), args);
}

void Audio::setVolume(double volume)
{
    volume = qBound(0.0, volume, 1.0);
    if (!m_available || qFuzzyCompare(1 + volume, 1 + m_volume))
        return;
    m_volume = volume;
    run({QStringLiteral("set-volume"), kSink, QString::number(volume, 'f', 2)});
    if (m_muted && volume > 0)
        setMuted(false);
    Q_EMIT changed();
}

void Audio::setMuted(bool muted)
{
    if (!m_available || muted == m_muted)
        return;
    m_muted = muted;
    run({QStringLiteral("set-mute"), kSink, muted ? QStringLiteral("1") : QStringLiteral("0")});
    Q_EMIT changed();
}
