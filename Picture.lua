--[==[
local Drawable = cimport "Drawable"
cimport "PictureBrowser"
local Colour = cimport "Colour"
cimport "ColourNames"
cimport "CubicSelector"
cimport "Coordinates"
cimport "MeshUtilities"

local Picture = class(Drawable)
local pictureShader

function Picture:init(tb,ui)
    Drawable.init(self,"Picture",tb)
    self.mesh = mesh()
    self.shader = shader()
    self.shader.vertexProgram,self.shader.fragmentProgram = pictureShader()
    self:updateStyle()
    ui:getPicture(
                function(i)
                    self:setpicture(i)
                    return true
                end
            )
            self.debug = 0
            debug:log({ name = "Drawing", 
                message = function() return self.debug end})
end

function Picture:setpicture(i)

    self.mesh.texture = i
    self.mesh.shader = self.shader
    local c = Colour.svg.White
    local w,h = i.width, i.height
    local s = math.min(1,
        RectAnchorOf(Portrait,"width")/(2*w),
        RectAnchorOf(Portrait,"height")/(2*h)
        )
    local x,y = RectAnchorOf(Portrait,"centre")
    w,h = s*w/2,s*h/2
    self.corners = {
        {vec2(x-w,y-h),c,vec2(0,0)},
        {vec2(x-w,y+h),c,vec2(0,1)},
        {vec2(x+w,y-h),c,vec2(1,0)},
        {vec2(x+w,y+h),c,vec2(1,1)},
    }
    addQuad({
        mesh = self.mesh,
        vertices = self.corners,
    })
end
    

function Picture:draw()
    self.mesh:draw()
end

function Picture:isTouchedBy(touch)
    local a = self.corners[1][1]
    local b = self.corners[2][1] - a
    local c = self.corners[3][1] - a
    local t = vec2(touch.x,touch.y) - a
    a = b:cross(c)
    if a == 0 then
        return false
    end
    b = b:cross(t)/a
    if b < 0 or b > 1 then
        return false
    end
    c = - c:cross(t)/a
    if c < 0 or c > 1 then
        return false
    end
    return true
end

function Picture:processTouches(g)
    if g.updated then
        local c = {}
        if g.num == 1 then
            local ta = g.touchesArr[1]
            local sa = OrientationInverse(PORTRAIT,
                vec2(ta.firsttouch.x,ta.firsttouch.y))
            local ea = OrientationInverse(PORTRAIT,
                vec2(ta.touch.x,ta.touch.y))

            for k,v in ipairs(self.corners) do
                c[k] = {v[1] + ea - sa}
            end
        elseif g.num == 2 then
        local ta,tb = g.touchesArr[1],g.touchesArr[2]
        local sa = OrientationInverse(PORTRAIT,
            vec2(ta.firsttouch.x,ta.firsttouch.y))
        local ea = OrientationInverse(PORTRAIT,
            vec2(ta.touch.x,ta.touch.y))
        local sb = OrientationInverse(PORTRAIT,
            vec2(tb.firsttouch.x,tb.firsttouch.y))
        local eb = OrientationInverse(PORTRAIT,
            vec2(tb.touch.x,tb.touch.y))
        local s = (eb - ea):len()/ (sb - sa):len()
        local ang = (sb - sa):angleBetween(eb - ea)
        local sc = (sb + sa)/2
        local ec = (ea + eb)/2
        for k,v in ipairs(self.corners) do
            c[k] = {s*(v[1]-sc):rotate(ang) + ec}
        end
        end
        addQuad({
            mesh = self.mesh,
            position = 0,
            vertices = c,
        })
        if g.type.ended then
            self.corners = c
        end
    end
    if g.type.ended then
        g:reset()
    end
end

function Picture:updateStyle()
    for k,v in pairs(self.style.picture) do
        self.shader[k] = v
    end
end

pictureShader = function()
    return [[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;

//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

//This is an output variable that will be passed to the fragment shader
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

void main()
{
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = vec2(texCoord.x, texCoord.y);
    
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * position;
}
]],[[
//
// A basic fragment shader
//

//This represents the current texture on the mesh
uniform lowp sampler2D texture;
uniform lowp vec4 red;
uniform lowp vec4 green;
uniform lowp vec4 blue;
uniform lowp vec4 alpha;
uniform lowp vec4 redcurve;
uniform lowp vec4 greencurve;
uniform lowp vec4 bluecurve;
uniform lowp vec4 alphacurve;
uniform lowp vec4 brightness;

mediump vec4 csat = red + green + blue + alpha;
mediump float cnorm = max(max(max(1.,csat.r),csat.g),csat.b);

//The interpolated vertex color for this fragment
varying lowp vec4 vColor;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;

lowp float cubic(lowp vec4 c, lowp float t)
{
    return c.x + c.y * t + c.z * t * t + c.w * t * t * t;
}

void main()
{
    //Sample the texture at the interpolated coordinate
    mediump vec4 col = texture2D( texture, vTexCoord );
    col *= vColor;
    col.r = cubic(redcurve, col.r);
    col.g = cubic(greencurve, col.g);
    col.b = cubic(bluecurve, col.b);
    col.a = cubic(alphacurve, col.a);
    col.r = cubic(brightness, col.r);
    col.g = cubic(brightness, col.g);
    col.b = cubic(brightness, col.b);
    col = col.r * red + col.g * green + col.b * blue + col.a * alpha;
    col.rgb = col.rgb/cnorm;
    //Set the output color to the texture color
    gl_FragColor = col;
}
]]
end

return Picture

--]==]