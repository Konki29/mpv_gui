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
    self.scroll_offset = 0    -- scroll position for long lists
    self.max_visible = 8      -- max subtitle items visible at once
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
    -- Clamp scroll
    local max_off = math.max(0, #self.sub_tracks - self.max_visible)
    self.scroll_offset = math.max(0, math.min(self.scroll_offset, max_off))
end

-- ── Layout constants ──
function Subs:_btn_pos()
    local cy = self.state.h - self.opts.controls_y_offset
    local bx = self.state.w / 2 - 130
    return bx, cy
end

function Subs:_menu_geo()
    local bx, cy = self:_btn_pos()
    local fs = self.opts.subtitle_font_size + 4  -- ensure readable
    local item_h = fs + 16
    local pad = 14
    local menu_w = 320
    local visible = math.min(#self.sub_tracks, self.max_visible)
    local menu_h = (visible + 1) * item_h + pad * 2  -- +1 for "Off" row
    local menu_x = bx
    local menu_y = cy - BTN_H / 2 - menu_h - 10
    return menu_x, menu_y, menu_w, menu_h, item_h, pad, fs
end

-- ── Draw ──
function Subs:draw(ass)
    local bx, cy = self:_btn_pos()
    self:update_tracks()
    local active = self.current_sub > 0

    -- CC button bg
    ass:new_event()
    ass:pos(bx, cy - BTN_H / 2)
    ass:an(7)
    ass:append("{\\bord1\\shad0\\3c&H444444&}")
    ass:append(active
        and "{\\1c&HFFFFFF&\\alpha&H50&}"
        or  "{\\1c&H333333&\\alpha&H40&}")
    ass:draw_start()
    ass:round_rect_cw(0, 0, BTN_W, BTN_H, 4)
    ass:draw_stop()

    -- CC text
    ass:new_event()
    ass:pos(bx + BTN_W / 2, cy)
    ass:an(5)
    ass:append(string.format(
        "{\\fnSegoe UI Semibold\\fs14\\bord1\\shad0\\1c&H%s&\\3c&H000000&}",
        active and "FFFFFF" or "AAAAAA"))
    ass:append("CC")

    if self.show_menu then self:_draw_menu(ass) end
end

function Subs:_draw_menu(ass)
    local mx, my, mw, mh, ih, pad, fs = self:_menu_geo()
    local has_scroll = #self.sub_tracks > self.max_visible

    -- Dark background
    ass:new_event()
    ass:pos(mx, my)
    ass:an(7)
    ass:append("{\\bord1\\shad3\\3c&H000000&\\4c&H000000&\\1c&H1A1A1A&\\alpha&H10&}")
    ass:draw_start()
    ass:round_rect_cw(0, 0, mw, mh, 10)
    ass:draw_stop()

    -- Row 0: "Off" / "Disabled"
    local row_y = my + pad
    local marker = self.current_sub == 0 and "●" or "○"
    local col    = self.current_sub == 0 and "44AAFF" or "DDDDDD"
    ass:new_event()
    ass:pos(mx + pad, row_y + ih / 2)
    ass:an(4)
    ass:append(string.format(
        "{\\fnSegoe UI\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H000000&}", fs, col))
    ass:append(marker .. "  Disabled")

    -- Separator
    ass:new_event()
    ass:pos(mx + pad, row_y + ih)
    ass:an(7)
    ass:append("{\\bord0\\shad0\\c&H444444&}")
    ass:draw_start()
    ass:rect_cw(0, 0, mw - pad * 2, 1)
    ass:draw_stop()

    -- Subtitle rows (scrollable window)
    local vis_start = self.scroll_offset + 1
    local vis_end   = math.min(#self.sub_tracks, self.scroll_offset + self.max_visible)

    for vi = vis_start, vis_end do
        local t = self.sub_tracks[vi]
        local idx = vi - vis_start + 1
        local ry = my + pad + idx * ih
        marker = t.selected and "●" or "○"
        col    = t.selected and "44AAFF" or "DDDDDD"
        ass:new_event()
        ass:pos(mx + pad, ry + ih / 2)
        ass:an(4)
        ass:append(string.format(
            "{\\fnSegoe UI\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H000000&}", fs, col))
        ass:append(string.format("%s  %s", marker, t.label))
    end

    -- Scroll indicators
    if has_scroll then
        if self.scroll_offset > 0 then
            ass:new_event()
            ass:pos(mx + mw - pad - 8, my + pad + ih / 2)
            ass:an(5)
            ass:append(string.format(
                "{\\fnSegoe UI\\fs%d\\bord1\\shad0\\1c&H888888&\\3c&H000000&}", fs))
            ass:append("▲")
        end
        if vis_end < #self.sub_tracks then
            ass:new_event()
            ass:pos(mx + mw - pad - 8, my + mh - pad - ih / 2)
            ass:an(5)
            ass:append(string.format(
                "{\\fnSegoe UI\\fs%d\\bord1\\shad0\\1c&H888888&\\3c&H000000&}", fs))
            ass:append("▼")
        end
    end
end

-- ── Input ──
function Subs:handle_input(event, x, y)
    local bx, cy = self:_btn_pos()

    if event == "down" then
        -- CC button toggle
        if x >= bx - 8 and x <= bx + BTN_W + 8
           and y >= cy - BTN_H / 2 - 8 and y <= cy + BTN_H / 2 + 8 then
            self:update_tracks()
            self.show_menu = not self.show_menu
            self.scroll_offset = 0
            return true
        end

        if self.show_menu then
            local mx, my, mw, mh, ih, pad = self:_menu_geo()
            -- Inside menu?
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
