## MenuProgress

### Overview

A simple menubar countdown and countup tool for Apple macOS. Powered by Swift and Cocoa(AppKit).

Add events with a target date and the menubar shows `NAME D-84` (remaining),
`NAME D+84` (passed) or `NAME D-Day`.

### Build

Make sure you have `swiftc` and `lipo` in your `PATH`.

```sh
chmod +x build.sh
./build.sh
```

### Test

```sh
./MenuProgress.app/Contents/MacOS/MenuProgress --selftest
```

### Installation

Move `MenuProgress.app` to your `/Applications` folder.

### Usage

Click the menubar item:

- Click an event to show it in the menubar.
- `Add Event...` to add a name and a `YYYY-MM-DD` target date.
- `Remove Event` to delete one.

Events are stored in `UserDefaults` under `Salmonization.MenuProgress`.

### License

BSD 2-Clause License
