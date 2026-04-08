cmake_minimum_required(VERSION 3.16)
project(Tricount VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Modules Qt pour l'UI (Quick) et les appels API (Network)
find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

# Sources C++ (Logique API)
qt_add_executable(appTricount
    main.cpp
    tricountapi.h
    tricountapi.cpp
)

# Enregistrement des composants QML
qt_add_qml_module(appTricount
    URI Tricount
    VERSION 1.0
    QML_FILES
        Main.qml
        LeftPanel.qml
        RightPanel.qml
        ExpensesView.qml
        BalancesView.qml
        NewGroupOverlay.qml
        NewExpenseOverlay.qml
    SOURCES
        tricountapi.h
        tricountapi.cpp
)

# Empêche l'ouverture d'une console Windows en arrière-plan
set_target_properties(appTricount PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appTricount
    PRIVATE Qt6::Quick Qt6::Network
)
