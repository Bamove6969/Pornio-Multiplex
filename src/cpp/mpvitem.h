#pragma once
#include <QQuickFramebufferObject>
#include <mpv/client.h>
#include <mpv/render_gl.h>

class MpvItemRenderer;

class MpvItem : public QQuickFramebufferObject {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool muted READ isMuted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY isPausedChanged)

public:
    explicit MpvItem(QQuickItem *parent = nullptr);
    ~MpvItem();

    Renderer *createRenderer() const override;

    QString source() const { return m_source; }
    void setSource(const QString &url);

    bool isMuted() const { return m_muted; }
    void setMuted(bool mute);

    float volume() const { return m_volume; }
    void setVolume(float vol);

    double position() const { return m_position; }
    double duration() const { return m_duration; }
    bool isPaused() const { return m_isPaused; }

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void seek(double seconds);
    Q_INVOKABLE void stop();

signals:
    void sourceChanged();
    void mutedChanged();
    void volumeChanged();
    void positionChanged();
    void durationChanged();
    void isPausedChanged();

private:
    void onMpvEvents();

    mpv_handle *m_mpv;
    QString m_source;
    bool m_muted;
    float m_volume;
    double m_position;
    double m_duration;
    bool m_isPaused;

    friend class MpvItemRenderer;
};
