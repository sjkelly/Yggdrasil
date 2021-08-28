# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LSOracle"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("/home/steve/Software/LSOracle", "b4ce4572df4dd7231e45a655bd120c2bc48951c9")
]

dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    Dependency("Readline_jll"; compat="~8.1.1")
]

# Bash recipe for building across all platforms
script = raw"""
# patch CMAKE_TARGET_TOOLCHAIN with readline exit codes
printf 'set(READLINE_WORKS_EXITCODE 0)\nset(READLINE_WORKS_EXITCODE__TRYRUN_OUTPUT 0)\n' >> $CMAKE_TARGET_TOOLCHAIN 
cd LSOracle
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLOCAL_PYBIND=OFF \
    -DLOCAL_BOOST=OFF \
    -DLOCAL_GTEST=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# cross compiling is badly broken
platforms = HostPlatform()#filter!(p -> Sys.islinux(p) && Sys.isapple(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)
# No CXX03 with boost
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("lsoracle", :lsoracle)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7", lock_microarchitecture=false)