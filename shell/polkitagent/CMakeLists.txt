# Agent polkit VinX (ADR 0028) : fenêtre de mot de passe administrateur aux couleurs de VinX.
# Construit seulement si polkit-qt pour Qt 6 est présent (Debian : libpolkit-qt6-1-dev).
find_package(PolkitQt6-1 QUIET)
if(PolkitQt6-1_FOUND)
    qt_add_executable(vinx-polkit-agent main.cpp agent.h agent.cpp)
    qt_add_resources(vinx-polkit-agent "polkitagent" PREFIX "/vinx-polkit-agent" FILES AuthDialog.qml)
    target_link_libraries(vinx-polkit-agent PRIVATE Qt6::Gui Qt6::Quick PolkitQt6-1::Agent)
    target_compile_definitions(vinx-polkit-agent PRIVATE VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}")
    install(TARGETS vinx-polkit-agent RUNTIME DESTINATION "${CMAKE_INSTALL_LIBEXECDIR}")
    install(FILES org.vinx.polkit-agent.desktop DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/xdg/autostart")
    # L'agent de KDE est désactivé dans la session VinX seulement, et seulement si celui de VinX existe.
    install(FILES plasma-polkit-agent-vinx.conf DESTINATION "lib/systemd/user/plasma-polkit-agent.service.d")
    message(STATUS "Agent polkit VinX : activé")
else()
    message(STATUS "Agent polkit VinX : polkit-qt (Qt 6) introuvable — non construit")
endif()
