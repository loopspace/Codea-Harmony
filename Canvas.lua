-- Canvas
--[==[


local JOINNONE = 0
local JOINMOVE = 1
local JOINLINE = 2
local CAPNONE = 0
local CAPSQUARE = 1
local CAPBUTT = 2
local CAPROUND = 3

local BLENDS = {
    {"Normal",{NORMAL}},
    {"Multiply",{MULTIPLY}},
    {"Additive",{ADDITIVE}},
    {"Eraser",{ZERO,ONE_MINUS_SRC_ALPHA}},
    {"Inverter",{ONE_MINUS_DST_COLOR,ONE_MINUS_SRC_COLOR,ZERO,ONE}},
    {"Mask",{ZERO,SRC_COLOR,ZERO,ONE}},
    {"Replace",{ONE,ZERO,ONE,ZERO}}
}

local Canvas = class()
local Colour = cimport "Colour"
cimport "ColourNames"
cimport "Keyboard"
cimport "Keypad"
cimport "PictureBrowser"
cimport "FontPicker"
cimport "Menu"
cimport "Coordinates"
cimport "ColourWheel"

local TextBlock = cimport "TextBlock"
local Picture = cimport "Picture"
local Brushes = {
    "FlowLines",
    "AirBrush",
    "Chrome",
    "Circles",
    "Discs",
    "Fur",
    "LongFur",
    "Shaded",
    "Simple",
    "Sketchy",
    "Squares",
    "Web",
    "Ink",
    "InkBlobs"
}

for _,v in ipairs(Brushes) do
    cimport (v)
end

function Canvas:init(t)
    t = t or {}
    if t.touchHandler then
        t.touchHandler:pushHandler(self)
    end
    self.ui = t.ui
    self.style = {
        thickness = 2,
        minthickness = 2,
        maxthickness = 15,
        blur = 1,
        smooth = true,
        bgcolour = Colour.opacity(Colour.svg.White,25),
        curve = false,
        join = JOINMOVE,
        cap = CAPBUTT,
        hidden = false,
        colour = Colour.svg.Black,
        alpha = 100,
        txtcolour = Colour.svg.Black,
        txtbgcolour = Colour.transparent,
        font = "Georgia",
        fontsize = 32,
        keyboard = "fullqwerty",
        blendmode = BLENDS[1][2],
        picture = {
            red = color(255, 0, 0, 0),
            green = color(0, 255, 0, 0),
            blue = color(0, 0, 255, 0),
            alpha = color(0, 0, 0, 255),
            redcurve = vec4(0,1,0,0),
            greencurve = vec4(0,1,0,0),
            bluecurve = vec4(0,1,0,0),
            alphacurve = vec4(0,1,0,0),
            brightness = vec4(0,1,0,0)
        }
    }
        
    if t.initialStyle then
        self:setStyle(t.initialStyle)
    end
    local useText = true
    local usePictures = true
    local singleBrush = false
    if t.enableText ~= nil then
        useText = t.enableText
    end
    if t.enablePictures ~= nil then
        usePictures = t.enablePictures
    end
    if t.brushes ~= nil then
        if type(t.brushes) == "table" then
            if #t.brushes == 1 then
                singleBrush = true
            end
        elseif type(t.brushes) == "string" then
            singleBrush = true
        end
    end
    
    if useText then
        t.ui:declareKeyboard({
            name = "ArialMT",
            type = self.style.keyboard
        })
    end
    if usePictures then
    t.ui:setPictureList({directory = "Documents", 
                camera = true,
                 filter = function(n,w,h) 
                    return math.min(w,h) > 500 
                    end})
    end
        -- meshes
        -- Background mesh, holding the background image
    self.bgmesh = mesh()
    self.bgmesh:addRect(
        Portrait[3]/2,Portrait[4]/2,Portrait[3],Portrait[4])
    self.bgmesh:setColors(Colour.svg.White)
    self.bgtcoords =  {
    vec2(0,0),vec2(1,0),vec2(1,1),vec2(0,0),vec2(1,1),vec2(0,1)
        } -- normal
    self.bgmesh.texCoords = self.bgtcoords
    -- canvas mesh, everything drawn so far
    self.canvas = image(Portrait[3],Portrait[4])
    self.canvasmesh = mesh()
    self.canvasmesh:addRect(
        Portrait[3]/2,Portrait[4]/2,Portrait[3],Portrait[4])
    self.canvasmesh.texture = self.canvas
    self.canvasmesh:setRectTex(1,0,0,1,1)
    -- undo mesh, very latest drawing
    self.undoimage = image(Portrait[3],Portrait[4])
    -- undo booleans
    self.undoable = false
    self.undo = true
    self.redoable = false
    -- for rendering alpha
    self.cvs = image(Portrait[3],Portrait[4])
    self.cvsmesh = mesh()
    self.cvsmesh:addRect(
        Portrait[3]/2,Portrait[4]/2,Portrait[3],Portrait[4])
    self.cvsmesh.texture = self.cvs
    --self.alphaim = image(5,5)
    -- menus
        local attach = true
        if t.attachMenu ~= nil then
            attach = t.attachMenu
        end
    local m = t.ui:addMenu({
        title = t.title or "Drawing",
        attach = attach
    })
    local stm = t.ui:addMenu({
        title = t.styleTitle or "Style",
        attach = attach
    })
    self.menu = m
    self.stylemenu = stm
    local bm,txtm,picm
    if not singleBrush then
        bm = t.ui:addMenu({})
        self.brushmenu = bm
        bm:isChildOf(m)
    end
    local bgm = t.ui:addMenu({})
    if useText then
        txtm = t.ui:addMenu({})
        txtm:isChildOf(stm)
    end
    if usePictures then
        picm = t.ui:addMenu({})
        picm:isChildOf(stm)
    end
    local sbm = t.ui:addMenu({})
    local bsm = t.ui:addMenu({})
    local pcm = t.ui:addMenu({})
    self.brushstylemenu = sbm
    local sm = t.ui:addMenu({})
    sbm:isChildOf(stm)
    sm:isChildOf(m)
    bgm:isChildOf(stm)
    bsm:isChildOf(sbm)
    pcm:isChildOf(sbm)

    if not singleBrush then
    m:addItem({
       title = "Brushes",
        action = function(x,y)
            bm.active = not bm.active
            bm.x = x
            bm.y = y
        end,
        highlight = function()
            return bm.active
        end,
        deselect = function()
            bm.active = false
        end,
    })
    end
    stm:addItem({
       title = "Brush Style",
        action = function(x,y)
            if sbm.active then
                sbm:deactivateDown()
            else
                sbm:activate()
                sbm.x = x
                sbm.y = y
            end
        end,
        highlight = function()
            return sbm.active
        end,
        deselect = function()
            sbm:deactivateDown()
        end,
    })
    sbm:addItem({
        title = "Colour",
        action = function()
            local col = self.style.colour
            col.a = self.style.alpha*2.55
            t.ui:getColour(
                col,
                function(c) self:setColour(c) return true end
            )
            return true
        end
    })
    sbm:addItem({
        title = "Thickness",
        action = function()
            t.ui:getParameter(
                self.style.thickness,
                self.style.minthickness,
                self.style.maxthickness,
                function(t)
                    self.style.thickness = t
                    return true
                end,
                function(t)
                    self.style.thickness = t
                    return true
                end
            )
            return true
        end
    })
    sbm:addItem({
        title = "Blur",
        action = function()
            t.ui:getParameter(
                self.style.blur,
                0,
                10,
                function(t)
                    self.style.blur = t
                    return true
                end,
                function(t)
                    self.style.blur = t
                    return true
                end
            )
            return true
        end
    })
    sbm:addItem({
        title = "Smooth",
        action = function()
            self.style.smooth = not self.style.smooth
            return true
        end,
        highlight = function() return self.style.smooth end
    })
    sbm:addItem({
       title = "Blend Style",
        action = function(x,y)
            if bsm.active then
                bsm:deactivateDown()
            else
                bsm:activate()
                bsm.x = x
                bsm.y = y
            end
        end,
        highlight = function()
            return bsm.active
        end,
        deselect = function()
            bsm:deactivateDown()
        end,
    })
    --[[
    sbm:addItem({
        title = "Curve",
        action = function()
            self.style.curve = not self.style.curve
            return true
        end,
        highlight = function() return self.style.curve end
    })
    --]]
    sbm:addItem({
        title = "Join paths (line)",
        action = function()
        if self.style.join == JOINLINE then
            self.style.join = JOINNONE
        else
            self.style.oldjoin = self.style.join
            self.style.join = JOINLINE
        end
            return true
        end,
        highlight = function() return self.style.join == JOINLINE end
    })
    sbm:addItem({
        title = "Join paths (move)",
        action = function()
        if self.style.join == JOINMOVE then
            self.style.join = JOINNONE
        else
            self.style.join = JOINMOVE
        end
            return true
        end,
        highlight = function() return self.style.join == JOINMOVE end
    })
    sbm:addItem({
       title = "Path Cap",
        action = function(x,y)
            if pcm.active then
                pcm:deactivateDown()
            else
                pcm:activate()
                pcm.x = x
                pcm.y = y
            end
        end,
        highlight = function()
            return pcm.active
        end,
        deselect = function()
            pcm:deactivateDown()
        end,
    })
    pcm:addItem({
        title = "Butt",
        action = function()
            self.style.cap = CAPBUTT
            return true
        end,
        highlight = function() return self.style.cap == CAPBUTT end
    })
    pcm:addItem({
        title = "Square",
        action = function()
            self.style.cap = CAPSQUARE
            return true
        end,
        highlight = function() return self.style.cap == CAPSQUARE end
    })
    pcm:addItem({
        title = "Round",
        action = function()
            self.style.cap = CAPROUND
            return true
        end,
        highlight = function() return self.style.cap == CAPROUND end
    })
    sbm:addItem({
        title = "Clear Current History",
        action = function()
            self.drawable:reset()
            return true
        end
    })
    sbm:addItem({
        title = "Unclog Pen",
        action = function()
            self.drawable.touchId = nil
            return true
        end
    })
    sbm:addItem({
        title = "Specific Options",
        action = function(x,y)
            if self.drawable.menu then
                self.drawable.menu.active = 
                    not self.drawable.menu.active
                self.drawable.menu.x = x
                self.drawable.menu.y = y
            end
            end,
        highlight = function()
                if self.drawable.menu then
                    return self.drawable.menu.active
                else
                    return false
                end
            end,
        deselect = function()
                if self.drawable.menu then
                    self.drawable.menu.active = false
                end
        end,
    })
    for _,v in ipairs(BLENDS) do
    bsm:addItem({
        title = v[1],
        action = function()
                self.style.blendmode = v[2]
            return true
        end,
        highlight = function()
            return self.style.blendmode == v[2]
        end,
    })
    end
    stm:addItem({
       title = "Background",
        action = function(x,y)
            bgm.active = not bgm.active
            bgm.x = x
            bgm.y = y
        end,
        highlight = function()
            return bgm.active
        end,
        deselect = function()
            bgm.active = false
        end
    })
    if useText then
    m:addItem({
        title = "Add Node",
        action = function()
            self:drawcanvas()
            self.drawable = TextBlock(self,t.ui)
            return true
        end
    })
    stm:addItem({
       title = "Text Style",
        action = function(x,y)
            txtm.active = not txtm.active
            txtm.x = x
            txtm.y = y
        end,
        highlight = function()
            return txtm.active
        end,
        deselect = function()
            txtm.active = false
        end
    })
    end
    if usePictures then
    m:addItem({
        title = "Add Picture",
        action = function()
            self:drawcanvas()
            self.drawable = Picture(self,t.ui)
            return true
        end
    })
    stm:addItem({
        title = "Picture Style",
        action = function(x,y)
            picm.active = not picm.active
            picm.x = x
            picm.y = y
        end,
        highlight = function()
            return picm.active
        end,
        deselect = function()
            picm.active = false
        end
    })
    for _,v in ipairs({
        {"Red", "red"},
        {"Green", "green"},
        {"Blue", "blue"},
        {"Alpha", "alpha"}
    }) do
    picm:addItem({
        title = v[1] .. " Channel",
        action = function()
            t.ui:getColour(
                self.style.picture[v[2]],
                function(c) 
                    self.style.picture[v[2]] = c
                    self.drawable:updateStyle()
                    return true
                end
            )
            picm:deactivateUp()
            return true
        end
    })
    picm:addItem({
        title = v[1] .. " Curve",
        action = function()
            t.ui:getCurve(
                self.style.picture[v[2] .. "curve"],
                function(c) 
                    self.style.picture[v[2] .. "curve"] = c
                    self.drawable:updateStyle()
                    return true
                end,
                function(c) 
                    self.style.picture[v[2] .. "curve"] = c
                    self.drawable:updateStyle()
                end
            )
            picm:deactivateUp()
            return true
        end
    })
    end
    picm:addItem({
        title = "Brightness",
        action = function()
            t.ui:getCurve(
                self.style.picture.brightness,
                function(c) 
                    self.style.picture.brightness = c
                    self.drawable:updateStyle()
                    return true
                end,
                function(c) 
                    self.style.picture.brightness = c
                    self.drawable:updateStyle()
                end
            )
            picm:deactivateUp()
            return true
        end
    })
    picm:addItem({
        title = "Reset Values",
        action = function()
            self.style.picture = {
                red = color(255, 0, 0, 0),
                green = color(0, 255, 0, 0),
                blue = color(0, 0, 255, 0),
                alpha = color(0, 0, 0, 255),
                redcurve = vec4(0,1,0,0),
                greencurve = vec4(0,1,0,0),
                bluecurve = vec4(0,1,0,0),
                alphacurve = vec4(0,1,0,0),
                brightness = vec4(0,1,0,0)
            }
            self.drawable:updateStyle()
            return true
        end
    })

    bgm:addItem({
        title = "Background Image",
        action = function()
            t.ui:getPicture(
                function(i)
                    self.bgmesh.texture = i
                    return true
                end
            )
            return true
        end
    })
    bgm:addItem({
        title = "Clear Background Image",
        action = function()
                    self.bgmesh.texture = nil
            return true
        end
    })
    for _,v in ipairs({
        {"Rotate Clockwise", USRotateCCW}, -- rotate tex coords other way
        {"Rotate Anticlockwise", USRotateCW},
        {"Reflect Horizontally", USReflectH},
        {"Reflect Vertically", USReflectV},
            }) do
    bgm:addItem({
        title = v[1],
        action = function()
            for l,u in ipairs(self.bgtcoords) do
                self.bgtcoords[l] = v[2](u)
            end
            self.bgmesh.texCoords = self.bgtcoords
            return true
        end
    })
    end

    bgm:addItem({
        title = "Background Image Tint",
        action = function()
            t.ui:getColour(
                function(c)
                    self.bgmesh:setColors(c)
                    return true
                end
            )
            return true
        end
    })
    end
    bgm:addItem({
        title = "Background Colour",
        action = function()
            t.ui:getColour(
                self.style.bgcolour,
                function(c)
                    self.style.bgcolour = c
                    return true
                end
            )
            return true
        end
    })
    m:addItem({
        title = "Undo",
        action = function()
        if self.undoable then
            self.undo = true
            self.redoable = true
            self.undoable = false
            self.drawable:undo()
            return true
        end
        return false
        end,
        highlight = function()
            return self.undoable
        end
    })
    m:addItem({
        title = "Redo",
        action = function()
        if self.redoable then
            self.undo = false
            self.undoable = true
            self.redoable = false
            self.drawable:redo()
            return true
        end
        return false
        end,
        highlight = function()
            return self.redoable
        end
    })
    m:addItem({
       title = "Save to ...",
        action = function(x,y)
            sm.active = not sm.active
            sm.x = x
            sm.y = y
        end,
        highlight = function()
            return sm.active
        end,
        deselect = function()
            sm.active = false
        end
    })
    for _,d in ipairs({"Documents","Dropbox"}) do
    sm:addItem({
        title = d,
        action = function()
            t.ui:getText(
                function(s)
                    self:export(d,s)
                    return true
                end)
            return true
            end
    })
    end
    m:addItem({
        title = "Use Stylus",
        action = function()
                self.stylus = true
            return true
        end,
        highlight = function()
                return self.stylus
        end
    })
    m:addItem({
        title = "Clear Canvas",
        action = function()
                self:clear()
            return true
        end
    })
    if useText then
    txtm:addItem({
        title = "Text Colour",
        action = function()
            t.ui:getColour(
                self.style.txtcolour,
                function(c)
                    self.style.txtcolour = c
                    self.drawable:updateStyle()
                    return true
                end
            )
            return true
        end
    })
    txtm:addItem({
        title = "Text Background Colour",
        action = function()
            t.ui:getColour(
                self.style.txtbgcolour,
                function(c)
                    self.style.txtbgcolour = c
                    self.drawable:updateStyle()
                    return true
                end
            )
            return true
        end
    })
    txtm:addItem({
        title = "Font",
        action = function()
            t.ui:getFont(
                function(c)
                    self.style.font = c
                    self.drawable:updateStyle()
                    return true
                end
            )
            return true
        end
    })
    txtm:addItem({
        title = "Font Size",
        action = function()
            t.ui:getNumber(
                function(c)
                    self.style.fontsize = c
                    self.drawable:updateStyle()
                    return true
                end
            )
            return true
        end
    })
    end
    t.ui:addHelp({
        title = "Drawing",
        text = "Select a brush to draw a path with different effects.  A path can be drawn in more than one go by selecting one of the \"join\" methods (\"line\" means that the segments are actually joined together).  In this case, the effect uses the whole path.  The alpha value of the colour is applied after a segment is completed meaning that crossings on the same segment are not overlaid but crossings on different segments are."
    })
    self:initBrushes(t.brushes)
end

function Canvas:hide()
    self.hidden = true
end

function Canvas:unhide()
    self.hidden = false
end

function Canvas:exportIfDrawn(...)
    if self.drawnon then
        self:export(...)
    end
end

function Canvas:export(d,s,o)
    self:drawcanvas()
    local sn = s
    if d then
    if not o then
        local l = assetList(d,SPRITES)
        local lt = {}
        for _,v in ipairs(l) do
            lt[v] = true
        end
        local n = 0
        while lt[sn] do
            n = n + 1
            sn = string.format("%s%03d",s,n)
        end
    end
        sn = d .. ":" .. sn
    end
    saveImage(sn,self.canvas)
    popStyle()
    popMatrix()
end
    


function Canvas:setColour(c)
    self.style.colour = Colour.opaque(c)
    self.style.alpha = c.a/2.55
    self:setLineAlpha()
end

function Canvas:setLineAlpha(a)
    a = a or self.style.alpha
    --[[
    self.alphaim = image(5,5)
    pushMatrix()
    pushStyle()
    resetMatrix()
    resetStyle()
    noSmooth()
    fill(Colour.opacity(Colour.svg.White,a))
    setContext(self.alphaim)
    rect(0,0,5,5)
    setContext()
    popStyle()
    popMatrix()
    --]]
    self.drawable:setAlpha(a)
end

-- Brushes Management

function Canvas:initBrushes(br)
    local t = Brushes
    local brn
    if br then
        brn = {}
        if type(br) == "string" then
            brn[br] = true
        else
            for _,v in ipairs(br) do
                brn[v] = true
            end
        end
    end
    local cb,dobrush,brush

    local m = self.brushmenu
    for _,v in ipairs(t) do
        dobrush = true
        if brn then
            if not brn[v] then
                dobrush = false
            end
        end
        if dobrush then
            brush = cimport (v)
            local b = brush(self)
            if not cb then cb = b end
            if m then 
                m:addItem({
                    title = b:getName(),
                    action = function()
                        if self.drawable ~= b then
                            self:drawcanvas()
                            self.drawable = b
                        end
                        return true
                    end,
                    highlight = function()
                    return self.drawable == b
                    end
                })
            end
        end
    end
    self.drawable = cb
    self:setLineAlpha()
end

function Canvas:setBrush(b)
    if self.brushmenu then
        self.brushmenu:invoke(b)
    end
end

function Canvas:isTouchedBy(touch)
    self.drawnon = true
    return self.drawable:isTouchedBy(touch)
end

function Canvas:processTouches(g)
if self.stylus then
    g:removeTouches(function(t) if t.touch.radius > 15 then return true else return false end end)
end
    self.drawable:processTouches(g)
end

function Canvas:draw()
    pushMatrix()
    TransformOrientation(PORTRAIT)
    local w,h = RectAnchorOf(Portrait,"size")
    self.drawable:predraw()
    if self.drawable:isFinished() then
        self:drawcanvas()
    end
    pushStyle()
    noSmooth()
    blendMode(NORMAL)
    --background(255, 255, 255, 255)
    self.bgmesh:draw()
    fill(self.style.bgcolour)
    noStroke()
    rectMode(CORNER)
    rect(0,0,w,h)
    self.canvasmesh:draw()
    --blendMode(unpack(self.style.blendmode))
    self.drawable:draw()
    --blendMode(NORMAL)
    popStyle()
    popMatrix()
    if not self.hidden then
        self.drawable:drawIcon()
    end
end

function Canvas:drawcanvas()
    pushStyle()
    pushMatrix()
    resetStyle()
    resetMatrix()
    noSmooth()
    setContext(self.undoimage)
    blendMode(NORMAL)
    background(Colour.transparent)
    self.canvasmesh:draw()
    setContext()
    -- local cvs = image(Portrait[3],Portrait[4])
    -- debug:log({name = "canvas", message = function() return cvs.width .. "," .. cvs.height end})
    self:setLineAlpha(100)
    setContext(self.cvs)
    blendMode(NORMAL)
    background(Colour.transparent)
    self.drawable:bake()
    setContext()
    self.cvsmesh:setColors(Colour.opacity(
                Colour.svg.White,self.style.alpha))
    setContext(self.canvas)
    blendMode(unpack(self.style.blendmode))
    self.cvsmesh:draw()
    setContext()
    self.drawable:clear()
    self.undoable = true
    self.redoable = false
    self.undo = false
    popMatrix()
    popStyle()
    self:setLineAlpha()
end

function Canvas:clear()
    setContext(self.canvas)
    background(Colour.transparent)
    setContext()
    setContext(self.undoimage)
    background(Colour.transparent)
    setContext()
    self.drawable:clear()
    self.drawnon = false
end

function Canvas:saveStyle()
    local t = {}
    for k,v in pairs(self.style) do
        t[k] = v
    end
    t.drawable = self.drawable:getName()
    return t
end

function Canvas:setStyle(t)
    if t.drawable then
        self:setBrush(t.drawable)
        t.drawable = nil
    end
    for k,v in pairs(t) do
        self.style[k] = v
    end
    self:setLineAlpha()
end

cmodule.gexport {
    JOINNONE = JOINNONE,
    JOINMOVE = JOINMOVE,
    JOINLINE = JOINLINE,
    CAPNONE = CAPNONE,
    CAPSQUARE = CAPSQUARE,
    CAPBUTT = CAPBUTT,
    CAPROUND = CAPROUND,
    BLENDS = BLENDS
}

return Canvas
--]==]

