# clip-history

Paste from clipboard history like emacs' kill-ring

![gif](https://raw.githubusercontent.com/t9md/t9md/a34a6ce5f1ac5535557c7b45496197b31435d03f/img/atom-clip-history.gif)

# Features

* Like Emacs' or Bash's kill-ring, you can paste older clipboard entry.
* Visually highlight(flash) pasted range.

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

* [ ] Make configurable flash duration.
