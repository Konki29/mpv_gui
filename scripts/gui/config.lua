local mp_options = require 'mp.options'

local opts = {
    scale = 1,
    
    -- Virtual resolution base (like mpv-osc-modern)
    base_res_y = 720,
    
    -- Progress bar (all values in virtual 720p pixels)
    bar_height = 4,
    bar_hover_height = 8,
    handle_size = 14,
    color_played = "FF0000",
    
    -- Layout (virtual pixels)
    box_height = 100,
    bar_y_offset = 70,
    controls_y_offset = 30,
    bar_hover_margin = 20,
    
    bar_margin_left = 25,
    bar_margin_right = 25,
    
    -- Font
    font = "Segoe UI",
    font_size = 18,
    
    -- Behavior
    mouse_wheel_volume = true,
    volume_step = 5,
    seek_step = 5,
    auto_hide_timeout = 2,
    
    -- Volume slider (virtual pixels)
    volume_slider_width = 80,
    
    -- Subtitles
    subtitle_font_size = 20,
    
    -- Window controls
    show_window_controls = true,
}

mp_options.read_options(opts, "custom_osc")

return opts