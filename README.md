# clip-history

Paste from clipboard history like emacs' kill-ring

![gif](https://raw.githubusercontent.com/t9md/t9md/2453c4abea50741938bce79b9087e4845e8b66d1/img/atom-clip-history.gif)

# Features

* Paste old clipboard entry.
* Keep layout of multi line text when pasted(enabled by default).
* Visually highlight(flash) pasted range.
* Also you can choose flash to be persisted until cursor move.
* Multi cursor support.

# How to use

1. Paste clipboard entry by `clip-history:paste`
2. Continue `clip-history:paste` until you get entry you want.
3. (optional) you can paste last pasted text with `clip-history:paste-last`.

# Commands

* `clip-history:paste`: Paste. Continuous execution without moving cursor pops older clipborad entry.
* `clip-history:paste-last`: Paste last pasted text.
* `clip-history:clear`: Clear clipboard history.

# Keymap
No keymap by default.

e.g.

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl-y': 'clip-history:paste'
  'ctrl-Y': 'clip-history:paste-last'
```

# Similar packages
* [kill-ring](https://atom.io/packages/kill-ring)
* [clipboard-plus](https://atom.io/packages/clipboard-plus)
* [clipboard-history](https://atom.io/packages/clipboard-history)

# TODO

* [x] Make configurable flash duration.
* [x] Multi cursor support
* [x] Use marker instead of range to track original range in multi cursor situation.
* [x] Adjust proceeding space to avoid breaking layout.
