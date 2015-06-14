# clip-history

Paste from clipboard history like emacs' kill-ring

![gif](https://raw.githubusercontent.com/t9md/t9md/a34a6ce5f1ac5535557c7b45496197b31435d03f/img/atom-clip-history.gif)

# Features

* Like Emacs' or Bash's kill-ring, you can paste older clipboard entry.
* Visually highlight(flash) pasted range.

# How to use
1. Paste clipboard entry by `clip-history:paste`
2. Just after `clip-history:paste`, execute `clip-history:paste-older` to paste older clipboard entry. You can repeat `clip-history:paste-older` until you get what you want.

# Commands

* `clip-history:paste`: Paste
* `clip-history:paste-older`: Paste older entry, works only just after `clip-history:paste`, otherwise it does nothing.
* `clip-history:clear`: Clear history entries.

# Keymap
No keymap by default.

e.g.

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl-y': 'clip-history:paste'
  'cmd-y':  'clip-history:paste-older'
```

# Similar packages
* [kill-ring](https://atom.io/packages/kill-ring)
* [clipboard-plus](https://atom.io/packages/clipboard-plus)
* [clipboard-history](https://atom.io/packages/clipboard-history)

# TODO

* [ ] Make configurable flash duration.
