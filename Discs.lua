-- Circles

--[==[
local Brush = cimport "Brush"
local Circles = class(Brush)

function Circles:init(tb)
    Brush.init(self,"Circles",tb)
end

function Circles:stroke(x,id,t)
    local dx = x - self.lines[id].finish
    self.lines[id].finish = x
    local dist = dx:len()
    self:addCircle({
        centre = x,
        radius = dist * self.style.thickness / 2,
        thickness = self.style.thickness / 4
        })

end

return Circles
--]==]