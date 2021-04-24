local M = {}


local variable = {}
M.variable = variable

local syntax_mapping = {
  boolean = 'Boolean',
  String = 'String',
  int = 'Number',
  long = 'Number',
  double = 'Float',
  float = 'Float',
}


function variable.render_parent(var)
  if var.name then
    return variable.render_child(var, 0)
  end
  local syntax_group = var.type and syntax_mapping[var.type]
  if syntax_group then
    return var.result, {{syntax_group, 0, -1},}
  end
  return var.result
end

function variable.render_child(var, indent)
  indent = indent or 2
  local hl_regions = {
    {'Identifier', indent, #var.name + indent + 1}
  }
  local prefix = string.rep(' ', indent) .. var.name .. ': '
  local syntax_group = var.type and syntax_mapping[var.type]
  if syntax_group then
    table.insert(hl_regions, {syntax_group, #prefix, -1})
  end
  return prefix .. var.value, hl_regions
end

function variable.has_children(var)
  return (var.variables and #var.variables > 0) or var.variablesReference ~= 0
end

function variable.get_children(var)
  if vim.tbl_islist(var.variables) then
    return var.variables
  else
    return var.variables and vim.tbl_values(var.variables) or {}
  end
end

function variable.fetch_children(var, cb)
  local session = require('dap').session()
  if var.variables then
    cb(variable.get_children(var))
  elseif session then
    local params = { variablesReference = var.variablesReference }
    session:request('variables', params, function(err, resp)
      if err then
        M.append(err.message)
      else
        var.variables = resp.variables
        cb(resp.variables)
      end
    end)
  end
end

variable.tree_spec = {
  render_parent = variable.render_parent,
  render_child = variable.render_child,
  has_children = variable.has_children,
  get_children = variable.get_children,
  fetch_children = variable.fetch_children,
}


local scope = {}
M.scope = scope


function scope.render_parent(value)
  return value.name
end

scope.tree_spec = {
  render_parent = scope.render_parent,
  render_child = variable.render_child,
  has_children = variable.has_children,
  get_children = variable.get_children,
  fetch_children = variable.fetch_children
}


return M