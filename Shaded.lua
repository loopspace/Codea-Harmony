-- Shaded

--[==[
local BrushEx = cimport "BrushEx"
local Colour = cimport "Colour"
local Shaded = class(BrushEx)


function Shaded:init(tb)
    BrushEx.init(self,"Shaded",tb)
end

function Shaded:stroke(x,id,t)
    local dx, d

    for i = 1, self.count do
        dx = self.points[i] - x
        d = dx:lenSqr()

        if (d < 1000) then
            self:addLine({
                start = x,
                finish = self.points[i],
                colour = Colour.opacity(self.style.colour,(1 - (d / 1000)) * 10),
                ends = true
                })
        end
    end
end

return Shaded
--]==]
