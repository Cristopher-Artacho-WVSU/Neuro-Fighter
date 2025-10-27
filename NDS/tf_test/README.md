This is the C shim that sets up Tensorflow and runs the models.

# Development

`clangd` LSP Server (the thing that gives hints and autocomplete and shi) needs
a compilation database to work well. This is generated with Meson and Ninja.

`meson setup builddir`
`ninja -C builddir -t compdb > compile_commands.json`

# Building

## Build Dependencies

- Meson
- Ninja (installed with Meson)

> Involves a a lot of work, will update for more instructions later and maybe automation scripts.

1. Add tensorflow library
    - Add static library to `./lib`.
    - Add headers to `./include`.
2. Dump GDExtension headers. 
3. `meson compile -C builddir`

You can now run `./builddir/tf_test`.

# TODO:

- Work on GDExtension, so that Godot can use the models.
    - GDExtension is laborious and needs a lot of boilerplate.
- Update/train models with the updated Dynamic Scripting and new training data set.
- Extend Dynamic Scripting with NDS model.
