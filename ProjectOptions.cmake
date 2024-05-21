include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(tdgame_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(tdgame_setup_options)
  option(tdgame_ENABLE_HARDENING "Enable hardening" ON)
  option(tdgame_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    tdgame_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    tdgame_ENABLE_HARDENING
    OFF)

  tdgame_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR tdgame_PACKAGING_MAINTAINER_MODE)
    option(tdgame_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(tdgame_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(tdgame_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(tdgame_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(tdgame_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(tdgame_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(tdgame_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(tdgame_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(tdgame_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(tdgame_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(tdgame_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(tdgame_ENABLE_PCH "Enable precompiled headers" OFF)
    option(tdgame_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(tdgame_ENABLE_IPO "Enable IPO/LTO" ON)
    option(tdgame_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(tdgame_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(tdgame_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(tdgame_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(tdgame_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(tdgame_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(tdgame_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(tdgame_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(tdgame_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(tdgame_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(tdgame_ENABLE_PCH "Enable precompiled headers" OFF)
    option(tdgame_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      tdgame_ENABLE_IPO
      tdgame_WARNINGS_AS_ERRORS
      tdgame_ENABLE_USER_LINKER
      tdgame_ENABLE_SANITIZER_ADDRESS
      tdgame_ENABLE_SANITIZER_LEAK
      tdgame_ENABLE_SANITIZER_UNDEFINED
      tdgame_ENABLE_SANITIZER_THREAD
      tdgame_ENABLE_SANITIZER_MEMORY
      tdgame_ENABLE_UNITY_BUILD
      tdgame_ENABLE_CLANG_TIDY
      tdgame_ENABLE_CPPCHECK
      tdgame_ENABLE_COVERAGE
      tdgame_ENABLE_PCH
      tdgame_ENABLE_CACHE)
  endif()

  tdgame_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (tdgame_ENABLE_SANITIZER_ADDRESS OR tdgame_ENABLE_SANITIZER_THREAD OR tdgame_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(tdgame_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(tdgame_global_options)
  if(tdgame_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    tdgame_enable_ipo()
  endif()

  tdgame_supports_sanitizers()

  if(tdgame_ENABLE_HARDENING AND tdgame_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR tdgame_ENABLE_SANITIZER_UNDEFINED
       OR tdgame_ENABLE_SANITIZER_ADDRESS
       OR tdgame_ENABLE_SANITIZER_THREAD
       OR tdgame_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${tdgame_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${tdgame_ENABLE_SANITIZER_UNDEFINED}")
    tdgame_enable_hardening(tdgame_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(tdgame_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(tdgame_warnings INTERFACE)
  add_library(tdgame_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  tdgame_set_project_warnings(
    tdgame_warnings
    ${tdgame_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(tdgame_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    tdgame_configure_linker(tdgame_options)
  endif()

  include(cmake/Sanitizers.cmake)
  tdgame_enable_sanitizers(
    tdgame_options
    ${tdgame_ENABLE_SANITIZER_ADDRESS}
    ${tdgame_ENABLE_SANITIZER_LEAK}
    ${tdgame_ENABLE_SANITIZER_UNDEFINED}
    ${tdgame_ENABLE_SANITIZER_THREAD}
    ${tdgame_ENABLE_SANITIZER_MEMORY})

  set_target_properties(tdgame_options PROPERTIES UNITY_BUILD ${tdgame_ENABLE_UNITY_BUILD})

  if(tdgame_ENABLE_PCH)
    target_precompile_headers(
      tdgame_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(tdgame_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    tdgame_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(tdgame_ENABLE_CLANG_TIDY)
    tdgame_enable_clang_tidy(tdgame_options ${tdgame_WARNINGS_AS_ERRORS})
  endif()

  if(tdgame_ENABLE_CPPCHECK)
    tdgame_enable_cppcheck(${tdgame_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(tdgame_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    tdgame_enable_coverage(tdgame_options)
  endif()

  if(tdgame_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(tdgame_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(tdgame_ENABLE_HARDENING AND NOT tdgame_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR tdgame_ENABLE_SANITIZER_UNDEFINED
       OR tdgame_ENABLE_SANITIZER_ADDRESS
       OR tdgame_ENABLE_SANITIZER_THREAD
       OR tdgame_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    tdgame_enable_hardening(tdgame_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
