# vinx-gallery : vitrine interactive du design system (sert aussi de recette visuelle).
qt_add_executable(vinx-gallery main.cpp)
qt_add_qml_module(vinx-gallery
    URI Vinx.Gallery
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES Gallery.qml
    NO_PLUGIN
)
target_link_libraries(vinx-gallery PRIVATE Qt6::Gui Qt6::Quick)
target_compile_definitions(vinx-gallery PRIVATE
    VINX_BUILD_QML_DIR="${QT_QML_OUTPUT_DIRECTORY}"
    VINX_VERSION="${PROJECT_VERSION}")

install(TARGETS vinx-gallery RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES org.vinx.gallery.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
