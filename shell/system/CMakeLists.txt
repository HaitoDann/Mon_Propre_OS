# Outils système de VinX (exécutés en administrateur via pkexec ou APT).
install(PROGRAMS vinx-snapshots DESTINATION "lib/vinx")
install(FILES 80vinx-snapshot DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/apt/apt.conf.d")
install(FILES org.vinx.snapshots.policy DESTINATION "${CMAKE_INSTALL_DATADIR}/polkit-1/actions")
