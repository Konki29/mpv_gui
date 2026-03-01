local mp = require 'mp'
local Element = require 'elements.Element'
local WindowControls = setmetatable({}, {__index = Element})
WindowControls.__index = WindowControls

local BTN_GAP = 30
local HITBOX = 20

function WindowControls.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, WindowControls)
end

function WindowControls:handle_input(event, x, y)
    if event ~= "down" then return false end
    if not self.opts.show_window_controls then return false end
    local cy = self.state.h - self.opts.controls_y_offset
    if y < self.state.h - self.opts.box_height then return false end
    local w = self.state.w

    if math.abs(x - (w - 25)) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "fullscreen")
        return true
    end
    if math.abs(x - (w - 25 - BTN_GAP)) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "window-minimized")
        return true
    end
    return false
end

function WindowControls:draw(ass)
    if not self.opts.show_window_controls then return end
    local cy = self.state.h - self.opts.controls_y_offset
    local w = self.state.w
    local s = 7
    local t = 2

    -- Fullscreen icon (absolute coords)
    local fs_x = w - 25
    local is_fs = mp.get_property_bool("fullscreen", false)

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append("{\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:draw_start()
    if is_fs then
        -- Shrink icon
        ass:rect_cw(fs_x - s, cy - s, fs_x - s + 4, cy - s + t)
        ass:rect_cw(fs_x - s, cy - s, fs_x - s + t, cy - s + 4)
        ass:rect_cw(fs_x + s - 4, cy + s - t, fs_x + s, cy + s)
        ass:rect_cw(fs_x + s - t, cy + s - 4, fs_x + s, cy + s)
    else
        -- Expand corners
        ass:rect_cw(fs_x - s, cy - s, fs_x - s + 4, cy - s + t)
        ass:rect_cw(fs_x - s, cy - s, fs_x - s + t, cy - s + 4)
        ass:rect_cw(fs_x + s - 4, cy - s, fs_x + s, cy - s + t)
        ass:rect_cw(fs_x + s - t, cy - s, fs_x + s, cy - s + 4)
        ass:rect_cw(fs_x - s, cy + s - t, fs_x - s + 4, cy + s)
        ass:rect_cw(fs_x - s, cy + s - 4, fs_x - s + t, cy + s)
        ass:rect_cw(fs_x + s - 4, cy + s - t, fs_x + s, cy + s)
        ass:rect_cw(fs_x + s - t, cy + s - 4, fs_x + s, cy + s)
    end
    ass:draw_stop()

    -- Minimize icon (absolute coords)
    local min_x = w - 25 - BTN_GAP
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append("{\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:draw_start()
    ass:rect_cw(min_x - 7, cy - 1, min_x + 7, cy + 1)
    ass:draw_stop()
end

return WindowControls
