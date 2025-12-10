# Find GEOS
# ~~~~~~~~~
# Copyright (c) 2008, Mateusz Loskot <mateusz@loskot.net>
# (based on FindGDAL.cmake by Magnus Homann)
# Redistribution and use is allowed according to the terms of the BSD license.
#
# CMake module to search for GEOS library
#
# If it's found it sets GEOS_FOUND to TRUE
# and the following target is added:
#   GEOS::geos_c

find_package(GEOS CONFIG QUIET)

if(NOT GEOS_FOUND)
  IF(WIN32)
    IF (MINGW)
      FIND_PATH(GEOS_INCLUDE_DIR geos_c.h /usr/local/include /usr/include c:/msys/local/include)
      FIND_LIBRARY(GEOS_LIBRARY NAMES geos_c PATHS /usr/local/lib /usr/lib c:/msys/local/lib)
    ENDIF (MINGW)

    IF (MSVC)
      FIND_PATH(GEOS_INCLUDE_DIR geos_c.h $ENV{INCLUDE})
      FIND_LIBRARY(GEOS_LIBRARY NAMES geos_c_i geos_c PATHS $ENV{LIB})
    ENDIF (MSVC)

  ELSE(WIN32)
    IF(UNIX)
      # Try to use geos-config first
      SET(GEOS_CONFIG_PREFER_PATH "$ENV{GEOS_HOME}/bin" CACHE STRING "preferred path to GEOS (geos-config)")
      FIND_PROGRAM(GEOS_CONFIG geos-config
        ${GEOS_CONFIG_PREFER_PATH}
        /usr/local/bin/
        /usr/bin/
      )

      IF (GEOS_CONFIG)
        execute_process(COMMAND ${GEOS_CONFIG} --version
          OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE GEOS_VERSION)
        STRING(REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\1" GEOS_VERSION_MAJOR "${GEOS_VERSION}")
        STRING(REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\2" GEOS_VERSION_MINOR "${GEOS_VERSION}")

        # set INCLUDE_DIR to prefix+include
        execute_process(COMMAND ${GEOS_CONFIG} --prefix
          OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE GEOS_PREFIX)

        FIND_PATH(GEOS_INCLUDE_DIR
          geos_c.h
          ${GEOS_PREFIX}/include
          /usr/local/include
          /usr/include
        )

        ## extract link dirs for rpath
        execute_process(COMMAND ${GEOS_CONFIG} --libs
          OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE GEOS_CONFIG_LIBS)

        ## split off the link dirs (for rpath)
        STRING(REGEX MATCHALL "[-][L]([^ ;])+"
          GEOS_LINK_DIRECTORIES_WITH_PREFIX
          "${GEOS_CONFIG_LIBS}")

        ## remove prefix -L
        IF (GEOS_LINK_DIRECTORIES_WITH_PREFIX)
          STRING(REGEX REPLACE "[-][L]" "" GEOS_LINK_DIRECTORIES ${GEOS_LINK_DIRECTORIES_WITH_PREFIX})
        ENDIF (GEOS_LINK_DIRECTORIES_WITH_PREFIX)

        SET(GEOS_LIB_NAME_WITH_PREFIX -lgeos_c CACHE STRING INTERNAL)

        IF (GEOS_LIB_NAME_WITH_PREFIX)
          STRING(REGEX REPLACE "[-][l]" "" GEOS_LIB_NAME ${GEOS_LIB_NAME_WITH_PREFIX})
        ENDIF (GEOS_LIB_NAME_WITH_PREFIX)

        FIND_LIBRARY(GEOS_LIBRARY NAMES ${GEOS_LIB_NAME} geos_c PATHS ${GEOS_LINK_DIRECTORIES})

      ELSE(GEOS_CONFIG)
        # Fallback to manual search
        FIND_PATH(GEOS_INCLUDE_DIR geos_c.h
          /usr/local/include
          /usr/include
        )
        FIND_LIBRARY(GEOS_LIBRARY NAMES geos_c
          PATHS /usr/local/lib /usr/lib
        )
      ENDIF(GEOS_CONFIG)
    ENDIF(UNIX)
  ENDIF(WIN32)

  # Try to get version from header if not already set
  IF(GEOS_INCLUDE_DIR AND NOT GEOS_VERSION)
    FILE(READ ${GEOS_INCLUDE_DIR}/geos_c.h VERSIONFILE)
    STRING(REGEX MATCH "#define GEOS_VERSION \"[0-9]+\\.[0-9]+\\.[0-9]+" GEOS_VERSION ${VERSIONFILE})
    STRING(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" GEOS_VERSION ${GEOS_VERSION})
  ENDIF(GEOS_INCLUDE_DIR AND NOT GEOS_VERSION)

  IF (GEOS_INCLUDE_DIR AND GEOS_LIBRARY)
    SET(GEOS_FOUND TRUE)
  ENDIF (GEOS_INCLUDE_DIR AND GEOS_LIBRARY)

  IF (GEOS_FOUND)
    add_library(GEOS::geos_c UNKNOWN IMPORTED)
    set_target_properties(GEOS::geos_c PROPERTIES
      IMPORTED_LOCATION ${GEOS_LIBRARY}
      INTERFACE_INCLUDE_DIRECTORIES ${GEOS_INCLUDE_DIR}
    )

    IF (NOT GEOS_FIND_QUIETLY)
      MESSAGE(STATUS "Found GEOS: ${GEOS_LIBRARY} (${GEOS_VERSION})")
    ENDIF (NOT GEOS_FIND_QUIETLY)

  ELSE (GEOS_FOUND)
    IF (GEOS_FIND_REQUIRED)
      MESSAGE(FATAL_ERROR "Could not find GEOS")
    ELSE()
      IF (NOT GEOS_FIND_QUIETLY)
        MESSAGE(STATUS "GEOS not found (optional)")
      ENDIF()
    ENDIF()
  ENDIF (GEOS_FOUND)
endif()
