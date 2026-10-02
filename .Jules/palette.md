## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-07-25 - Custom Search Fields Need Clear Buttons
**Learning:** Custom `TextField` components used for searching on macOS lack the native clear button ("x"). Omitting this makes resetting queries tedious for users.
**Action:** Always add a clear button `.overlay(alignment: .trailing)` to custom search text fields, ensuring it includes both an `.accessibilityLabel` for screen readers and a `.help` tooltip for mouse users discovering icon-only buttons.
