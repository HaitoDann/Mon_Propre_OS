# Session « VinX OS » proposée par l'écran de connexion (SDDM).
install(PROGRAMS vinx-session DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(PROGRAMS vinx-shell-autostart DESTINATION "${CMAKE_INSTALL_LIBEXECDIR}")
install(FILES vinx.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/wayland-sessions")
install(FILES org.vinx.shell.desktop DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/xdg/autostart")
install(FILES plasmashell-vinx.conf DESTINATION "lib/systemd/user/plasma-plasmashell.service.d")
install(FILES xdg/kwinrc xdg/mimeapps.list xdg/kde-mimeapps.list DESTINATION "${CMAKE_INSTALL_DATADIR}/vinx/xdg")
# Applications KDE remplacées par VinX, masquées dans la session VinX seulement (ADR 0025).
install(DIRECTORY data/applications DESTINATION "${CMAKE_INSTALL_DATADIR}/vinx/data")
install(PROGRAMS vinx-shellctl DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.shellctl.search.desktop org.vinx.shellctl.control.desktop org.vinx.shellctl.calendar.desktop org.vinx.shellctl.clipboard.desktop
        DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
