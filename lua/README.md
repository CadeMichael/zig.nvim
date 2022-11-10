# Parody of zig-mode in emacs

## Similar functionality, very minimal (< 210 lines of lua)

## Setup 

- require for defaults, or set them before requiring with the following 

```lua
vim.g.zig_settings = {
  test = '<space>tf', -- command to test file
  build = '<space>bf', -- command to build file
  autoFmt = true, -- auto format on save
}
require('zig')
```

