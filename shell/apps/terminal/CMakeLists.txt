# Terminal VinX (ADR 0025) : Qt Widgets + QTermWidget (moteur de terminal de LXQt, sans KDE).
# Construit seulement si QTermWidget pour Qt 6 est présent (Debian : libqtermwidget6-2-dev).
find_package(qtermwidget6 QUIET)
if(qtermwidget6_FOUND)
    qt_add_executable(vinx-terminal main.cpp terminalwindow.cpp terminalwindow.h termtheme.h)
    target_link_libraries(vinx-terminal PRIVATE Qt6::Widgets qtermwidget6 vinx::tokens)
    install(TARGETS vinx-terminal RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
    install(FILES org.vinx.terminal.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
    message(STATUS "Terminal VinX : activé")
else()
    message(STATUS "Terminal VinX : QTermWidget (Qt 6) introuvable — non construit")
endif()
