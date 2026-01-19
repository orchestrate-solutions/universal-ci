cmake_minimum_required(VERSION 3.10)
project(cpp_example)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Main executable
add_executable(example src/main.cpp)

# Tests
enable_testing()
add_executable(test_main test/test_main.cpp)
add_test(NAME MainTest COMMAND test_main)
