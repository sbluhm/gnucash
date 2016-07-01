

FUNCTION(GET_GUILE_ENV)
  SET(_GNC_MODULE_PATH ${CMAKE_BINARY_DIR}/lib:${CMAKE_BINARY_DIR}/lib/gnucash)
  IF (WIN32)
    SET(_GNC_MODULE_PATH ${CMAKE_BINARY_DIR}/bin)
  ENDIF()
  SET(env "")
  LIST(APPEND env "GNC_UNINSTALLED=yes")
  LIST(APPEND env "GNC_BUILDDIR=${CMAKE_BINARY_DIR}")
  LIST(APPEND env "GUILE_WARN_DEPRECATED=no")
  LIST(APPEND env "GNC_MODULE_PATH=${_GNC_MODULE_PATH}")
  IF (APPLE)
    LIST(APPEND env "DYLD_LIBRARY_PATH=${_GNC_MODULE_PATH}")
  ENDIF()
  IF (UNIX)
    LIST(APPEND env LD_LIBRARY_PATH=${_GNC_MODULE_PATH})
  ENDIF()
  IF (NOT WIN32)
    LIST(APPEND env "GUILE_LOAD_COMPILED_PATH=${CMAKE_BINARY_DIR}/lib/gnucash/scm/ccache/2.0")
  ENDIF()
  SET(guile_load_paths "")
  LIST(APPEND guile_load_paths ${CMAKE_CURRENT_SOURCE_DIR}/mod-foo)
  LIST(APPEND guile_load_paths ${CMAKE_CURRENT_SOURCE_DIR}/mod-bar)
  LIST(APPEND guile_load_paths ${CMAKE_CURRENT_SOURCE_DIR}/mod-baz)
  IF (WIN32)
    LIST(APPEND guile_load_paths ${CMAKE_BINARY_DIR}/share/gnucash/scm)
  ENDIF()
  SET(guile_load_path "${guile_load_paths}")
  IF (WIN32)
    STRING(REPLACE ";" "\\\\;" GUILE_LOAD_PATH "${guile_load_path}")
  ELSE()
    STRING(REPLACE ";" ":" GUILE_LOAD_PATH "${guile_load_path}")
  ENDIF()
  LIST(APPEND env "GUILE_LOAD_PATH=${GUILE_LOAD_PATH}")
  SET(GUILE_ENV ${env} PARENT_SCOPE)
ENDFUNCTION()


FUNCTION(GNC_ADD_TEST _TARGET _SOURCE_FILES TEST_INCLUDE_VAR_NAME TEST_LIBS_VAR_NAME)
  SET(HAVE_ENV_VARS FALSE)
  IF (${ARGC} GREATER 4)
    # Extra arguments are treated as environment variables
    SET(HAVE_ENV_VARS TRUE)
  ENDIF()
  SET(TEST_INCLUDE_DIRS ${${TEST_INCLUDE_VAR_NAME}})
  SET(TEST_LIBS ${${TEST_LIBS_VAR_NAME}})
  SET_SOURCE_FILES_PROPERTIES (${_SOURCE_FILES} PROPERTIES OBJECT_DEPENDS ${CONFIG_H})
  ADD_EXECUTABLE(${_TARGET} EXCLUDE_FROM_ALL ${_SOURCE_FILES})
  TARGET_LINK_LIBRARIES(${_TARGET} ${TEST_LIBS})
  TARGET_INCLUDE_DIRECTORIES(${_TARGET} PRIVATE ${TEST_INCLUDE_DIRS})
  IF (${HAVE_ENV_VARS})
    SET(CMAKE_COMMAND_TMP "")
    IF (${CMAKE_VERSION} VERSION_GREATER 3.1)
      SET(CMAKE_COMMAND_TMP ${CMAKE_COMMAND} -E env "${ARGN}")
    ENDIF()
    ADD_TEST(${_TARGET} ${CMAKE_COMMAND_TMP}
      ${CMAKE_BINARY_DIR}/bin/${_TARGET}
    )
    SET_TESTS_PROPERTIES(${_TARGET} PROPERTIES ENVIRONMENT "${ARGN}")
  ELSE()
    ADD_TEST(NAME ${_TARGET} COMMAND ${_TARGET})
  ENDIF()
  ADD_DEPENDENCIES(check ${_TARGET})
ENDFUNCTION()

FUNCTION(GNC_ADD_TEST_WITH_GUILE _TARGET _SOURCE_FILES TEST_INCLUDE_VAR_NAME TEST_LIBS_VAR_NAME)
  GET_GUILE_ENV()
  GNC_ADD_TEST(${_TARGET} "${_SOURCE_FILES}" "${TEST_INCLUDE_VAR_NAME}" "${TEST_LIBS_VAR_NAME}"
    "${GUILE_ENV};${ARGN}"
  )
ENDFUNCTION()


FUNCTION(GNC_ADD_SCHEME_TEST _TARGET _SOURCE_FILE)
  SET(CMAKE_COMMAND_TMP "")
  IF (${CMAKE_VERSION} VERSION_GREATER 3.1)
    SET(CMAKE_COMMAND_TMP ${CMAKE_COMMAND} -E env)
  ENDIF()
  ADD_TEST(${_TARGET} ${CMAKE_COMMAND_TMP}
    ${GUILE_EXECUTABLE} --debug -l ${CMAKE_CURRENT_SOURCE_DIR}/${_SOURCE_FILE} -c "(exit (run-test))"
  )
  GET_GUILE_ENV()
  SET_TESTS_PROPERTIES(${_TARGET} PROPERTIES ENVIRONMENT "${GUILE_ENV};${ARGN}")
ENDFUNCTION()

FUNCTION(GNC_GTEST_CONFIGURE)
  MESSAGE(STATUS "Maybe setting up GTEST with " ${GTEST_DISABLE})
  IF (NOT GTEST_DISABLE)
    FIND_PATH(GTEST_INCLUDE_DIR gtest/gtest.h
      PATHS /usr/include ${GMOCK_ROOT}/gtest/include ${GTEST_ROOT}/include)
    FIND_PATH(GTEST_SRC_DIR src/gtest-all.cc
      PATHS /usr/src/gtest ${GMOCK_ROOT}/gtest ${GTEST_ROOT})
    FIND_PATH(GMOCK_INCLUDE_DIR gmock/gmock.h
      PATHS /usr/include ${GMOCK_ROOT}/include)
    FIND_PATH(GMOCK_SRC_DIR src/gmock-all.cc
      PATHS /usr/src/gmock ${GMOCK_ROOT})
    FIND_LIBRARY(GTEST_SHARED_LIB gtest)
    FIND_LIBRARY(GTEST_MAIN_LIB gtest_main)
    IF ((GTEST_SHARED_LIB OR GTEST_SRC_DIR) AND GTEST_INCLUDE_DIR)
      SET(THREADS_PREFER_PTHREAD_FLAG ON)
      FIND_PACKAGE(Threads REQUIRED)
      SET(GTEST_FOUND YES CACHE INTERNAL "Found GTest")
      IF(GTEST_SHARED_LIB)
        SET(GTEST_LIB "${GTEST_SHARED_LIB};${GTEST_MAIN_LIB}" PARENT_SCOPE)
        UNSET(GTEST_SRC_DIR CACHE)
      ELSE()
        SET(GTEST_SRC "${GTEST_SRC_DIR}/src/gtest_main.cc" PARENT_SCOPE)
        SET(GTEST_LIB "${CMAKE_BINARY_DIR}/src/test-core/libgtest.a" PARENT_SCOPE)
      ENDIF()
      if (GMOCK_INCLUDE_DIR AND GMOCK_SRC_DIR)
        SET(GMOCK_FOUND YES PARENT_SCOPE)
        SET(GMOCK_SRC "${GMOCK_SRC_DIR}/src/gmock_main.cc" PARENT_SCOPE)
        SET(GMOCK_LIB "${CMAKE_BINARY_DIR}/src/test-core/libgmock.a" PARENT_SCOPE)
      ENDIF()
    ENDIF()
  ENDIF()
ENDFUNCTION()
