local mp = require 'mp' 
local Element = require 'elements.Element'
local Subs = setmetatable({}, {__index = Element})
Subs.__index = Subs

local BTN_W, BTN_H = 28, 18
local HITBOX_PADDING = 8

function Subs.new(state, opts)
    local self = Element.new(state, opts)
    self.show_menu = false
    self.sub_tracks = {}
    self.current_sub = 0
    return setmetatable(self, Subs)
end

function Subs:update_tracks()
    self.sub_tracks = {}
    local track_list = mp.get_property_native("track-list", {})
    for _, track in ipairs(track_list) do
        if track.type == "sub" then
            table.insert(self.sub_tracks, {
                id = track.id,
                title = track.title or track.lang or ("Track " .. track.id),
                lang = track.lang or "",
                selected = track.selected or false
            })
            if track.selected then
                self.current_sub = track.id
            end
        end
    end
end

function Subs:draw(ass)
    local w, h = self.state.w, self.state.h
    
    -- Position: left of center controls
    local btn_x = self.state.w / 2 - 120
    local btn_y = h - self.opts.controls_y_offset - BTN_H/2
    
    self:update_tracks()
    local has_active_sub = self.current_sub > 0
    
    -- CC button background
    ass:new_event()
    ass:append(string.format("{\\pos(%d,%d)\\an7\\bord0\\shad0}", btn_x, btn_y))
    if has_active_sub then
        ass:append("{\\c&HFFFFFF&\\alpha&H80&}") 
    else
        ass:append("{\\c&H404040&\\alpha&H40&}")
    end
    ass:draw_start()
    ass:round_rect_cw(0, 0, BTN_W, BTN_H, 3)
    ass:draw_stop()
    
    -- CC text
    local center_x = btn_x + (BTN_W / 2)
    local center_y = btn_y + (BTN_H / 2)
    
    ass:new_event()
    ass:append(string.format("{\\pos(%d,%d)\\an5}", center_x, center_y))
    ass:append("{\\fnSegoe UI Semibold\\fs10\\bord0\\shad0\\c&HFFFFFF&}")
    ass:append("CC")
    
    if self.show_menu and #self.sub_tracks > 0 then
        self:draw_menu(ass, btn_x, btn_y)
    end
end

function Subs:draw_menu(ass, btn_x, btn_y)
    local menu_w = 180
    local item_h = 26
    local menu_h = (#self.sub_tracks + 1) * item_h + 10
    local menu_x = btn_x
    local menu_y = btn_y - menu_h - 5
    
    -- Menu background
    ass:new_event()
    ass:append(string.format("{\\pos(%d,%d)\\an7\\bord0\\shad0}", menu_x, menu_y))
    ass:append("{\\c&H1A1A1A&\\alpha&H20&}")
    ass:draw_start()
    ass:round_rect_cw(0, 0, menu_w, menu_h, 6)
    ass:draw_stop()
    
    -- Disable option
    local item_y = menu_y + 5
    ass:new_event()
    ass:append(string.format("{\\pos(%d,%d)\\an4}", menu_x + 10, item_y + item_h/2))
    if self.current_sub == 0 then
        ass:append("{\\fnSegoe UI\\fs12\\bord0\\shad0\\c&H00AAFF&}")
    else
        ass:append("{\\fnSegoe UI\\fs12\\bord0\\shad0\\c&HFFFFFF&}")
    end
    ass:append("✕ Disable subtitles")
    
    -- Subtitle tracks
    for i, track in ipairs(self.sub_tracks) do
        item_y = menu_y + 5 + i * item_h
        ass:new_event()
        ass:append(string.format("{\\pos(%d,%d)\\an4}", menu_x + 10, item_y + item_h/2))
        if track.selected then
            ass:append("{\\fnSegoe UI\\fs12\\bord0\\shad0\\c&H00AAFF&}")
        else
            ass:append("{\\fnSegoe UI\\fs12\\bord0\\shad0\\c&HFFFFFF&}")
        end
        local display = track.title
        if track.lang ~= "" and track.lang ~= track.title then
            display = display .. " (" .. track.lang .. ")"
        end
        ass:append(display)
    end
end

function Subs:handle_input(event, x, y)
    local h = self.state.h
    local btn_x = self.state.w / 2 - 120
    local btn_y = h - self.opts.controls_y_offset
    
    if event == "down" then
        local pad = HITBOX_PADDING
        if x >= btn_x - pad and x <= btn_x + BTN_W + pad and
           y >= btn_y - BTN_H/2 - pad and y <= btn_y + BTN_H/2 + pad then
            self:update_tracks()
            self.show_menu = not self.show_menu
            return true
        end
        
        if self.show_menu then
            local menu_w = 180
            local item_h = 26
            local menu_h = (#self.sub_tracks + 1) * item_h + 10
            local menu_x = btn_x
            local menu_y = btn_y - BTN_H/2 - menu_h - 5
            
            if x >= menu_x and x <= menu_x + menu_w and
               y >= menu_y and y <= menu_y + menu_h then
                local relative_y = y - menu_y - 5
                local option_index = math.floor(relative_y / item_h)
                
                if option_index == 0 then
                    mp.set_property("sid", "no")
                    self.current_sub = 0
                elseif option_index > 0 and option_index <= #self.sub_tracks then
                    local track = self.sub_tracks[option_index]
                    mp.set_property_number("sid", track.id)
                    self.current_sub = track.id
                end
                
                self.show_menu = false
                return true
            else
                self.show_menu = false
                return true
            end
        end
    end
    
    return false
end

return Subs
