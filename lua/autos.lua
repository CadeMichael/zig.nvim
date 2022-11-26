-----------------
-- Zig Autocmd --
-----------------
local settings = vim.g.zig_settings
    or {
      test = '<space>tf',
      build = '<space>bf',
      save = {
        format = true,
        build = true,
      }
    }

vim.api.nvim_create_autocmd(
  "FileType",
  {
    pattern = {
      "zig",
    },
    command = [[
    set ts=4 sw=4
    nnoremap <silent><buffer> ]] .. settings.test .. [[ :ZigTest<CR>
    nnoremap <silent><buffer> ]] .. settings.build .. [[ :ZigBuild<CR>
    ]],
  }
)

if settings.save.format then
  vim.api.nvim_create_autocmd(
    "BufWritePost",
    {
      pattern = {
        "*.zig",
      },
      callback = function()
        local file = vim.api.nvim_buf_get_name(0)
        vim.cmd('silent !zig fmt ' .. file)
        if settings.save.build then
          vim.cmd [[silent lua ZigBuild()]]
        end
      end,
    }
  )
end
