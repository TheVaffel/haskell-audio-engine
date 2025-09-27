# Haskell sound engine with Rust interface

Experimental project using the `synthesizer-core` Haskell package to create a sound engine. The engine has an FFI interface, and a "UI" (in the loosest sense of the word) is included in this project.

The synthesizer countinuously polls an input circular buffer for new commands, inbetween relaying audio buffers to the system sound sink. The UI uses the circular buffer to write commands on user input.

## Prerequisites

- Cabal (Haskell build system)
- Cargo (Rust build system)

## Build

- Run
```
$ cabal build
```

in the `audio-engine` folder.

- Run
```
$ cargo run
```

in the `ui` folder.

- Profit.

## FAQ

### Why?

Idk

### But isn't audio applications extremely real-time sensitive? Why would you inject an FFI layer in the middle of the event loop when creating sounds based on user input? Furthermore, why would you even consider a lazy-evaluated garbage-collected language with unreliable execution speed like Haskell for such a task?

Shut up, nerd
