# toolchain-mcpp.cmake
set(CMAKE_C_COMPILER /usr/bin/clang)
set(CMAKE_C_FLAGS "")

set(CUSTOM_CPP "mcpp_preprocess.sh")

set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "Library install dir")

# Avoid interfering with compiler tests during configure
if(NOT CMAKE_BINARY_DIR MATCHES ".*/CMakeFiles/CMakeScratch.*")
  set(CMAKE_C_COMPILE_OBJECT
    "${CUSTOM_CPP} <DEFINES> <INCLUDES> <FLAGS> <SOURCE> > <OBJECT>.i && \
     /usr/bin/clang -Xclang -dump-tokens -E -xc <OBJECT>.i 2> <OBJECT>.rawtokens && \
     sed -E 's/[[:space:]]*(\\[.*|Loc=<.*)//' <OBJECT>.rawtokens > <OBJECT>.tokens && \
     rm -f <OBJECT>.rawtokens && \
     clang-format -style=file -i <OBJECT>.i && \
     /usr/bin/clang -c <OBJECT>.i -o <OBJECT>"
  )
endif()
