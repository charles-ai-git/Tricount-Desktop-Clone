#include <QGuiApplication>
#include <QQmlApplicationEngine>

// Enregistrement manuel du module (généré par CMake)
extern void qml_register_types_Tricount();

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Force l'inclusion des types QML pour éviter que le linker
    // ne les ignore (module non référencé directement en C++)
    volatile auto registration = &qml_register_types_Tricount;
    Q_UNUSED(registration)

    QQmlApplicationEngine engine;

    // Gestion de l'échec de chargement
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    // Chargement via l'URI du module
    engine.loadFromModule("Tricount", "Main");

    return app.exec();
}
