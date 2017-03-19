--[==[

local Drawable = cimport "Drawable"
local TextNode = cimport "TextNode"
local Font = unpack(cimport "Font")
local TextBlock = class(Drawable)
cimport "Coordinates"

function TextBlock:init(tb,ui)
    Drawable.init(self,"TextBlock",tb)
    self.node = TextNode({
        font = Font({name = self.style.font, 
                size = self.style.fontsize}),
        textColour = self.style.txtcolour,
        colour = self.style.txtbgcolour,
        width = "20em",
        maxHeight = "10lh",
        anchor = "centre",
        pos = function() return RectAnchorOf(Screen,"centre") end,
        fit = true,
        ui = ui,
        keyboard = self.style.keyboard
    })
    self.ostyle = {}
    for _,v in ipairs({
        "font",
        "fontsize",
        "txtcolour",
        "txtbgcolour"
        }) do
            self.ostyle[v] = self.style[v]
    end
end

function TextBlock:draw()
    pushMatrix()
    resetMatrix()
    self.node:draw()
    popMatrix()
end

function TextBlock:bake()
    self.node:setEdit(false)
    pushMatrix()
    TransformInverseOrientation(PORTRAIT)
    self.node:draw()
    popMatrix()
end

function TextBlock:isTouchedBy(touch)
    return self.node:isTouchedBy(touch)
end

function TextBlock:processTouches(g)
    self.node:processTouches(g)
end

function TextBlock:reset()
end

function TextBlock:updateStyle()
    if self.style.txtcolour ~= self.ostyle.txtcolour then
        self.node:setTextColour(self.style.txtcolour)
    end
    if self.style.font ~= self.ostyle.font
        or self.style.fontsize ~= self.ostyle.fontsize then
        self.node:setFont(Font(
            {name = self.style.font, size = self.style.fontsize}))
    end
    if self.style.txtbgcolour ~= self.ostyle.txtbgcolour then
        self.node:setColour(self.style.txtbgcolour)
    end
    for _,v in ipairs({
        "font",
        "fontsize",
        "txtcolour",
        "txtbgcolour"
        }) do
            self.ostyle[v] = self.style[v]
    end
end

return TextBlock
--]==]