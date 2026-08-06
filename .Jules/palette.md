## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-08-06 - Missing Accessibility Labels on Help Tooltips
**Learning:** Icon-only buttons often use `.help` for visual tooltips but omit `.accessibilityLabel`. This creates a gap for VoiceOver users who won't hear the tooltip content.
**Action:** Always audit buttons using SF Symbols to ensure both `.help` and `.accessibilityLabel` are present.
