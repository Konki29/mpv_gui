local Element = {}
Element.__index = Element

function Element.new(state, opts)
    local self = setmetatable({}, Element)
    self.state = state
    self.opts = opts
    return self
end

-- Abstract methods
function Element:draw(ass) 
end

-- Returns true if input was consumed
function Element:handle_input(event, x, y)
    return false
end

return Element
