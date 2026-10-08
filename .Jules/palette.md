## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-10-08 - [Text Field Clear Buttons]
**Learning:** Native clear buttons via `.searchable()` are preferable, but when building custom `TextField` views in SwiftUI (like in `MenuBarSearchView`), explicitly placing an "x" clear button inside an `HStack` next to the `TextField` is a safer implementation than using an `.overlay()`. Overlaying buttons over the text input area can cause typed text to disappear underneath the button, breaking visibility. Also, never apply structural modifiers like `.overlay()` directly to standard inputs used inside an `.alert` actions closure, as it violates the strict `ViewBuilder` constraints and can break the UI.
**Action:** Always prefer `HStack` over `.overlay` for attaching trailing actions to custom text inputs. Never attempt to restyle elements within an `alert` actions block.
