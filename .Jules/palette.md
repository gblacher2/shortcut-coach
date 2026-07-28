## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-05-18 - [Icon-Only Button Accessibility in SwiftUI]
**Learning:** In SwiftUI, relying solely on `.help` modifiers for tooltips is insufficient for screen readers. Icon-only buttons MUST have explicit `.accessibilityLabel` modifiers to ensure VoiceOver users can understand their purpose.
**Action:** Always ensure both `.help` (for mouse hover) and `.accessibilityLabel` (for VoiceOver) are applied to icon-centric or borderless buttons in macOS apps.
