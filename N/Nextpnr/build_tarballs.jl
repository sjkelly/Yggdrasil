# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Nextpnr"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("/home/steve/Software/nextpnr", "53918a9766a1bff7e1fecac37822e31051888b35")
]

dependencies = [
    Dependency("Icestorm_jll"; compat="0.1.0"),
    Dependency("Prjtrellis_jll"; compat="0.1.0"),
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    #Dependency("Python_jll"; compat="3.8.1"), # used for prjtrellis
    HostBuildDependency("Python_jll"),
    Dependency("Eigen_jll"; compat="3.3.9")
]

# Bash recipe for building across all platforms
script = raw"""
cd nextpnr
git submodule --init && git submodule --update
export PYTHONPATH=${prefix}/lib/python3.8
cmake -DARCH="ice40;ecp5" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DICESTORM_INSTALL_PREFIX=${prefix} \
    -DPYTHON_EXECUTABLE=${prefix}/bin/python3 \
    -DTRELLIS_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release .
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)
# For some reason, building for CXX03 string ABI doesn't actually work, skip it
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = Product[

]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
