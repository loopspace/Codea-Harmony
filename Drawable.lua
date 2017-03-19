
local Drawable = class()

function Drawable:init(name,tb)
    self.style = tb.style
    self.name = name
end

function Drawable:draw()
end

function Drawable:predraw()
end

function Drawable:getName()
    return self.name
end

function Drawable:isTouchedBy(touch)
    return true
end

function Drawable:processTouches(g)
    g:noted()
end

function Drawable:bake()
    self:draw()
end

function Drawable:isFinished()
    return self.isfinished
end

function Drawable:drawIcon()
end

function Drawable:setAlpha(aim)
end

function Drawable:reset()
end

function Drawable:undo()
end

function Drawable:redo()
end

function Drawable:clear()
    self.isfinished = false
end

function Drawable:updateStyle()
end

if _M then
    return Drawable
end
