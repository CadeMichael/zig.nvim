if vim.g.zig_loaded then
  return
end

vim.g.zig_loaded = 1

local M = {}

M.zig = require('zig')
M.autos = require('autos')

return M
