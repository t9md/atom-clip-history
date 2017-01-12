# clip-history [![Build Status](https://travis-ci.org/t9md/atom-clip-history.svg)](https://travis-ci.org/t9md/atom-clip-history)

Paste from clipboard history like emacs' kill-ring

![gif](https://raw.githubusercontent.com/t9md/t9md/8c161f165a9caa86021a25c3e91c80dfa559ff2e/img/atom-toggle.gif)

# How to use

1. Paste clipboard entry by `clip-history:paste`
2. Continue `clip-history:paste` until you get entry you want.
3. (optional) when you get passed the text you wanted to paste, use `clip-history:paste-newer`.
4. (optional) you can paste last pasted text with `clip-history:paste-last`.

# Commands

* `clip-history:paste`: Paste. Continuous execution without moving cursor pops older entry.
* `clip-history:paste-newer`: Paste. Continuous execution without moving cursor pops newer entry.
* `clip-history:paste-last`: Paste last pasted text.
* `clip-history:clear`: Clear clipboard history.

# Keymap
No keymap by default.

e.g.

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl-y': 'clip-history:paste'
  'cmd-y': 'clip-history:paste-newer'
  'ctrl-Y': 'clip-history:paste-last'
```

# Modify flash duration

From v0.3.0, `flashDurationMilliSeconds` config was removed to use better flashing animation by CSS keyframe.
Default duration is one second, if you want this shorter, modify your `style.less`.

```less
atom-text-editor.editor .clip-history-pasted .region {
  // default is 1s, you can tweak in the range from 0 to 1s(maximum).
  animation-duration: 0.5s;
}
```

# Features

* Paste old clipboard entry.
* Keep multi-line text layout on past by adjusting leading white-spaces of each line(enabled by default).
* Flash pasted area.
* Support multiple cursor(disabled by default).

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
