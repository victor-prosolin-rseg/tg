cmake_minimum_required(VERSION 3.10)

# If this is the top-level CMakeLists.txt, set up the project
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(tg_examples C)

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
else()
    # If included from parent CMakeLists.txt, the tg library should already be defined
    if(NOT TARGET tg)
        message(FATAL_ERROR "tg library target not found")
    endif()
endif()

# Find all example source files
file(GLOB EXAMPLE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.c")

# Create an executable for each example
foreach(example_source ${EXAMPLE_SOURCES})
    # Get the file name without path and extension
    get_filename_component(example_name ${example_source} NAME_WE)

    # Create an executable for this example
    add_executable(${example_name} ${example_source})

    # Link with tg library
    target_link_libraries(${example_name} PRIVATE tg)

    message(STATUS "Added example: ${example_name}")
endforeach()
