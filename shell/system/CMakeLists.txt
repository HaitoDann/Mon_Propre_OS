# Outils système de VinX (exécutés en administrateur via pkexec ou APT).
install(PROGRAMS vinx-snapshots vinx-admin DESTINATION "lib/vinx")
install(PROGRAMS vinx-dev vinx-backup DESTINATION "${CMAKE_INSTALL_BINDIR}")
# Sauvegarde des documents : minuteur utilisateur, démarré par vinx-session (ADR 0032).
install(FILES vinx-backup.service vinx-backup.timer DESTINATION "lib/systemd/user")
install(FILES 80vinx-snapshot DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/apt/apt.conf.d")
install(FILES org.vinx.snapshots.policy org.vinx.admin.policy DESTINATION "${CMAKE_INSTALL_DATADIR}/polkit-1/actions")
