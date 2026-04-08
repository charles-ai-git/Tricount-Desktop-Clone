cmake_minimum_required(VERSION 3.16)
project(TricountServer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core HttpServer Sql Network)

qt_add_executable(TricountServer
    main.cpp
)

# Liens avec les modules Qt nécessaires au backend
target_link_libraries(TricountServer
    PRIVATE
        Qt6::Core
        Qt6::HttpServer
        Qt6::Sql
        Qt6::Network
)
