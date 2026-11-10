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
