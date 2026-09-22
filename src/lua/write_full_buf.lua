local target, content = ...
if content == nil then content = "" end
local b, err = find_or_create_buf(target)
if not b then
  return { error = err }
end
if content:sub(-1) == "\n" then
  content = content:sub(1, -2)
  if content:sub(-1) == "\r" then
    content = content:sub(1, -2)
  end
end
local new_lines = (content == "") and { "" } or vim.split(content, "\n", { plain = true })
vim.api.nvim_buf_set_lines(b, 0, -1, false, new_lines)
return {
  total_lines = vim.api.nvim_buf_line_count(b),
}
