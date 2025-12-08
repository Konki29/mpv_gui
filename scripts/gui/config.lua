local opts = {
    scale = 1,
    
    -- Barra de progreso
    bar_height = 4,
    bar_hover_height = 5,
    handle_size = 16,        -- Tamaño del círculo handle
    color_played = "0000FF", -- Rojo en BGR (MPV usa BGR)
    
    -- Layout de 2 filas (más espacio vertical)
    box_height = 300,         -- Altura total del área de controles (aumentada)
    bar_row_offset = 150,     -- Offset desde abajo para la fila de la barra (más arriba)
    controls_row_offset = 50, -- Offset desde abajo para la fila de controles
    bar_hover_margin = 30,    -- Margen vertical para detectar hover en la barra
    
    -- Márgenes horizontales
    bar_margin_left = 20,     -- Margen izquierdo de la barra
    bar_margin_right = 20,    -- Margen derecho de la barra
    play_icon_centered = true,-- Botón play centrado horizontalmente
    time_margin_right = 20,   -- Margen derecho del tiempo
    
    -- Estilos
    color_bg = "FFFFFF",
    opacity_bg = "CC",
    font_size = 16,
}

return opts