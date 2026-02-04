cmake_minimum_required(VERSION 3.18)
project(task04 LANGUAGES CXX CUDA)

if (MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()
set(CMAKE_CUDA_RUNTIME_LIBRARY "Shared")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_ARCHITECTURES 86)

if (MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4 /WX")
else()
    add_compile_options(-Wall -Wextra -Werror)
endif()

add_executable(task4
    src/main.cpp
    src/mat_io.cpp
    src/mat_ops.cpp
    src/mat_ops.cu
    src/timer.cpp
)