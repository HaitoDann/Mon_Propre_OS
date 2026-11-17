# Thème de fenêtre VinX (KWin Aurorae, ADR 0024) : générateur et thème par défaut installé.
qt_add_executable(vinx-window-theme main.cpp)
target_link_libraries(vinx-window-theme PRIVATE Qt6::Core Qt6::Gui Qt6::DBus)
install(TARGETS vinx-window-theme RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

# Thème par défaut (clair, vert) pour le premier démarrage, avant que le shell n'écrive celui de
# l'utilisateur dans ~/.local/share/aurorae/themes/VinX.
set(VINX_AURORAE_DIR "${CMAKE_CURRENT_BINARY_DIR}/aurorae/VinX")
add_custom_command(
    OUTPUT "${VINX_AURORAE_DIR}/VinXrc"
    COMMAND vinx-window-theme --output "${VINX_AURORAE_DIR}"
    DEPENDS vinx-window-theme
    COMMENT "Génération du thème de fenêtre VinX")
add_custom_target(vinx-aurorae-theme ALL DEPENDS "${VINX_AURORAE_DIR}/VinXrc")
install(DIRECTORY "${VINX_AURORAE_DIR}" DESTINATION "${CMAKE_INSTALL_DATADIR}/aurorae/themes")
