# Module Vinx.Controls : composants du design system.
file(GLOB ICON_FILES "${VINX_BRANDING_DIR}/icons/*.svg")
foreach(f IN LISTS ICON_FILES)
    get_filename_component(name "${f}" NAME)
    set_source_files_properties("${f}" PROPERTIES QT_RESOURCE_ALIAS "icons/${name}")
endforeach()

qt_add_qml_module(vinxcontrols
    URI Vinx.Controls
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    PLUGIN_TARGET vinxcontrols
    IMPORTS Vinx.Theme
    SOURCES icon.h icon.cpp
    QML_FILES
        Label.qml
        Surface.qml
        Elevation.qml
        Button.qml
        IconButton.qml
        AppIcon.qml
        Switch.qml
        Slider.qml
        SegmentedControl.qml
        Tile.qml
        Popover.qml
        Menu.qml
        MenuItem.qml
    RESOURCES ${ICON_FILES}
)
target_link_libraries(vinxcontrols PRIVATE Qt6::Quick Qt6::Svg)

install(TARGETS vinxcontrols LIBRARY DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/Controls")
install(FILES
    "${QT_QML_OUTPUT_DIRECTORY}/Vinx/Controls/qmldir"
    "${QT_QML_OUTPUT_DIRECTORY}/Vinx/Controls/vinxcontrols.qmltypes"
    DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/Controls")
