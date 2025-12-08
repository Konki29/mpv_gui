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

return state
