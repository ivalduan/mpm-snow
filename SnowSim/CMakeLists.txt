cmake_minimum_required(VERSION 3.15)
project(snowsim CXX)

# Optional PNG frame export (needs stb_image_write). Off by default, matching
# the historical SCREENCAST value in SimConstants.h.
option(SNOWSIM_SCREENCAST "Export simulation frames as PNG via stb_image_write" OFF)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Provided by Conan (see conanfile.py). glfw3 -> "glfw" target.
find_package(glfw3 REQUIRED)
find_package(OpenGL REQUIRED)

set(SNOWSIM_SOURCES
    main.cpp
    Grid.cpp
    Matrix2f.cpp
    Particle.cpp
    PointCloud.cpp
    Shape.cpp
    Vector2f.cpp
)

# stb is header-only; one translation unit must define the implementation.
if(SNOWSIM_SCREENCAST)
    list(APPEND SNOWSIM_SOURCES stb_image_write_impl.cpp)
endif()

add_executable(snowsim ${SNOWSIM_SOURCES})

target_include_directories(snowsim PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(snowsim PRIVATE glfw OpenGL::GL)

# SCREENCAST is consumed with `#if SCREENCAST`; always give it a concrete value
# so the preprocessor never has to fall back to the header default.
if(SNOWSIM_SCREENCAST)
    find_package(stb REQUIRED)
    target_link_libraries(snowsim PRIVATE stb::stb)
    target_compile_definitions(snowsim PRIVATE SCREENCAST=true)
else()
    target_compile_definitions(snowsim PRIVATE SCREENCAST=false)
endif()

if(MSVC)
    target_compile_definitions(snowsim PRIVATE _CRT_SECURE_NO_WARNINGS NOMINMAX)
endif()
