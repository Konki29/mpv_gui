local mp = require 'mp'
local Element = require 'elements.Element'
local VolumeButton = setmetatable({}, {__index = Element})
VolumeButton.__index = VolumeButton

local HITBOX = 18
local VOL_STEP = 5

function VolumeButton.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, VolumeButton)
end

function VolumeButton:handle_input(event, x, y)
    if event ~= "down" then return false end
    
    local cy = self.state.h - self.opts.controls_y_offset
    local box_top = self.state.h - self.opts.box_height
    if y < box_top then return false end
    
    -- Speaker icon: left side, mute toggle
    local spk_x = self.state.w / 2 + 120
    if math.abs(x - spk_x) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "mute")
        return true
    end
    
    -- [+] button
    local plus_x = spk_x + 35
    if math.abs(x - plus_x) < 12 and math.abs(y - cy) < HITBOX then
        mp.commandv("add", "volume", tostring(VOL_STEP))
        return true
    end
    
    -- [-] button
    local minus_x = spk_x + 55
    if math.abs(x - minus_x) < 12 and math.abs(y - cy) < HITBOX then
        mp.commandv("add", "volume", tostring(-VOL_STEP))
        return true
    end
    
    return false
end

function VolumeButton:draw(ass)
    local cy = self.state.h - self.opts.controls_y_offset
    local vol = self.state.volume or 100
    local muted = self.state.muted or false
    local s = 10
    
    -- Position: right of center controls
    local spk_x = self.state.w / 2 + 120
    
    -- Speaker icon
    ass:new_event()
    ass:pos(spk_x, cy)
    ass:an(5)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", muted and "666666" or "FFFFFF"))
    ass:draw_start()
    ass:rect_cw(-s*0.3, -s*0.35, s*0.1, s*0.35)
    ass:move_to(s*0.1, -s*0.35)
    ass:line_to(s*0.5, -s*0.7)
    ass:line_to(s*0.5, s*0.7)
    ass:line_to(s*0.1, s*0.35)
    ass:line_to(s*0.1, -s*0.35)
    ass:draw_stop()
    
    -- Volume percentage
    ass:new_event()
    ass:pos(spk_x + 16, cy)
    ass:an(4)
    ass:append(string.format("{\\fnSegoe UI\\fs11\\bord0\\shad0\\c&H%s&}", muted and "666666" or "BBBBBB"))
    ass:append(string.format("%d", math.floor(vol)))
    
    -- [+] button
    ass:new_event()
    ass:pos(spk_x + 35, cy)
    ass:an(5)
    ass:append("{\\fnSegoe UI\\fs12\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:append("+")
    
    -- [-] button
    ass:new_event()
    ass:pos(spk_x + 55, cy)
    ass:an(5)
    ass:append("{\\fnSegoe UI\\fs12\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:append("−")
end

return VolumeButton
