# Visionneur d'images : parcourir, zoomer, infos, retouches simples (ADR 0038).
qt_add_executable(vinx-images main.cpp)
qt_add_qml_module(vinx-images
    URI Vinx.Viewer
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    NO_PLUGIN
    SOURCES
        exif.h photo.h
        viewer.h viewer.cpp
    QML_FILES
        Main.qml
        Stage.qml
        InfoPanel.qml
        EditView.qml
        DarkChip.qml
)
# Annotations communes avec la capture d'écran (captureutil.h).
target_include_directories(vinx-images PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${PROJECT_SOURCE_DIR}/apps/screenshot")
target_link_libraries(vinx-images PRIVATE Qt6::Gui Qt6::Quick Qt6::DBus)
target_compile_definitions(vinx-images PRIVATE VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}" VINX_VERSION="${PROJECT_VERSION}")
install(TARGETS vinx-images RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.images.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
