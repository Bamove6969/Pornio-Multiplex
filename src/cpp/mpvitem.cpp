#include "mpvitem.h"
#include <QOpenGLFramebufferObject>
#include <QOpenGLContext>
#include <QQuickWindow>
#include <QTimer>
#include <QDebug>
#include <windows.h>

class MpvItemRenderer : public QQuickFramebufferObject::Renderer {
public:
    MpvItemRenderer(const MpvItem *item) : m_item(item), m_mpv_gl(nullptr) {}

    ~MpvItemRenderer() {
        if (m_mpv_gl) {
            mpv_render_context_free(m_mpv_gl);
            m_mpv_gl = nullptr;
        }
    }

    void render() override {
        if (!m_item || !m_item->m_mpv) return;

        if (!m_mpv_gl) {
            mpv_opengl_init_params gl_params{get_proc_address, nullptr};
            mpv_render_param params[] = {
                {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
                {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_params},
                {MPV_RENDER_PARAM_INVALID, nullptr}
            };
            if (mpv_render_context_create(&m_mpv_gl, m_item->m_mpv, params) < 0) {
                qWarning() << "Failed to initialize mpv OpenGL render context";
                return;
            }

            mpv_render_context_set_update_callback(m_mpv_gl, [](void *ctx) {
                auto item = static_cast<MpvItem *>(ctx);
                if (item) {
                    QMetaObject::invokeMethod(item, [item]() {
                        item->update();
                    }, Qt::QueuedConnection);
                }
            }, const_cast<MpvItem *>(m_item));
        }

        QOpenGLFramebufferObject *fbo = framebufferObject();
        if (!fbo) return;

        mpv_opengl_fbo mpv_fbo{
            static_cast<int>(fbo->handle()),
            fbo->width(),
            fbo->height(),
            0
        };

        // flip_y = 0 renders right-side up for QQuickFramebufferObject
        int flip_y = 0;
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpv_fbo},
            {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
            {MPV_RENDER_PARAM_INVALID, nullptr}
        };
        mpv_render_context_render(m_mpv_gl, params);
    }

    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override {
        QSize s = size.isEmpty() ? QSize(640, 360) : size;
        return new QOpenGLFramebufferObject(s, QOpenGLFramebufferObject::CombinedDepthStencil);
    }

    static void *get_proc_address(void *, const char *name) {
        QOpenGLContext *ctx = QOpenGLContext::currentContext();
        if (ctx) {
            void *proc = reinterpret_cast<void *>(ctx->getProcAddress(name));
            if (proc) return proc;
        }
        // Critical Windows fix: wglGetProcAddress returns NULL for core OpenGL 1.1 functions
        static HMODULE glMod = LoadLibraryA("opengl32.dll");
        if (glMod) {
            void *proc = reinterpret_cast<void *>(GetProcAddress(glMod, name));
            if (proc) return proc;
        }
        return nullptr;
    }

private:
    const MpvItem *m_item;
    mpv_render_context *m_mpv_gl;
};

MpvItem::MpvItem(QQuickItem *parent)
    : QQuickFramebufferObject(parent),
      m_muted(true),
      m_volume(100.0f),
      m_position(0.0),
      m_duration(0.0),
      m_isPaused(false) {
    
    m_mpv = mpv_create();
    if (m_mpv) {
        // Robust multi-stream hardware decode & network configuration
        mpv_set_option_string(m_mpv, "hwdec", "auto-safe");
        mpv_set_option_string(m_mpv, "vo", "libmpv");
        mpv_set_option_string(m_mpv, "keep-open", "yes");
        mpv_set_option_string(m_mpv, "idle", "yes");
        mpv_set_option_string(m_mpv, "demuxer-lavf-o", "tls_verify=0");
        mpv_set_option_string(m_mpv, "user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");
        mpv_set_property_string(m_mpv, "mute", "yes");
        mpv_initialize(m_mpv);

        // Observe playback properties
        mpv_observe_property(m_mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
        mpv_observe_property(m_mpv, 0, "duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(m_mpv, 0, "pause", MPV_FORMAT_FLAG);
    }

    // Periodic event poller
    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &MpvItem::onMpvEvents);
    timer->start(100);
}

MpvItem::~MpvItem() {
    if (m_mpv) {
        mpv_terminate_destroy(m_mpv);
        m_mpv = nullptr;
    }
}

QQuickFramebufferObject::Renderer *MpvItem::createRenderer() const {
    return new MpvItemRenderer(this);
}

void MpvItem::onMpvEvents() {
    if (!m_mpv) return;

    while (true) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (!event || event->event_id == MPV_EVENT_NONE) break;

        if (event->event_id == MPV_EVENT_PROPERTY_CHANGE) {
            mpv_event_property *prop = static_cast<mpv_event_property *>(event->data);
            if (!prop || !prop->data) continue;

            if (strcmp(prop->name, "time-pos") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                m_position = *static_cast<double *>(prop->data);
                emit positionChanged();
            } else if (strcmp(prop->name, "duration") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                m_duration = *static_cast<double *>(prop->data);
                emit durationChanged();
            } else if (strcmp(prop->name, "pause") == 0 && prop->format == MPV_FORMAT_FLAG) {
                m_isPaused = *static_cast<int *>(prop->data) != 0;
                emit isPausedChanged();
            }
        }
    }
}

void MpvItem::setSource(const QString &url) {
    if (m_source == url || !m_mpv) return;
    m_source = url;
    if (url.isEmpty()) {
        const char *cmd[] = {"stop", nullptr};
        mpv_command_async(m_mpv, 0, cmd);
    } else {
        const char *cmd[] = {"loadfile", url.toUtf8().constData(), "replace", nullptr};
        mpv_command_async(m_mpv, 0, cmd);
    }
    emit sourceChanged();
}

void MpvItem::setMuted(bool mute) {
    if (m_muted == mute || !m_mpv) return;
    m_muted = mute;
    mpv_set_property_string(m_mpv, "mute", mute ? "yes" : "no");
    emit mutedChanged();
}

void MpvItem::setVolume(float vol) {
    if (!m_mpv) return;
    m_volume = vol;
    double dVol = static_cast<double>(vol);
    mpv_set_property(m_mpv, "volume", MPV_FORMAT_DOUBLE, &dVol);
    emit volumeChanged();
}

void MpvItem::play() {
    if (!m_mpv) return;
    int pause = 0;
    mpv_set_property(m_mpv, "pause", MPV_FORMAT_FLAG, &pause);
}

void MpvItem::pause() {
    if (!m_mpv) return;
    int pause = 1;
    mpv_set_property(m_mpv, "pause", MPV_FORMAT_FLAG, &pause);
}

void MpvItem::togglePause() {
    if (!m_mpv) return;
    int pause = m_isPaused ? 0 : 1;
    mpv_set_property(m_mpv, "pause", MPV_FORMAT_FLAG, &pause);
}

void MpvItem::seek(double seconds) {
    if (!m_mpv) return;
    const char *cmd[] = {"seek", QString::number(seconds).toUtf8().constData(), "relative", nullptr};
    mpv_command_async(m_mpv, 0, cmd);
}

void MpvItem::stop() {
    if (!m_mpv) return;
    const char *cmd[] = {"stop", nullptr};
    mpv_command_async(m_mpv, 0, cmd);
}
