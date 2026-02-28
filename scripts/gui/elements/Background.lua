local mp = require 'mp'
local Element = require 'elements.Element'
local Background = setmetatable({}, {__index = Element})
Background.__index = Background

function Background.new(state, opts)
    local self = Element.new(state, opts)
    self._cache = nil
    self._cache_w = 0
    self._cache_h = 0
    return setmetatable(self, Background)
end

function Background:_build_cache()
    local w, h = self.state.w, self.state.h
    local box_height = self.opts.box_height
    
    local pixel_step = 4
    local num_strips = math.floor(box_height / pixel_step)
    
    local alpha_bottom = 0x20
    local alpha_top = 0xFF
    
    local parts = {}
    local n = 0
    
    for i = 0, num_strips - 1 do
        local t = i / num_strips
        local eased_t = 1 - (1 - t) * (1 - t)
        local alpha = math.floor(alpha_bottom + (alpha_top - alpha_bottom) * eased_t)
        local alpha_hex = string.format("%02X", alpha)
        
        local strip_bottom = h - (i * pixel_step)
        local strip_top = strip_bottom - pixel_step
        
        n = n + 1
        parts[n] = string.format(
            "{\\pos(0,0)\\r\\shad0\\bord0\\an7}{\\c&H000000&\\alpha&H%s&}{\\p1}m 0 %d l %d %d %d %d 0 %d{\\p0}",
            alpha_hex, strip_top, w, strip_top, w, strip_bottom, strip_bottom
        )
    end
    
    self._cache = "\n" .. table.concat(parts, "\n")
    self._cache_w = w
    self._cache_h = h
end

function Background:draw(ass)
    if not self._cache or self._cache_w ~= self.state.w or self._cache_h ~= self.state.h then
        self:_build_cache()
    end
    ass:append(self._cache)
end

function Background:handle_input(event, x, y)
    local box_top = self.state.h - self.opts.box_height
    local in_control_area = y >= box_top
    
    if event == "move" then
        if in_control_area or self.state.dragging then
            if not self.state.control_area_active then
                self.state.control_area_active = true
                mp.set_property("window-dragging", "no")
            end
        else
            if self.state.control_area_active then
                self.state.control_area_active = false
                mp.set_property("window-dragging", "yes")
            end
        end
        return false
    end
    
    return false
end

return Background