add_executable(tdbackend main.cpp)

target_link_libraries(
  tdbackend
  PRIVATE tdgame::tdgame_options
          tdgame::tdgame_warnings)

target_link_system_libraries(
  tdbackend
  PRIVATE
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          EnTT::EnTT)

target_include_directories(tdbackend PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")
