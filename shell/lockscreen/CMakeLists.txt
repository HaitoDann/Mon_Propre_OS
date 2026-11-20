# Écran de verrouillage VinX.
# Plasma 6 (kscreenlocker 6.x) lit l'écran de verrouillage dans le paquet de *shell* Plasma
# (plasmashellrc [Shell] ShellPackage, sinon $PLASMA_DEFAULT_SHELL, sinon org.kde.plasma.desktop),
# plus dans le paquet d'apparence (ADR 0045). vinx-session exporte PLASMA_DEFAULT_SHELL=org.vinx.lockscreen.
set(VINX_LOCK_SHELL "${CMAKE_INSTALL_DATADIR}/plasma/shells/org.vinx.lockscreen")
install(FILES shell-package/metadata.json DESTINATION "${VINX_LOCK_SHELL}")
install(FILES shell-package/contents/views/Desktop.qml DESTINATION "${VINX_LOCK_SHELL}/contents/views")
install(FILES LockScreen.qml DESTINATION "${VINX_LOCK_SHELL}/contents/lockscreen")
# Ancien emplacement (paquet d'apparence), gardé pour les versions de Plasma qui le lisent encore.
install(FILES LockScreen.qml DESTINATION "${CMAKE_INSTALL_DATADIR}/plasma/look-and-feel/org.vinx.desktop/contents/lockscreen")
