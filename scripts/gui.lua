local mp = require 'mp'
local assdraw = require 'mp.assdraw'
local msg = require 'mp.msg'

-- Configuration options
local opts = {
    scale = 1,
    bar_height = 4,
    bar_hover_height = 6,
    handle_size = 14,
    box_height = 48,
    color_played = "0000FF", -- Red in BGR
    color_bg = "FFFFFF",
    opacity_bg = "CC",
    font_size = 20,
}

-- State variables
local state = {
    w = 0, h = 0,
    mouse_x = 0, mouse_y = 0,
    hovering_bar = false,
    dragging = false,
    show_ui = false,
    last_mouse_move = 0,
    activity_timeout = 2,
    duration = 0,
    position = 0,
    paused = false,
    user_activity = false,
    
    -- LÓGICA MODERN.LUA: Variable para evitar comandos repetidos
    last_seek_pct = -1,
    visual_seek_pct = -1 -- Para visualización suave durante el arrastre
}

local function get_virtual_mouse_pos()
    local x, y = mp.get_mouse_pos()
    return x, y
end

local function timestamp(seconds)
    if not seconds then return "0:00" end
    local hrs = math.floor(seconds / 3600)
    local min = math.floor((seconds % 3600) / 60)
    local sec = math.floor(seconds % 60)
    if hrs > 0 then
        return string.format("%d:%02d:%02d", hrs, min, sec)
    else
        return string.format("%d:%02d", min, sec)
    end
end

local function draw()
    if not state.show_ui and not state.paused and not state.dragging then
        mp.set_osd_ass(state.w, state.h, "")
        return
    end

    local ass = assdraw.ass_new()
    local w, h = state.w, state.h
    
    -- 1. Gradient Background
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&H000000&\\alpha&H40&}")
    ass:draw_start()
    ass:rect_cw(0, h - opts.box_height, w, h)
    ass:draw_stop()
    
    -- 2. Progress Bar Calculation
    local bar_h = (state.hovering_bar or state.dragging) and opts.bar_hover_height or opts.bar_height
    local bar_y_pos = h - opts.box_height + ((state.hovering_bar or state.dragging) and -2 or 0)
    
    -- VISUALIZACIÓN TIPO MODERN.LUA:
    -- Si arrastramos, la barra debe responder al ratón (visual_seek_pct), no al video.
    local progress = 0
    if state.dragging and state.visual_seek_pct >= 0 then
        progress = state.visual_seek_pct
    elseif state.duration > 0 then
        progress = state.position / state.duration
    end
    
    -- Background Bar
    ass:new_event()
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H%s&}", "FFFFFF", "BB"))
    ass:pos(0, bar_y_pos)
    ass:draw_start()
    ass:rect_cw(0, 0, w, bar_h)
    ass:draw_stop()
    
    -- Played Bar
    if progress > 0 then
        ass:new_event()
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H00&}", opts.color_played))
        ass:pos(0, bar_y_pos)
        ass:draw_start()
        ass:rect_cw(0, 0, w * progress, bar_h)
        ass:draw_stop()
        
        -- Handle (Knob)
        if state.hovering_bar or state.dragging then
           ass:new_event()
           ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", opts.color_played))
           ass:pos(w * progress, bar_y_pos + bar_h/2)
           ass:draw_start()
           ass:round_rect_cw(-opts.handle_size/2, -opts.handle_size/2, opts.handle_size/2, opts.handle_size/2, opts.handle_size/4)
           ass:draw_stop()
        end
    end

    -- 3. Controls (Play/Pause & Time)
    local icon_y = h - opts.box_height / 2
    local cur_x = 20
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if state.paused then
        ass:move_to(0, -10)
        ass:line_to(15, 0)
        ass:line_to(0, 10)
    else
        ass:rect_cw(0, -10, 5, 10)
        ass:rect_cw(10, -10, 15, 10)
    end
    ass:draw_stop()
    
    cur_x = cur_x + 40
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:an(4)
    ass:append(string.format("{\\fs%d\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}", opts.font_size))
    
    -- Si arrastramos, mostramos el tiempo objetivo, no el actual
    local time_to_show = state.position
    if state.dragging and state.visual_seek_pct >= 0 then
        time_to_show = state.visual_seek_pct * state.duration
    end
    ass:append(timestamp(time_to_show) .. " / " .. timestamp(state.duration))
    
    mp.set_osd_ass(state.w, state.h, ass.text)
end

local function update_dimensions()
    state.w, state.h = mp.get_osd_size()
    draw()
end

-- LÓGICA DE MOVIMIENTO (Mouse Move)
local function input_handler(event)
    state.mouse_x, state.mouse_y = get_virtual_mouse_pos()
    state.user_activity = true
    
    local bar_y_start = state.h - opts.box_height - 10
    local bar_y_end = state.h - opts.box_height + opts.bar_hover_height + 10
    
    state.hovering_bar = (state.mouse_y >= bar_y_start and state.mouse_y <= bar_y_end)
    
    -- === APLICANDO LÓGICA MODERN.LUA AQUÍ ===
    if state.dragging then
        local pct = state.mouse_x / state.w
        pct = math.max(0, math.min(1, pct)) -- Limitar entre 0 y 1
        
        -- SOLO actuamos si el valor ha cambiado significativamente (filtro de spam)
        -- 0.001 significa 0.1% de diferencia. Suficiente para ser suave, pero no satura.
        if math.abs(pct - state.last_seek_pct) > 0.001 then
            
            -- Enviamos el seek (modern.lua usa 'absolute-percent' + 'exact')
            mp.commandv("seek", pct * 100, "absolute-percent+exact")
            
            -- Guardamos este valor como el último enviado
            state.last_seek_pct = pct
        end
    end
    -- =========================================
    
    draw()
end

local function mouse_handler(table)
    if table.event == "down" then
        if state.hovering_bar then
            mp.set_property("window-dragging", "no")
            state.dragging = true
            
            -- Iniciar seek inmediatamente al hacer clic (Lógica modern.lua: start drag)
            input_handler() 
        else
            mp.set_property("window-dragging", "yes")
            if state.mouse_x < 60 and state.mouse_y > (state.h - opts.box_height) then
                mp.command("cycle pause")
                mp.set_property("window-dragging", "no")
            else
                mp.command("cycle pause")
            end
        end
    
    elseif table.event == "up" then
        -- Fin del arrastre
        state.dragging = false
        state.last_seek_pct = -1
        state.visual_seek_pct = -1
        mp.set_property("window-dragging", "yes")
    end
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
mp.add_key_binding("MOUSE_BTN0", "mouse_master", mouse_handler, {complex=true})
mp.add_forced_key_binding("mouse_move", "mouse_move", input_handler)
update_dimensions()