cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES C CXX)

# Embed the window icon so direct launches do not depend on desktop installation.
find_program(GLIB_COMPILE_RESOURCES glib-compile-resources)
if(NOT GLIB_COMPILE_RESOURCES)
  message(FATAL_ERROR "glib-compile-resources is required to embed the app icon")
endif()
set(APP_ICON "${CMAKE_CURRENT_SOURCE_DIR}/../../assets/images/app_icon.png")
set(APP_ICON_DARK "${CMAKE_CURRENT_SOURCE_DIR}/../../assets/images/app_icon_dark.png")
configure_file("resources.gresource.xml.in"
  "${CMAKE_CURRENT_BINARY_DIR}/resources.gresource.xml" @ONLY)
set(APP_RESOURCES "${CMAKE_CURRENT_BINARY_DIR}/stork_resources.c")
add_custom_command(
  OUTPUT "${APP_RESOURCES}"
  COMMAND "${GLIB_COMPILE_RESOURCES}"
    --generate-source --c-name stork --target "${APP_RESOURCES}"
    --sourcedir "${CMAKE_CURRENT_SOURCE_DIR}/../../assets/images"
    "${CMAKE_CURRENT_BINARY_DIR}/resources.gresource.xml"
  DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/resources.gresource.xml"
    "${APP_ICON}" "${APP_ICON_DARK}"
  VERBATIM
)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "${APP_RESOURCES}"
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "../../src/native/stork_canard.c"
  "../../src/native/libcanard/canard.c"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Export symbols to allow DynamicLibrary.executable() to look them up via FFI
set_target_properties(${BINARY_NAME} PROPERTIES ENABLE_EXPORTS TRUE)


# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "../../src/native")
