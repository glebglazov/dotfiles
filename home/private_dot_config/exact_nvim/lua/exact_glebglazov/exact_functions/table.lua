local M = {}

local metatable = {
  __add = function(lhs, rhs)
    for k, v in pairs(rhs) do
      lhs[k] = v
    end

    return lhs
  end
}

M.new = function(initial_table)
  local instance = {}
  setmetatable(instance, metatable)

  return instance + initial_table
end

return M
