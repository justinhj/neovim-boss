local target, start_line, end_line = ...
local b, err = resolve_buf(target)
if not b then
  return { error = err }
end
local total = vim.api.nvim_buf_line_count(b)
local s = (type(start_line) == "number") and start_line or 1
local e = (type(end_line) == "number") and end_line or total
if s > e then s, e = e, s end
if s < 1 then s = 1 end
if e > total then e = total end
if total == 0 or s > total then
  return { lines = {}, total_lines = total }
end
local lines = vim.api.nvim_buf_get_lines(b, s - 1, e, false)
local numbered = {}
for i, l in ipairs(lines) do
  table.insert(numbered, string.format("%d: %s", s + i - 1, l))
end
return {
  lines = numbered,
  total_lines = total,
}
