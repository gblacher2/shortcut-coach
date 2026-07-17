## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-06-23 - Explicit Accessibility Labels in SwiftUI
**Learning:** While SwiftUI's `.help()` modifier sometimes sets the accessibility label implicitly for mouse users on macOS, relying solely on it is unreliable for VoiceOver. Explicitly setting `.accessibilityLabel()` alongside `.help()` is necessary for cross-platform robustness and ensures screen readers reliably read the buttons' intent.
**Action:** Always add an explicit `.accessibilityLabel` to icon-only or state-toggling buttons in SwiftUI, even if a `.help` tooltip is already present.
