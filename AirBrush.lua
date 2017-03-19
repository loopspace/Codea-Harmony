-- AirBrush

local Brush = cimport "Brush"
local AirBrush = class(Brush)

function AirBrush:init(tb)
    Brush.init(self,"Air Brush",tb)
end

function AirBrush:stroke(x,id,t)
    local dx = x - self.lines[id].finish
    self.lines[id].finish = x
    local dist = 100/(dx:len() +1) + 4
    self:addDisc({
        centre = x,
        radius = dist * self.style.thickness / 2,
        edgeOpacity = 0,
        smooth = false
    })
end

function AirBrush:strokeEnd(v,id)
    self.lastline = self.lines[id]
    self.lines[id] = nil
end

if _M then
    return AirBrush
end
