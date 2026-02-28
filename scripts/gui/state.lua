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
    has_file = false,
    
    -- Active element locking (mpv-osc-modern pattern)
    active_element = nil,
    
    -- Volume
    volume = 100,
    muted = false,
    
    -- Visual seek during drag
    visual_seek_pct = -1,
    
    -- Window-dragging control
    control_area_active = false,
}

return state
