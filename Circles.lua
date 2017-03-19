-- Discs

local Brush = cimport "Brush"
local Discs = class(Brush)

function Discs:init(tb)
    Brush.init(self,"Discs",tb)
end

function Discs:stroke(x,id,t)

    local dx = x - self.lines[id].finish
    self.lines[id].finish = x
    local d = 2*dx:len()
    local cx = math.floor(x.x / 100) * 100 + 50
    local cy = math.floor(x.y / 100) * 100 + 50
    local c = vec2(cx,cy)
    local steps = math.floor( math.random() * 10 )
    local step_delta = d / steps
        
    for i = 0, steps do
        self:addCircle({
            centre = c,
            radius = (steps - i) * step_delta
            })
    end
end

if _M then
    return Discs
end
