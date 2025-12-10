cmake_minimum_required(VERSION 3.10)

# If this is the top-level CMakeLists.txt, set up the project
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(tg_tests C CXX)

    # Build the tg library from parent directory
    set(TG_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")

    # Add dependencies
    add_library(tg_deps OBJECT
        ${TG_ROOT}/deps/json.c
        ${TG_ROOT}/deps/fp.c
    )
    target_include_directories(tg_deps PUBLIC ${TG_ROOT}/deps)

    # Add main tg library
    add_library(tg STATIC
        ${TG_ROOT}/tg.c
        $<TARGET_OBJECTS:tg_deps>
    )
    target_include_directories(tg PUBLIC ${TG_ROOT})
    target_link_libraries(tg PUBLIC m)

    # On Windows, link bcrypt
    if(WIN32)
        target_link_libraries(tg PUBLIC bcrypt)
    endif()

    # Option to disable amalgamation
    option(TG_NOAMALGA "Disable TG amalgamation mode" OFF)
    if(TG_NOAMALGA)
        target_compile_definitions(tg PUBLIC TG_NOAMALGA)
    endif()
else()
    # If included from parent CMakeLists.txt, the tg library should already be defined
    if(NOT TARGET tg)
        message(FATAL_ERROR "tg library target not found")
    endif()
endif()

# Add this directory to module path for FindGEOS
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})

# Optional GEOS support for benchmarking
option(GEOS_BENCH "Enable GEOS benchmarking" OFF)
if(GEOS_BENCH)
    find_package(GEOS)
    if(GEOS_FOUND)
        message(STATUS "GEOS benchmarking enabled")
    else()
        message(WARNING "GEOS_BENCH is ON but GEOS was not found")
    endif()
endif()

# Enable testing
enable_testing()

# Generate relations.h using genrelations.sh
# This script reads files from relations/ directory and generates the header
file(GLOB RELATION_FILES "${CMAKE_CURRENT_SOURCE_DIR}/relations/*.jsonc")
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/relations.h
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/genrelations.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS ${RELATION_FILES} ${CMAKE_CURRENT_SOURCE_DIR}/genrelations.sh
    COMMENT "Generating relations.h from relations/*.jsonc files"
)

# Create a custom target for the generated header
add_custom_target(generate_relations_header
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/relations.h
)

# Find all test source files
file(GLOB TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_*.c")

# Create an executable for each test
foreach(test_source ${TEST_SOURCES})
    # Get the file name without path and extension
    get_filename_component(test_name ${test_source} NAME_WE)

    # Create an executable for this test
    add_executable(${test_name} ${test_source})

    # Ensure relations.h is generated before building this test
    add_dependencies(${test_name} generate_relations_header)

    # Link with tg library
    target_link_libraries(${test_name} PRIVATE tg)

    # Include tests directory for tests.h
    target_include_directories(${test_name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

    # Set compile options similar to run.sh
    if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR NOT CMAKE_BUILD_TYPE)
        target_compile_options(${test_name} PRIVATE
            -Wall -Wextra -fstrict-aliasing
        )
    endif()

    # Register this test with CTest
    add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()

# Benchmark executable (only if requested)
if(GEOS_BENCH AND GEOS_FOUND)
    add_executable(bench
        bench.c
        bmalloc.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/../tg.c
    )

    target_link_libraries(bench PRIVATE
        tg
        GEOS::geos_c
        m
        pthread
    )

    target_compile_definitions(bench PRIVATE GEOS_BENCH)
    target_include_directories(bench PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

    # Use Release mode optimizations for benchmarking
    target_compile_options(bench PRIVATE -O3)
endif()

# Print summary
message(STATUS "========================================")
message(STATUS "TG Tests Configuration Summary")
message(STATUS "========================================")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Tests found: ${TEST_SOURCES}")
message(STATUS "GEOS benchmarking: ${GEOS_BENCH}")
if(GEOS_BENCH AND GEOS_FOUND)
    message(STATUS "GEOS version: ${GEOS_VERSION}")
endif()
message(STATUS "========================================")
