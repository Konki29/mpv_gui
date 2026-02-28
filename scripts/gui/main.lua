-- 1. Setup Path (Portable)
local script_path = debug.getinfo(1).source:match("@(.*[\\/])")
package.path = script_path .. "?.lua;" .. package.path

local mp = require 'mp'
local assdraw = require 'mp.assdraw'

-- 2. Import Shared State & Config
local state = require 'state'
local opts = require 'config'

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
-- RENDER
-- ============================================================================

local bg_visible = false

local function sync_res(ov)
    if state.w > 0 and state.h > 0 then
        ov.res_x = state.w
        ov.res_y = state.h
    end
end

local function render_bg()
    sync_res(bg_overlay)
    if not state.has_file then
        bg_overlay.data = ""
        bg_overlay:update()
        bg_visible = false
        return
    end
    local should_show = state.show_ui or state.paused or state.dragging
    if should_show then
        local ass = assdraw.ass_new()
        for _, el in ipairs(bg_elements) do el:draw(ass) end
        bg_overlay.data = ass.text
        bg_overlay:update()
        bg_visible = true
    elseif bg_visible then
        bg_overlay.data = ""
        bg_overlay:update()
        bg_visible = false
    end
end

local function render_ui()
    sync_res(ui_overlay)
    if not state.has_file then
        local ass = assdraw.ass_new()
        dropzone:draw(ass)
        ui_overlay.data = ass.text
        ui_overlay:update()
        return
    end
    if not state.show_ui and not state.paused and not state.dragging then
        ui_overlay.data = ""
        ui_overlay:update()
        return
    end
    local ass = assdraw.ass_new()
    for _, el in ipairs(ui_elements) do el:draw(ass) end
    ui_overlay.data = ass.text
    ui_overlay:update()
end

local function render()
    render_bg()
    render_ui()
end

-- ============================================================================
-- INPUT: Active-Element Locking (mpv-osc-modern pattern)
-- ============================================================================

local function input_handler()
    local x, y = mp.get_mouse_pos()
    state.mouse_x = x
    state.mouse_y = y
    state.user_activity = true
    
    -- Background always handles window-dragging
    bg_elements[1]:handle_input("move", x, y)
    
    -- If an element is locked (active during drag), dispatch ONLY to it
    if state.active_element then
        state.active_element:handle_input("move", x, y)
    else
        -- Normal hover: dispatch to all (top-first)
        for i = #ui_elements, 1, -1 do
            if ui_elements[i]:handle_input("move", x, y) then
                break
            end
        end
    end
    
    render_ui()
end

local function mouse_handler(tbl)
    local x, y = mp.get_mouse_pos()
    state.mouse_x = x
    state.mouse_y = y
    
    local event = tbl.event
    
    if event == "down" then
        -- Find which element was clicked (top-first)
        -- Try UI elements first
        for i = #ui_elements, 1, -1 do
            if ui_elements[i]:handle_input("down", x, y) then
                -- Lock onto this element for the duration of the drag
                state.active_element = ui_elements[i]
                render_ui()
                return
            end
        end
        -- Then try DropZone
        if dropzone:handle_input("down", x, y) then
            state.active_element = dropzone
            render_ui()
            return
        end
        
    elseif event == "up" then
        -- Dispatch up to the locked element
        if state.active_element then
            state.active_element:handle_input("up", x, y)
            state.active_element = nil
        end
        -- Restore window-dragging if needed
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
            render()
        end
    elseif (now - state.last_mouse_move > opts.auto_hide_timeout) 
           and not state.hovering_bar and not state.paused and not state.dragging then
        if state.show_ui then
            state.show_ui = false
            render()
        end
    end
end)

-- ============================================================================
-- WINDOW RESIZE
-- ============================================================================

mp.observe_property("osd-dimensions", "native", function(_, val)
    if val then
        state.w = val.w
        state.h = val.h
        render()
    end
end)

-- ============================================================================
-- MOUSE BINDINGS
-- ============================================================================

mp.add_key_binding("mouse_btn0", "mouse_btn0", mouse_handler, {complex=true})
mp.add_key_binding("mouse_move", "mouse_move", input_handler, {complex=true})

-- ============================================================================
-- MOUSE WHEEL: Subtitle scroll OR volume control
-- ============================================================================

local function wheel_handler(direction)
    -- Try dispatching scroll to UI elements (Subs menu first)
    for i = #ui_elements, 1, -1 do
        if ui_elements[i]:handle_input(direction, state.mouse_x, state.mouse_y) then
            render_ui()
            return
        end
    end
    -- No element consumed it → volume control
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