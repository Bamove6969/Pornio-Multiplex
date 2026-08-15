#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QSurfaceFormat>
#include <QLoggingCategory>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include "mpvitem.h"
#include "quadcontroller.h"

int main(int argc, char *argv[]) {
    // Suppress benign Qt network SSL warnings since Rust & libmpv handle all TLS/HTTPS directly
    qputenv("QT_LOGGING_RULES", "qt.network.ssl.*=false");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    qputenv("QSG_RHI_BACKEND", "opengl");

    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    QSurfaceFormat format;
    format.setRenderableType(QSurfaceFormat::OpenGL);
    format.setDepthBufferSize(24);
    format.setStencilBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);
    app.setApplicationName("Stremio Multiview");
    app.setOrganizationName("StremioMultiview");

    QString appDir = QCoreApplication::applicationDirPath();
    QCoreApplication::addLibraryPath(appDir);
    QCoreApplication::addLibraryPath(appDir + "/plugins");

    QQuickStyle::setStyle("Basic");

    // Register custom QML types
    qmlRegisterType<MpvItem>("StremioMultiview", 1, 0, "MpvItem");

    QuadController quadController;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("QuadController", &quadController);

    // Robustly resolve Main.qml location independent of Current Working Directory (CWD)
    QString qmlPath;
    if (QFileInfo::exists(appDir + "/qml/Main.qml")) {
        qmlPath = QFileInfo(appDir + "/qml/Main.qml").canonicalFilePath();
    } else if (QFileInfo::exists(appDir + "/../qml/Main.qml")) {
        qmlPath = QFileInfo(appDir + "/../qml/Main.qml").canonicalFilePath();
    } else if (QFileInfo::exists("qml/Main.qml")) {
        qmlPath = QFileInfo("qml/Main.qml").canonicalFilePath();
    }

    if (qmlPath.isEmpty()) {
        qCritical() << "Fatal: Could not locate qml/Main.qml. Looked in:" 
                    << appDir + "/qml/Main.qml" << "and" << appDir + "/../qml/Main.qml";
        return -1;
    }

    const QUrl url = QUrl::fromLocalFile(qmlPath);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
