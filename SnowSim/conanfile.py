from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMakeDeps, cmake_layout


class SnowSimConan(ConanFile):
    name = "snowsim"
    settings = "os", "compiler", "build_type", "arch"
    options = {"screencast": [True, False]}
    default_options = {"screencast": False}

    def requirements(self):
        self.requires("glfw/3.4")
        if self.options.screencast:
            # Header-only PNG writer. Avoids FreeImage's heavy dependency tree
            # (OpenEXR/libraw/...) which we don't need for a plain RGB dump.
            self.requires("stb/cci.20240531")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        CMakeDeps(self).generate()
        tc = CMakeToolchain(self)
        # Forward the Conan option to the CMake project.
        tc.variables["SNOWSIM_SCREENCAST"] = str(self.options.screencast) == "True"
        tc.generate()
