-- main.lua
-- Set package path to find sibling modules
local script_path = debug.getinfo(1, "S").source:match("@(.*[/\\])")
package.path = script_path .. "?.lua;" .. package.path

local mp = require 'mp'
local config = require 'config'
local state = require 'state'
local draw_lib = require 'draw'
local input_lib = require 'input'

-- Helper to call draw with current state
local function draw()
    draw_lib.draw(state, config)
end

-- Initialize input with state and draw callback
input_lib.init(state, config, draw)

local function update_dimensions()
    state.w, state.h = mp.get_osd_size()
    draw()
end

local function check_activity()
    local now = mp.get_time()
    if state.user_activity then
        state.last_mouse_move = now
        state.show_ui = true
        state.user_activity = false
    end
    if not state.paused and (now - state.last_mouse_move > state.activity_timeout) and not state.hovering_bar and not state.dragging then
        if state.show_ui then
            state.show_ui = false
            draw()
        end
    else
        if not state.show_ui then
            state.show_ui = true
            draw()
        end
    end
end

local function on_tick()
    -- Solo actualizamos position real si NO estamos arrastrando
    -- (para que la barra no vibre luchando entre el ratón y el video)
    if not state.dragging then
        state.position = mp.get_property_number("time-pos") or 0
    end
    state.duration = mp.get_property_number("duration") or 0
    state.paused = mp.get_property_native("pause")
    
    check_activity()
    draw()
end

mp.observe_property("osd-dimensions", "native", update_dimensions)
mp.add_periodic_timer(0.05, on_tick)
mp.add_key_binding("MOUSE_BTN0", "mouse_master", input_lib.mouse_handler, {complex=true})
mp.add_forced_key_binding("mouse_move", "mouse_move", input_lib.input_handler)
update_dimensions()
