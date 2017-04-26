## 0.4.0:
- Reduce activation time, by reducing disk-IO on startup. No longer use `underscore-plus`.
  - Activation time diff: from 15ms to 3ms in my env.

## 0.3.0
- Breaking, Improve: flash-style
  - Improve: Tweak flash style using keyframe animation
  - Breaking: Deprecate `flashDurationMilliSeconds` setting.

## 0.2.2
- Fix: Deprecated warning, remove `::shadow` from style #9.

## 0.2.1
- Add fash highlight style for non-shadowDOM user

## 0.2.0
- Cleanup
- Breaking: Remove `flashPersist` settings.

## 0.1.12 - Improve
* [BUG]: Now clear paste state on active item change.
* [BUG]: Cause exception when cursor added in-middle-of sequential-paste.
* Spec: More coverage.
* Refactoring.
* Deprecate: flashColor config parameter.
* Re-enable `syncToSystemClipboard()`.

## 0.1.11 - FIX
* [BUG] Latest copied entry didn't popped first when entry already in history.
* Disable `syncToSystemClipboard()` since its not respect when its saved.

## 0.1.10 - Improve
* Now `scrollToCursorPosition` when pasted to avoid cursor position off-screen.

## 0.1.9 - Improve
* `syncToSystemClipboard()` to sync clipboard update happened on other window.

## 0.1.8 - Improve
* `adjustIndent` now aware hardTab indent.

## 0.1.7 - Improve
* Introduce `adjustIndent` and its enabled by default.

## 0.1.6 - Improve
* Add some tests
* More constant approach to wrap atom.clipboard.write

## 0.1.5 - Improve
* Refactor
* [FIX] Marker did not destroyed()
* [feature] new `flashPersist` option.

## 0.1.4 - Improve
* [FIX] `max` configuration is not respected.
* Add config for color style of flashing.
* Use `Marker::copy()` instead of duplicately create marker for flashing.

## 0.1.3 - Improve
* [FIX] Flash and paste was broken when multi cursors.
* Update gif anime and doc.

## 0.1.2 - Improve
* [breaking] `clip-history:paste-older` no longer available.
* new command `clip-history:paste-last` to paste last pasted text.

## 0.1.1 - Change default value
* max 100 -> 10 for easy round.

## 0.1.0 - First Release
