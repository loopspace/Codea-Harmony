-- BrushEx

local Brush = cimport "Brush"
cimport "Coordinates"
BrushEx = class(Brush)

function BrushEx:init(name,tb)
    Brush.init(self,name,tb)
    self.points = {}
    self.count = 0
    self.pcount = 0
    self.lines = {}
    self.touches = {}
end

function BrushEx:reset()
    self.lines = {}
    self.points = {}
    self.count = 0
    self.pcount = 0
    self.lastline = nil
end

function BrushEx:undo()
    self.pcount,self.count = self.count,self.pcount
end

function BrushEx:redo()
    self.pcount,self.count = self.count,self.pcount
end

function BrushEx:predraw()
    for _,t in ipairs(self.touches) do
        local v = OrientationInverse(
            PORTRAIT, vec2(t.touch.x,t.touch.y))
        if t.touch.state == BEGAN then
            self.pcount = self.count
            self.lines[t.touch.id] = nil
            self:strokeStart(v,t.touch.id)
        elseif t.touch.state == MOVING then
            self:stroke(v,t.touch.id)
        else
            self:strokeEnd(v,t.touch.id)
        end
        self.count = self.count + 1
        self.points[self.count] = v
    end
    self.touches = {}
    if self.resetafter then
        self:reset()
        self.resetafter = false
    end
end

if _M then
    return BrushEx
end
