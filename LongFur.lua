-- LongFur
--[==[
local BrushEx = cimport "BrushEx"
local Colour = cimport "Colour"
local LongFur = class(BrushEx)

function LongFur:init(tb)
    BrushEx.init(self,"Long Fur",tb)
end


function LongFur:stroke(x,id,t)
    self:basicStroke(x,id,t)
    local c = Colour.opacity(self.style.colour,10)
    
    local dx, d
    
    for i = 1, self.count do
        size = -math.random()
        dx = self.points[i] - x
        d = dx:lenSqr()
        if d < 4000 and math.random() > d/4000 then
            self:addLine({
                start = x + dx * size,
                finish = x - dx * size,
                colour = c,
                ends = true
                })
        end
    end
end
return LongFur
--]==]