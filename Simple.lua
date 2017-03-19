-- Simple

local Brush = cimport "Brush"
local Simple = class(Brush)

function Simple:init(tb)
    Brush.init(self,"Simple",tb)
end

function Simple:stroke(x,id,t)
    self:basicStroke(x,id,t)
end

if _M then
    return Simple
end
