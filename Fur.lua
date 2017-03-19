-- Fur
--[==[
local BrushEx = cimport "BrushEx"
local Colour = cimport "Colour"
local Fur = class(BrushEx)

function Fur:init(tb)
    BrushEx.init(self,"Fur",tb)
end

function Fur:stroke(x,id,t)
    self:basicStroke(x,id,t)
    
    local c = Colour.opacity(self.style.colour,20)
    
    local dx, d
    
    for i = 1, self.count do
        dx = self.points[i] - x
        d = dx:lenSqr()
        if d < 2000 and math.random() > d/2000 then
            self:addLine({
                start = x + dx * 0.5,
                finish = x - dx * 0.5,
                colour = c,
                ends = true
                })
        end
    end
end
return Fur
--]==]