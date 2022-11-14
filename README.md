# Parody of zig-mode in emacs

## Similar functionality, very minimal (< 210 lines of lua)
- this plugin is mainly for learning about writing plugins and having fun with neovim!
- it was an overgrown custom zig setup I had that I thought some people might like as a plugin or just as source code to graft into their own configs
- there are some *irregularities* with the error output that I have tried to filter with regex to properly mark all errors with virtual text. I'm sure there's some behavior I haven't accounted for and if you're using it and you see something not being marked make an issue or a pr! either are welcome. 

## Setup 

- require for defaults, or set them before requiring with the following 

```lua
vim.g.zig_settings = {
  -- command to test file
  test = '<space>tf',
  -- command to build file
  build = '<space>bf',
  -- settings on save
  save = {format = true, build = false},
}
require('zig')
```
## Screen Shots

### Successful Test Run

![](imgs/zig_pass.jpeg)

### Failing Test Run

#### User Message

![](imgs/zig_fail.jpeg)

#### Virtual Text Insertion

![](imgs/virt_text.jpeg)

## Testing

### Building a file
- main areas of concern for testing are errors at the line number == 1 and == max line nums in buffer
- the line number of the error will usually be off by one when setting virt text so you need to subtract one and keep that in mind when determining where to place a mark
- test by breaking code at first and last line
  - at the last line offset will need to be -2 so as the zig compiler will give a line number one greater than the last lineas it is an 'eof' error where it expects something it isn't finding

### Testing a file
- break a test and see if the error is at the right point
- break multiple tests and see if all failing tests are marked
- make all tests passed and see if marks go away
- create an error in a test on first and last line and see if they're reported
