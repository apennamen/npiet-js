# Emscripten Generated Npiet
This repo allows to generate the npiet.js and npiet.wasm files used to run the [npiet interpreter](http://www.bertnase.de/npiet/) in the browser.

## How to Generate
1. Pull this repo and build the docker image:

`docker build -t npiet-js .`

2. Retrieve the generated files from the container:

Start the container in detach mode, without exiting

`docker run -d --name=npietcontainer npiet-js tail -F /dev/null`

Copy the output folder from the container in host the current directory

`docker cp npietcontainer:/npiet/output .`

Stop the running container

`docker stop npietcontainer`

3. Cleanup (Powershell version)

`docker container rm npietcontainer`

`docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}"|findstr "npiet-js")`

## How to Use npiet.js
The sample folder provides an example on how npiet.js can be used to execute a simple piet program.

npiet.js provides the `npiet()` method to pilot execution of the program.
It allows you to override all the methods of the [emscripten Module object](https://emscripten.org/docs/api_reference/module.html)

You'll need to override at least `preRun` and `arguments` in order to communicate with npiet.

With the npiet executable, you would execute this command line:

`npiet -t -cs 5 myprogram.png`

With npiet.js, you do it like this:
```js
const myMod = {
  preRun: [
	// Use the FileSystem provided by emscripten (MEMFS) to load the image (png, gif...)
	function(mod) {
	  const { FS } = mod;
	  FS.createPreloadedFile('/', 'myprogram.png', '/assets/myprogram.png', true, false);
	}
  ],
  arguments: ['-t', '-cs', '5', '/myprogram.png'],
};

npiet(myMod).then(() => console.log('Execution complete!'));
```


## Current Support
* SUPPORTED FILE FORMATS:
- PPM
- PNG
- GIF

* SUPPORTED ARGUMENTS:
See [npiet man page](http://www.bertnase.de/npiet/npiet.1.html)
-h, -v, -q, -d, -v11, -t, -e, -cs

* UNSUPPORTED ARGUMENTS:
Following arguments needs a port of libgd in emscripten
-tpic, -tpf, -tps, -ts, -te

## External links
Piet programming language: https://www.dangermouse.net/esoteric/piet.html
Home of npiet : http://www.bertnase.de/npiet/


## The Magic behind emscripten
The npiet.c was NOT modified in order to be compatible with the browser.
Everything is contained in those three lines:

```bash
emconfigure ./configure
emmake make npiet
emcc npiet.o -o npiet.js -s USE_LIBPNG=1 -s USE_GIFLIB=1 -s EXIT_RUNTIME=1 -s ENVIRONMENT=web -s MODULARIZE=1 -s 'EXPORT_NAME="npiet"' -s EXPORTED_RUNTIME_METHODS='["FS"]' --use-preload-plugins
```

The *configure* step checks the presence of lib_gif.h, png.h and gd.h, to enable special features of npiet (GIF support, PNG support, and Trace file feature).
Therefore, you need emscripten ports for those 3 libraires. Fortunately, as of today (11/2021), there are already ports for giflib and libpng.
However, there is none for libgd.

In order to have those ports installed in the Docker image, I first compile a dummy.c program with the option USE_LIBPNG and USE_GIFLIB.
It triggers the installation of those ports, and therefore the configure step detects the presence of those libraries.

The *make* step generates the npiet.o 

Finally, the last step (*compiling with emcc*) can be decomposed like this:

| Arguments | Description |
|---|---|
| npiet.o | Output of the last step, and input of the emcc compiler |
| -o npiet.js | Specify that we only want js and wasm generated (no html) |
| -s USE_LIBPNG=1 | Linking to the libpng port |
| -s USE_GIFLIB=1 | Linking to the giflib port |
| -s EXIT_RUNTIME=1 | Force the runtime to shutdown. Allows to flush the fprint, and launch several times the npiet() function |
| -s ENVIRONMENT=web | small optimization to reduce bundle size |
| -s MODULARIZE=1 -s 'EXPORT_NAME="npiet"' | Options to produce a js output as a module, with function named "npiet" |
| -s EXPORTED_RUNTIME_METHODS='["FS"]' | Needed to expose the FS.\* functions (FS.writeFile, FS.createPreloadedFile) in preRun function |
| --use-preload-plugins | Needed to use FS.createPreloadedFile |
