-- ==========================================================================
-- Subs.lua — Spider-Verse Comic-Book Subtitle & Audio Menu
-- ==========================================================================
-- ARCHITECTURE:
--   • The CC button is always drawn (3 ASS events max).
--   • The menu panel is cached as a single pre-built ASS string
--     (`self.menu_ass_cache`). It is ONLY rebuilt when `self.render_dirty`
--     is true (scroll, tab switch, track change, sub-scale change).
--   • All mpv property access happens via observers (zero sync calls in draw).
--   • All track switching uses mp.commandv (async, non-blocking).
-- ==========================================================================
local mp   = require 'mp'
local assdraw = require 'mp.assdraw'
local Element = require 'elements.Element'
local Subs = setmetatable({}, {__index = Element})
Subs.__index = Subs

local BTN_W, BTN_H = 40, 26

-- Spider-Verse palette (ASS = BGR order)
local C = {
    bg          = "0D0D0D",
    bg_alpha    = "88",
    border      = "000000",
    cyan        = "FFFF00",
    magenta     = "FF00FF",
    yellow      = "00FFFF",
    white       = "FFFFFF",
    grey        = "888888",
    dark_grey   = "444444",
    dim         = "555555",
    active_glow = "FFFF00",
    inactive    = "333333",
    tab_active  = "FFFF00",
    tab_text    = "000000",
    selected    = "FFFF00",
    halftone    = "222222",
}

-- ══════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ══════════════════════════════════════════════════════════════════════════

function Subs.new(state, opts)
    local self = Element.new(state, opts)
    self.show_menu    = false
    self.active_tab   = "subs"
    self.sub_tracks   = {}
    self.audio_tracks = {}
    self.current_sub  = 0
    self.current_aid  = 0
    self.scroll_offset     = 0
    self.scroll_offset_aud = 0
    self.max_visible  = 8

    -- Dirty flags
    self.tracks_dirty  = true   -- track-list changed, need rescan
    self.render_dirty  = true   -- menu visual needs rebuild
    self.menu_ass_cache = ""    -- pre-built ASS string for the entire menu
    self.halftone_cache = {}
    self.cached_sub_scale = 1.0

    local obj = setmetatable(self, Subs)

    mp.observe_property("track-list", "native", function()
        obj.tracks_dirty = true
        obj.render_dirty = true
    end)
    mp.observe_property("sub-scale", "number", function(_, val)
        obj.cached_sub_scale = val or 1.0
        obj.render_dirty = true
    end)
    mp.observe_property("sid", "string", function()
        obj.tracks_dirty = true
        obj.render_dirty = true
    end)
    mp.observe_property("aid", "string", function()
        obj.tracks_dirty = true
        obj.render_dirty = true
    end)

    return obj
end

-- ══════════════════════════════════════════════════════════════════════════
-- TRACK SCANNING (only called when tracks_dirty == true)
-- ══════════════════════════════════════════════════════════════════════════

function Subs:update_tracks()
    self.sub_tracks   = {}
    self.audio_tracks = {}
    self.current_sub  = 0
    self.current_aid  = 0

    local ok, err = pcall(function()
        local tl = mp.get_property_native("track-list", {})
        if not tl then return end
        for _, t in ipairs(tl) do
            if t.id ~= nil and (t.type == "sub" or t.type == "audio") then
                local lbl = ""
                if t.lang and t.lang ~= "" then lbl = t.lang:upper() end
                if t.title and t.title ~= "" then
                    lbl = lbl ~= "" and (lbl .. " — " .. t.title) or t.title
                end

                if t.type == "sub" then
                    if lbl == "" then lbl = "Track " .. t.id end
                    self.sub_tracks[#self.sub_tracks + 1] = {
                        id = t.id, label = lbl, selected = t.selected or false
                    }
                    if t.selected then self.current_sub = t.id end
                elseif t.type == "audio" then
                    if lbl == "" then lbl = "Audio " .. t.id end
                    local codec = t.codec or ""
                    local ch = t["demux-channel-count"]
                    if codec ~= "" then
                        local extra = codec:upper()
                        if ch then extra = extra .. " " .. ch .. "ch" end
                        lbl = lbl .. "  [" .. extra .. "]"
                    end
                    self.audio_tracks[#self.audio_tracks + 1] = {
                        id = t.id, label = lbl, selected = t.selected or false
                    }
                    if t.selected then self.current_aid = t.id end
                end
            end
        end
    end)
    if not ok then
        mp.msg.error("[Subs] update_tracks: " .. tostring(err))
    end

    -- Clamp scroll offsets
    local max_s = math.max(0, #self.sub_tracks - self.max_visible)
    self.scroll_offset = math.max(0, math.min(self.scroll_offset, max_s))
    local max_a = math.max(0, #self.audio_tracks - self.max_visible)
    self.scroll_offset_aud = math.max(0, math.min(self.scroll_offset_aud, max_a))
end

-- ══════════════════════════════════════════════════════════════════════════
-- GEOMETRY HELPERS
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_btn_pos()
    local cy = self.state.h - self.opts.controls_y_offset
    local bx = self.state.w / 2 - 130
    return bx, cy
end

function Subs:_menu_geo()
    local bx, cy = self:_btn_pos()
    local fs     = self.opts.subtitle_font_size
    local ih     = fs + 16
    local pad    = 14
    local tab_h  = fs + 12        -- compact tab bar
    local menu_w = 360

    local tracks = self.active_tab == "subs" and self.sub_tracks or self.audio_tracks
    local visible = math.min(#tracks, self.max_visible)
    local content_rows = visible + 1
    if self.active_tab == "subs" then
        content_rows = content_rows + 1
    end
    local menu_h = tab_h + content_rows * ih + pad * 2
    local menu_w = 340  -- Slightly narrower to look better right-aligned

    -- Anchor right edge of menu to right edge of CC button, grow leftward
    local menu_x = bx + BTN_W - menu_w
    -- Clamp to left screen edge
    if menu_x < 4 then menu_x = 4 end
    
    -- Avoid drawing negative geometry or overlapping the button
    local max_h = cy - BTN_H / 2 - 20
    if menu_h > max_h then menu_h = max_h end
    
    local menu_y = cy - BTN_H / 2 - menu_h - 50
    return menu_x, menu_y, menu_w, menu_h, ih, pad, fs, tab_h
end

-- ══════════════════════════════════════════════════════════════════════════
-- DRAW (called every frame by main.lua)
-- ══════════════════════════════════════════════════════════════════════════

function Subs:draw(ass)
    -- Refresh track data only when dirty
    if self.tracks_dirty then
        self:update_tracks()
        self.tracks_dirty = false
    end

    -- ── CC Button (always drawn — lightweight: 3 events max) ──
    local bx, cy = self:_btn_pos()
    local active = self.current_sub > 0
    local font   = self.opts.font
    local btn_cx  = bx + BTN_W / 2
    local btn_top = cy - BTN_H / 2

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    if active then
        ass:append(string.format(
            "{\\bord3\\shad0\\3c&H%s&\\1c&H%s&\\alpha&H40&}",
            C.active_glow, C.bg))
    else
        ass:append(string.format(
            "{\\bord2\\shad0\\3c&H%s&\\1c&H%s&\\alpha&H60&}",
            C.dim, C.inactive))
    end
    ass:draw_start()
    ass:round_rect_cw(bx, btn_top, bx + BTN_W, btn_top + BTN_H, 3)
    ass:draw_stop()

    if active then
        ass:new_event()
        ass:pos(btn_cx + 1, cy - 1) 
        ass:an(5)
        ass:append(string.format(
            "{\\fn%s\\fsp2\\b1\\fs14\\bord0\\shad0\\1c&H%s&\\alpha&HC0&}",
            font, C.cyan))
        ass:append("CC")
    end

    ass:new_event()
    ass:pos(btn_cx, cy)
    ass:an(5)
    ass:append(string.format(
        "{\\fn%s\\fsp2\\b1\\fs14\\bord1\\shad0\\1c&H%s&\\3c&H%s&}",
        font, active and C.white or C.dim, C.border))
    ass:append("CC")

    -- ── Menu Panel (cached ASS — rebuilt only when render_dirty) ──
    if self.show_menu then
        if self.render_dirty then
            self:_rebuild_menu_cache()
            self.render_dirty = false
        end
        ass:append(self.menu_ass_cache)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- MENU CACHE BUILDER (runs ONLY when render_dirty == true)
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_rebuild_menu_cache()
    local a = assdraw.ass_new()
    local mx, my, mw, mh, ih, pad, fs, tab_h = self:_menu_geo()
    local font = self.opts.font

    -- ── Panel background ──
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(string.format(
        "{\\bord2\\shad0\\3c&H%s&\\1c&H%s&\\alpha&H%s&}",
        C.border, C.bg, C.bg_alpha))
    a:draw_start()
    a:round_rect_cw(mx, my, mx + mw, my + mh, 6)
    a:draw_stop()

    -- ── Halftone (cached separately by size) ──
    self:_draw_halftone(a, mx, my, mw, mh)

    -- ── Tab bar (with gap between tabs) ──
    local tab_gap = 8
    local tw = (mw - pad * 2 - tab_gap) / 2
    self:_draw_tab(a, mx + pad, my + 4, tw, tab_h - 8,
                   "SUBS", self.active_tab == "subs", font, fs)
    self:_draw_tab(a, mx + pad + tw + tab_gap, my + 4, tw, tab_h - 8,
                   "AUDIO", self.active_tab == "audio", font, fs)

    -- ── Separator ──
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(string.format("{\\bord0\\shad0\\c&H%s&}", C.dark_grey))
    a:draw_start()
    a:rect_cw(mx + pad, my + tab_h, mx + mw - pad, my + tab_h + 2)
    a:draw_stop()

    -- ── Content ──
    local content_y = my + tab_h + pad
    if self.active_tab == "subs" then
        self:_build_subs_content(a, mx, content_y, mw, ih, pad, fs, font)
    else
        self:_build_audio_content(a, mx, content_y, mw, ih, pad, fs, font)
    end

    self.menu_ass_cache = a.text
end

-- ══════════════════════════════════════════════════════════════════════════
-- HALFTONE (cached by panel size)
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_draw_halftone(ass, mx, my, mw, mh)
    local key = tostring(math.floor(mw)) .. "x" .. tostring(math.floor(mh))
    local cached = self.halftone_cache[key]

    if not cached then
        local spacing = 14
        local r = 1.5
        local k = 0.5522847498
        local cmds = {}
        for ry = 8, mh - 8, spacing do
            for cx = 8, mw - 8, spacing do
                cmds[#cmds + 1] = string.format(
                    "m %d %d b %s %s %s %s %s %s b %s %s %s %s %s %s b %s %s %s %s %s %s b %s %s %s %s %s %s ",
                    cx, ry - r,
                    cx+r*k, ry-r,   cx+r, ry-r*k, cx+r, ry,
                    cx+r, ry+r*k,   cx+r*k, ry+r, cx, ry+r,
                    cx-r*k, ry+r,   cx-r, ry+r*k, cx-r, ry,
                    cx-r, ry-r*k,   cx-r*k, ry-r, cx, ry-r
                )
            end
        end
        cached = table.concat(cmds)
        self.halftone_cache[key] = cached
    end

    ass:new_event()
    ass:pos(mx, my)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&HE0&\\p1}", C.halftone))
    ass:append(cached)
    ass:append("{\\p0}")
end

-- ══════════════════════════════════════════════════════════════════════════
-- TAB BUTTON
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_draw_tab(ass, tx, ty, tw, th, label, is_active, font, fs)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    if is_active then
        ass:append(string.format(
            "{\\bord2\\shad0\\3c&H%s&\\1c&H%s&\\alpha&H00&}",
            C.border, C.tab_active))
    else
        -- Subdued sketch style: very dim, transparent
        ass:append(string.format(
            "{\\bord1\\shad0\\3c&H%s&\\1c&H%s&\\alpha&HC0&}",
            C.dark_grey, C.bg))
    end
    ass:draw_start()
    ass:round_rect_cw(tx, ty, tx + tw, ty + th, 4)
    ass:draw_stop()

    ass:new_event()
    ass:pos(tx + tw/2, ty + th/2)
    ass:an(5)
    ass:append(string.format(
        "{\\fn%s\\b1\\fsp2\\fs%d\\bord%s\\shad0\\1c&H%s&\\3c&H%s&}",
        font, fs - 3,
        is_active and "0" or "1",
        is_active and C.tab_text or C.dim,
        C.border))
    ass:append(label)
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBS TAB CONTENT
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_build_subs_content(ass, mx, top_y, mw, ih, pad, fs, font)
    local ctrl_cy = top_y + ih / 2
    local sub_scale = self.cached_sub_scale
    local btn_w = 44

    -- Minus button
    local minus_x = mx + pad
    self:_draw_comic_btn(ass, minus_x, ctrl_cy - ih/2 + 4, btn_w, ih - 8, "−", font, fs, C.magenta)

    -- Scale value
    ass:new_event()
    ass:pos(mx + mw/2, ctrl_cy)
    ass:an(5)
    ass:append(string.format(
        "{\\fn%s\\b1\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H%s&}",
        font, fs, C.white, C.border))
    ass:append(string.format("%.1f", sub_scale))

    -- Plus button
    local plus_x = mx + mw - pad - btn_w
    self:_draw_comic_btn(ass, plus_x, ctrl_cy - ih/2 + 4, btn_w, ih - 8, "+", font, fs, C.cyan)

    -- Separator
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", C.dark_grey))
    ass:draw_start()
    ass:rect_cw(mx + pad, top_y + ih, mx + mw - pad, top_y + ih + 1)
    ass:draw_stop()

    -- "Disabled" row
    local dis_y = top_y + ih + ih / 2
    self:_draw_track_row(ass, mx + pad, dis_y, mw - pad*2,
                         "Disabled", self.current_sub == 0, font, fs)

    -- Visible subtitle rows
    local vis_start = self.scroll_offset + 1
    local vis_end   = math.min(#self.sub_tracks, self.scroll_offset + self.max_visible)
    for vi = vis_start, vis_end do
        local t = self.sub_tracks[vi]
        if t then
            local row_idx = vi - vis_start + 2
            local row_y = top_y + row_idx * ih + ih / 2
            local label = t.label
            if #label > 42 then label = label:sub(1, 39) .. "..." end
            self:_draw_track_row(ass, mx + pad, row_y, mw - pad*2,
                                 label, t.selected, font, fs)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- AUDIO TAB CONTENT
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_build_audio_content(ass, mx, top_y, mw, ih, pad, fs, font)
    if #self.audio_tracks == 0 then
        ass:new_event()
        ass:pos(mx + mw/2, top_y + ih/2)
        ass:an(5)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H%s&}",
            font, fs, C.dim, C.border))
        ass:append("No audio tracks")
        return
    end

    if #self.audio_tracks == 1 then
        local t = self.audio_tracks[1]
        local label = t.label
        if #label > 42 then label = label:sub(1, 39) .. "..." end
        self:_draw_track_row(ass, mx + pad, top_y + ih / 2, mw - pad*2,
                             label, true, font, fs)
        ass:new_event()
        ass:pos(mx + mw/2, top_y + ih + ih / 2)
        ass:an(5)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H%s&}",
            font, fs - 3, C.yellow, C.border))
        ass:append("SINGLE TRACK")
        return
    end

    local vis_start = self.scroll_offset_aud + 1
    local vis_end   = math.min(#self.audio_tracks, self.scroll_offset_aud + self.max_visible)
    for vi = vis_start, vis_end do
        local t = self.audio_tracks[vi]
        if t then
            local idx = vi - vis_start
            local row_y = top_y + idx * ih + ih / 2
            local label = t.label
            if #label > 42 then label = label:sub(1, 39) .. "..." end
            self:_draw_track_row(ass, mx + pad, row_y, mw - pad*2,
                                 label, t.selected, font, fs)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- SHARED DRAWING HELPERS (minimal ASS events)
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_draw_comic_btn(ass, bx, by, bw, bh, label, font, fs, accent)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format(
        "{\\bord2\\shad0\\3c&H%s&\\1c&H%s&\\alpha&H80&}",
        C.border, C.bg))
    ass:draw_start()
    ass:round_rect_cw(bx, by, bx + bw, by + bh, 3)
    ass:draw_stop()

    ass:new_event()
    ass:pos(bx + bw/2, by + bh/2)
    ass:an(5)
    ass:append(string.format(
        "{\\fn%s\\b1\\fs%d\\bord1\\shad0\\1c&H%s&\\3c&H%s&}",
        font, fs + 2, accent, C.border))
    ass:append(label)
end

function Subs:_draw_track_row(ass, rx, ry, rw, label, is_selected, font, fs)
    local marker = is_selected and "◆" or "◇"
    local col    = is_selected and C.selected or C.white

    -- Chromatic ghost only on the selected track (saves 1 event per unselected row)
    if is_selected then
        ass:new_event()
        ass:pos(rx + 1, ry - 1)
        ass:an(4)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\alpha&HC0&}",
            font, fs, C.magenta))
        ass:append(marker .. "  " .. label)
    end

    ass:new_event()
    ass:pos(rx, ry)
    ass:an(4)
    ass:append(string.format(
        "{\\fn%s\\fs%d\\bord2\\shad1\\1c&H%s&\\3c&H%s&\\4c&H000000&}",
        font, fs, col, C.border))
    ass:append(marker .. "  " .. label)
end

-- ══════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ══════════════════════════════════════════════════════════════════════════

function Subs:handle_input(event, x, y)
    local bx, cy = self:_btn_pos()

    if event == "down" then
        -- CC button toggle
        if x >= bx - 8 and x <= bx + BTN_W + 8
           and y >= cy - BTN_H / 2 - 8 and y <= cy + BTN_H / 2 + 8 then
            self.show_menu = not self.show_menu
            self.scroll_offset = 0
            self.scroll_offset_aud = 0
            self.render_dirty = true
            
            -- Set global state for centralized margin management in main.lua
            self.state.subs_open = self.show_menu
            
            if self.state.calculate_sub_margins then
                self.state.calculate_sub_margins()
            end
            
            return true
        end

        if self.show_menu then
            local mx, my, mw, mh, ih, pad, fs, tab_h = self:_menu_geo()

            if x >= mx and x <= mx + mw and y >= my and y <= my + mh then
                -- Tab bar (matched to gapped layout)
                if y < my + tab_h then
                    local tab_gap = 8
                    local tw = (mw - pad * 2 - tab_gap) / 2
                    local subs_right = mx + pad + tw
                    local audio_left = mx + pad + tw + tab_gap
                    if x <= subs_right then
                        self.active_tab = "subs"
                    elseif x >= audio_left then
                        self.active_tab = "audio"
                    end
                    self.scroll_offset = 0
                    self.scroll_offset_aud = 0
                    self.render_dirty = true
                    return true
                end

                -- Content area
                local content_y = my + tab_h + pad
                local ry = y - content_y
                local idx = math.floor(ry / ih)
                if idx < 0 then idx = 0 end

                if self.active_tab == "subs" then
                    return self:_handle_subs_click(mx, mw, ih, pad, idx, x)
                else
                    return self:_handle_audio_click(idx)
                end
            else
                -- Click outside → close
                self.show_menu = false
                self.state.subs_open = false
                self.render_dirty = true
                if self.state.calculate_sub_margins then
                    self.state.calculate_sub_margins()
                end
                return true
            end
        end

    -- Scroll: consume ONLY when mouse is over the menu
    elseif event == "scroll_up" or event == "scroll_down" then
        if self.show_menu then
            local mx, my, mw, mh = self:_menu_geo()
            if x >= mx and x <= mx + mw and y >= my and y <= my + mh then
                if event == "scroll_up" then
                    if self.active_tab == "subs" then
                        if self.scroll_offset > 0 then
                            self.scroll_offset = self.scroll_offset - 1
                            self.render_dirty = true
                        end
                    else
                        if self.scroll_offset_aud > 0 then
                            self.scroll_offset_aud = self.scroll_offset_aud - 1
                            self.render_dirty = true
                        end
                    end
                else
                    if self.active_tab == "subs" then
                        local max_off = math.max(0, #self.sub_tracks - self.max_visible)
                        if self.scroll_offset < max_off then
                            self.scroll_offset = self.scroll_offset + 1
                            self.render_dirty = true
                        end
                    else
                        local max_off = math.max(0, #self.audio_tracks - self.max_visible)
                        if self.scroll_offset_aud < max_off then
                            self.scroll_offset_aud = self.scroll_offset_aud + 1
                            self.render_dirty = true
                        end
                    end
                end
                return true  -- Block volume scroll
            end
        end
    end

    return false
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBS CLICK HANDLER
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_handle_subs_click(mx, mw, ih, pad, idx, x)
    if idx == 0 then
        -- Sub-scale controls
        local btn_w = 44
        local minus_left  = mx + pad
        local minus_right = minus_left + btn_w
        local plus_right  = mx + mw - pad
        local plus_left   = plus_right - btn_w

        if x >= minus_left and x <= minus_right then
            local new_s = math.max(0.2, self.cached_sub_scale - 0.1)
            mp.commandv("set", "sub-scale", tostring(new_s))
        elseif x >= plus_left and x <= plus_right then
            local new_s = math.min(5.0, self.cached_sub_scale + 0.1)
            mp.commandv("set", "sub-scale", tostring(new_s))
        end
        return true

    elseif idx == 1 then
        -- Disabled
        mp.commandv("set", "sid", "no")
        self.current_sub = 0
        self.show_menu = false
        self.render_dirty = true
        return true

    else
        -- Track selection (strict bounds)
        local drawn_idx = idx - 2
        local max_drawn = math.min(#self.sub_tracks, self.max_visible) - 1
        if drawn_idx >= 0 and drawn_idx <= max_drawn then
            local real = drawn_idx + self.scroll_offset + 1
            local track = self.sub_tracks[real]
            if track then
                mp.commandv("set", "sid", tostring(track.id))
                self.current_sub = track.id
            end
            self.show_menu = false
            self.state.subs_open = false
            self.render_dirty = true
            local base = self.saved_sub_margin or 22
            mp.commandv("set", "sub-margin-y", tostring(base + 80))
            return true
        end
        return true  -- Consume empty-space click
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- AUDIO CLICK HANDLER
-- ══════════════════════════════════════════════════════════════════════════

function Subs:_handle_audio_click(idx)
    -- Single-track badge
    if #self.audio_tracks == 1 and idx == 0 then
        self.show_menu = false
        self.render_dirty = true
        return true
    end

    -- Strict bounds
    local max_drawn = math.min(#self.audio_tracks, self.max_visible) - 1
    if idx >= 0 and idx <= max_drawn then
        local real = idx + self.scroll_offset_aud + 1
        local track = self.audio_tracks[real]
        if track then
            local ok, err = pcall(function()
                mp.commandv("set", "aid", tostring(track.id))
            end)
            if ok then
                self.current_aid = track.id
            else
                mp.msg.error("[Subs] set aid failed: " .. tostring(err))
            end
        end
        self.show_menu = false
        self.state.subs_open = false
        self.render_dirty = true
        local base = self.saved_sub_margin or 22
        mp.commandv("set", "sub-margin-y", tostring(base + 80))
        return true
    end

    return true  -- Consume empty-space click
end

return Subs
