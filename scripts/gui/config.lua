local opts = {
    scale = 1,
    
    -- Progress bar
    bar_height = 3,
    bar_hover_height = 5,
    handle_size = 14,
    color_played = "0000FF",  -- Red in BGR
    
    -- Layout: single bottom bar
    box_height = 70,           -- Total control area height
    bar_y_offset = 45,         -- Bar distance from bottom
    controls_y_offset = 16,    -- Controls row distance from bottom
    bar_hover_margin = 20,     -- Vertical margin for bar hover detection
    
    -- Horizontal margins
    bar_margin_left = 20,
    bar_margin_right = 20,
    
    -- Styles
    color_bg = "FFFFFF",
    opacity_bg = "CC",
    font_size = 14,
}

return opts