This is the C shim that sets up Tensorflow and runs the models.

# Development

`clangd` LSP Server (the thing that gives hints and autocomplete and shi) needs
a compilation database to work well. This is generated with Meson and Ninja.

```bash
$ meson setup builddir
$ ninja -C builddir -t compdb > compile_commands.json
```

# Building

## Build Dependencies

- Meson
- Ninja (installed with Meson)

> Involves a a lot of work, will update for more instructions later and maybe automation scripts.

1. Add tensorflow library

    Get it from [Tensorflow build](https://storage.googleapis.com/tensorflow/versions/2.18.0/libtensorflow-cpu-linux-x86_64.tar.gz).

    - Add dynamic library to `./lib`.
    - Add headers to `./include`.

    > I just symlinked from the extracted tarball into the respective directories
    > in `tf_test/lib` and `tf_test/include`. 

2. Dump GDExtension headers into `./include`. 
3. `meson compile -C builddir`

You can now run `./builddir/tf_test`.

# Notes:

- Will not work on Windows, hmu @computerscience-person for help with setting up Windows.

# TODO:

- Work on GDExtension, so that Godot can use the models.
    - GDExtension is laborious and needs a lot of boilerplate.
- Update/train models with the updated Dynamic Scripting and new training data set.
- Extend Dynamic Scripting with NDS model.
