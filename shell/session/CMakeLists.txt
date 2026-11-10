# Session « VinX OS » proposée par l'écran de connexion (SDDM).
install(PROGRAMS vinx-session DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(PROGRAMS vinx-shell-autostart DESTINATION "${CMAKE_INSTALL_LIBEXECDIR}")
install(FILES vinx.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/wayland-sessions")
install(FILES org.vinx.shell.desktop DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/xdg/autostart")
install(FILES plasmashell-vinx.conf DESTINATION "lib/systemd/user/plasma-plasmashell.service.d")
install(FILES xdg/kwinrc DESTINATION "${CMAKE_INSTALL_DATADIR}/vinx/xdg")
