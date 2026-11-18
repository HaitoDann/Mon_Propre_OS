#pragma once

// Historique du presse-papiers (ADR 0037) : logique pure, testée dans tests/tst_clipboard.cpp.
// 50 éléments au plus hors épinglés, doublons remontés en tête, épinglés conservés sur disque.

#include <algorithm>
#include <functional>

#include <QByteArray>
#include <QCryptographicHash>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QRegularExpression>
#include <QString>

struct ClipItem {
    enum Kind { Text, Link, Image };
    QString id;
    Kind kind = Text;
    QString text;          // texte, ou « 1280 × 720 » pour une image
    QByteArray png;        // image (PNG)
    qint64 time = 0;       // millisecondes depuis l'époque
    bool pinned = false;
    QByteArray key;        // empreinte des pixels d'une image (le PNG peut varier d'un encodage à l'autre)

    QByteArray hash() const
    {
        if (kind == Image && !key.isEmpty())
            return key;
        return QCryptographicHash::hash(kind == Image ? png : text.toUtf8(), QCryptographicHash::Sha1);
    }
};

class ClipHistory
{
public:
    static constexpr int kLimit = 50;
    static constexpr int kMaxText = 200000;   // au-delà : ignoré (gros copier-coller de fichiers)

    const QList<ClipItem> &items() const { return m_items; }

    static ClipItem::Kind kindOfText(const QString &text)
    {
        static const QRegularExpression link(QStringLiteral("^(https?|ftp|mailto):\\S+$"));
        return link.match(text.trimmed()).hasMatch() ? ClipItem::Link : ClipItem::Text;
    }

    // Ajoute en tête ; renvoie false si rien n'a changé (même contenu déjà en tête).
    bool add(ClipItem item)
    {
        if (item.kind != ClipItem::Image && (item.text.trimmed().isEmpty() || item.text.size() > kMaxText))
            return false;
        if (item.kind == ClipItem::Image && item.png.isEmpty())
            return false;
        const QByteArray h = item.hash();
        for (int i = 0; i < m_items.size(); ++i) {
            if (m_items.at(i).hash() != h)
                continue;
            if (i == 0)
                return false;
            ClipItem existing = m_items.takeAt(i);
            existing.time = item.time;
            m_items.prepend(existing);
            return true;
        }
        if (item.id.isEmpty())
            item.id = QString::number(++m_counter);
        m_items.prepend(item);
        trim();
        return true;
    }

    int indexOf(const QString &id) const
    {
        for (int i = 0; i < m_items.size(); ++i)
            if (m_items.at(i).id == id)
                return i;
        return -1;
    }

    bool setPinned(const QString &id, bool pinned)
    {
        const int i = indexOf(id);
        if (i < 0 || m_items.at(i).pinned == pinned)
            return false;
        m_items[i].pinned = pinned;
        trim();
        return true;
    }

    bool remove(const QString &id)
    {
        const int i = indexOf(id);
        if (i < 0)
            return false;
        m_items.removeAt(i);
        return true;
    }

    // « Tout effacer » : les épinglés restent.
    void clearUnpinned()
    {
        m_items.erase(std::remove_if(m_items.begin(), m_items.end(), [](const ClipItem &c) { return !c.pinned; }), m_items.end());
    }

    // Épinglés, pour le disque : les images sont des fichiers à part (nom = id.png).
    QJsonArray pinnedToJson() const
    {
        QJsonArray a;
        for (const ClipItem &c : m_items) {
            if (!c.pinned)
                continue;
            a.append(QJsonObject{{QStringLiteral("id"), c.id}, {QStringLiteral("kind"), int(c.kind)},
                                 {QStringLiteral("text"), c.text}, {QStringLiteral("time"), double(c.time)}});
        }
        return a;
    }

    // image(id) : PNG enregistré ; key(png) : empreinte des pixels (voir ClipItem::key).
    void loadPinned(const QJsonArray &a, const std::function<QByteArray(const QString &)> &image,
                    const std::function<QByteArray(const QByteArray &)> &key = {})
    {
        for (const QJsonValue &v : a) {
            const QJsonObject o = v.toObject();
            ClipItem c;
            c.id = o.value(QStringLiteral("id")).toString();
            c.kind = ClipItem::Kind(qBound(0, o.value(QStringLiteral("kind")).toInt(), 2));
            c.text = o.value(QStringLiteral("text")).toString();
            c.time = qint64(o.value(QStringLiteral("time")).toDouble());
            c.pinned = true;
            if (c.kind == ClipItem::Image)
                c.png = image(c.id);
            if (c.kind == ClipItem::Image && key)
                c.key = key(c.png);
            if (c.id.isEmpty() || (c.kind == ClipItem::Image && c.png.isEmpty()))
                continue;
            m_counter = qMax(m_counter, c.id.toLongLong());
            m_items.append(c);
        }
    }

private:
    void trim()
    {
        int unpinned = 0;
        for (int i = 0; i < m_items.size(); ++i) {
            if (m_items.at(i).pinned)
                continue;
            if (++unpinned > kLimit)
                m_items.removeAt(i--);
        }
    }

    QList<ClipItem> m_items;
    qint64 m_counter = 0;
};
