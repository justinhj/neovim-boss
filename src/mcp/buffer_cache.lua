-- Event-driven buffer status for neovim://buffers (issue #6).
--
-- One RPC does everything: attaches nvim_buf_attach to every buffer backing a
-- visible window, detaches buffers that are no longer visible, installs the
-- visibility autocmds (once), and returns the authoritative snapshot.
--
-- Args:
--   chan            our RPC channel id, for vim.rpcnotify back to the client
--   attached_list   array of bufnrs the client believes are attached
--   setup_autocmds  true on first subscribe; installs the NeobossBufferCache
--                   augroup (cleared first, so re-running is idempotent)
--
-- Returns: array of { bufnr, name, line_count, modified, changedtick }
-- for every currently visible buffer.
local chan, attached_list, setup_autocmds = ...
assert(type(chan) == 'number', 'buffer_cache: channel id (arg 1) required')

local attached = {}
for _, b in ipairs(attached_list) do
  attached[b] = true
end

local function try_attach(buf)
  if attached[buf] then
    return true
  end
  local ok = pcall(vim.api.nvim_buf_attach, buf, false, {
    on_lines = function(_, b, tick, firstline, lastline, linedata, _)
      -- Only the replacement line count crosses the wire, not the lines.
      vim.rpcnotify(chan, 'neoboss_buf_lines', b, tick, firstline, lastline, #linedata)
    end,
    on_changedtick = function(_, b, tick)
      vim.rpcnotify(chan, 'neoboss_buf_tick', b, tick)
    end,
    on_detach = function(_, b)
      vim.rpcnotify(chan, 'neoboss_buf_detach', b)
    end,
  })
  if ok then
    attached[buf] = true
  end
  return ok
end

local function snapshot(buf)
  local ok, info = pcall(function()
    return {
      bufnr = buf,
      name = vim.api.nvim_buf_get_name(buf),
      line_count = vim.api.nvim_buf_line_count(buf),
      modified = vim.api.nvim_get_option_value('modified', { buf = buf }),
      changedtick = vim.api.nvim_buf_get_changedtick(buf),
    }
  end)
  if ok then
    return info
  end
  return nil
end

-- Every buffer backing a visible window.
local visible = {}
for _, win in ipairs(vim.api.nvim_list_wins()) do
  local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
  if ok then
    visible[buf] = true
  end
end

local result = {}
for buf, _ in pairs(visible) do
  if try_attach(buf) then
    local info = snapshot(buf)
    if info then
      result[#result + 1] = info
    end
  end
end

-- Drop buffers that are no longer visible (their on_detach also notifies us).
for buf, _ in pairs(attached) do
  if not visible[buf] then
    pcall(vim.api.nvim_buf_detach, buf)
  end
end

if setup_autocmds then
  local group = vim.api.nvim_create_augroup('NeobossBufferCache', { clear = true })
  vim.api.nvim_create_autocmd(
    { 'BufEnter', 'WinEnter', 'BufDelete', 'BufWipeout', 'BufWritePost' },
    {
      group = group,
      callback = function()
        vim.rpcnotify(chan, 'neoboss_buf_visibility')
      end,
    }
  )
end

return result
