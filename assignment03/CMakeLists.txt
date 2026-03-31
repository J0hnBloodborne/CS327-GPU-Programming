cmake_minimum_required(VERSION 3.18)

# Must be set before project() so CMake's CUDA compiler test also uses it.
set(CMAKE_CUDA_FLAGS_INIT "-allow-unsupported-compiler -Xptxas -v")

project(assignment03 LANGUAGES CXX CUDA)

if (MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_RUNTIME_LIBRARY Shared)
set(CMAKE_CUDA_ARCHITECTURES 86)

set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -allow-unsupported-compiler -Xptxas -v")

add_executable(cuda-denoise
    cuda-denoise.cu
)

add_executable(cuda-edge-detect
    cuda-edge-detect.cu
)

# hpc.h uses OpenMP timing when _OPENMP is defined.
# Pass OpenMP flags to the host compiler through nvcc.
if (MSVC)
    target_compile_options(cuda-denoise PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/openmp>)
    target_compile_options(cuda-edge-detect PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/openmp>)
else()
    target_compile_options(cuda-denoise PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-fopenmp>)
    target_compile_options(cuda-edge-detect PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-fopenmp>)
endif()
