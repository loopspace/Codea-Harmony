-- InkBlobs

--[==[
local Brush = cimport "Brush"
local InkBlobs = class(Brush)

function InkBlobs:init(tb)
    Brush.init(self,"Fish Bone",tb)
end

function InkBlobs:stroke(x,id,t)
    t = t or {}
    t.startThickness = t.endThickness
    local w = t.thickness or self.style.thickness
    local y = self.lines[id].finish
    t.endThickness = w*(x - y):len()
    self:basicStroke(x,id,t)
end

return InkBlobs
--]==]