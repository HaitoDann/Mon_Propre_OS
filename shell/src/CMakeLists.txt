# vinx-shell : processus du shell (barre supérieure pour l'instant).
qt_add_executable(vinx-shell main.cpp)
target_link_libraries(vinx-shell PRIVATE Qt6::Gui Qt6::Quick)
target_compile_definitions(vinx-shell PRIVATE
    VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}"
    VINX_VERSION="${PROJECT_VERSION}")

# Ancrage des surfaces du shell (Wayland, protocole wlr-layer-shell) — optionnel à la compilation.
find_package(LayerShellQt 6 QUIET)
if(LayerShellQt_FOUND)
    target_link_libraries(vinx-shell PRIVATE LayerShellQt::Interface)
    target_compile_definitions(vinx-shell PRIVATE VINX_HAVE_LAYERSHELL=1)
    message(STATUS "vinx-shell : layer-shell activé")
else()
    message(STATUS "vinx-shell : LayerShellQt 6 introuvable — mode aperçu uniquement")
endif()

install(TARGETS vinx-shell RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.shell-preview.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
