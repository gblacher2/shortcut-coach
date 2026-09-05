## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2025-02-12 - Accessibility Labels for Icon-only Buttons
**Learning:** Found an icon-only button without an accessibility label in the `ShortcutCoachRootView` component (`arrow.clockwise` refresh button). Also found an icon-only button in the `TodayView` component (mark practiced button) without an accessibility label. While they have `.help` modifiers which give mouse users tooltips, VoiceOver users will just hear "button" without a clear purpose.
**Action:** When inspecting macOS SwiftUI app code, search for `Button`s that only contain an `Image`. Verify they have both `.help()` and `.accessibilityLabel()` to support all users.
