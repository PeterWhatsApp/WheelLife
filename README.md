# Life Planning Wheel

Native SwiftUI iPhone app for tracking life balance — wired to App Store Connect as **Life Planning Wheel**.

## App Store Connect alignment

| Field | Value |
| --- | --- |
| App Name | Life Planning Wheel |
| Bundle ID | `com.crimson.lifeplanningwheel` |
| Widget Bundle ID | `com.crimson.lifeplanningwheel.widget` |
| Version | `1.0` |
| App Group | `group.com.crimson.lifeplanningwheel` |
| Apple ID | `6762238978` |
| SKU | `lifeplanningwheel-ios-001` |

## Features

- Interactive drag-to-rate wheel with haptic feedback
- Templates (Full Spectrum 10 / Classic 8)
- Insights, history snapshots, share image
- Reassessment reminders
- Home Screen widget

## Open in Xcode

1. Open `WheelOfLife.xcodeproj`
2. Signing & Capabilities → select your Team (already `2UNF9LFD26`)
3. Confirm App Group `group.com.crimson.lifeplanningwheel` is enabled for app + widget
4. Run (⌘R), then **Product → Archive** when ready to upload

## Upload checklist

1. In App Store Connect, set Primary Category (e.g. Lifestyle)
2. Archive in Xcode → Distribute App → App Store Connect
3. Attach the build to version **1.0 Prepare for Submission**
