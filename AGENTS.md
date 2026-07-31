# MenuProgress

macOS menubar countdown/countup tool. Single-file Swift + AppKit, no dependencies.

## Build

```sh
./build.sh
```

Produces a universal `MenuProgress.app` (arm64 + x86_64).

## Test

```sh
./MenuProgress.app/Contents/MacOS/MenuProgress --selftest
```

Asserts the date-delta and formatting logic in `main.swift`. Uses `precondition`,
not `assert`, because `build.sh` compiles with `-O` which strips `assert`.
