## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-07-09 - [Empty State UI]
**Learning:** Adding empty states (`ContentUnavailableView`) in search views drastically improves user guidance, preventing users from assuming the app is broken or frozen when no search matches.
**Action:** Use SwiftUI's native `ContentUnavailableView` whenever filtering or search capabilities might result in an empty list.
