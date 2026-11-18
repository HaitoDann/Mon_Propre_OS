# Capture d'écran : zone, fenêtre ou écran, annotation, copie et enregistrement (ADR 0036).
qt_add_executable(vinx-screenshot main.cpp)
qt_add_qml_module(vinx-screenshot
    URI Vinx.Screenshot
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    NO_PLUGIN
    SOURCES
        captureutil.h
        shot.h shot.cpp
    QML_FILES
        Main.qml
        Selector.qml
        Editor.qml
        ToolChip.qml
)
target_include_directories(vinx-screenshot PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(vinx-screenshot PRIVATE Qt6::Gui Qt6::Quick Qt6::DBus)
target_compile_definitions(vinx-screenshot PRIVATE VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}" VINX_VERSION="${PROJECT_VERSION}")
install(TARGETS vinx-screenshot RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.screenshot.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
