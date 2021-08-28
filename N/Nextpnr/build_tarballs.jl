# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Nextpnr"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/YosysHQ/nextpnr.git", "dd6376433154e008045695f5420469670b0c3a88")
]

dependencies = [
    Dependency("Icestorm_jll"; compat="0.1.0"),
    Dependency("Prjtrellis_jll"; compat="0.1.0"), #TODO
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    #HostBuildDependency("Python_jll"),
    Dependency("Eigen_jll"; compat="3.3.9")
]

# Bash recipe for building across all platforms
script = raw"""
cd nextpnr
git submodule --init && git submodule --update

#export PYTHONPATH=${prefix}/lib/python3.8:${prefix}/lib/trellis

cd bba 
cmake . -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
make
cd ..

cmake . -DARCH="ecp5" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DICESTORM_INSTALL_PREFIX=${prefix} \
    -DTRELLIS_INSTALL_PREFIX=${prefix} \
    -DBBA_IMPORT=./bba/bba-export.cmake \
    -DBUILD_PYTHON=OFF \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    .
make -j${nproc}
make install
"""
# 

    #-DEXTERNAL_CHIPDB=ON \
    #-DECP5_CHIPDB=${prefix}/share/prjtrellis-db/ \

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = HostPlatform() #filter!(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)
# For some reason, building for CXX03 string ABI doesn't actually work, skip it
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = Product[

]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
