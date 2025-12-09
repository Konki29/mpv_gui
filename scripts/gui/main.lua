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
local TimeDisplay = require 'elements.TimeDisplay'
local DropZone = require 'elements.DropZone'

-- 3. Initialize Components
local elements = {
    DropZone.new(state, opts),    -- DropZone primero (capa inferior)
    Background.new(state, opts),
    ProgressBar.new(state, opts),
    PlayButton.new(state, opts),
    TimeDisplay.new(state, opts)
}

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

local function render() 
    -- Siempre mostrar UI si no hay archivo (para mostrar DropZone)
    if not state.has_file then
        -- Renderizar solo DropZone cuando no hay archivo
        local ass = require('mp.assdraw').ass_new()
        elements[1]:draw(ass)  -- DropZone
        mp.set_osd_ass(state.w, state.h, ass.text)
        return
    end
    
    if not state.show_ui and not state.paused and not state.dragging then
        mp.set_osd_ass(state.w, state.h, "")
        return
    end

    local ass = assdraw.ass_new()
    
    for _, element in ipairs(elements) do
        element:draw(ass)
    end
    
    mp.set_osd_ass(state.w, state.h, ass.text)
end

local function input_handler()
    local x, y = mp.get_mouse_pos()
    state.mouse_x = x
    state.mouse_y = y
    
    -- Check for general activity
    state.user_activity = true
    
    -- Primero: Background maneja el bloqueo de window-dragging (siempre se ejecuta)
    elements[1]:handle_input("move", x, y) -- Background
    
    -- Dispatch move event to components (orden inverso para priorizar capas superiores)
    for i = #elements, 2, -1 do
        if elements[i]:handle_input("move", x, y) then
            break -- Parar si un elemento consume el evento
        end
    end
    
    render()
end

local function mouse_handler(table)
    local x, y = mp.get_mouse_pos()
    state.mouse_x = x
    state.mouse_y = y
    
    -- Dispatch down/up event to components
    local event = table.event
    local consumed = false
    
    -- Reverse order for clicks (topmost element first)
    for i = #elements, 1, -1 do
        if elements[i]:handle_input(event, x, y) then
            consumed = true
            break -- Stop propagation if consumed
        end
    end
    
    render()
end

-- ============================================================================
-- EVENT LISTENERS
-- ============================================================================

-- Main Loop / Update
mp.add_periodic_timer(0.05, function()
    local now = mp.get_time()
    
    -- Auto-hide logic
    if state.user_activity then
        state.last_mouse_move = now
        state.user_activity = false
        state.show_ui = true
    elseif (now - state.last_mouse_move > state.activity_timeout) and not state.hovering_bar and not state.paused then
        if state.show_ui then
            state.show_ui = false
            render()
        end
    end
    
    -- Update duration/position for UI
    state.duration = mp.get_property_number("duration", 0)
    state.position = mp.get_property_number("time-pos", 0)
    state.paused = mp.get_property_bool("pause", false)
    
    -- Detectar si hay un archivo cargado
    local path = mp.get_property("path")
    state.has_file = (path ~= nil and path ~= "")
    
    if state.show_ui or state.paused then
        render()
    end
end)

-- Window resize
mp.observe_property("osd-dimensions", "native", function(name, val)
    if val then
        state.w = val.w
        state.h = val.h
        render()
    end
end)

-- Mouse Bindings
mp.add_key_binding("mouse_btn0", "mouse_btn0", mouse_handler, {complex=true})
mp.add_key_binding("mouse_move", "mouse_move", input_handler, {complex=true})