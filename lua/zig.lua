------------------
-- Zig Commands --
------------------

-- handle command output and alert errors
local handleOutput = function(data, regex, b, ns)
  -- check input
  if data then
    local msg = ''
    -- compose message from data
    for _, v in ipairs(data) do
      msg = msg .. v .. "\n"
    end
    local result = string.gmatch(msg, regex)
    local lines = {}
    for v in result do
      -- get just the line numbers
      table.insert(lines, string.match(v, '[0-9]+'))
    end
    if #lines > 0 then
      -- add marks to where tests failed
      for _, v in ipairs(lines) do
        -- make sure line exists in file
        local max = vim.api.nvim_buf_line_count(0)
        if tonumber(v) <= max then
          vim.api.nvim_buf_set_extmark(b, ns, tonumber(v) - 1, -1, {
            virt_text = { { ' ✗', 'ErrorMsg' } },
            -- overlay prevents conflict with diagnostic messages
            virt_text_pos = 'overlay',
          })
        end
      end
    end
    return msg
  end
end

-- take string data and decide if there is an Error
local function handleData(data, regex, b, ns)
  local msg = {}
  for _, v in ipairs(data) do
    table.insert(msg, v)
  end
  -- get the output as a string and set vir text
  local output = handleOutput(msg, regex, b, ns)
  -- if there is output message user
  if #output > 1 then
    vim.api.nvim_notify(output, vim.log.levels.DEBUG, {})
  end
end

-- test current File or Zig Project
function ZigTest()
  -- get buffer information
  local b = vim.api.nvim_get_current_buf()
  local ns = vim.api.nvim_create_namespace('test')
  local file = vim.api.nvim_buf_get_name(0)
  -- let user know
  print("Testing " .. file)
  -- compose command
  local command = "zig test " .. file .. " -O Debug"
  local regex = file .. ':[0-9]+'
  vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
  vim.fn.jobstart(vim.fn.split(command), {
    -- allows proper newlines
    stderr_buffered = true,
    stdout_buffered = true,
    cwd = vim.fn.getcwd(),
    -- handle err / out
    on_stderr = function(_, data)
      handleData(data, regex, b, ns)
    end,
    on_stdout = function(_, data)
      handleData(data, regex, b, ns)
    end,
  })
end

-- create user command
vim.api.nvim_create_user_command("ZigTest",
  function()
    ZigTest()
  end, {})

-- Determine if file is in a project
local function isZigProject()
  -- look for build.zig as it's in root
  local proj = vim.fn.findfile('build.zig', ';.')
  if proj ~= '' then
    -- construct root as a string
    local path = vim.fn.split(proj, '/')
    table.remove(path, #path)
    return '/' .. table.concat(path, '/') .. '/'
  end
  -- not in file
  return false
end

function ZigBuild()
  -- get buffer information
  local file = vim.api.nvim_buf_get_name(0)
  local b = vim.api.nvim_get_current_buf()
  local ns = vim.api.nvim_create_namespace('test')
  -- get variables for functions
  local proj = isZigProject()
  local command
  local regex = file .. ':[0-9]+'
  -- let user know
  print('Building ...')
  if proj then
    -- check if you're already at root
    if proj == '//' then proj = vim.fn.getcwd() end
    command = 'zig build'
    vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
    -- wait for job to finish so msg can populate
    vim.fn.jobstart(vim.fn.split(command), {
      -- allows proper newlines
      stderr_buffered = true,
      stdout_buffered = true,
      cwd = proj,
      -- handle err / out
      on_stderr = function(_, data)
        -- output means error
        if #data > 1 then
          handleData(data, regex, b, ns)
        else
          vim.api.nvim_notify('No Compile Time Errors...', vim.log.levels.INFO, {})
        end
      end,
      on_stdout = function(_, data)
        handleData(data, regex, b, ns)
      end,
    })
  else
    -- single file build command
    command = 'zig build-exe ' .. file .. ' -O Debug'
    vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
    vim.fn.jobstart(vim.fn.split(command), {
      -- allows proper newlines
      stderr_buffered = true,
      stdout_buffered = true,
      cwd = vim.fn.getcwd(),
      -- handle err / out
      on_stderr = function(_, data)
        -- output means error
        if #data > 1 then
          handleData(data, regex, b, ns)
        else
          vim.api.nvim_notify('No Compile Time Errors...', vim.log.levels.INFO, {})
        end
      end,
      on_stdout = function(_, data)
        handleData(data, regex, b, ns)
      end,
    })
  end
end

-- create user command
vim.api.nvim_create_user_command("ZigBuild",
  function()
    ZigBuild()
  end, {})

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
