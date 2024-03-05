# Architect

Architect is a simple, lightweight Lua-based Makefile-style build tool and a toy project for UNIX systems designed for my personal C/C++ use. It provides a simple and flexible way to define build configurations, compile source files, and run arbitrary shell commands.

## Prerequisites

- Lua/LuaJIT installed on your system.

## Installation

```bash
git clone https://github.com/kseou/Architect.git
```

```lua
local architect = require("architect")
```

A better way of installation and usage will be explored.

## Usage
```lua
-- build.lua (can be named anything)

local architect = require("architect")

local params = {
    sourceFiles = {"main.cpp"},
    outputExecutable = "main",
    compiler = "clang++",
    libs = {"sdl2", "SDL2_image"},
    additionalFlags = "-O3",
    outputFolder = "bin",
    commands = {
        "mv player.png ./bin/"
    }
}

architect.plan(params)
```

To run it:

`luajit build.lua --build` or `lua build.lua --build`

---

Architect can also be used to run arbitrary shell commands:

```lua
local architect = require("architect")

-- Counterproductive, but good enough as an example
local params = {
    commands = {
        "echo Building...",
        "mkdir build",
        "g++ -o build/main main.cpp",
        "./build/main",
    }
}

architect.plan(params)
```

To run it:

`luajit build.lua --build` or `lua build.lua --build`

---

It can also be used as a pseudo `Makefile` to run commands based on tasks defined and named by the user:

```lua
local architect = require("architect")
local tasks = {}

tasks.build = {
    name = "build",
    commands = {
        "echo Building...",
        "mkdir build",
        "g++ -o build/hello hello.cpp"
    }
}

tasks.run = {
    name = "run",
    commands = {
        "./build/hello"
    }
}

tasks.clean = {
    name = "clean",
    commands = {
        "rm -rf build"
    }
}

-- Usage: lua build.lua build/run/clean
architect.runTasks(tasks)
```

---

## Useful information

All values of the `params` table (can be named anything) are optional. If the parameters are passed empty or not at all either a default value will be set or nothing.
However, Architect can only accept these values within the configuration table:

```
- sourceFiles (your main source file)
- outputExecutable (name of the executable. If nil, it will be automatically set to a.out
- compiler (which compiler to use)
- compilerFlags (compiler flags)
- additionalFlags (pass any flags to your compiler/linker)
- libs (uses pkg-config to determine what cflags and libs are required)
- outputFolder (where your executable should be build to)
- commands (arbitrary shell commands)
```

Therefore, if you don't want to pass what compiler you want to use, you don't have to add `compiler` field into your configuration. Architect will automatically determine what compiler it should use. Either by checking the `CC` environmental variable or by the file extension.

# Dependencies

## Third-Party Libraries

### Chalk

- **Name**: Chalk
- **Version**: 0.1.0-1
- **License**: MIT

The project uses the "Chalk" to draw text with . The library is included in the project under the terms of the MIT License. You can find more information about the "Chalk" and its license in the [LICENSE](https://github.com/Desvelao/chalk/blob/master/LICENSE.md) file.

