local mp = require 'mp'
local Element = require 'elements.Element'
local SkipButtons = setmetatable({}, {__index = Element})
SkipButtons.__index = SkipButtons

local SKIP_OFFSET_X = 55
local HITBOX = 22

function SkipButtons.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, SkipButtons)
end

function SkipButtons:handle_input(event, x, y)
    if event ~= "down" then return false end
    local cy = self.state.h - self.opts.controls_y_offset
    local cx = self.state.w / 2
    if y < self.state.h - self.opts.box_height then return false end

    if math.abs(x - (cx - SKIP_OFFSET_X)) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("seek", tostring(-self.opts.seek_step), "relative", "exact")
        return true
    end
    if math.abs(x - (cx + SKIP_OFFSET_X)) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("seek", tostring(self.opts.seek_step), "relative", "exact")
        return true
    end
    return false
end

function SkipButtons:draw(ass)
    local cy = self.state.h - self.opts.controls_y_offset
    local cx = self.state.w / 2
    local s = 9  -- arrow size

    -- ◀◀ Backward (absolute coords)
    local bx = cx - SKIP_OFFSET_X
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    -- First arrow
    ass:move_to(bx + 2, cy - s)
    ass:line_to(bx - s + 2, cy)
    ass:line_to(bx + 2, cy + s)
    ass:line_to(bx + 2, cy - s)
    -- Second arrow
    ass:move_to(bx - s + 4, cy - s)
    ass:line_to(bx - s*2 + 4, cy)
    ass:line_to(bx - s + 4, cy + s)
    ass:line_to(bx - s + 4, cy - s)
    ass:draw_stop()

    -- ▶▶ Forward (absolute coords)
    local fx = cx + SKIP_OFFSET_X
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    ass:move_to(fx - 2, cy - s)
    ass:line_to(fx + s - 2, cy)
    ass:line_to(fx - 2, cy + s)
    ass:line_to(fx - 2, cy - s)
    ass:move_to(fx + s - 4, cy - s)
    ass:line_to(fx + s*2 - 4, cy)
    ass:line_to(fx + s - 4, cy + s)
    ass:line_to(fx + s - 4, cy - s)
    ass:draw_stop()
end

return SkipButtons
