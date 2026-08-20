## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-05-18 - [Icon-Only Buttons UX]
**Learning:** Icon-only buttons often use `.help` for mouse tooltips, but without explicit `.accessibilityLabel`, screen readers may not read them correctly.
**Action:** Always ensure `.accessibilityLabel` matches the intent of `.help` on icon-only buttons for full accessibility compliance.
