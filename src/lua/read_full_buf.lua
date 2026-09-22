local target = ...
local b, err = resolve_buf(target)
if not b then
  return { error = err }
end
local total = vim.api.nvim_buf_line_count(b)
local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
local numbered = {}
for i, l in ipairs(lines) do
  table.insert(numbered, string.format("%d: %s", i, l))
end
return {
  lines = numbered,
  total_lines = total,
}
