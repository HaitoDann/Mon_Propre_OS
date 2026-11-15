cmake_minimum_required(VERSION 3.22)
project(vinx-shell VERSION 0.9.0 LANGUAGES CXX)

# Shell de bureau VinX OS — Qt 6 / QML, au-dessus de KWin.
# Modules : Vinx.Theme, Vinx.Controls, Vinx.System, Vinx.Shell ; programmes vinx-shell et vinx-gallery.

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Widgets Qml Quick Svg DBus)
find_package(Python3 3.11 REQUIRED COMPONENTS Interpreter)
# KIO (KDE Frameworks 6) : moteur du gestionnaire de fichiers (réseau, corbeille, conflits).
# Facultatif : sans lui, Fichiers se limite aux dossiers locaux.
find_package(KF6KIO 6.0 QUIET CONFIG)
message(STATUS "KIO pour Fichiers : ${KF6KIO_FOUND}")
qt_standard_project_setup()

include(GNUInstallDirs)
include(CTest)

set(VINX_BRANDING_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../branding" CACHE PATH "Dossier branding/ (tokens, icônes)")
set(VINX_QML_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml" CACHE PATH "Dossier d'installation des modules QML")
# Tous les modules QML sont produits dans build/qml/ (chemin d'import pour la galerie et les tests).
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

add_subdirectory(qml/Vinx/Theme)
add_subdirectory(qml/Vinx/Controls)
add_subdirectory(qml/Vinx/System)
add_subdirectory(qml/Vinx/Shell)
add_subdirectory(src)
add_subdirectory(session)
add_subdirectory(apps)
add_subdirectory(lockscreen)
add_subdirectory(gallery)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
