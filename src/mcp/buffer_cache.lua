-- Event-driven buffer status for neovim://buffers (issue #6).
--
-- One RPC does everything: attaches nvim_buf_attach to every buffer backing a
-- visible window, detaches callbacks for buffers that are no longer visible,
-- installs the visibility autocmds (once), and returns the authoritative snapshot.
--
-- Args:
--   chan            our RPC channel id, for vim.rpcnotify back to the client
--   attached_list   unused (authoritative attach generation state lives in _G)
--   setup_autocmds  true on first subscribe; installs the NeobossBufferCache_<chan>
--                   augroup (cleared first, so re-running is idempotent)
--
-- Returns: array of { bufnr, name, line_count, modified, changedtick }
-- for every currently visible buffer.
local chan, _, setup_autocmds = ...
assert(type(chan) == 'number', 'buffer_cache: channel id (arg 1) required')

_G._neoboss_buf_cache = _G._neoboss_buf_cache or {}
local state = _G._neoboss_buf_cache[chan]
if not state then
  state = { next_gen = 0, bufs = {} }
  _G._neoboss_buf_cache[chan] = state
end

local function try_attach(buf)
  if state.bufs[buf] ~= nil then
    return true
  end
  state.next_gen = state.next_gen + 1
  local gen = state.next_gen
  state.bufs[buf] = gen

  local ok, attached_ok = pcall(vim.api.nvim_buf_attach, buf, false, {
    on_lines = function(_, b, tick, firstline, lastline, new_lastline)
      if state.bufs[b] ~= gen then
        return true
      end
      if tick == nil then
        local ok_t, t = pcall(vim.api.nvim_buf_get_changedtick, b)
        if ok_t then
          tick = t
        end
      end
      -- In-process Lua on_lines receives (event, buf, tick, firstline, lastline, new_lastline, byte_size).
      -- Replacement line count is new_lastline - firstline.
      local new_line_count = new_lastline - firstline
      pcall(vim.rpcnotify, chan, 'neoboss_buf_lines', b, tick, firstline, lastline, new_line_count)
    end,
    on_changedtick = function(_, b, tick)
      if state.bufs[b] ~= gen then
        return true
      end
      pcall(vim.rpcnotify, chan, 'neoboss_buf_tick', b, tick)
    end,
    on_detach = function(_, b)
      if state.bufs[b] == gen then
        state.bufs[b] = nil
        pcall(vim.rpcnotify, chan, 'neoboss_buf_detach', b)
      end
    end,
  })
  if not (ok and attached_ok) then
    state.bufs[buf] = nil
    return false
  end
  return true
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

-- Mark non-visible buffers inactive so their callbacks return true and detach.
for buf, _ in pairs(state.bufs) do
  if not visible[buf] then
    state.bufs[buf] = nil
  end
end

if setup_autocmds then
  local group = vim.api.nvim_create_augroup('NeobossBufferCache_' .. chan, { clear = true })
  vim.api.nvim_create_autocmd(
    {
      'BufEnter',
      'WinEnter',
      'WinClosed',
      'BufDelete',
      'BufWipeout',
      'BufWritePost',
      'BufModifiedSet',
      'BufFilePost',
      'BufReadPost',
    },
    {
      group = group,
      callback = function()
        pcall(vim.rpcnotify, chan, 'neoboss_buf_visibility')
      end,
    }
  )
end

return result
