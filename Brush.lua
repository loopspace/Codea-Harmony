-- Brush
--[==[

local Drawable = cimport "Drawable"
local Colour = cimport "Colour"
--cimport "Path"
cimport "Slider"
cimport "MeshUtilities"
cimport "Bezier"
cimport "Coordinates"
local Brush = class(Drawable)

function Brush:init(name,tb)
    Drawable.init(self,name,tb)
    self.lines = {}
    self.touches = {}
    self.mesh = mesh()
    self.mesh.shader = shader("Documents:Alpha Smooth")
    self.mesh.shader.alpha = self.alpha or 1
    self.mesh:resize(30000)
    self.nlines = 0
    self.beziers = {}
    self.nbeziers = 1
end

function Brush:reset()
    self.lines = {}
    self.lastline = nil
end

function Brush:clear()
    self.isfinished = false
    self.touches = {}
    self.mesh = mesh()
    self.mesh.shader = shader("Documents:Alpha Smooth")
    self.mesh.shader.alpha = self.alpha or 1
    self.mesh:resize(30000)
    self.nlines = 0
    self.beziers = {}
    self.nbeziers = 1
    self:reset()
end

function Brush:undo()
end

function Brush:redo()
end

function Brush:setAlpha(a)
    a = a/100
    self.alpha = a
    self.mesh.shader.alpha = a
end

function Brush:strokeStart(x,id)
    if self.style.join == JOINNONE then
        self.lines[id] = {}
        self.lines[id].finish = x
    elseif self.style.join == JOINMOVE then
        self.lines[id] = {}
        self.lines[id].finish = x
    elseif self.style.join == JOINLINE then
        if self.lastline then
            self.lines[id] = self.lastline
            self.lastline = nil
            self:stroke(x,id)
        else
            self.lines[id] = {}
            self.lines[id].finish = x
        end
        self.style.join = self.style.oldjoin or JOINNONE
    end
end

function Brush:stroke(x,id,t)
end
--[[
function Brush:basicStroke(x,id,t)
    if self.lines[id] then
        t = t or {}
        local y,th
        local l = self.lines[id]
        if l.start then

            if l.start:distSqr(l.finish) > 100 
            --and math.abs((l.finish - l.start):normalize():rotate90():dot((x - l.finish):normalize())) > .2
                then
            -- if false then
            -- if true then
            local bza,bzb
            bza,bzb,th = QuickHobby(l.start,l.finish,x,l.th)
            local ca = bza:point(1/3)
            local cb = bza:point(2/3)
            local a,b
            if l.previousSegment then
                if l.previousSegment.start then
                a = (l.previousSegment.finish - 
                     l.previousSegment.start):normalize()
                b = (ca - 
                     l.previousSegment.finish):normalize()
                if a:dot(b) < -0.5 then
                    l.previousSegment.after =
                         l.previousSegment.finish - b
                    l.before = l.previousSegment.finish + a
                else
                    l.previousSegment.after = ca
                end

                    self:addLine(l.previousSegment)
                end
            end
            
            local c = {
                l.before,
                l.start, 
                ca,
                cb,
                l.finish,
                x}

            for i=2,4 do
                l.before = c[i-1]
                l.start = c[i]
                l.finish = c[i+1]
                a = (c[i+1] - c[i]):normalize()
                b = (c[i+2] - c[i+1]):normalize()
                if a:dot(b) < -0.5 then
                    l.after = l.finish - b
                    c[i] = l.finish + a
                else
                    l.after = c[i+2]
                end
                self:addLine(l)
                if i ~= 4 then l.position = nil end
            end
            y = c[4]
            else
                local a,b
                a = (l.finish - l.start):normalize()
                b = (x - l.finish):normalize()
                if a:dot(b) < -0.5 then
                    l.after = l.finish - b
                    y = l.finish + a
                else
                    l.after = x
                    y = l.start
                end
            self:addLine(l)
            end
        end
        l.previousSegment = nil
        t.start = l.finish
        t.before = y
        t.finish = x
        t.th = th
        t.previousSegment = l
        t.startCapData = l.startCapData
        t.endCapData = l.endCapData
        t.startCap = l.startCap
        t.endCap = l.endCap
        self.lines[id] = self:addLine(t)
    end
end
--]]

function Brush:basicStroke(x,id,t)
    if self.lines[id] then
        t = t or {}
        local y,th,bza,bzb
        local l = self.lines[id]
        if l.start then
            bza,bzb,th = QuickHobby(l.start,l.finish,x,l.th)
            bza.steps = 50
            bzb.steps = 50
            l.bezier = bza
            l.after = x
            self:addBezier(l)
        end

        t.start = l.finish
        t.before = l.start
        t.finish = x
        t.th = th
        t.startCapData = l.startCapData
        t.endCapData = l.endCapData
        t.startCap = l.startCap
        t.endCap = l.endCap
        t.bezier = bzb
        self.lines[id] = self:addBezier(t)
    end
end
function Brush:strokeEnd(v,id)
    self:stroke(v,id)
    self.lastline = self.lines[id]
    self.lines[id] = nil
end

function Brush:processTouches(g)
    self.touches = {}
    self.ntouches = 0
    for _,t in ipairs(g.touchesArr) do
        if t.updated then
            table.insert(self.touches,t)
        end
    end
    if g.type.ended then
        if self.style.join == JOINNONE then
            self.resetafter = true
        end
        self.isfinished = true
        g:reset()
    else
        g:noted()
    end
end

function Brush:predraw()
    for _,t in ipairs(self.touches) do
        local v = OrientationInverse(
                PORTRAIT, vec2(t.touch.x,t.touch.y))
        if t.touch.state == BEGAN then
            self.lines[t.touch.id] = nil
            self:strokeStart(v,t.touch.id)
        elseif t.touch.state == MOVING then
            self:stroke(v,t.touch.id)
        else
            self:strokeEnd(v,t.touch.id)
        end
    end
    self.touches = {}
    if self.resetafter then
        self:reset()
        self.resetafter = false
    end
end

function Brush:draw()
    self.mesh:draw()
    for k,v in ipairs(self.beziers) do
        v:draw()
    end
end

function Brush:addLine(t)
    local s,e,ws,we,b,a,sw,ew,wl,wn,n,sm,bl,sc,ec
    t.startThickness = t.startThickness or t.thickness or self.style.thickness
    t.endThickness = t.endThickness or t.thickness or self.style.thickness
    t.startColour = t.startColour or t.colour or self.style.colour
    t.endColour = t.endColour or t.colour or self.style.colour
    t.startOpacity = t.startOpacity or 
            t.opacity or self.style.opacity or 100
    t.endOpacity = t.endOpacity or 
            t.opacity or self.style.opacity or 100
    t.smooth = t.smooth or self.style.smooth
    t.blur = t.blur or self.style.blur
    t.startCap = t.startCap or self.style.cap
    t.endCap = t.endCap or self.style.cap
    t.startCapData = t.startCapData or {}
    t.endCapData = t.endCapData or {}
    ws = t.startThickness
    we = t.endThickness
    s = t.start
    e = t.finish
    b = t.before
    a = t.after
    bl = t.blur
    sm = t.smooth
    sc = Colour.opacity(t.startColour,t.startOpacity)
    ec = Colour.opacity(t.endColour,t.endOpacity)
    if sm then
        we = math.max(0,we-2*bl)
        ws = math.max(0,ws-2*bl)
    end
    we = we/2
    ws = ws/2
    wl = (e - s):normalize()
    wn = wl:rotate90()
    if b then
        sw = (s - b):normalize() - wl
        if wn:dot(sw) == 0 then
            sw = wn
        else
            sw = sw/wn:dot(sw)
        end
    else
        sw = wn
    end
    if a then
        ew = (a - e):normalize() - wl
        if wn:dot(ew) == 0 then
            ew = wn
        else
            ew = ew/wn:dot(ew)
        end
    else
        ew = wn
    end
    if ew:dot(sw) < 0 then
        ew = - ew
    end
    if not b then
        -- update start cap data
        local ct = t.startCapData
        ct.thickness = t.startThickness
        ct.colour = t.startColour
        ct.opacity = t.startOpacity
        ct.smooth = t.smooth
        ct.blur = t.blur
        ct.cap = t.startCap
        ct.start = s
        ct.direction = -wl
        t.startCapData = self:addCap(ct)
    end
    if not a then
        -- update end cap data
        local ct = t.endCapData
        ct.thickness = t.endThickness
        ct.colour = t.endColour
        ct.opacity = t.endOpacity
        ct.smooth = t.smooth
        ct.blur = t.blur
        ct.cap = t.endCap
        ct.start = e
        ct.direction = wl
        t.endCapData = self:addCap(ct)
    end
    t.position = t.position or self.nlines
    n = t.position
    n = addQuad({
        mesh = self.mesh,
        position = n,
        vertices = {
            {s-ws*sw,sc},
            {s+ws*sw,sc},
            {e-we*ew,ec},
            {e+we*ew,ec}
        }
    })
    if sm then
        local l
        local sct = Colour.opacity(sc,0)
        local ect = Colour.opacity(ec,0)

        local corners = {
            {{s+ws*sw,sc},{s+(ws+bl)*sw,sct}},
            {{e+we*ew,ec},{e+(we+bl)*ew,ect}},
            {{e-we*ew,ec},{e-(we+bl)*ew,ect}},
            {{s-ws*sw,sc},{s-(ws+bl)*sw,sct}},
        }
        for _,k in ipairs({1,3}) do
            l=k%4+1
            n = addQuad({
                mesh = self.mesh,
                position = n,
                vertices = {
                    corners[k][1],
                    corners[k][2],
                    corners[l][1],
                    corners[l][2],
                }
            })
        end
    end
    self.nlines = math.max(self.nlines,n)
    return t
end

function Brush:addBezier(t)
    local sw,ew,a,b,bl,sc,ec,bzr,ws,we
    t.startThickness = t.startThickness or t.thickness or self.style.thickness
    t.endThickness = t.endThickness or t.thickness or self.style.thickness
    t.startColour = t.startColour or t.colour or self.style.colour
    t.endColour = t.endColour or t.colour or self.style.colour
    t.startOpacity = t.startOpacity or 
            t.opacity or self.style.opacity or 100
    t.endOpacity = t.endOpacity or 
            t.opacity or self.style.opacity or 100
    t.smooth = t.smooth or self.style.smooth
    t.blur = t.blur or self.style.blur
    t.cap = t.cap or self.style.cap

    if not t.position then
        t.position = self.nbeziers
        self.nbeziers = self.nbeziers + 1
    end
    if not t.bezier then
        return t
    end
    ws = t.startThickness
    we = t.endThickness
    bzr = t.bezier
    sc = Colour.opacity(t.startColour,t.startOpacity)
    ec = Colour.opacity(t.endColour,t.endOpacity)
    if t.smooth then
        bl = t.blur
        we = we+bl
        ws = ws+bl
    else
        bl = 0
    end
    if t.before then
        t.scap = 0
    else
        t.scap = 1
    end
    if t.after then
        t.ecap = 0
    else
        t.ecap = 1
    end
    bzr:setStyle({
        scolour = sc,
        ecolour = ec,
        width = t.startThickness,
        taper = t.endThickness/t.startThickness,
        blur = bl,
        cap = t.cap,
        scap = t.scap,
        ecap = t.ecap
    })
    self.beziers[t.position] = bzr
    return t
end

function Brush:addCircle(t)
    local w,c,r,n,bl,sm,col,e
    t.colour = t.colour or self.style.colour
    t.opacity = t.opacity or self.style.opacity or 100
    t.position = t.position or self.nlines
    t.smooth = t.smooth or self.style.smooth
    t.blur = t.blur or self.style.blur
    t.accuracy = t.accuracy or 5
    t.thickness = t.thickness or self.style.thickness
    w = t.thickness
    c = t.centre
    r = t.radius
    n = t.position
    bl = t.blur
    sm = t.smooth
    col = Colour.opacity(t.colour,t.opacity)
    e = t.accuracy
    if sm then
        w = math.max(0,w-2*bl)
    end
    w = w/2
    local m = math.max(math.floor(2*math.pi*r/e),15)
    local a = 2*math.pi/m
    local n = self.nlines
    local v = vec2(1,0)
    local u = vec2(math.cos(a),math.sin(a))
    for i=1,m do
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c+(r-w)*v,col},
                {c+(r+w)*v,col},
                {c+(r-w)*u,col},
                {c+(r+w)*u,col},
            }
        })
        v = u
        u = vec2(math.cos((i+1)*a),math.sin((i+1)*a))
    end
    if sm then
        local tcol = Colour.opacity(col,0)
    v = vec2(1,0)
    u = vec2(math.cos(a),math.sin(a))
        for i=1,m do
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c+(r+w)*v,col},
                {c+(r+w+bl)*v,tcol},
                {c+(r+w)*u,col},
                {c+(r+w+bl)*u,tcol},
            }
        })
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c+(r-w)*v,col},
                {c+(r-w-bl)*v,tcol},
                {c+(r-w)*u,col},
                {c+(r-w-bl)*u,tcol},
            }
        })
        v = u
        u = vec2(math.cos((i+1)*a),math.sin((i+1)*a))
    end
    end
    self.nlines = math.max(self.nlines,n)
    return t
end

function Brush:addDisc(t)
    local c,r,n,bl,sm,sc,ec,e
    t.centreColour = t.centreColour or t.colour or self.style.colour
    t.edgeColour = t.edgeColour or t.colour or self.style.colour
    t.centreOpacity = t.centreOpacity 
            or t.opacity or self.style.opacity or 100
    t.edgeOpacity = t.edgeOpacity or
            t.opacity or self.style.opacity or 100
    t.position = t.position or self.nlines
    t.smooth = t.smooth or self.style.smooth
    t.blur = t.blur or self.style.blur
    t.accuracy = t.accuracy or 5
    c = t.centre
    r = t.radius
    n = t.position
    bl = t.blur
    sm = t.smooth
    sc = Colour.opacity(t.centreColour,t.centreOpacity)
    ec = Colour.opacity(t.edgeColour,t.edgeOpacity)
    e = t.accuracy
    if sm then
        r = math.max(0,r-bl)
    end
    local m = math.max(math.floor(2*math.pi*r/e),15)
    local a = 2*math.pi/m
    local n = t.position
    local v = vec2(1,0)
    local u = vec2(math.cos(a),math.sin(a))
    for i=1,m do
        n = addTriangle({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c,sc},
                {c+r*v,ec},
                {c+r*u,ec},
            }
        })
        v = u
        u = vec2(math.cos((i+1)*a),math.sin((i+1)*a))
    end
    if sm then
        local tec = Colour.opacity(ec,0)
    v = vec2(1,0)
    u = vec2(math.cos(a),math.sin(a))
        for i=1,m do
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c+r*v,ec},
                {c+(r+bl)*v,tec},
                {c+r*u,ec},
                {c+(r+bl)*u,tec},
            }
        })
        v = u
        u = vec2(math.cos((i+1)*a),math.sin((i+1)*a))
    end
    end
    self.nlines = math.max(self.nlines,n)
    return t
end

function Brush:addHalfDisc(t)
    local c,r,n,bl,sm,sc,ec,e,nv,m,a,v,u
    t.centreColour = t.centreColour or t.colour or self.style.colour
    t.edgeColour = t.edgeColour or t.colour or self.style.colour
    t.centreOpacity = t.centreOpacity 
            or t.opacity or self.style.opacity or 100
    t.edgeOpacity = t.edgeOpacity or
            t.opacity or self.style.opacity or 100
    t.position = t.position or self.nlines
    t.smooth = t.smooth or self.style.smooth
    t.blur = t.blur or self.style.blur
    t.accuracy = t.accuracy or 5
    c = t.centre
    r = t.radius
    nv = t.normal:normalize()
    n = t.position
    bl = t.blur
    sm = t.smooth
    sc = Colour.opacity(t.centreColour,t.centreOpacity)
    ec = Colour.opacity(t.edgeColour,t.edgeOpacity)
    e = t.accuracy
    if sm then
        r = math.max(0,r-bl)
    end
    m = math.max(math.floor(2*math.pi*r/e),15)
    a = math.pi/m
    v = nv
    u = nv:rotate(a)
    for i=1,m do
        n = addTriangle({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c,sc},
                {c+r*v,ec},
                {c+r*u,ec},
            }
        })
        v = u
        u = nv:rotate((i+1)*a)
    end
    if sm then
        local tec = Colour.opacity(ec,0)
    v = nv
    u = nv:rotate(a)
        for i=1,m do
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {c+r*v,ec},
                {c+(r+bl)*v,tec},
                {c+r*u,ec},
                {c+(r+bl)*u,tec},
            }
        })
        v = u
        u = nv:rotate((i+1)*a)
    end
    end
    self.nlines = math.max(self.nlines,n)
    return t
end

function Brush:addCap(t)
    local s,w,sw,wl,wn,n,sm,bl,sc
    t.thickness = t.thickness or t.thickness or self.style.thickness
    t.colour = t.colour or t.colour or self.style.colour
    t.opacity = t.opacity or 
            t.opacity or self.style.opacity or 100
    t.smooth = t.smooth or self.style.smooth
    t.blur = t.blur or self.style.blur
    t.cap = t.cap or self.style.cap
    t.position = t.position or self.nlines
    
    if t.cap == CAPNONE then return t end
    if t.cap == CAPSQUARE and not t.smooth then return t end
    
    w = t.thickness
    s = t.start
    bl = t.blur
    sm = t.smooth
    sc = Colour.opacity(t.colour,t.opacity)
    if sm then
        w = math.max(0,w-2*bl)
    end
    w = w/2
    wl = t.direction:normalize()
    wn = wl:rotate90()
    if t.cap == CAPROUND then
        t.normal = -wn
        t.centre = s
        t.radius = t.thickness/2
        t.centreColour = t.colour
        t.edgeColour = t.colour
        t.centreOpacity = t.opacity
        t.edgeOpacity = t.opacity
        return self:addHalfDisc(t)
    end
    if t.cap == CAPBUTT then
        local e = s + w*wl
        n = t.position
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {s-w*wn,sc},
                {s+w*wn,sc},
                {e-w*wn,sc},
                {e+w*wn,sc}
            }
        })
        if sm then
            local l
            local sct = Colour.opacity(sc,0)
            local edges = {1,2,3}
            local corners = {
                {{s+w*wn,sc},{s+(w+bl)*wn,sct}},
                {{e+w*wn,sc},{e+(w+bl)*wn+bl*wl,sct}},
                {{e-w*wn,sc},{e-(w+bl)*wn+bl*wl,sct}},
                {{s-w*wn,sc},{s-(w+bl)*wn,sct}},
            }
            for _,k in ipairs(edges) do
                l=k%4+1
                n = addQuad({
                    mesh = self.mesh,
                    position = n,
                    vertices = {
                        corners[k][1],
                        corners[k][2],
                        corners[l][1],
                        corners[l][2],
                    }
                })
            end
        end
        self.nlines = math.max(self.nlines,n)
        return t
    end
    if t.cap == CAPSQUARE and sm then
        local l
        local sct = Colour.opacity(sc,0)
        n = t.position
        n = addQuad({
            mesh = self.mesh,
            position = n,
            vertices = {
                {s+w*wn,sc},
                {s+(w+bl)*wn+bl*wl,sct},
                {s-w*wn,sc},
                {s-(w+bl)*wn+bl*wl,sct}
            }
        })
        n = addTriangle({
            mesh = self.mesh,
            position = n,
            vertices = {
                {s+w*wn,sc},
                {s+(w+bl)*wn+bl*wl,sct},
                {s+(w+bl)*wn,sct},
            }
        })
        n = addTriangle({
            mesh = self.mesh,
            position = n,
            vertices = {
                {s-w*wn,sc},
                {s-(w+bl)*wn+bl*wl,sct},
                {s-(w+bl)*wn,sct},
            }
        })
        self.nlines = math.max(self.nlines,n)
        return t
    end
    return t
end

return Brush

--]==]
