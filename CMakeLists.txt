cmake_minimum_required(VERSION 3.10)
project(tg
    VERSION 1.0.0
    DESCRIPTION "Geometry library for C"
    LANGUAGES C
)

# Build options
option(BUILD_EXAMPLES "Build example programs" OFF)
option(BUILD_TESTS "Build test suite" OFF)

# Main tg library
add_library(tg STATIC
    tg.c
    tg.h
    deps/fp.c
    deps/fp.h
    deps/json.c
    deps/json.h
)

# Modern CMake: use target-based include directories
target_include_directories(tg PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)

target_include_directories(tg PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/deps
)

# Link with math library
target_link_libraries(tg PUBLIC m)

# Optional: Set compile options for debug builds
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(tg PRIVATE -Wall -Wextra)
endif()

# Optional subdirectories
if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
