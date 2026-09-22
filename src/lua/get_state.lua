local brief, target_buf = ...
local cwd = vim.fn.getcwd()

local function format_path(p)
  if not p or p == "" then return "" end
  p = (vim.fs and vim.fs.normalize) and vim.fs.normalize(p) or p
  local prefix = cwd .. "/"
  if p:sub(1, #prefix) == prefix then
    return p:sub(#prefix + 1)
  elseif p == cwd then
    return "."
  else
    return p
  end
end

local raw_mode = vim.api.nvim_get_mode().mode
local mode_map = {
  n = "normal", no = "normal", nov = "normal", ["noV"] = "normal", ["no\22"] = "normal",
  i = "insert", ic = "insert", ix = "insert",
  v = "visual", V = "visual_line", ["\22"] = "visual_block",
  s = "select", S = "select_line", ["\19"] = "select_block",
  R = "replace", Rc = "replace", Rx = "replace", Rv = "replace",
  c = "command", cv = "command", ce = "command",
  t = "terminal",
}
local mode = mode_map[raw_mode] or raw_mode

local all_bufs = vim.fn.getbufinfo()
local listed_bufs = {}
local modified_bufs = {}
local open_terminals = {}

for _, b in ipairs(all_bufs) do
  local p = format_path(b.name)
  if b.listed == 1 then table.insert(listed_bufs, p) end
  if b.changed == 1 then table.insert(modified_bufs, p) end
  local bt = vim.bo[b.bufnr].buftype
  if bt == "terminal" then table.insert(open_terminals, { id = b.bufnr, name = p }) end
end

local current_win = vim.api.nvim_get_current_win()
local alt_winnr = vim.fn.winnr("#")
local alt_win = alt_winnr > 0 and vim.fn.win_getid(alt_winnr) or nil

if target_buf and target_buf ~= vim.NIL then
  local tbnr = vim.fn.bufnr(target_buf)
  if tbnr ~= -1 then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(w) == tbnr then
        current_win = w
        break
      end
    end
  end
end

local function get_win_info(w, is_active)
  local b = vim.api.nvim_win_get_buf(w)
  local bname = format_path(vim.api.nvim_buf_get_name(b))
  local bt = vim.bo[b].buftype
  if bt == "" then bt = "file" end
  local ft = vim.bo[b].filetype
  local total_lines = vim.api.nvim_buf_line_count(b)
  local cursor = vim.api.nvim_win_get_cursor(w)
  local cur_line = (total_lines > 0) and math.max(1, cursor[1]) or 0
  local cur_col = cursor[2]

  local is_visual = is_active and (mode == "visual" or mode == "visual_line" or mode == "visual_block")
  local s_line, s_col, e_line, e_col
  if is_visual then
    local vpos = vim.fn.getpos("v")
    local cpos = vim.fn.getpos(".")
    s_line, s_col = vpos[2], vpos[3]
    e_line, e_col = cpos[2], cpos[3]
    if s_line > e_line or (s_line == e_line and s_col > e_col) then
      s_line, e_line = e_line, s_line
      s_col, e_col = e_col, s_col
    end
  end

  local ctx_start, ctx_end
  if is_visual and s_line and e_line then
    ctx_start = math.max(1, s_line - 2)
    ctx_end = math.min(total_lines, e_line + 2)
  else
    ctx_start = math.max(1, cur_line - 3)
    ctx_end = math.min(total_lines, cur_line + 2)
  end

  local context = {}
  if total_lines > 0 and ctx_start <= ctx_end then
    local lines = vim.api.nvim_buf_get_lines(b, ctx_start - 1, ctx_end, false)
    for i, l in ipairs(lines) do
      table.insert(context, string.format("%d: %s", ctx_start + i - 1, l))
    end
  end

  local role = is_active and "active" or (w == alt_win and "alternate" or nil)

  local win_data = {
    id = w,
    buffer = bname,
    role = role,
    buftype = bt,
    filetype = ft,
    total_lines = total_lines,
    line = cur_line,
    col = cur_col,
    context = context,
  }

  if not brief then
    if is_visual and s_line and e_line then
      win_data.selection = {
        start_line = s_line,
        end_line = e_line,
        start_col = s_col,
        end_col = e_col,
      }
    else
      win_data.selection = nil
    end

    local folds = {}
    local l = 1
    while l <= total_lines do
      local f_start = vim.fn.foldclosed(l)
      if f_start ~= -1 then
        local f_end = vim.fn.foldclosedend(l)
        table.insert(folds, { start_line = f_start, end_line = f_end })
        l = f_end + 1
      else
        l = l + 1
      end
    end
    win_data.folds = folds

    local marks = {}
    for code = string.byte("a"), string.byte("z") do
      local char = string.char(code)
      local mpos = vim.api.nvim_buf_get_mark(b, char)
      if mpos and mpos[1] > 0 then
        table.insert(marks, { mark = char, line = mpos[1], col = mpos[2] })
      end
    end
    win_data.marks = marks

    win_data.indent = {
      tabstop = vim.bo[b].tabstop,
      shiftwidth = vim.bo[b].shiftwidth,
      expandtab = vim.bo[b].expandtab,
    }

    local diags = (vim.diagnostic and vim.diagnostic.get) and vim.diagnostic.get(b) or {}
    local err_cnt, warn_cnt, info_cnt, hint_cnt = 0, 0, 0, 0
    for _, d in ipairs(diags) do
      if d.severity == vim.diagnostic.severity.ERROR then err_cnt = err_cnt + 1
      elseif d.severity == vim.diagnostic.severity.WARN then warn_cnt = warn_cnt + 1
      elseif d.severity == vim.diagnostic.severity.INFO then info_cnt = info_cnt + 1
      elseif d.severity == vim.diagnostic.severity.HINT then hint_cnt = hint_cnt + 1
      end
    end
    win_data.diagnostics_summary = {
      error = err_cnt,
      warning = warn_cnt,
      info = info_cnt,
      hint = hint_cnt,
    }

    win_data.mcp_highlights = {}
    win_data.mcp_virtual_text = {}
  end

  return win_data
end

local tab_count = vim.fn.tabpagenr("$")
local current_tab = vim.fn.tabpagenr()

if brief then
  local act_data = get_win_info(current_win, true)
  local alt_data = alt_win and { id = alt_win, buffer = format_path(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(alt_win))) } or nil
  return {
    mode = mode,
    cwd = cwd,
    buffers = listed_bufs,
    modified_buffers = modified_bufs,
    active_window = act_data,
    alternate_window = alt_data,
    open_terminals = open_terminals,
    tab_count = tab_count,
    current_tab = current_tab,
  }
else
  local wins = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    table.insert(wins, get_win_info(w, w == current_win))
  end
  return {
    mode = mode,
    cwd = cwd,
    buffers = listed_bufs,
    modified_buffers = modified_bufs,
    windows = wins,
    tab_count = tab_count,
    current_tab = current_tab,
  }
end
