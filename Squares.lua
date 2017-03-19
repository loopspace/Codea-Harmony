-- Squares

local Brush = cimport "Brush"
local Squares = class(Brush)

function Squares:init(tb)
    Brush.init(self,"Squares",tb)
end

function Squares:stroke(x,id,t)
    local y = self.lines[id].finish
    local dx = x - y

    local angle = 1.57079633
    local p = dx:rotate(angle)
    local corners = {
        y - p,
        y + p,
        x + p,
        x - p
    }
    for k=1,4 do
        table.insert(corners,table.remove(corners,1))
    self:addLine({
        before = corners[1],
        start = corners[2],
        finish = corners[3],
        after = corners[4]
        })
    end
    self.lines[id].finish = x
end

if _M then
    return Squares
end
