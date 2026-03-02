-- 1. Setup Path (Portable)
local script_path = debug.getinfo(1).source:match("@(.+[\\/])")
package.path = script_path .. "?.lua;" .. package.path

local mp = require 'mp'
local assdraw = require 'mp.assdraw'

-- 2. Import Shared State & Config
local state = require 'state'
local opts = require 'config'

-- Sub-margin management: avoid subtitle overlap with controls
local original_sub_margin_y = nil
local original_sub_margin_x = nil
local original_sub_align_x = nil

local function update_sub_margins()
    if not state.show_ui then
        if original_sub_margin_y then mp.commandv("set", "sub-margin-y", tostring(original_sub_margin_y)) end
        if original_sub_margin_x then mp.commandv("set", "sub-margin-x", tostring(original_sub_margin_x)) end
        if original_sub_align_x then mp.commandv("set", "sub-align-x", tostring(original_sub_align_x)) end
        return
    end

    -- Save original values only once when UI appears
    if not original_sub_margin_y then original_sub_margin_y = mp.get_property_number("sub-margin-y", 22) end
    if not original_sub_margin_x then original_sub_margin_x = mp.get_property_number("sub-margin-x", 25) end
    if not original_sub_align_x then original_sub_align_x = mp.get_property("sub-align-x", "center") end

    -- Vertical push calculation: Only the base push (so it doesn't jump into the middle of the screen)
    local base_push = 80
    mp.commandv("set", "sub-margin-y", tostring(original_sub_margin_y + base_push))

    -- Horizontal shift calculation: Move to the right when menu opens (dodging menu on left)
    if state.subs_open then
        mp.commandv("set", "sub-align-x", "right")
        -- By anchoring the subtitles to the right edge with a small 40px margin, 
        -- we avoid applying symmetrical margins (which crushes the width) and completely dodge the left menu.
        mp.commandv("set", "sub-margin-x", "60")
    else
        mp.commandv("set", "sub-align-x", tostring(original_sub_align_x))
        mp.commandv("set", "sub-margin-x", tostring(original_sub_margin_x))
    end
end

state.calculate_sub_margins = update_sub_margins

-- 3. Import Components
local Background = require 'elements.Background'
local ProgressBar = require 'elements.ProgressBar'
local PlayButton = require 'elements.PlayButton'
local SkipButtons = require 'elements.SkipButtons'
local VolumeButton = require 'elements.VolumeButton'
local TimeDisplay = require 'elements.TimeDisplay'
local WindowControls = require 'elements.WindowControls'
local DropZone = require 'elements.DropZone'
local Subs = require 'elements.Subs'

-- 4. Initialize Components
local bg_elements = {
    Background.new(state, opts),
}

local ui_elements = {
    ProgressBar.new(state, opts),       -- [1]
    PlayButton.new(state, opts),        -- [2]
    SkipButtons.new(state, opts),       -- [3]
    VolumeButton.new(state, opts),      -- [4]
    TimeDisplay.new(state, opts),       -- [5]
    WindowControls.new(state, opts),    -- [6]
    Subs.new(state, opts),              -- [7]
}

local dropzone = DropZone.new(state, opts)

-- 5. Two separate OSD overlays (z-order: lower = behind)
local bg_overlay = mp.create_osd_overlay("ass-events")
bg_overlay.z = 10
local ui_overlay = mp.create_osd_overlay("ass-events")
ui_overlay.z = 20

-- ============================================================================
-- VIRTUAL RESOLUTION (mpv-osc-modern pattern)
-- ============================================================================
-- Instead of mapping 1:1 to physical pixels, we use a virtual 720p canvas.
-- This makes all element sizes resolution-independent: a 20px font is always
-- the same fraction of the screen, whether on 720p, 1080p, 2K, or 4K.

local function update_virtual_res()
    local rw = state.real_w > 0 and state.real_w or 1280
    local rh = state.real_h > 0 and state.real_h or 720
    
    local base_y = opts.base_res_y / opts.scale
    local aspect = rw / rh
    state.h = base_y
    state.w = base_y * aspect
end

local function sync_overlay(ov)
    if state.w > 0 and state.h > 0 then
        ov.res_x = state.w
        ov.res_y = state.h
    end
end

-- Translate physical mouse coords → virtual coords
local function mouse_to_virtual(px, py)
    if state.real_w <= 0 or state.real_h <= 0 then return px, py end
    local sx = state.w / state.real_w
    local sy = state.h / state.real_h
    return px * sx, py * sy
end

-- ============================================================================
-- RENDER
-- ============================================================================

local bg_visible = false
local last_bg_data = nil
local last_ui_data = nil

local function render_bg()
    if state.real_w <= 0 then -- Only block background rendering if real_w <= 0
        if last_bg_data ~= "" then
            bg_overlay.data = ""
            bg_overlay:update()
            last_bg_data = ""
            bg_visible = false
        end
        return
    end
    
    sync_overlay(bg_overlay)
    
    local should_show = state.show_ui or state.paused or state.dragging
    if should_show then
        local ass = assdraw.ass_new()
        for _, el in ipairs(bg_elements) do el:draw(ass) end
        local new_data = ass.text
        if new_data ~= last_bg_data then
            bg_overlay.data = new_data
            bg_overlay:update()
            last_bg_data = new_data
        end
        bg_visible = true
    elseif bg_visible then
        bg_overlay.data = ""
        bg_overlay:update()
        last_bg_data = ""
        bg_visible = false
    end
end

local function render_ui()
    -- Always calculate virtual res first if uninitialized so dropzone has canvas scope
    if state.w == 0 or state.h == 0 then update_virtual_res() end
    sync_overlay(ui_overlay)
    
    if not state.has_file then
        local ass = assdraw.ass_new()
        dropzone:draw(ass)
        local new_data = ass.text
        if new_data ~= last_ui_data then
            ui_overlay.data = new_data
            ui_overlay:update()
            last_ui_data = new_data
        end
        return
    end
    if not state.show_ui and not state.paused and not state.dragging then
        if last_ui_data ~= "" then
            ui_overlay.data = ""
            ui_overlay:update()
            last_ui_data = ""
        end
        return
    end
    local ass = assdraw.ass_new()
    for _, el in ipairs(ui_elements) do el:draw(ass) end
    local new_data = ass.text
    if new_data ~= last_ui_data then
        ui_overlay.data = new_data
        ui_overlay:update()
        last_ui_data = new_data
    end
end

local function render()
    render_bg()
    render_ui()
end

-- ============================================================================
-- INPUT: Active-Element Locking (mpv-osc-modern pattern)
-- ============================================================================

local function input_handler()
    local px, py = mp.get_mouse_pos()
    local x, y = mouse_to_virtual(px, py)
    state.mouse_x = x
    state.mouse_y = y
    state.user_activity = true
    
    bg_elements[1]:handle_input("move", x, y)
    
    if state.active_element then
        state.active_element:handle_input("move", x, y)
    else
        for i = #ui_elements, 1, -1 do
            if ui_elements[i]:handle_input("move", x, y) then
                break
            end
        end
    end
    
    render_ui()
end

local function mouse_handler(tbl)
    local px, py = mp.get_mouse_pos()
    local x, y = mouse_to_virtual(px, py)
    state.mouse_x = x
    state.mouse_y = y
    
    local event = tbl.event
    
    if event == "down" then
        for i = #ui_elements, 1, -1 do
            if ui_elements[i]:handle_input("down", x, y) then
                state.active_element = ui_elements[i]
                render_ui()
                return
            end
        end
        if dropzone:handle_input("down", x, y) then
            state.active_element = dropzone
            render_ui()
            return
        end
        
    elseif event == "up" then
        if state.active_element then
            state.active_element:handle_input("up", x, y)
            state.active_element = nil
        end
        if not state.dragging then
            local box_top = state.h - opts.box_height
            if y < box_top and state.control_area_active then
                state.control_area_active = false
                mp.set_property("window-dragging", "yes")
            end
        end
    end
    
    render_ui()
end

-- ============================================================================
-- PROPERTY OBSERVERS
-- ============================================================================

mp.observe_property("duration", "number", function(_, v)
    state.duration = v or 0
    render_ui()
end)

mp.observe_property("time-pos", "number", function(_, v)
    if not state.dragging then
        state.position = v or 0
        render_ui()
    end
end)

mp.observe_property("pause", "bool", function(_, v)
    state.paused = v or false
    render()
end)

mp.observe_property("path", "string", function(_, v)
    state.has_file = (v ~= nil and v ~= "")
    render()
end)

mp.observe_property("volume", "number", function(_, v)
    state.volume = v or 0
    render_ui()
end)

mp.observe_property("mute", "bool", function(_, v)
    state.muted = v or false
    render_ui()
end)

-- ============================================================================
-- AUTO-HIDE
-- ============================================================================

mp.add_periodic_timer(0.25, function()
    local now = mp.get_time()
    if state.user_activity then
        state.last_mouse_move = now
        state.user_activity = false
        if not state.show_ui then
            state.show_ui = true
            update_sub_margins()
            render()
        end
    elseif (now - state.last_mouse_move > opts.auto_hide_timeout)
           and not state.hovering_bar and not state.paused and not state.dragging then
        if state.show_ui then
            state.show_ui = false
            -- Force close subs menu if UI auto-hides
            local subs = ui_elements[#ui_elements]
            if subs and subs.show_menu then
                subs.show_menu = false
                subs.render_dirty = true
                state.subs_open = false
            end
            update_sub_margins()
            render()
        end
    end
end)

-- ============================================================================
-- WINDOW RESIZE → update virtual resolution
-- ============================================================================

mp.observe_property("osd-dimensions", "native", function(_, val)
    if val then
        state.real_w = val.w
        state.real_h = val.h
        update_virtual_res()
        render()
    end
end)

-- ============================================================================
-- MOUSE BINDINGS
-- ============================================================================

mp.add_key_binding("mouse_btn0", "mouse_btn0", mouse_handler, {complex=true})
mp.add_key_binding("mouse_move", "mouse_move", input_handler, {complex=true})

-- Double-click: block fullscreen toggle when UI controls or Subs menu is active
mp.add_key_binding("mouse_btn0_dbl", "mouse_btn0_dbl", function()
    local px, py = mp.get_mouse_pos()
    local x, y = mouse_to_virtual(px, py)
    local box_top = state.h - opts.box_height
    -- Block double-click in the control bar area
    if y >= box_top and state.show_ui then return end
    -- Block double-click when Subs menu is open (check Subs element)
    local subs = ui_elements[#ui_elements]  -- Subs is last in the list
    if subs and subs.show_menu then return end
    -- Otherwise: allow native fullscreen toggle
    mp.commandv("cycle", "fullscreen")
end)

-- ============================================================================
-- MOUSE WHEEL: Subtitle scroll OR volume control
-- ============================================================================

local function wheel_handler(direction)
    for i = #ui_elements, 1, -1 do
        if ui_elements[i]:handle_input(direction, state.mouse_x, state.mouse_y) then
            render_ui()
            return
        end
    end
    if opts.mouse_wheel_volume then
        if direction == "scroll_up" then
            mp.command(string.format("no-osd add volume %d", opts.volume_step))
        else
            mp.command(string.format("no-osd add volume -%d", opts.volume_step))
        end
    end
end

mp.add_forced_key_binding("WHEEL_UP", "osc_wheel_up", function()
    wheel_handler("scroll_up")
end)
mp.add_forced_key_binding("WHEEL_DOWN", "osc_wheel_down", function()
    wheel_handler("scroll_down")
end)

-- ============================================================================
-- GLOBAL EVENTS
-- ============================================================================

mp.register_event("end-file", function()
    -- Reset all subtitle layout properties safely when file closed
    if original_sub_margin_y then mp.commandv("set", "sub-margin-y", tostring(original_sub_margin_y)) end
    if original_sub_margin_x then mp.commandv("set", "sub-margin-x", tostring(original_sub_margin_x)) end
    if original_sub_align_x then mp.commandv("set", "sub-align-x", tostring(original_sub_align_x)) end
    
    original_sub_margin_y = nil
    original_sub_margin_x = nil
    original_sub_align_x = nil
    state.subs_open = false
end)