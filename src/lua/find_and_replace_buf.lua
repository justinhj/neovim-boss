local target, find_str, replace_str = ...
if find_str == nil or find_str == "" then
  return { error = "find string cannot be empty" }
end
if replace_str == nil then replace_str = "" end
local b, err = find_or_create_buf(target)
if not b then
  return { error = err }
end
local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
local text = table.concat(lines, "\n")
local s, e = string.find(text, find_str, 1, true)
if not s then
  return { error = "find string not found in buffer" }
end
if string.find(text, find_str, e + 1, true) then
  return { error = "find string matches multiple locations; add context to make it unique" }
end
local before = text:sub(1, s - 1)
local start_line = select(2, before:gsub("\n", ""))
local end_line = start_line + select(2, find_str:gsub("\n", ""))
local prefix = before:match("[^\n]*$") or ""
local suffix = (text:sub(e + 1)):match("^[^\n]*") or ""
local replacement = prefix .. replace_str .. suffix
local new_lines = vim.split(replacement, "\n", { plain = true })
-- Execute within buffer context and touch &undolevels to force an undo sequence
-- checkpoint (u_newheader), ensuring discrete undo steps even for background buffers.
vim.api.nvim_buf_call(b, function()
  vim.cmd("let &undolevels = &undolevels")
  vim.api.nvim_buf_set_lines(b, start_line, end_line + 1, false, new_lines)
end)
return {
  start_line = start_line + 1,
  lines_removed = end_line - start_line + 1,
  lines_added = #new_lines,
  total_lines = vim.api.nvim_buf_line_count(b),
}
