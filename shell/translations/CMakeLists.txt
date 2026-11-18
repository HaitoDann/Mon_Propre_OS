# Traduction anglaise (ADR 0034) : vinx_en.ts → vinx_en.qm, installé dans /usr/share/vinx/translations.
# Mise à jour du catalogue : lupdate (voir docs/TRADUCTION.md), puis tools/fill_translations.py en.
find_package(Qt6 QUIET COMPONENTS LinguistTools)
set(VINX_QM "${CMAKE_CURRENT_BINARY_DIR}/vinx_en.qm")
if(TARGET Qt6::lrelease)
    add_custom_command(OUTPUT "${VINX_QM}"
        COMMAND Qt6::lrelease -silent "${CMAKE_CURRENT_SOURCE_DIR}/vinx_en.ts" -qm "${VINX_QM}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/vinx_en.ts"
        COMMENT "Compilation de la traduction anglaise")
    add_custom_target(vinx-translations ALL DEPENDS "${VINX_QM}")
    install(FILES "${VINX_QM}" DESTINATION "${CMAKE_INSTALL_DATADIR}/vinx/translations")
else()
    message(WARNING "lrelease introuvable (qt6-l10n-tools) : traduction anglaise non construite")
endif()
