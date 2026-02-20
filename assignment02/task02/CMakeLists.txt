cmake_minimum_required(VERSION 3.10)
project(task2)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(task2 ./src/main.cpp ./src/mat_io.cpp ./src/mat_ops.cpp)

if(MSVC)
    target_compile_options(task2 PRIVATE /W4 /WX)
else()
    target_compile_options(task2 PRIVATE -Wall -Wextra -Werror -pedantic)
endif()