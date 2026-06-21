# ShannonSwitching With GUI

This version keeps the terminal-tested core logic and adds a lazy-loaded Gtk4/Cairo GUI.

## Run tests

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.test()
```

## Terminal game

```julia
using ShannonSwitching
play_terminal()
```

## GUI game

```julia
using ShannonSwitching
run_game()
```

If Gtk4/Cairo causes installation problems on Windows, the terminal version still works.
