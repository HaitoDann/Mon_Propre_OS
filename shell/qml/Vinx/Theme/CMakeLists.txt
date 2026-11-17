# Module Vinx.Theme : singleton Theme généré depuis branding/tokens.toml.
set(TOKENS "${VINX_BRANDING_DIR}/tokens.toml")
set(GENERATED "${CMAKE_CURRENT_BINARY_DIR}/Theme.qml")

set(GENERATED_HEADER "${CMAKE_CURRENT_BINARY_DIR}/include/vinxtokens.h")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include")
add_custom_command(
    OUTPUT "${GENERATED}" "${GENERATED_HEADER}"
    COMMAND Python3::Interpreter "${PROJECT_SOURCE_DIR}/tools/gen_theme.py" "${TOKENS}" "${GENERATED}" "${GENERATED_HEADER}"
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

# Mêmes valeurs pour le C++ (Terminal VinX…) : #include "vinxtokens.h" en liant vinx::tokens.
add_custom_target(vinx-tokens-header DEPENDS "${GENERATED_HEADER}")
add_library(vinxtokens INTERFACE)
add_library(vinx::tokens ALIAS vinxtokens)
target_include_directories(vinxtokens INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/include")
add_dependencies(vinxtokens vinx-tokens-header)
