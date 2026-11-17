# Module Vinx.System : services système exposés au QML (singletons C++).
qt_add_qml_module(vinxsystem
    URI Vinx.System
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    PLUGIN_TARGET vinxsystem
    SOURCES
        dbusutil.h wpctl.h
        battery.h battery.cpp
        network.h network.cpp
        bluetooth.h bluetooth.cpp
        audio.h audio.cpp
        session.h session.cpp
        desktopentry.h
        applications.h applications.cpp
        preferences.h preferences.cpp
        notifications.h notifications.cpp
        filesearch.h filesearch.cpp
        shellservice.h shellservice.cpp
        flatpak.h flatpak.cpp
        menubridge.h menubridge.cpp
        updateparse.h updates.h updates.cpp
        syscmd.h sysparse.h
        wifi.h wifi.cpp
        printers.h printers.cpp
        drivers.h drivers.cpp
        accounts.h accounts.cpp
        diagparse.h diagnostics.h diagnostics.cpp
        debianpackages.h debianpackages.cpp
)
target_link_libraries(vinxsystem PRIVATE Qt6::Qml Qt6::Gui Qt6::Widgets Qt6::DBus crypt)

install(TARGETS vinxsystem LIBRARY DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/System")
install(FILES
    "${QT_QML_OUTPUT_DIRECTORY}/Vinx/System/qmldir"
    "${QT_QML_OUTPUT_DIRECTORY}/Vinx/System/vinxsystem.qmltypes"
    DESTINATION "${VINX_QML_INSTALL_DIR}/Vinx/System")
