local function ensure_no_swap_prompt()
  if not vim.o.shortmess:find("A", 1, true) then
    vim.o.shortmess = vim.o.shortmess .. "A"
  end
end

local function resolve_buf(target)
  ensure_no_swap_prompt()
  local b
  if type(target) == "number" then
    b = (target == 0) and vim.api.nvim_get_current_buf() or target
  elseif type(target) == "string" then
    if target == "" then
      b = vim.api.nvim_get_current_buf()
    else
      b = vim.fn.bufnr(target)
      if b == -1 and tonumber(target) then
        local num = tonumber(target)
        if vim.api.nvim_buf_is_valid(num) then
          b = num
        end
      end
    end
  else
    return nil, "Expected buffer name or number"
  end
  if b == -1 or not vim.api.nvim_buf_is_valid(b) then
    return nil, "Buffer not found: " .. tostring(target)
  end
  if not vim.api.nvim_buf_is_loaded(b) then
    pcall(vim.fn.bufload, b)
  end
  return b
end

local function find_or_create_buf(target)
  ensure_no_swap_prompt()
  local b
  if type(target) == "number" then
    b = (target == 0) and vim.api.nvim_get_current_buf() or target
    if not vim.api.nvim_buf_is_valid(b) then
      return nil, "Invalid buffer number: " .. tostring(target)
    end
  elseif type(target) == "string" then
    if target == "" then
      b = vim.api.nvim_get_current_buf()
    else
      b = vim.fn.bufnr(target)
      if b == -1 and tonumber(target) then
        local num = tonumber(target)
        if vim.api.nvim_buf_is_valid(num) then
          b = num
        end
      end
      if b == -1 then
        b = vim.fn.bufadd(target)
        pcall(function() vim.bo[b].swapfile = false end)
        pcall(vim.fn.bufload, b)
        pcall(function() vim.bo[b].buflisted = true end)
      end
    end
  else
    return nil, "Expected buffer name or number"
  end
  if b == -1 or not vim.api.nvim_buf_is_valid(b) then
    return nil, "Buffer not found: " .. tostring(target)
  end
  if not vim.api.nvim_buf_is_loaded(b) then
    pcall(vim.fn.bufload, b)
  end
  return b
end
