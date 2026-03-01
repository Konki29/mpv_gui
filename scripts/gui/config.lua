local mp_options = require 'mp.options'

local opts = {
    scale = 1,
    
    -- Progress bar
    bar_height = 4,
    bar_hover_height = 8,
    handle_size = 16,
    color_played = "0000FF",
    
    -- Layout
    box_height = 120,
    bar_y_offset = 80,
    controls_y_offset = 30,
    bar_hover_margin = 22,
    
    -- Horizontal margins
    bar_margin_left = 20,
    bar_margin_right = 20,
    
    -- Font (use a clean sans-serif that exists on Windows)
    font = "Segoe UI",
    font_size = 16,
    
    -- Behavior
    mouse_wheel_volume = true,
    volume_step = 5,
    seek_step = 5,
    auto_hide_timeout = 2,
    
    -- Volume slider
    volume_slider_width = 80,
    
    -- Subtitles
    subtitle_font_size = 24,
    
    -- Window controls
    show_window_controls = true,
}

mp_options.read_options(opts, "custom_osc")

return opts