# Prompt 04 - Local Install Convenience

You are working in:

`/Users/gabrielblacher/Documents/Codex/shortcut-coach`

Task:

Make Shortcut Coach easier to use after development, without making it noisy or changing system behavior unexpectedly.

Preferred outcome:

- Add a simple script such as `script/install_local_app.sh` that builds/stages the app and copies or syncs `dist/ShortcutCoach.app` to `/Applications/ShortcutCoach.app` or `~/Applications/ShortcutCoach.app`.
- Prefer `~/Applications` if it avoids permissions prompts.
- Do not enable launch-at-login automatically.
- If launch-at-login is useful, document it as a manual next step or add a separate opt-in script.

Requirements:

- Keep `script/build_and_run.sh` as the development run path.
- Keep install script separate from source code.
- Preserve menu-bar-only/accessory behavior.
- Do not modify Karabiner, macOS keyboard shortcuts, or notification settings.

Acceptance:

- Install script is idempotent.
- It prints the final app path.
- It does not require sudo unless the user explicitly chooses `/Applications`.
- It does not auto-start at login.
