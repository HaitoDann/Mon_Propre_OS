# Écran de verrouillage VinX : installé dans le paquet d'apparence org.vinx.desktop,
# où kscreenlocker le cherche (contents/lockscreen/LockScreen.qml).
install(FILES LockScreen.qml DESTINATION "${CMAKE_INSTALL_DATADIR}/plasma/look-and-feel/org.vinx.desktop/contents/lockscreen")
