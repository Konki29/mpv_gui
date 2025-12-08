local mp = require 'mp'
local Element = require 'gui.elements.Element'
local PlayButton = setmetatable({}, {__index = Element})
PlayButton.__index = PlayButton

function PlayButton.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, PlayButton)
end

function PlayButton:handle_input(event, x, y)
    if event == "down" then
        -- Simple zone check for play button area
        -- In the original code it was "not seekbar", so general click area
        -- Here we can be more specific or generic. 
        -- Original logic: if x < 60 and bottom area -> pause. OR just general click toggle.
        -- Let's stick to the visual area of the button for specificity 
        -- OR follow the original logic which was looser.
        
        -- Let's make it specific to the icon area + padding
        local icon_y = self.state.h - self.opts.box_height / 2
        local icon_x = 20
        local radius = 20
        
        if math.abs(x - icon_x) < radius and math.abs(y - icon_y) < radius then
             mp.command("cycle pause")
             return true
        end
        
        -- Fallback: Original code had a loose "click anywhere else" policy?
        -- Original code:
        -- if state.mouse_x < 60 and state.mouse_y > (state.h - opts.box_height) then ... else cycle pause end
        -- It seems clicking ANYWHERE not on the bar toggled pause.
        
        if y > (self.state.h - self.opts.box_height) then
            -- Click in the control box area but not on specific buttons
             mp.command("cycle pause")
             return true
        end
    end
    return false
end

function PlayButton:draw(ass)
    local icon_y = self.state.h - self.opts.box_height / 2
    local cur_x = 20
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if self.state.paused then
        ass:move_to(0, -10)
        ass:line_to(15, 0)
        ass:line_to(0, 10)
    else
        ass:rect_cw(0, -10, 5, 10)
        ass:rect_cw(10, -10, 15, 10)
    end
    ass:draw_stop()
end

return PlayButton
