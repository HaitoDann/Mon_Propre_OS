# Module Vinx.Shell : éléments du shell (barre supérieure, panneaux, fenêtres).
set_source_files_properties(ShellState.qml Tasks.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(vinxshell
    URI Vinx.Shell
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    PLUGIN_TARGET vinxshell
    IMPORTS Vinx.Theme Vinx.Controls Vinx.System
    QML_FILES
        ShellState.qml
        TopBar.qml
        TopBarButton.qml
        ControlCenter.qml
        CalendarPanel.qml
        Panels.qml
        TopBarWindow.qml
        PopupWindow.qml
        Preview.qml
        Tasks.qml
        PreviewTasksBackend.qml
        AppStyle.js
        Dock.qml
        DockItem.qml
        DockWindow.qml
        Background.qml
        BackgroundWindow.qml
    # Chargé dynamiquement (dépend de org.kde.taskmanager, absent à la compilation) :
    RESOURCES KdeTasksBackend.qml
)

install(TARGETS vinxshell LIBRARY DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/Shell")
install(FILES "${QT_QML_OUTPUT_DIRECTORY}/Vinx/Shell/qmldir" DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/Shell")
