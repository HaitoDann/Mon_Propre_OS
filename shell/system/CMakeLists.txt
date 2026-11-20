# Outils système de VinX (exécutés en administrateur via pkexec ou APT).
install(PROGRAMS vinx-snapshots vinx-admin vinx-update vinx-greeter-sync DESTINATION "lib/vinx")
install(FILES vinx-i18n.sh DESTINATION "lib/vinx")
install(PROGRAMS vinx-dev vinx-backup DESTINATION "${CMAKE_INSTALL_BINDIR}")
# Sauvegarde des documents : minuteur utilisateur, démarré par vinx-session (ADR 0032).
install(FILES vinx-backup.service vinx-backup.timer DESTINATION "lib/systemd/user")
install(FILES 80vinx-snapshot DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/apt/apt.conf.d")
install(FILES org.vinx.snapshots.policy org.vinx.admin.policy org.vinx.greeter-sync.policy DESTINATION "${CMAKE_INSTALL_DATADIR}/polkit-1/actions")
# Version unique de VinX OS (ADR 0040) : écrite par le postinst du paquet et le déclencheur os-release.
configure_file(vinx-release.in "${CMAKE_CURRENT_BINARY_DIR}/vinx-release" @ONLY)
install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/vinx-release" DESTINATION "lib/vinx")
