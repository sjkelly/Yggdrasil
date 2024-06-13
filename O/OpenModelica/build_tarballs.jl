# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OpenModelica"
version = v"1.22.3"

# Collection of sources required to build CImGuiPack
sources = [
    GitSource("https://github.com/OpenModelica/OpenModelica.git",
              "d9eb834c9d90458acc41184dc9759920e98cf56e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OpenModelica
apk add openjdk17-jdk build-base libc6-compat libpthread-stubs linux-headers musl-dev
git config submodule.OMOptim.url https://github.com/OpenModelica/OMOptim.git
git config submodule.OMSimulator.url https://github.com/OpenModelica/OMSimulator.git
git config submodule.OMCompiler/3rdParty.url https://github.com/OpenModelica/OMCompiler-3rdParty.git
git config submodule.OMSens.url https://github.com/OpenModelica/OMSens.git
git config submodule.OMSens_Qt.url https://github.com/OpenModelica/OMSens_Qt.git
git submodule update --init --recursive
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DOM_OMC_USE_CORBA=OFF \
         -DOM_ENABLE_GUI_CLIENTS=OFF \
         -DOM_OMC_ENABLE_IPOPT=OFF \
         -DOM_OMC_USE_LAPACK=OFF \
         -DOM_USE_CCACHE=OFF \
         -DCMAKE_BUILD_TYPE=Release \
         -DOM_OMC_ENABLE_FORTRAN=OFF

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    #Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("boost_jll"),
    Dependency("Expat_jll"),
    Dependency("HDF5_jll"),
    Dependency("LibCURL_jll"),
    Dependency("Ncurses_jll"),
    Dependency("Readline_jll"),
    Dependency("Libuuid_jll"),
    Dependency("OpenCL_jll"),
    Dependency("OpenCL_Headers_jll"),
    Dependency("LAPACK_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
