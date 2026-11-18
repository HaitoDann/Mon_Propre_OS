# Moniteur système : applications et processus, processeur, mémoire, disque, réseau (ADR 0035).
qt_add_executable(vinx-monitor main.cpp)
qt_add_qml_module(vinx-monitor
    URI Vinx.Monitor
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    NO_PLUGIN
    SOURCES
        procparse.h
        processmodel.h processmodel.cpp
    QML_FILES
        Main.qml
        Sparkline.qml
)
target_include_directories(vinx-monitor PRIVATE "${PROJECT_SOURCE_DIR}/apps" "${PROJECT_SOURCE_DIR}/qml/Vinx/System" "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(vinx-monitor PRIVATE Qt6::Gui Qt6::Quick)
target_compile_definitions(vinx-monitor PRIVATE VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}" VINX_VERSION="${PROJECT_VERSION}")
install(TARGETS vinx-monitor RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.monitor.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
