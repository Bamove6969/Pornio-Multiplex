cmake_minimum_required(VERSION 3.16)
project(stremio_multiview LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml OpenGL QuickControls2)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src/cpp
)

set(SOURCES
    src/cpp/main.cpp
    src/cpp/mpvitem.h
    src/cpp/mpvitem.cpp
    src/cpp/quadcontroller.h
    src/cpp/quadcontroller.cpp
)

add_executable(stremio-multiview ${SOURCES})

# Target Rust library path
set(RUST_TARGET_DIR "${CMAKE_CURRENT_SOURCE_DIR}/target/release")

find_library(RUST_CORE_LIB
    NAMES stremio_multiview_core libstremio_multiview_core
    PATHS ${RUST_TARGET_DIR}
    NO_DEFAULT_PATH
)

find_library(MPV_LIB
    NAMES mpv libmpv libmpv-2 mpv-2
    PATHS ${CMAKE_CURRENT_SOURCE_DIR}/lib
    NO_DEFAULT_PATH
)

target_link_libraries(stremio-multiview PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::OpenGL
    Qt6::QuickControls2
    ${MPV_LIB}
    ${RUST_CORE_LIB}
    ws2_32
    userenv
    bcrypt
    ntdll
)

# Post-build: Copy runtime DLLs, GCC libs, and QML files to output directory
add_custom_command(TARGET stremio-multiview POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/lib/libmpv-2.dll"
        $<TARGET_FILE_DIR:stremio-multiview>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/target/release/stremio_multiview_core.dll"
        $<TARGET_FILE_DIR:stremio-multiview>
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/qml"
        "$<TARGET_FILE_DIR:stremio-multiview>/qml"
)
