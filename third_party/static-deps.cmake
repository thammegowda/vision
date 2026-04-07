# third_party/static-deps.cmake
# Build zlib, libpng, libjpeg-turbo from submodules as PIC static libraries.
# Called before find_package(PNG/JPEG) to override their cache variables.
#
# After this file runs:
#   - ZLIB::ZLIB, PNG_LIBRARY, JPEG_LIBRARIES point to our static builds
#   - find_package(PNG/JPEG) in the parent will pick them up

set(_TP "${CMAKE_CURRENT_SOURCE_DIR}/third_party")
if(NOT EXISTS "${_TP}/zlib/CMakeLists.txt")
    return()  # third_party not populated; fall back to system libs
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ── zlib ──────────────────────────────────────────────────────────────────
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ZLIB_BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
set(_SAVED_BSL "${BUILD_SHARED_LIBS}")
set(BUILD_SHARED_LIBS OFF)
add_subdirectory(${_TP}/zlib ${CMAKE_CURRENT_BINARY_DIR}/_deps/zlib EXCLUDE_FROM_ALL)
set(BUILD_SHARED_LIBS "${_SAVED_BSL}")
set_target_properties(zlibstatic PROPERTIES POSITION_INDEPENDENT_CODE ON)
if(NOT TARGET ZLIB::ZLIB)
    add_library(ZLIB::ZLIB ALIAS zlibstatic)
endif()
set(ZLIB_FOUND TRUE CACHE BOOL "" FORCE)
set(ZLIB_LIBRARIES zlibstatic CACHE STRING "" FORCE)
set(ZLIB_INCLUDE_DIRS "${_TP}/zlib;${CMAKE_CURRENT_BINARY_DIR}/_deps/zlib" CACHE STRING "" FORCE)
set(ZLIB_INCLUDE_DIR "${_TP}/zlib;${CMAKE_CURRENT_BINARY_DIR}/_deps/zlib" CACHE STRING "" FORCE)
set(ZLIB_LIBRARY zlibstatic CACHE STRING "" FORCE)

# ── libpng ────────────────────────────────────────────────────────────────
set(PNG_SHARED OFF CACHE BOOL "" FORCE)
set(PNG_STATIC ON CACHE BOOL "" FORCE)
set(PNG_TESTS OFF CACHE BOOL "" FORCE)
set(PNG_TOOLS OFF CACHE BOOL "" FORCE)
add_subdirectory(${_TP}/libpng ${CMAKE_CURRENT_BINARY_DIR}/_deps/libpng EXCLUDE_FROM_ALL)
set_target_properties(png_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(png_static PUBLIC
    "${_TP}/libpng" "${CMAKE_CURRENT_BINARY_DIR}/_deps/libpng")
set(PNG_FOUND TRUE CACHE BOOL "" FORCE)
set(PNG_LIBRARY png_static CACHE STRING "" FORCE)
set(PNG_LIBRARIES png_static CACHE STRING "" FORCE)
set(PNG_INCLUDE_DIRS "${_TP}/libpng;${CMAKE_CURRENT_BINARY_DIR}/_deps/libpng" CACHE STRING "" FORCE)

# ── libjpeg-turbo (ExternalProject — it rejects add_subdirectory) ─────────
include(ExternalProject)
set(_JPEG_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/_deps/libjpeg-turbo-install)
ExternalProject_Add(libjpeg_turbo_ep
    SOURCE_DIR        ${_TP}/libjpeg-turbo
    BINARY_DIR        ${CMAKE_CURRENT_BINARY_DIR}/_deps/libjpeg-turbo-build
    INSTALL_DIR       ${_JPEG_PREFIX}
    CMAKE_ARGS
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DCMAKE_BUILD_TYPE=Release
        -DENABLE_SHARED=OFF -DENABLE_STATIC=ON
        -DWITH_TURBOJPEG=OFF -DWITH_JAVA=OFF
        -DCMAKE_INSTALL_PREFIX=${_JPEG_PREFIX}
    BUILD_BYPRODUCTS ${_JPEG_PREFIX}/lib/libjpeg.a
)
add_library(jpeg-static STATIC IMPORTED GLOBAL)
set_target_properties(jpeg-static PROPERTIES IMPORTED_LOCATION ${_JPEG_PREFIX}/lib/libjpeg.a)
add_dependencies(jpeg-static libjpeg_turbo_ep)
file(MAKE_DIRECTORY ${_JPEG_PREFIX}/include)
target_include_directories(jpeg-static INTERFACE ${_JPEG_PREFIX}/include)
set(JPEG_FOUND TRUE CACHE BOOL "" FORCE)
set(JPEG_LIBRARY jpeg-static CACHE STRING "" FORCE)
set(JPEG_LIBRARIES jpeg-static CACHE STRING "" FORCE)
set(JPEG_INCLUDE_DIRS "${_JPEG_PREFIX}/include" CACHE STRING "" FORCE)
set(JPEG_INCLUDE_DIR "${_JPEG_PREFIX}/include" CACHE PATH "" FORCE)

message(STATUS "TorchVision: using static PIC zlib + libpng + libjpeg-turbo from third_party/")
