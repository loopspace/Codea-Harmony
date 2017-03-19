-- Chrome

local BrushEx = cimport "BrushEx"
local Colour = cimport "Colour"
local Chrome = class(BrushEx)

function Chrome:init(tb)
    BrushEx.init(self,"Chrome",tb)
    self.ntouches = 0
end

function Chrome:stroke(x,id,t)
    self:basicStroke(x,id,t)
    local c = Colour.opacity(self.style.colour,20)
    if self.lines[id] then
    local dx, d, a
    local l = self.lines[id].start - x
    for i = 1, self.count do
        dx = self.points[i] - x
        d = dx:lenSqr()
        a = math.abs(dx:angleBetween(l))
        if d < 1000 and a > .1 then
            self:addLine({
                start = x + dx * 0.2,
                finish = self.points[i] - dx * 0.2,
                colour = c,
                ends = true
                })
        end
    end
    end
end

if _M then
    return Chrome
end
