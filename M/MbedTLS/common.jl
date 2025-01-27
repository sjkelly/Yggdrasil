using BinaryBuilder

name = "MbedTLS"

# Collection of sources required to build MbedTLS
sources_by_version = Dict(
    v"2.24.0" => [
        GitSource("https://github.com/ARMmbed/mbedtls.git",
                  "523f0554b6cdc7ace5d360885c3f5bbcc73ec0e8"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.25.0" => [
        GitSource("https://github.com/ARMmbed/mbedtls.git",
                  "1c54b5410fd48d6bcada97e30cac417c5c7eea67"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.26.0" => [
        GitSource("https://github.com/ARMmbed/mbedtls.git",
                  "e483a77c85e1f9c1dd2eb1c5a8f552d2617fe400"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ]
)
sources = sources_by_version[version]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mbedtls

# llvm-ranlib gets confused, use the binutils one
if [[ "${target}" == *apple* ]]; then
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/ranlib
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/${target}-ranlib
    atomic_patch -p1 ../patches/0001-Remove-flags-not-sopported-by-ranlib.patch
fi

# MbedTLS 2.24.0 needs a patch for platforms where `char` is unsigned
P=${WORKSPACE}/srcdir/patches/0002-fix-incorrect-eof-check.patch
if [[ -f ${P} ]]; then
    atomic_patch -p1 ${P}
fi

# MbedTLS 2.24.0 also needs a patch for platforms that build with Clang 12
P=${WORKSPACE}/srcdir/patches/0003-Prevent-triggering-Clang-12--Wstring-concatenation.patch
if [[ -f ${P} ]]; then
    atomic_patch -p1 ${P}
fi

# enable MD4
sed "s|//#define MBEDTLS_MD4_C|#define MBEDTLS_MD4_C|" -i include/mbedtls/config.h

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_C_STANDARD=99 \
    -DUSE_SHARED_MBEDTLS_LIBRARY=On \
    -DENABLE_TESTING=OFF \
    ..
make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    # For some reason, the build system doesn't set the `.dll` files as
    # executable, which prevents them from being loaded.  Also, we need
    # to explicitly use `${prefix}/lib` here because the build system
    # is a simple one, and blindly uses `/lib`, even on Windows.
    chmod +x ${prefix}/lib/*.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmbedcrypto", :libmbedcrypto),
    LibraryProduct("libmbedx509", :libmbedx509),
    LibraryProduct("libmbedtls", :libmbedtls),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

