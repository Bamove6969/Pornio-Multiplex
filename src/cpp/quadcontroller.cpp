#include "quadcontroller.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QDebug>

// FFI Declarations matching Rust core
extern "C" {
    void *stremio_quad_create();
    void stremio_quad_destroy(void *handle);
    char *stremio_quad_get_state(void *handle);
    void stremio_quad_set_slot_stream(void *handle, size_t slot_idx, const char *stream_url, const char *title, const char *poster);
    void stremio_quad_set_active_audio(void *handle, size_t slot_idx);
    void stremio_quad_set_solo(void *handle, ptrdiff_t slot_idx);
    char *stremio_quad_fetch_catalog(void *handle, const char *addon_url, const char *catalog_type, const char *catalog_id, const char *search_query);
    char *stremio_quad_search(void *handle, const char *query, const char *item_type);
    char *stremio_quad_resolve_streams(void *handle, const char *addon_url, const char *item_type, const char *id);
    void stremio_quad_free_string(char *s);
}

QuadController::QuadController(QObject *parent)
    : QObject(parent),
      m_coreHandle(nullptr),
      m_activeAudioSlot(0),
      m_soloSlot(-1),
      m_allPaused(false),
      m_defaultAddonUrl("https://127-0-0-1.local-ip.medicmobile.org:58828/eyJlbmFibGVKYWNrZXR0Ijoib24iLCJqYWNrZXR0VXJsIjoiaHR0cDovL2phY2tldHQ6OTExNyIsImphY2tldHRLZXkiOiJ3N2l5Z3B3d3A5bG14MWNtaXRvNnU0N3NobmNyanRvcyIsImphY2tldHRQdWJsaWNVcmwiOiJodHRwOi8vbG9jYWxob3N0OjkxMTciLCJzZWFyY2hCeVRpdGxlIjoib24iLCJyZWFsRGVicmlkS2V5IjoiSVROSVBVTks2VFhVNUxLVjNLVk4ySEk1VFNTQlZXUVRXQ0NUSlkzVFVaNDZRNDJERktCUSIsInRwZGJBcGlLZXkiOiJ3TjJBQnhnaDlzZkh5ZWJLQ2p2WXgwTmZKYjlDTzBNSmJBZ2pNVklzMzc3MWYzOWUifQ") {
    
    m_coreHandle = stremio_quad_create();
    updateFromRustState();
}

QuadController::~QuadController() {
    if (m_coreHandle) {
        stremio_quad_destroy(m_coreHandle);
        m_coreHandle = nullptr;
    }
}

QVariantList QuadController::slotList() const {
    return m_slotList;
}

int QuadController::activeAudioSlot() const {
    return m_activeAudioSlot;
}

int QuadController::soloSlot() const {
    return m_soloSlot;
}

QString QuadController::defaultAddonUrl() const {
    return m_defaultAddonUrl;
}

void QuadController::setDefaultAddonUrl(const QString &url) {
    if (m_defaultAddonUrl != url) {
        m_defaultAddonUrl = url;
        emit defaultAddonUrlChanged();
    }
}

void QuadController::loadStream(int slotIdx, const QString &title, const QString &poster, const QString &streamUrl) {
    if (!m_coreHandle || slotIdx < 0 || slotIdx >= 4) return;

    stremio_quad_set_slot_stream(
        m_coreHandle,
        static_cast<size_t>(slotIdx),
        streamUrl.toUtf8().constData(),
        title.toUtf8().constData(),
        poster.toUtf8().constData()
    );
    updateFromRustState();
}

void QuadController::setActiveAudioSlot(int slotIdx) {
    if (!m_coreHandle || slotIdx < 0 || slotIdx >= 4) return;
    if (m_activeAudioSlot == slotIdx) return;

    m_activeAudioSlot = slotIdx;
    stremio_quad_set_active_audio(m_coreHandle, static_cast<size_t>(slotIdx));
    emit activeAudioSlotChanged();
    updateFromRustState();
}

void QuadController::setSoloSlot(int slotIdx) {
    if (!m_coreHandle) return;
    if (m_soloSlot == slotIdx) return;

    m_soloSlot = slotIdx;
    stremio_quad_set_solo(m_coreHandle, static_cast<ptrdiff_t>(slotIdx));
    emit soloSlotChanged();
}

void QuadController::togglePlayPauseAll() {
    m_allPaused = !m_allPaused;
    emit playPauseAllRequested(m_allPaused);
}

QVariantList QuadController::fetchCatalog(const QString &addonUrl, const QString &catalogType, const QString &catalogId, const QString &searchQuery) {
    QVariantList list;
    if (!m_coreHandle) return list;

    QString targetUrl = addonUrl.isEmpty() ? m_defaultAddonUrl : addonUrl;

    char *jsonStr = stremio_quad_fetch_catalog(
        m_coreHandle,
        targetUrl.toUtf8().constData(),
        catalogType.toUtf8().constData(),
        catalogId.toUtf8().constData(),
        searchQuery.toUtf8().constData()
    );

    if (jsonStr) {
        QJsonDocument doc = QJsonDocument::fromJson(QByteArray(jsonStr));
        stremio_quad_free_string(jsonStr);

        if (doc.isObject()) {
            QJsonArray metas = doc.object().value("metas").toArray();
            for (const QJsonValue &val : metas) {
                QJsonObject obj = val.toObject();
                if (!obj.contains("name") && obj.contains("title")) {
                    obj["name"] = obj["title"];
                }
                list.append(obj.toVariantMap());
            }
        }
    }
    return list;
}

QVariantList QuadController::searchContent(const QString &query, const QString &itemType) {
    QVariantList list = fetchCatalog(m_defaultAddonUrl, itemType, "torrent-search", query);
    if (!list.isEmpty()) {
        return list;
    }

    if (!m_coreHandle) return list;

    char *jsonStr = stremio_quad_search(
        m_coreHandle,
        query.toUtf8().constData(),
        itemType.toUtf8().constData()
    );

    if (jsonStr) {
        QJsonDocument doc = QJsonDocument::fromJson(QByteArray(jsonStr));
        stremio_quad_free_string(jsonStr);

        if (doc.isObject()) {
            QJsonArray metas = doc.object().value("metas").toArray();
            for (const QJsonValue &val : metas) {
                list.append(val.toObject().toVariantMap());
            }
        }
    }
    return list;
}

QVariantList QuadController::resolveStreams(const QString &addonUrl, const QString &itemType, const QString &id) {
    QVariantList list;
    if (!m_coreHandle) return list;

    QString targetUrl = addonUrl.isEmpty() ? m_defaultAddonUrl : addonUrl;

    char *jsonStr = stremio_quad_resolve_streams(
        m_coreHandle,
        targetUrl.toUtf8().constData(),
        itemType.toUtf8().constData(),
        id.toUtf8().constData()
    );

    if (jsonStr) {
        QJsonDocument doc = QJsonDocument::fromJson(QByteArray(jsonStr));
        stremio_quad_free_string(jsonStr);

        if (doc.isObject()) {
            QJsonArray streams = doc.object().value("streams").toArray();
            for (const QJsonValue &val : streams) {
                QJsonObject obj = val.toObject();
                if (!obj.contains("title") && obj.contains("name")) {
                    obj["title"] = obj["name"];
                } else if (obj.contains("description") && !obj.contains("title")) {
                    obj["title"] = obj["description"];
                }
                list.append(obj.toVariantMap());
            }
        }
    }
    return list;
}

void QuadController::updateFromRustState() {
    if (!m_coreHandle) return;

    char *jsonStr = stremio_quad_get_state(m_coreHandle);
    if (!jsonStr) return;

    QJsonDocument doc = QJsonDocument::fromJson(QByteArray(jsonStr));
    stremio_quad_free_string(jsonStr);

    if (doc.isObject()) {
        QJsonObject root = doc.object();
        QJsonArray slotArray = root.value("slots").toArray();

        QVariantList newList;
        for (const QJsonValue &val : slotArray) {
            QJsonObject slotObj = val.toObject();
            QVariantMap map;
            map["index"] = slotObj.value("index").toInt();
            map["streamUrl"] = slotObj.value("stream_url").toString();
            map["title"] = slotObj.value("title").toString();
            map["poster"] = slotObj.value("poster").toString();
            map["isMuted"] = slotObj.value("is_muted").toBool();
            map["volume"] = slotObj.value("volume").toDouble();
            map["isPlaying"] = slotObj.value("is_playing").toBool();
            map["position"] = slotObj.value("position").toDouble();
            map["duration"] = slotObj.value("duration").toDouble();
            newList.append(map);
        }
        m_slotList = newList;
        m_activeAudioSlot = root.value("active_audio_slot").toInt();

        emit slotListChanged();
    }
}
