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

qt_add_executable(tst_desktopentry tst_desktopentry.cpp)
target_include_directories(tst_desktopentry PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_desktopentry PRIVATE Qt6::Test)
add_test(NAME desktop-entry COMMAND tst_desktopentry)

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

# Relance automatique : 3 plantages simulés → abandon avec le code du shell.
add_test(NAME shell-autostart-restart
    COMMAND sh -c "printf '#!/bin/sh\\necho x >> \"$0.count\"\\nexit 3\\n' > crash.sh && chmod +x crash.sh && rm -f crash.sh.count && VINX_SESSION=1 VINX_SHELL_BIN=./crash.sh VINX_SHELL_MAX_CRASHES=3 sh ${CMAKE_SOURCE_DIR}/session/vinx-shell-autostart; [ $? -eq 3 ] && [ $(wc -l < crash.sh.count) -eq 3 ]"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

# Fichiers : moteur local (le moteur KIO n'est compilé que si KIO est présent).
qt_add_executable(tst_files tst_files.cpp
    ${PROJECT_SOURCE_DIR}/apps/files/foldermodel.cpp ${PROJECT_SOURCE_DIR}/apps/files/fileops.cpp)
target_include_directories(tst_files PRIVATE "${PROJECT_SOURCE_DIR}/apps/files")
target_link_libraries(tst_files PRIVATE Qt6::Test Qt6::Gui Qt6::Qml)
add_test(NAME files-local COMMAND tst_files)
set_tests_properties(files-local PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;LANG=C.UTF-8")
