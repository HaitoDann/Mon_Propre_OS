#pragma once

#include <QImage>
#include <QObject>
#include <QQuickImageProvider>
#include <QRectF>
#include <QStringList>
#include <QVariantMap>

#include "photo.h"

// Visionneur d'images VinX (ADR 0038) : images du dossier, image courante et ses infos,
// actions (copier, envoyer, corbeille, fond d'écran) et mode Modifier.
// Instance unique, enregistrée dans le moteur QML par main.cpp (singleton « Viewer »).
class Viewer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList files READ files NOTIFY folderChanged)
    Q_PROPERTY(int index READ index WRITE go NOTIFY currentChanged)
    Q_PROPERTY(QString current READ current NOTIFY currentChanged)
    Q_PROPERTY(QVariantMap info READ info NOTIFY currentChanged)
    Q_PROPERTY(bool animated READ animated NOTIFY currentChanged)
    // Mode Modifier
    Q_PROPERTY(int revision READ revision NOTIFY editChanged)
    Q_PROPERTY(int quarterTurns READ quarterTurns NOTIFY editChanged)
    Q_PROPERTY(bool mirror READ mirror NOTIFY editChanged)
    Q_PROPERTY(QRectF crop READ crop WRITE setCrop NOTIFY editChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY editChanged)
    Q_PROPERTY(int contrast READ contrast WRITE setContrast NOTIFY editChanged)
    Q_PROPERTY(bool forMail READ forMail WRITE setForMail NOTIFY editChanged)
    Q_PROPERTY(bool modified READ modified NOTIFY editChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY editChanged)
    Q_PROPERTY(QSize baseSize READ baseSize NOTIFY editChanged)      // image pivotée (aperçu)
    Q_PROPERTY(QSize editedSize READ editedSize NOTIFY editChanged)  // taille finale en pixels

public:
    explicit Viewer(QObject *parent = nullptr);
    static Viewer *instance();

    QStringList files() const { return m_files; }
    int index() const { return m_index; }
    QString current() const { return m_files.value(m_index); }
    QVariantMap info() const { return m_info; }
    bool animated() const;

    Q_INVOKABLE bool open(const QString &path);
    void go(int index);
    Q_INVOKABLE void next() { if (!m_files.isEmpty()) go((m_index + 1) % m_files.size()); }
    Q_INVOKABLE void previous() { if (!m_files.isEmpty()) go((m_index - 1 + m_files.size()) % m_files.size()); }
    Q_INVOKABLE bool trash();
    Q_INVOKABLE void copyImage() const;
    Q_INVOKABLE bool email() const;
    Q_INVOKABLE void openFolder() const;
    Q_INVOKABLE void openWith() const;
    Q_INVOKABLE bool saveRotation(int quarterTurns);   // rotation faite dans le visionneur

    // Mode Modifier
    Q_INVOKABLE bool beginEdit();
    Q_INVOKABLE void rotate(int quarterTurns);
    Q_INVOKABLE void flip();
    Q_INVOKABLE void addShape(const QVariantMap &shape);   // coordonnées de l'aperçu modifié
    Q_INVOKABLE void undo();
    Q_INVOKABLE void resetEdits();
    Q_INVOKABLE QString saveCopy();
    Q_INVOKABLE bool replaceOriginal();
    int revision() const { return m_revision; }
    int quarterTurns() const { return m_edits.quarterTurns; }
    bool mirror() const { return m_edits.mirror; }
    QRectF crop() const { return m_edits.crop; }
    void setCrop(const QRectF &c);
    int brightness() const { return m_edits.brightness; }
    void setBrightness(int v);
    int contrast() const { return m_edits.contrast; }
    void setContrast(int v);
    bool forMail() const { return m_edits.maxSide > 0; }
    void setForMail(bool on);
    bool modified() const { return !m_edits.isIdentity(); }
    bool canUndo() const { return !m_history.isEmpty(); }
    QSize baseSize() const { return m_base.size(); }
    QSize editedSize() const;

    QImage baseImage() const { return m_base; }
    QImage previewImage() const { return m_preview; }

Q_SIGNALS:
    void folderChanged();
    void currentChanged();
    void editChanged();
    void failed(const QString &message);

private:
    void loadInfo();
    void editsChanged(bool remember = true);
    Photo::Edits fullEdits() const;
    bool writeImage(const QImage &image, const QString &path) const;

    QStringList m_files;
    int m_index = -1;
    QVariantMap m_info;

    QImage m_source;     // pleine résolution, orientation EXIF appliquée
    QImage m_small;      // aperçu (2400 px au plus)
    QImage m_base;       // aperçu pivoté (recadrage)
    QImage m_preview;    // aperçu avec toutes les retouches
    Photo::Edits m_edits;
    QList<Photo::Edits> m_history;
    int m_revision = 0;
};

// image://photo/base/<révision> et image://photo/edited/<révision>
class PhotoImageProvider : public QQuickImageProvider
{
public:
    PhotoImageProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override;
};
