# Tests QML (Qt Quick Test) des modules Vinx.Theme et Vinx.Controls.
find_program(QMLTESTRUNNER qmltestrunner HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}" /usr/lib/qt6/bin)
if(QMLTESTRUNNER)
    add_test(NAME qml-controls
        COMMAND "${QMLTESTRUNNER}" -input "${CMAKE_CURRENT_SOURCE_DIR}" -import "${QT_QML_OUTPUT_DIRECTORY}")
    set_tests_properties(qml-controls PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
else()
    message(WARNING "qmltestrunner introuvable : tests QML désactivés")
endif()
