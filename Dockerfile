FROM emscripten/emsdk:2.0.34

RUN apt update && apt install -y groff bison

#######
# First step: install libpng in emscripten ports
#######

WORKDIR /tmp

COPY dummy.c .

# hacky way to install ports by compiling a dummy program
RUN emcc -s USE_LIBPNG=1 -s USE_GIFLIB=1 dummy.c

#######
# Second step: compile npiet
#######

WORKDIR /npiet

# ADD command untar automagically
ADD npiet-1.3f.tar.gz .

WORKDIR npiet-1.3f/

RUN emconfigure ./configure

RUN emmake make npiet

RUN emcc npiet.o -o npiet.js -s USE_LIBPNG=1 -s USE_GIFLIB=1 -s EXIT_RUNTIME=1 -s ENVIRONMENT=web -s MODULARIZE=1 -s 'EXPORT_NAME="npiet"' -s EXPORTED_RUNTIME_METHODS='["FS"]' --use-preload-plugins -O3 --closure=1

#######
# Last step: place interesting files in output folder for ease of use
#######

WORKDIR /npiet
RUN mkdir ./output
RUN cp ./npiet-1.3f/npiet.wasm ./output
RUN cp ./npiet-1.3f/npiet.js ./output
