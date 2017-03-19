-- Test

local Brush = cimport "Brush"
local Test = class(Brush)

function Test:init(tb)
    Brush.init(self,"Test",tb)
end

function Brush:strokeStart(x,id)
    self.lines[id] = {}
    self.lines.start = vec2(300,300)
    self.lines.finish = vec2(300,400)
    self:addline(self.lines[id])
end

function Brush:strokeEnd(x,id)
    if self.lines[id] then
        t = t or {}
        local y,th
        local l = self.lines[id]
        if l.start then

            if l.start:distSqr(l.finish) > 100 
            and math.abs((l.finish - l.start):normalize():rotate90():dot((x - l.finish):normalize())) > .2
                then

            -- if true then
            local bza,bzb
            bza,bzb,th = QuickHobby(l.start,l.finish,x,l.th)
            local ca = Bezierpt(1/3,unpack(bza))
            local cb = Bezierpt(2/3,unpack(bza))
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
            y = l.start
            l.after = x
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
    self.isfinished = false
end

if _M then
    return Test
end
