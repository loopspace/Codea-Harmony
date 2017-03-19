-- Web

--[==[
local BrushEx = cimport "BrushEx"
local Colour = cimport "Colour"
local Web = class(BrushEx)

function Web:init(tb)
    BrushEx.init(self,"Web",tb)
end

function Web:stroke(x,id,t)
    self:basicStroke(x,id,t)

    local c = Colour.opacity(self.style.colour,20)
    
    local dx, d

    for i = 1, self.count do
        dx = self.points[i] - x
        d = dx:lenSqr()

        if (d < 2500 and math.random() > 0.9) then
            self:addLine({
                start = x + dx, 
                finish = self.points[i] - dx,
                colour = c,
                ends = true
                })
        end
    end
end

return Web
--]==]
