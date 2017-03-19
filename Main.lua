-- Main

--[[
To load pictures for selection as background images:

1. Click on the brackets: sprite() to bring up the selector
2. Select "Documents"
3. Select "Photo Library"
4. Choose your photo
5. Name it
6. Repeat from 3 to select more
7. Click outside the sprite selector to dismiss it
--]]

supportedOrientations(ANY)
displayMode(FULLSCREEN_NO_BUTTONS)

VERSION = 2.1
cmodule "Harmony CModule"
cmodule.path("Base", "UI", "Utilities", "Graphics", "Maths")
function setup()
    if AutoGist then
        autogist = AutoGist("Harmony CModule","A drawing application with lots of brush styles.",VERSION)
        autogist:backup(true)
    end
    
    local Touches = cimport "Touch"
    local UI = cimport "UI"
    local Debug = cimport "Debug"
    local Canvas = cimport "Canvas"

    touches = Touches()
    ui = UI(touches)
    ui:systemmenu()
    ui:helpmenu()
    debug = Debug({ui = ui})
    ui.messages:deactivate()
    canvas = Canvas({
        ui = ui, 
        touchHandler = touches, 
        debug = debug,
        --[[
        enableText = false,
        enablePictures = false,
        brushes = {"Simple","Flow Lines"}
        --]]
        })
        --[[
    canvas:setStyle({
        drawable = "Simple",
        thickness = 50,
        alpha = 100,
        blur = 20,
        cap = CAPROUND
    })
    --]]
    orientationChanged = _orientationChanged
end

function draw()
    background(0, 0, 0, 255)
    touches:draw()
    canvas:draw()
    ui:draw()
    debug:draw()
    AtEndOfDraw()
end

function touched(touch)
    touches:addTouch(touch)
end

function _orientationChanged(o)
    ui:orientationChanged(o)
    debug:orientationChanged(o)
end

function hide()
    ui:hide(5)
    canvas:hide()
    debug:hide()
end

function unhide()
    ui:unhide()
    canvas:unhide()
    debug:unhide()
end