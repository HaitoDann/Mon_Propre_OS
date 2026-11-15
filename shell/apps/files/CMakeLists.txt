# Fichiers : gestionnaire de fichiers (interface VinX, moteur KIO de KDE si disponible).
qt_add_executable(vinx-files main.cpp)
qt_add_qml_module(vinx-files
    URI Vinx.Files
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    NO_PLUGIN
    SOURCES
        folderentry.h
        foldermodel.h foldermodel.cpp
        fileops.h fileops.cpp
    QML_FILES
        Main.qml
        Sidebar.qml
        FileGrid.qml
        FileList.qml
        PathBar.qml
        FileIcon.qml
        RenameField.qml
        ConflictDialog.qml
)
target_include_directories(vinx-files PRIVATE "${PROJECT_SOURCE_DIR}/apps" "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(vinx-files PRIVATE Qt6::Gui Qt6::Widgets Qt6::Quick)
target_compile_definitions(vinx-files PRIVATE VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}" VINX_VERSION="${PROJECT_VERSION}")
if(KF6KIO_FOUND)
    target_compile_definitions(vinx-files PRIVATE VINX_HAVE_KIO)
    target_link_libraries(vinx-files PRIVATE KF6::KIOCore KF6::KIOGui KF6::KIOWidgets)
endif()
install(TARGETS vinx-files RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.files.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
