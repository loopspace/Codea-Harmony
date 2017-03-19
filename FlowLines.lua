-- FlowLines, version 1

local Brush = cimport "Brush"
cimport "NumberSpinner"
local Colour = cimport "Colour"
cimport "ColourNames"
cimport "Coordinates"

local FlowLines = class(Brush)


function FlowLines:init(tb)
    Brush.init(self,"Flow Lines",tb)
    self.ntouches = 0
    local om = tb.ui:addMenu({})
    for _,v in ipairs({
        {"Swirls", "swirls",0.001, 1, 0.01},
        {"Length of path", "framesToLive", 1, 600, 20},
        {"Curliness", "curliness", 1, 16, .1},
        {"Speed", "gspeed", 0.1, 5, 5},
        {"Size", "gsize", 0.1, 50, 1.5},
        {"Brightness Variation", "varyBrightness", 0.0, 1.0, 0.45}
    }) do 
    om:addItem({
        title = v[1],
        action = function()
            tb.ui:getNumberSpinner({
                value = self[v[2]],
                action = function(n)
                        self[v[2]] = n
                        return true
                    end,
                maxvalue = v[4],
                minvalue = v[3]
            })
            return true
        end,
    })
    self[v[2]] = v[5]
    end
    self.menu = om
    om:isChildOf(tb.brushstylemenu)
    self.seed = math.random(1000)
    self.lastpts = {}
end

function FlowLines:clear()
    Brush.clear(self)
    self.seed = math.random(1000)
    self.lastpts = {}
end

function FlowLines:stroke(x,id,t)
    local v = 1.0 - self.varyBrightness * math.random()
    local rc = Colour.shade(self.style.colour,v*100)
    if self.lastpts[id] then
        local dx = x - self.lastpts[id]
    local l = dx:len()
    dx = dx:normalize()
    local sw = self.swirls
    local s = self.seed
    local speedRnd = self.gspeed * ( 1+ math.random()/2)
    local r = 2 + self.gsize * ( 1 + math.random(-1,1)/2)
    local angle = math.pi * self.curliness * (1+l)/(.5+l)
    local px,sx,bx,ex,ax,sa,ea,st,et
    local pts = {}
    ex = x
    ea = 100
    px = noise((s+ex.x)*sw, (s+ex.y)*sw)
    dx = dx:rotate(px * angle)
    ax = ex - dx * speedRnd
    et = self.style.thickness
    for i = 1,self.framesToLive do
        if
            x.x < 0 or
            x.x > RectAnchorOf(Portrait,"width") or
            x.y < 0 or
            x.y > RectAnchorOf(Portrait,"height")
        then
            break
        end
        bx = sx
        sx = ex
        ex = ax
        sa = ea
        st = et
        px = noise((s+ex.x)*sw, (s+ex.y)*sw)
        dx = dx:rotate(px * angle)
        ax = ax - dx * speedRnd * (1 - .1*math.random())
        ea = (1 - i / self.framesToLive) * 100
        et = (1 - i / self.framesToLive) * self.style.thickness
        self:addLine({
            before = bx,
            start = sx,
            finish = ex,
            after = ax,
            colour = rc,
            startOpacity = sa,
            endOpacity = ea,
            startThickness = st,
            endThickness = et,
            startCap = CAPNONE,
            endCap = CAPNONE
            })
    end

    end
    self.lastpts[id] = x
end

if _M then
    return FlowLines
end

