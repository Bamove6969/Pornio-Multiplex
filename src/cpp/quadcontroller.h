#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class QuadController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList slotList READ slotList NOTIFY slotListChanged)
    Q_PROPERTY(int activeAudioSlot READ activeAudioSlot WRITE setActiveAudioSlot NOTIFY activeAudioSlotChanged)
    Q_PROPERTY(int soloSlot READ soloSlot WRITE setSoloSlot NOTIFY soloSlotChanged)
    Q_PROPERTY(QString defaultAddonUrl READ defaultAddonUrl WRITE setDefaultAddonUrl NOTIFY defaultAddonUrlChanged)

public:
    explicit QuadController(QObject *parent = nullptr);
    ~QuadController();

    QVariantList slotList() const;
    int activeAudioSlot() const;
    int soloSlot() const;
    QString defaultAddonUrl() const;

    Q_INVOKABLE void loadStream(int slotIdx, const QString &title, const QString &poster, const QString &streamUrl);
    Q_INVOKABLE void setActiveAudioSlot(int slotIdx);
    Q_INVOKABLE void setSoloSlot(int slotIdx);
    Q_INVOKABLE void setDefaultAddonUrl(const QString &url);

    // Stremio Addon API integrations
    Q_INVOKABLE QVariantList searchContent(const QString &query, const QString &itemType = "movie");
    Q_INVOKABLE QVariantList fetchCatalog(const QString &addonUrl, const QString &catalogType = "movie", const QString &catalogId = "torrent-search", const QString &searchQuery = "");
    Q_INVOKABLE QVariantList resolveStreams(const QString &addonUrl, const QString &itemType, const QString &id);

    Q_INVOKABLE void togglePlayPauseAll();

signals:
    void slotListChanged();
    void activeAudioSlotChanged();
    void soloSlotChanged();
    void defaultAddonUrlChanged();
    void playPauseAllRequested(bool pause);

private:
    void updateFromRustState();
    void *m_coreHandle;
    QVariantList m_slotList;
    int m_activeAudioSlot;
    int m_soloSlot;
    bool m_allPaused;
    QString m_defaultAddonUrl;
};
