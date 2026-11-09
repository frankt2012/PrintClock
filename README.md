# Time Calculator

A small native macOS app for 3D printing: enter the print time reported by your
slicer and see exactly what time the print will finish.

## Features

- Enter print time in hours and minutes, with quick presets
- Finish time updates live, with a countdown and progress bar
- Start now, or choose a custom start date and time
- Remembers your last duration between launches
- Copy the finish date and time to the clipboard (⇧⌘C)

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
