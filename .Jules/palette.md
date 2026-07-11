## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2026-07-11 - [Missing Accessibility Labels on Icon-Only Buttons]
**Learning:** Icon-only buttons using only `.help` tooltips are a recurring pattern in the app. While `.help` provides visual tooltips, explicit `.accessibilityLabel` properties are essential for screen reader users to understand the button's action without guessing based on nearby context.
**Action:** When adding or updating icon-only buttons, always ensure both a `.help` tooltip (for mouse users) and an explicit `.accessibilityLabel` (for screen reader users) are present.
