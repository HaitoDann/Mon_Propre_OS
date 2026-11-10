# Module Vinx.Theme : singleton Theme généré depuis branding/tokens.toml.
set(TOKENS "${VINX_BRANDING_DIR}/tokens.toml")
set(GENERATED "${CMAKE_CURRENT_BINARY_DIR}/Theme.qml")

add_custom_command(
    OUTPUT "${GENERATED}"
    COMMAND Python3::Interpreter "${PROJECT_SOURCE_DIR}/tools/gen_theme.py" "${TOKENS}" "${GENERATED}"
    DEPENDS "${TOKENS}" "${PROJECT_SOURCE_DIR}/tools/gen_theme.py"
    COMMENT "Génération de Theme.qml depuis tokens.toml"
)
set_source_files_properties("${GENERATED}" PROPERTIES QT_QML_SINGLETON_TYPE TRUE QT_RESOURCE_ALIAS Theme.qml)

qt_add_qml_module(vinxtheme
    URI Vinx.Theme
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    PLUGIN_TARGET vinxtheme
    QML_FILES "${GENERATED}"
)

install(TARGETS vinxtheme LIBRARY DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/Theme")
install(FILES "${QT_QML_OUTPUT_DIRECTORY}/Vinx/Theme/qmldir" DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/Theme")
