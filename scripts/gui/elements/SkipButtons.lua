local mp = require 'mp'
local Element = require 'elements.Element'
local SkipButtons = setmetatable({}, {__index = Element})
SkipButtons.__index = SkipButtons

local SKIP_SIZE = 8
local SKIP_OFFSET_X = 50
local HITBOX_RADIUS = 20

function SkipButtons.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, SkipButtons)
end

function SkipButtons:handle_input(event, x, y)
    if event ~= "down" then return false end
    
    local cy = self.state.h - self.opts.controls_y_offset
    local cx = self.state.w / 2
    local box_top = self.state.h - self.opts.box_height
    if y < box_top then return false end
    
    -- Backward
    local bx = cx - SKIP_OFFSET_X
    if math.abs(x - bx) < HITBOX_RADIUS and math.abs(y - cy) < HITBOX_RADIUS then
        mp.commandv("seek", tostring(-self.opts.seek_step), "relative", "exact")
        return true
    end
    
    -- Forward
    local fx = cx + SKIP_OFFSET_X
    if math.abs(x - fx) < HITBOX_RADIUS and math.abs(y - cy) < HITBOX_RADIUS then
        mp.commandv("seek", tostring(self.opts.seek_step), "relative", "exact")
        return true
    end
    
    return false
end

function SkipButtons:draw(ass)
    local cy = self.state.h - self.opts.controls_y_offset
    local cx = self.state.w / 2
    local s = SKIP_SIZE
    
    -- ◀◀ Backward
    local bx = cx - SKIP_OFFSET_X
    ass:new_event()
    ass:pos(bx, cy)
    ass:an(5)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    ass:move_to(2, -s)
    ass:line_to(-s + 2, 0)
    ass:line_to(2, s)
    ass:line_to(2, -s)
    ass:move_to(-s + 2, -s)
    ass:line_to(-s*2 + 2, 0)
    ass:line_to(-s + 2, s)
    ass:line_to(-s + 2, -s)
    ass:draw_stop()
    
    -- ▶▶ Forward
    local fx = cx + SKIP_OFFSET_X
    ass:new_event()
    ass:pos(fx, cy)
    ass:an(5)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    ass:move_to(-2, -s)
    ass:line_to(s - 2, 0)
    ass:line_to(-2, s)
    ass:line_to(-2, -s)
    ass:move_to(s - 2, -s)
    ass:line_to(s*2 - 2, 0)
    ass:line_to(s - 2, s)
    ass:line_to(s - 2, -s)
    ass:draw_stop()
end

return SkipButtons
