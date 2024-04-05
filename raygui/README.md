# rGuiLayout

Launch `rGuiLayout` through `cmake --build build -- rguilayout` and create
the layout you require.

> [!CAUTION]
> Save the layout as a `.h` file and make sure that all names follow the `PascalCaseConvention`.
> The configuration is built around this convention.

Then add the bindings in the [[raygui.odin]] file.

Reconfigure `cmake` to recompile the `libraygui.a` library and you are good to go.

