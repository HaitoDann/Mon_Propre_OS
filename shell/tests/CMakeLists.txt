# Tests QML (Qt Quick Test) des modules Vinx.Theme et Vinx.Controls.
find_program(QMLTESTRUNNER qmltestrunner HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}" /usr/lib/qt6/bin)
if(QMLTESTRUNNER)
    add_test(NAME qml-controls
        COMMAND "${QMLTESTRUNNER}" -input "${CMAKE_CURRENT_SOURCE_DIR}" -import "${QT_QML_OUTPUT_DIRECTORY}")
    # Préférences isolées : les tests ne lisent jamais la configuration de l'utilisateur qui construit.
    set_tests_properties(qml-controls PROPERTIES ENVIRONMENT
        "QT_QPA_PLATFORM=offscreen;XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/config-qml;LANG=C.UTF-8;VINX_TASKS_BACKEND=preview")
else()
    message(WARNING "qmltestrunner introuvable : tests QML désactivés")
endif()

# Tests C++ (analyse des sorties des outils système).
find_package(Qt6 REQUIRED COMPONENTS Test)
qt_add_executable(tst_wpctl tst_wpctl.cpp)
target_include_directories(tst_wpctl PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_wpctl PRIVATE Qt6::Test)
add_test(NAME wpctl-parsing COMMAND tst_wpctl)

qt_add_executable(tst_updates tst_updates.cpp)
target_include_directories(tst_updates PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_updates PRIVATE Qt6::Test)
add_test(NAME update-parsing COMMAND tst_updates)

qt_add_executable(tst_sysparse tst_sysparse.cpp)
target_include_directories(tst_sysparse PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_sysparse PRIVATE Qt6::Test)
add_test(NAME system-parsing COMMAND tst_sysparse)

qt_add_executable(tst_diag tst_diag.cpp)
target_include_directories(tst_diag PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_diag PRIVATE Qt6::Test)
add_test(NAME diagnostics COMMAND tst_diag)

qt_add_executable(tst_desktopentry tst_desktopentry.cpp)
target_include_directories(tst_desktopentry PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_desktopentry PRIVATE Qt6::Test)
add_test(NAME desktop-entry COMMAND tst_desktopentry)

qt_add_executable(tst_accentpick tst_accentpick.cpp)
target_include_directories(tst_accentpick PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_accentpick PRIVATE Qt6::Test Qt6::Gui)
add_test(NAME accent-pick COMMAND tst_accentpick)

qt_add_executable(tst_windowtheme tst_windowtheme.cpp)
target_include_directories(tst_windowtheme PRIVATE "${PROJECT_SOURCE_DIR}/windowtheme")
target_link_libraries(tst_windowtheme PRIVATE Qt6::Test Qt6::Gui Qt6::Svg)
add_test(NAME window-theme COMMAND tst_windowtheme)

qt_add_executable(tst_termtheme tst_termtheme.cpp)
target_include_directories(tst_termtheme PRIVATE "${PROJECT_SOURCE_DIR}/apps/terminal")
target_link_libraries(tst_termtheme PRIVATE Qt6::Test Qt6::Gui vinx::tokens)
add_test(NAME terminal-theme COMMAND tst_termtheme)

qt_add_executable(tst_office tst_office.cpp)
target_include_directories(tst_office PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_office PRIVATE Qt6::Test)
add_test(NAME office-format COMMAND tst_office)

qt_add_executable(tst_flatpak tst_flatpak.cpp "${PROJECT_SOURCE_DIR}/qml/Vinx/System/flatpak.cpp")
target_include_directories(tst_flatpak PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_flatpak PRIVATE Qt6::Test Qt6::DBus Qt6::Qml)
add_test(NAME flatpak-progress COMMAND tst_flatpak)
# Les tests QML de tests/store/ sont exécutés par qml-controls (parcours récursif).

# Écran de verrouillage (kscreenlocker) avec un faux authentificateur.
qt_add_executable(tst_lockscreen tst_lockscreen.cpp)
target_link_libraries(tst_lockscreen PRIVATE Qt6::Test Qt6::Quick)
target_compile_definitions(tst_lockscreen PRIVATE
    VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}"
    LOCKSCREEN_QML="${PROJECT_SOURCE_DIR}/lockscreen/LockScreen.qml")
add_test(NAME lockscreen COMMAND tst_lockscreen)
set_tests_properties(lockscreen PROPERTIES ENVIRONMENT
    "QT_QPA_PLATFORM=offscreen;XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/config-lockscreen;LANG=C.UTF-8")

# Repartir de préférences vierges à chaque exécution des tests.
file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/config-qml" "${CMAKE_CURRENT_BINARY_DIR}/config-lockscreen")

# Relance automatique : 3 plantages simulés → abandon avec le code du shell. Le « logger » factice
# évite d'écrire ces faux plantages dans le journal réel (visible dans Dépannage).
add_test(NAME shell-autostart-restart
    COMMAND sh -c "printf '#!/bin/sh\\necho x >> \"$0.count\"\\nexit 3\\n' > crash.sh && chmod +x crash.sh && rm -f crash.sh.count && mkdir -p nolog && printf '#!/bin/sh\\nexit 1\\n' > nolog/logger && chmod +x nolog/logger && PATH=$PWD/nolog:$PATH VINX_SESSION=1 VINX_SHELL_BIN=./crash.sh VINX_SHELL_MAX_CRASHES=3 sh ${CMAKE_SOURCE_DIR}/session/vinx-shell-autostart; [ $? -eq 3 ] && [ $(wc -l < crash.sh.count) -eq 3 ]"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

# Fichiers : moteur local (le moteur KIO n'est compilé que si KIO est présent).
qt_add_executable(tst_files tst_files.cpp
    ${PROJECT_SOURCE_DIR}/apps/files/foldermodel.cpp ${PROJECT_SOURCE_DIR}/apps/files/fileops.cpp)
target_include_directories(tst_files PRIVATE "${PROJECT_SOURCE_DIR}/apps/files")
target_link_libraries(tst_files PRIVATE Qt6::Test Qt6::Gui Qt6::Qml)
add_test(NAME files-local COMMAND tst_files)
set_tests_properties(files-local PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;LANG=C.UTF-8")

# Comptes : hachage des mots de passe et noms d'utilisateur.
qt_add_executable(tst_accounts tst_accounts.cpp ${PROJECT_SOURCE_DIR}/qml/Vinx/System/accounts.cpp)
target_include_directories(tst_accounts PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_accounts PRIVATE Qt6::Test Qt6::DBus Qt6::Qml crypt)
add_test(NAME accounts COMMAND tst_accounts)

# Version unique de VinX OS (vinx-release, ADR 0040).
add_test(NAME release COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/release-test.sh" "${PROJECT_BINARY_DIR}/system/vinx-release")

# Sauvegarde des documents (vinx-backup) : versions, liens physiques, restauration à part.
find_program(RSYNC rsync)
if(RSYNC)
    add_test(NAME backup COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/backup-test.sh" "${PROJECT_SOURCE_DIR}/system/vinx-backup")
endif()

# Traduction anglaise complète : tout texte de l'interface doit avoir sa traduction (ADR 0034).
find_program(LUPDATE NAMES lupdate HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}" /usr/lib/qt6/bin)
if(LUPDATE)
    add_test(NAME translations-complete COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/translations-test.sh" "${LUPDATE}" "${PROJECT_SOURCE_DIR}")
endif()

# Moniteur système : lecture de /proc et regroupement par application (ADR 0035).
qt_add_executable(tst_monitor tst_monitor.cpp ${PROJECT_SOURCE_DIR}/apps/monitor/processmodel.cpp)
target_include_directories(tst_monitor PRIVATE "${PROJECT_SOURCE_DIR}/apps/monitor" "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_monitor PRIVATE Qt6::Test Qt6::Gui)
add_test(NAME monitor COMMAND tst_monitor)
set_tests_properties(monitor PROPERTIES ENVIRONMENT "LANG=C.UTF-8")

# Capture d'écran : image brute de KWin, nom de fichier, annotations (ADR 0036).
qt_add_executable(tst_screenshot tst_screenshot.cpp)
target_include_directories(tst_screenshot PRIVATE "${PROJECT_SOURCE_DIR}/apps/screenshot")
target_link_libraries(tst_screenshot PRIVATE Qt6::Test Qt6::Gui)
add_test(NAME screenshot COMMAND tst_screenshot)
set_tests_properties(screenshot PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")

# Presse-papiers : historique, épinglés, mots de passe ignorés (ADR 0037).
qt_add_executable(tst_clipboard tst_clipboard.cpp ${PROJECT_SOURCE_DIR}/qml/Vinx/System/clipboard.cpp)
target_include_directories(tst_clipboard PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_clipboard PRIVATE Qt6::Test Qt6::Gui Qt6::Qml)
if(KF6GuiAddons_FOUND)
    target_compile_definitions(tst_clipboard PRIVATE VINX_HAVE_GUIADDONS)
    target_link_libraries(tst_clipboard PRIVATE KF6::GuiAddons)
endif()
add_test(NAME clipboard COMMAND tst_clipboard)
set_tests_properties(clipboard PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;LANG=C.UTF-8")

# Visionneur d'images : EXIF, retouches, dossier, copie modifiée (ADR 0038).
qt_add_executable(tst_viewer tst_viewer.cpp ${PROJECT_SOURCE_DIR}/apps/viewer/viewer.cpp)
target_include_directories(tst_viewer PRIVATE "${PROJECT_SOURCE_DIR}/apps/viewer" "${PROJECT_SOURCE_DIR}/apps/screenshot")
target_link_libraries(tst_viewer PRIVATE Qt6::Test Qt6::Gui Qt6::Quick Qt6::DBus)
add_test(NAME viewer COMMAND tst_viewer)
set_tests_properties(viewer PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;LANG=C.UTF-8")

# Noms des couleurs d'accent : common/accentnames.h (déclarés pour la traduction) suit tokens.toml.
add_test(NAME accent-names
    COMMAND "${Python3_EXECUTABLE}" -c "import re,sys,tomllib; t=tomllib.load(open(sys.argv[1],'rb')); h=open(sys.argv[2],encoding='utf-8').read(); m=[a['name'] for a in t['accents'].values() if '\"'+a['name']+'\"' not in h]; print('manquants :', m) if m else None; sys.exit(1 if m else 0)"
            "${VINX_BRANDING_DIR}/tokens.toml" "${PROJECT_SOURCE_DIR}/common/accentnames.h")

# Outils /usr/lib/vinx cités dans le code : tous installés (installation de test dans le dossier de build).
add_test(NAME installed-tools
    COMMAND sh -c "rm -rf destdir && DESTDIR=$PWD/destdir \"${CMAKE_COMMAND}\" --install \"${PROJECT_BINARY_DIR}\" --prefix /usr >/dev/null && sh \"${CMAKE_CURRENT_SOURCE_DIR}/installed-tools.sh\" \"${PROJECT_SOURCE_DIR}\" destdir"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

# Contrastes WCAG AA de tokens.toml, 8 accents, clair et sombre (docs/DESIGN.md § 2).
add_test(NAME contrast COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/contrast.py" "${VINX_BRANDING_DIR}/tokens.toml")

# Fumée : chaque page des Paramètres et chaque application s'ouvre sans erreur QML.
add_test(NAME apps-smoke COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/apps-smoke.sh" "${PROJECT_BINARY_DIR}")
set_tests_properties(apps-smoke PROPERTIES TIMEOUT 900)

# vinx-admin (administrateur) : arguments douteux refusés (option, plusieurs lignes, URI non IPP…).
add_test(NAME admin COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/admin-test.sh" "${PROJECT_SOURCE_DIR}/system/vinx-admin")

# vinx-snapshots restore : Timeshift appelé pour un nom valide, noms douteux refusés.
add_test(NAME snapshots COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/snapshots-test.sh" "${PROJECT_SOURCE_DIR}/system/vinx-snapshots")
