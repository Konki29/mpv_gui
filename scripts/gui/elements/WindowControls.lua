local mp = require 'mp'
local Element = require 'elements.Element'
local WindowControls = setmetatable({}, {__index = Element})
WindowControls.__index = WindowControls

local BTN_SIZE = 20
local BTN_GAP = 12
local HITBOX = 20

function WindowControls.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, WindowControls)
end

function WindowControls:handle_input(event, x, y)
    if event ~= "down" then return false end
    if not self.opts.show_window_controls then return false end
    
    local cy = self.state.h - self.opts.controls_y_offset
    local box_top = self.state.h - self.opts.box_height
    if y < box_top then return false end
    
    local w = self.state.w
    
    -- Fullscreen button (rightmost)
    local fs_x = w - 25
    if math.abs(x - fs_x) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "fullscreen")
        return true
    end
    
    -- Minimize button
    local min_x = w - 25 - BTN_SIZE - BTN_GAP
    if math.abs(x - min_x) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "window-minimized")
        return true
    end
    
    return false
end

function WindowControls:draw(ass)
    if not self.opts.show_window_controls then return end
    
    local cy = self.state.h - self.opts.controls_y_offset
    local w = self.state.w
    local s = 7  -- icon scale
    
    -- Fullscreen toggle
    local fs_x = w - 25
    local is_fs = mp.get_property_bool("fullscreen", false)
    
    ass:new_event()
    ass:pos(fs_x, cy)
    ass:an(5)
    ass:append("{\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:draw_start()
    if is_fs then
        -- Shrink icon (two inward arrows)
        -- Top-left inward
        ass:move_to(-s, -s)
        ass:line_to(-s + 4, -s)
        ass:line_to(-s + 4, -s + 4)
        ass:line_to(-s, -s + 4)
        ass:line_to(-s, -s)
        -- Bottom-right inward
        ass:move_to(s, s)
        ass:line_to(s - 4, s)
        ass:line_to(s - 4, s - 4)
        ass:line_to(s, s - 4)
        ass:line_to(s, s)
    else
        -- Expand icon (four corners of a rectangle)
        local t = 2 -- thickness
        -- TL corner
        ass:rect_cw(-s, -s, -s + 4, -s + t)
        ass:rect_cw(-s, -s, -s + t, -s + 4)
        -- TR corner
        ass:rect_cw(s - 4, -s, s, -s + t)
        ass:rect_cw(s - t, -s, s, -s + 4)
        -- BL corner
        ass:rect_cw(-s, s - t, -s + 4, s)
        ass:rect_cw(-s, s - 4, -s + t, s)
        -- BR corner
        ass:rect_cw(s - 4, s - t, s, s)
        ass:rect_cw(s - t, s - 4, s, s)
    end
    ass:draw_stop()
    
    -- Minimize button
    local min_x = w - 25 - BTN_SIZE - BTN_GAP
    ass:new_event()
    ass:pos(min_x, cy)
    ass:an(5)
    ass:append("{\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:draw_start()
    -- Simple horizontal line
    ass:rect_cw(-s, -1, s, 1)
    ass:draw_stop()
end

return WindowControls
