function PressKey(key)
    print("PressKey "..key)
end

function ReleaseKey(key)
    print("ReleaseKey "..key)
end



function Setup()
    mode1 = {
        kb = {
        },
        lhc = {
            G1 = new (function(this)
                    this.Init(300, 3)
                    local tapKeys = { "a", "b", "c" }

                    function this.OnPressed(tapCount)
                        PressKey(tapKeys[tapCount])
                    end

                    function this.OnReleased(tapCount)
                        ReleaseKey(tapKeys[tapCount])
                    end
                end, ButtonHandler)
        }
    }
end

function Setup2()
    eventHandlers = {
        lhc_G_PRESSED_1 = handlers.lhc.G1.Pressed(),
        lhc_G_RELEASED_1 = handlers.lhc.G1.Released()
    }
end

function SetMode(mode)
    mode = mode or {}

    eventHandlers = { kb = {}, lhc = {} }
    local familyTable

    for family, handlers in mode do
        if eventHandlers[family] ~= nil then
            familyTable = eventHandlers[family]
        else
            familyTable = eventHandlers
        end

        for eventHandler, object in handlers do
            if eventHan
        end
end

function OnEvent(event, arg, family)
    family = family or ""
    arg = arg or ""
    if str:sub(1, 1) == "P" then arg = "" end
    local eventarg = event..arg
    local fn = eventHandlers[family..eventarg]
    if type(fn) == "function" then fn()
    else
        fn = eventHandlers[eventarg]
        if type(fn) == "function" then fn() end
    end
end

function ButtonHandler(this)
    local isPressed = false
    local pressTime = 0
    local tapCount = 0
    local isPolling = false
    local tapDuration = 0
    local tapMax = 0

    function this.Init(multiTapSpan, maxTapCount)
        tapDuration = multiTapSpan
        tapMax = maxTapCount
        return this
    end

    function this.Pressed()
        isPressed = true
        tapCount = tapCount + 1
    end

    function this.Released()
        isPressed = false
    end

    function this.Test()
        this.OnPressed(tapCount)
        this.OnReleased(tapCount)
        tapCount = 0
    end
end

function EventHandler(this)
    local family
    local name
    local arg
    local event

    function this.Init(n, e)
        name = n
        event = e
    end

    function this.OnEvent(eventName, arg, family)
    end
end




function inherit(this, ...)
    this = this or {}

    local item, current, base
    for i = select('#', ...) , 1, -1 do
        item = select(i, ...)
        if (type(item)) == "function" then
            current = {}
            for k, v in pairs(this) do
                current[k] = v
            end
            item(this)

            base = {}
            for k, v in pairs(this) do
                if current[k] ~= v then
                    base[k] = v
                end
            end
            this[item] = base
        end
    end

    return this
end

function new(constructor, ...)
    local this = {}
    inherit(this, ...)
    constructor(this);
    return this
end


str = "TEST"
print(str:sub(1, 1));


-- main function
(function()
    Setup()

    handlers.lhc.G1.Pressed()
    handlers.lhc.G1.Pressed()

    handlers.lhc.G1.Test()
end)()
