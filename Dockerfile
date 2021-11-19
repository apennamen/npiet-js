FROM emscripten/emsdk:2.0.34

RUN apt update && apt install -y groff bison

#######
# First step: install libpng and giflib in emscripten ports
#######

WORKDIR /src

COPY dummy.c .

# hacky way to install ports by compiling a dummy program
RUN emcc -s USE_LIBPNG=1 -s USE_GIFLIB=1 dummy.c

#######
# Second step: port gd.h 2.3
#######

RUN git clone https://github.com/libgd/libgd.git

WORKDIR libgd

RUN git checkout --track origin/GD-2.3

RUN cp ./src/*.h /emsdk/upstream/emscripten/cache/sysroot/include

RUN emcmake cmake -DENABLE_PNG=1 .

RUN emmake make

# Install generated GD library in emscripten
RUN cp ./Bin/* /emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten


#######
# Third step: compile npiet
#######

WORKDIR /npiet

# ADD command untar automagically
ADD npiet-1.3f.tar.gz .

WORKDIR npiet-1.3f/

RUN emconfigure ./configure

RUN emmake make npiet

RUN emcc /src/libgd/Bin/libgd.a npiet.o -o npiet.js -s USE_LIBPNG=1 -s USE_GIFLIB=1 -s EXIT_RUNTIME=1 -s ENVIRONMENT=web -s MODULARIZE=1 -s 'EXPORT_NAME="npiet"' -s EXPORTED_RUNTIME_METHODS='["FS"]' --use-preload-plugins

RUN emcc /src/libgd/Bin/libgd.a npiet.o -o npiet-min.js -s USE_LIBPNG=1 -s USE_GIFLIB=1 -s EXIT_RUNTIME=1 -s ENVIRONMENT=web -s MODULARIZE=1 -s 'EXPORT_NAME="npiet"' -s EXPORTED_RUNTIME_METHODS='["FS"]' --use-preload-plugins -O3 --closure=1

#######
# Last step: place interesting files in output folder for ease of use
#######

WORKDIR /npiet
RUN mkdir ./output
RUN cp ./npiet-1.3f/npiet*.wasm ./output
RUN cp ./npiet-1.3f/npiet*.js ./output
