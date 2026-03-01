local mp = require 'mp' 
local Element = require 'elements.Element'
local Subs = setmetatable({}, {__index = Element})
Subs.__index = Subs

local BTN_W, BTN_H = 36, 24

function Subs.new(state, opts)
    local self = Element.new(state, opts)
    self.show_menu = false
    self.sub_tracks = {}
    self.current_sub = 0
    self.scroll_offset = 0
    self.max_visible = 8
    return setmetatable(self, Subs)
end

function Subs:update_tracks()
    self.sub_tracks = {}
    self.current_sub = 0
    local tl = mp.get_property_native("track-list", {})
    for _, t in ipairs(tl) do
        if t.type == "sub" then
            local lbl = ""
            if t.lang and t.lang ~= "" then lbl = t.lang:upper() end
            if t.title and t.title ~= "" then
                lbl = lbl ~= "" and (lbl .. " — " .. t.title) or t.title
            end
            if lbl == "" then lbl = "Track " .. t.id end
            self.sub_tracks[#self.sub_tracks + 1] = {
                id = t.id, label = lbl, selected = t.selected or false
            }
            if t.selected then self.current_sub = t.id end
        end
    end
    local max_off = math.max(0, #self.sub_tracks - self.max_visible)
    self.scroll_offset = math.max(0, math.min(self.scroll_offset, max_off))
end

function Subs:_btn_pos()
    local cy = self.state.h - self.opts.controls_y_offset
    local bx = self.state.w / 2 - 130
    return bx, cy
end

function Subs:_menu_geo()
    local bx, cy = self:_btn_pos()
    local fs = self.opts.subtitle_font_size
    local item_h = fs + 18
    local pad = 16
    local menu_w = 340
    local visible = math.min(#self.sub_tracks, self.max_visible)
    local menu_h = (visible + 1) * item_h + pad * 2
    local menu_x = bx
    local menu_y = cy - BTN_H / 2 - menu_h - 12
    return menu_x, menu_y, menu_w, menu_h, item_h, pad, fs
end

function Subs:draw(ass)
    local bx, cy = self:_btn_pos()
    self:update_tracks()
    local active = self.current_sub > 0
    local font = self.opts.font

    -- CC button background (centered at cy)
    ass:new_event()
    ass:pos(bx + BTN_W / 2, cy)
    ass:an(5)
    ass:append("{\\bord1\\shad0\\3c&H444444&}")
    ass:append(active
        and "{\\1c&HFFFFFF&\\alpha&H50&}"
        or  "{\\1c&H333333&\\alpha&H40&}")
    ass:draw_start()
    ass:round_rect_cw(-BTN_W/2, -BTN_H/2, BTN_W/2, BTN_H/2, 4)
    ass:draw_stop()

    -- CC text (centered at cy)
    ass:new_event()
    ass:pos(bx + BTN_W / 2, cy)
    ass:an(5)
    ass:append(string.format(
        "{\\fn%s\\fsp1\\b1\\fs14\\bord1\\shad0\\1c&H%s&\\3c&H000000&}",
        font, active and "FFFFFF" or "AAAAAA"))
    ass:append("CC")

    if self.show_menu then self:_draw_menu(ass) end
end

function Subs:_draw_menu(ass)
    local mx, my, mw, mh, ih, pad, fs = self:_menu_geo()
    local font = self.opts.font

    -- Dark background
    ass:new_event()
    ass:pos(mx, my)
    ass:an(7)
    ass:append("{\\bord1\\shad4\\3c&H000000&\\4c&H000000&\\1c&H1A1A1A&\\alpha&H08&}")
    ass:draw_start()
    ass:round_rect_cw(0, 0, mw, mh, 10)
    ass:draw_stop()

    -- "Disabled" row
    local ry = my + pad + ih / 2
    local marker = self.current_sub == 0 and "●" or "○"
    local col    = self.current_sub == 0 and "44AAFF" or "DDDDDD"
    ass:new_event()
    ass:pos(mx + pad, ry)
    ass:an(4)
    ass:append(string.format(
        "{\\fn%s\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H000000&}", font, fs, col))
    ass:append(marker .. "  Disabled")

    -- Separator
    ass:new_event()
    ass:pos(mx + pad, my + pad + ih)
    ass:an(7)
    ass:append("{\\bord0\\shad0\\c&H444444&}")
    ass:draw_start()
    ass:rect_cw(0, 0, mw - pad * 2, 1)
    ass:draw_stop()

    -- Subtitle rows (scrolled window)
    local vis_start = self.scroll_offset + 1
    local vis_end   = math.min(#self.sub_tracks, self.scroll_offset + self.max_visible)

    for vi = vis_start, vis_end do
        local t = self.sub_tracks[vi]
        local idx = vi - vis_start + 1
        local item_y = my + pad + idx * ih + ih / 2
        marker = t.selected and "●" or "○"
        col    = t.selected and "44AAFF" or "DDDDDD"
        ass:new_event()
        ass:pos(mx + pad, item_y)
        ass:an(4)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H000000&}", font, fs, col))
        -- Truncate very long labels
        local label = t.label
        if #label > 40 then label = label:sub(1, 37) .. "..." end
        ass:append(string.format("%s  %s", marker, label))
    end

    -- Scroll indicators
    local has_scroll = #self.sub_tracks > self.max_visible
    if has_scroll then
        if self.scroll_offset > 0 then
            ass:new_event()
            ass:pos(mx + mw - pad, my + pad + ih / 2)
            ass:an(6)
            ass:append(string.format(
                "{\\fn%s\\fs%d\\bord1\\shad0\\1c&H888888&\\3c&H000000&}", font, fs - 2))
            ass:append("▲")
        end
        if vis_end < #self.sub_tracks then
            ass:new_event()
            ass:pos(mx + mw - pad, my + mh - pad)
            ass:an(6)
            ass:append(string.format(
                "{\\fn%s\\fs%d\\bord1\\shad0\\1c&H888888&\\3c&H000000&}", font, fs - 2))
            ass:append("▼")
        end
    end
end

function Subs:handle_input(event, x, y)
    local bx, cy = self:_btn_pos()

    if event == "down" then
        if x >= bx - 8 and x <= bx + BTN_W + 8
           and y >= cy - BTN_H / 2 - 8 and y <= cy + BTN_H / 2 + 8 then
            self:update_tracks()
            self.show_menu = not self.show_menu
            self.scroll_offset = 0
            return true
        end
        if self.show_menu then
            local mx, my, mw, mh, ih, pad = self:_menu_geo()
            if x >= mx and x <= mx + mw and y >= my and y <= my + mh then
                local ry = y - my - pad
                local idx = math.floor(ry / ih)
                if idx == 0 then
                    mp.set_property("sid", "no")
                    self.current_sub = 0
                else
                    local real = idx + self.scroll_offset
                    if real >= 1 and real <= #self.sub_tracks then
                        mp.set_property_number("sid", self.sub_tracks[real].id)
                        self.current_sub = self.sub_tracks[real].id
                    end
                end
                self.show_menu = false
                return true
            else
                self.show_menu = false
                return true
            end
        end

    elseif event == "scroll_up" then
        if self.show_menu and self.scroll_offset > 0 then
            self.scroll_offset = self.scroll_offset - 1
            return true
        end
    elseif event == "scroll_down" then
        if self.show_menu then
            local max_off = math.max(0, #self.sub_tracks - self.max_visible)
            if self.scroll_offset < max_off then
                self.scroll_offset = self.scroll_offset + 1
                return true
            end
        end
    end
    return false
end

return Subs
