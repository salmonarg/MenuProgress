## MenuProgress

### Overview

A simple menubar progress tracking tool for Apple macOS. Powered by Swift and Cocoa(AppKit).

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

To start it at login, add it in System Settings > General > Login Items.

### Usage

Click the menubar item:

- Click an event to show it in the menubar.
- `Add...` for a name and a target date.
- `Edit` to change the date of an event.
- `Remove` to delete one, with confirmation.

Events are stored in `UserDefaults` under `Salmonization.MenuProgress`.

### License

BSD 2-Clause License
