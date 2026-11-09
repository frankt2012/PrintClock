# Time Calculator

A small native macOS app for 3D printing: enter the print time reported by your
slicer and see exactly what time the print will finish.

![Time Calculator screenshot](docs/screenshot.png)

Click the clock in the menu bar for a compact calculator that stays in sync with the main window.

![Menu bar popover](docs/menubar.png)

## Features

- Enter print time in hours and minutes, with quick presets
- Finish time updates live, with a countdown and progress bar
- Start now, or choose a custom start date and time
- Menu bar extra for quick access, synced with the main window
- Remembers your last duration between launches
- Copy the finish date and time to the clipboard (⇧⌘C)

## Menu bar

The app adds a clock-with-check icon to the menu bar. If you use a menu bar
manager such as Thaw, make sure the Time Calculator item is in the visible
section.

## Build

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
open TimeCalculator.xcodeproj
```

Or build from the command line:

```sh
xcodegen generate
xcodebuild -project TimeCalculator.xcodeproj -scheme TimeCalculator -configuration Release build
```

The built app appears in Xcode's DerivedData folder, or use **Product → Show Build Folder in Finder** from Xcode.

## Tests

```sh
swift test --package-path Packages/TimeCalculatorKit
```
