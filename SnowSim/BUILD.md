# Building SnowSim on Windows (CMake + Conan)

## Prerequisites

- **Visual Studio 2019 or 2022** with the "Desktop development with C++" workload
  (provides the MSVC compiler and the Windows SDK, which supplies `<GL/gl.h>` and
  `opengl32.lib`).
- **CMake ≥ 3.23** (`cmake --version`). Needed to consume the `CMakePresets.json`
  that Conan generates (`--preset` requires 3.19; the preset schema version Conan
  emits requires 3.23). Older CMake: use the "Without presets" commands below.
- **Conan 2.x** (`conan --version`). The `conanfile.py` uses the Conan 2 API.
  Upgrade an older install with:

  ```powershell
  pip install --upgrade "conan>=2.0"
  ```

- First-time Conan setup (creates the default profile by auto-detecting MSVC):

  ```powershell
  conan profile detect --force
  ```

## Dependencies

Pulled from ConanCenter automatically:

| Library   | Purpose                              | When            |
|-----------|--------------------------------------|-----------------|
| `glfw`    | window + OpenGL context + input      | always          |
| `stb`     | PNG frame export (screencast), header-only | only with `-o screencast=True` |

OpenGL itself comes from the system (`opengl32`), resolved by CMake's
`find_package(OpenGL)`.

## Configure & build

Run from the `SnowSim` folder:

```powershell
# 1. Resolve/build dependencies and generate the CMake toolchain + presets
conan install . --output-folder=build --build=missing -s build_type=Release

# 2. Configure using the preset Conan generated
cmake --preset conan-default

# 3. Build
cmake --build --preset conan-release
```

The executable is produced at `build\build\Release\snowsim.exe`.

### Debug build

```powershell
conan install . --output-folder=build --build=missing -s build_type=Debug
cmake --preset conan-default
cmake --build --preset conan-debug
```

## Enabling the screencast (PNG export) feature

`SCREENCAST` is off by default (unchanged from the original `SimConstants.h`).
To turn it on, request the Conan option — it adds the header-only `stb`
dependency and defines `SCREENCAST=true` for the build:

```powershell
conan install . --output-folder=build --build=missing -s build_type=Release -o screencast=True
cmake --preset conan-default
cmake --build --preset conan-release
```

Frames are written to the directory in `SCREENCAST_DIR` (`../screencast/`).
