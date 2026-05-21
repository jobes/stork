cmake_minimum_required(VERSION 3.10)
project(stork_canard LANGUAGES C)

add_library(stork_canard SHARED
    stork_canard.c
    libcanard/canard.c
)

target_include_directories(stork_canard PRIVATE .)
