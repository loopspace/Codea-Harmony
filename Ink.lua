-- Ink

local Brush = cimport "Brush"
local Ink = class(Brush)

function Ink:init(tb)
    Brush.init(self,"Ink",tb)
end

function Ink:stroke(x,id,t)
    t = t or {}
    t.startThickness = self.lines[id].endThickness
    local w = t.thickness or self.style.thickness
    local y = self.lines[id].finish
    t.endThickness = w*(math.atan((x - y):lenSqr())/math.pi+2)
    self:basicStroke(x,id,t)
end

if _M then
    return Ink
end
