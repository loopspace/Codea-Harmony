-- Sketchy

--[==[
local BrushEx = cimport "BrushEx"
local Colour = cimport "Colour"
local Sketchy = class(BrushEx)

function Sketchy:init(tb)
    BrushEx.init(self,"Sketchy",tb)
end

function Sketchy:stroke(x,id,t)
    self:basicStroke(x,id,t)
   
    local dx, d

    for i = 1, self.count do
        dx = self.points[i] - x
        d = dx:lenSqr()

        if (d < 4000 and math.random() > (d/2000)) then

            self:addLine({
                start = x + dx * 0.3,
                finish = self.points[i] - dx * 0.3,
                colour = Colour.opacity(self.style.colour,(1 - (d / 1000)) * 10),
                ends = true
                })

        end
    end
end

return Sketchy

--]==]