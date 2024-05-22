#include <CLI/CLI.hpp>
#include <entt/entity/fwd.hpp>
#include <spdlog/spdlog.h>
#include <cstdlib>
#include <exception>
#include <fmt/core.h>
#include <entt/entity/registry.hpp>

// This file will be generated automatically when cur_you run the CMake
// configuration step. It creates a namespace called `tdgame`. You can modify
// the source template at `configured_files/config.hpp.in`.
#include <internal_use_only/config.hpp>


struct position {
  double x;
  double y;
};

// NOLINTNEXTLINE(bugprone-exception-escape)
int main(int argc, const char **argv)
{
  try {
    CLI::App app{ fmt::format("{} version {}", tdgame::cmake::project_name, tdgame::cmake::project_version) };

    bool show_version = false;
    app.add_flag("--version", show_version, "Show version information");

    CLI11_PARSE(app, argc, argv);

    if (show_version) {
      fmt::print("{}\n", tdgame::cmake::project_version);
      return EXIT_SUCCESS;
    }

    fmt::print("Hello tower defense game backend!\n");

  } catch (const std::exception &e) {
    spdlog::error("Unhandled exception in main: {}", e.what());
  }

  entt::basic_registry registry;

  const int numberOfEntities = 10;
  const double xPosition = 20.53;
  const double yPosition = 59.40;
  for(int i = 0; i < numberOfEntities; i++) {
    const auto entity = registry.create();

    position pos{};
    pos.x = xPosition;
    pos.y = yPosition;

    registry.emplace<position>(entity, pos);
  }
}
