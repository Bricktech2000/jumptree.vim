# jumptree.vim

_Undo tree semantics for the jumplist_

## Overview

This plugin provides a set of four mappings for navigating the jumplist that are analogous to those for navigating the undo tree. The result is a consolidation of the “stack” jumplist and classic jumplist:

- Relative locations of jumplist entries are preserved, as with the “stack” jumplist when `'jumpoptions'` includes `stack`;
- No jumplist entries are discarded, as with the classic jumplist when `'jumpoptions'` does not include `stack`.

## Mappings

The mappings provided are best illustrated as a correspondence between them and equivalent jumplist bindings and analogous undo tree bindings:

|                       | Jumptree Default | “Stack” Jumplist | Classic Jumplist | Undo Tree Analogue |
| --------------------- | ---------------- | ---------------- | ---------------- | ------------------ |
| `<Plug>JumptreeUp`    | `CTRL-O`         | `CTRL-O`         |                  | `u`                |
| `<Plug>JumptreeDown`  | `CTRL-I`         | `CTRL-I`         |                  | `CTRL-R`           |
| `<Plug>JumptreeOlder` | `g CTRL-O`       |                  | `CTRL-O`         | `g-`               |
| `<Plug>JumptreeNewer` | `g CTRL-I`       |                  | `CTRL-I`         | `g+`               |

Default mappings can be disabled with

```vim
let g:jumptree_no_mappings=1
```
