# Tests QML (Qt Quick Test) des modules Vinx.Theme et Vinx.Controls.
find_program(QMLTESTRUNNER qmltestrunner HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}" /usr/lib/qt6/bin)
if(QMLTESTRUNNER)
    add_test(NAME qml-controls
        COMMAND "${QMLTESTRUNNER}" -input "${CMAKE_CURRENT_SOURCE_DIR}" -import "${QT_QML_OUTPUT_DIRECTORY}")
    set_tests_properties(qml-controls PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
else()
    message(WARNING "qmltestrunner introuvable : tests QML désactivés")
endif()

# Tests C++ (analyse des sorties des outils système).
find_package(Qt6 REQUIRED COMPONENTS Test)
qt_add_executable(tst_wpctl tst_wpctl.cpp)
target_include_directories(tst_wpctl PRIVATE "${PROJECT_SOURCE_DIR}/qml/Vinx/System")
target_link_libraries(tst_wpctl PRIVATE Qt6::Test)
add_test(NAME wpctl-parsing COMMAND tst_wpctl)

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
set_tests_properties(lockscreen PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
