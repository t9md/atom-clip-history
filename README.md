# clip-history [![Build Status](https://travis-ci.org/t9md/atom-clip-history.svg)](https://travis-ci.org/t9md/atom-clip-history)

Paste from clipboard history like emacs' kill-ring

![gif](https://raw.githubusercontent.com/t9md/t9md/021f6b3e37b4296d3464d66e54a02bc2907a79f0/img/atom-clip-history.gif)

# Features

* Paste old clipboard entry.
* Keep layout of multi line text when pasted(enabled by default).
* Visually highlight(flash) pasted range.
* Support multiple cursor.

# Commands

* `clip-history:paste`: Paste. Continuous execution without moving cursor pops older entry.
* `clip-history:paste-newer`: Paste. Continuous execution without moving cursor pops newer entry.
* `clip-history:paste-last`: Paste last pasted text.
* `clip-history:clear`: Clear clipboard history.

# How to use

1. Paste clipboard entry by `clip-history:paste`
2. Continue `clip-history:paste` until you get entry you want.
3. (optional) when you get passed the text you wanted to paste, use `clip-history:paste-newer`.
4. (optional) you can paste last pasted text with `clip-history:paste-last`.

# Keymap
No keymap by default.

e.g.

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl-y': 'clip-history:paste'
  'cmd-y': 'clip-history:paste-newer'
  'ctrl-Y': 'clip-history:paste-last'
```

# Similar packages
* [kill-ring](https://atom.io/packages/kill-ring)
* [clipboard-plus](https://atom.io/packages/clipboard-plus)
* [clipboard-history](https://atom.io/packages/clipboard-history)

# TODO

* [x] Configurable flash duration.
* [x] Multi cursor support
* [x] Use marker instead of range to track original range in multi cursor situation.
* [x] Adjust proceeding space to keep layout.
* [x] Sync system's clipboard update.
