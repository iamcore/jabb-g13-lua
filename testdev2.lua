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
                end, ButtonHandler),
            M1 = {},
            Mouse1 = {},
            ModCtl = {}
        },
        P = {
            Activated = function() end,
            Deactivated = function() end
        }
    }
end


function OnEvent(event, arg, family)
    family = family or ""
    arg = arg or ""
    if event:sub(1, 1) == "P" then arg = "" end
    local eventarg = event
    if arg:len() > 0 then eventarg = event.."_"..arg end
    local fn = eventHandlers[family.."_"..eventarg]
    if type(fn) == "function" then fn()
    else
        fn = eventHandlers[eventarg]
        if type(fn) == "function" then fn()
        end
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

eventAbbrToName = {
    P = { "P", "PROFILE", { "ACTIVATED", "Activated" }, { "DEACTIVATED", "Deactivated" } },
    M = { "M", "M", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } },
    G = { "G", "G", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } },
    MOU = { "MOUSE", "MOUSE", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } },
    MOD = { "MOD", "MOD", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } }
}


function Setup2()
    eventHandlers = {
        lhc_G_PRESSED_1 = handlers.lhc.G1.Pressed(),
        lhc_G_RELEASED_1 = handlers.lhc.G1.Released()
    }
end

function SetMode(mode)
    mode = mode or {}

    eventHandlers = {}

    local families = { kb = 0, lhc = 0 }
    local eventAbbr, eventAbbrLookup, eventName, arg, temp, partName

    for family, handlers in pairs(mode) do
        if families[family] ~= nil then
            family = family.."_"
        else
            handlers = { [family] = mode[family] }
            family = ""
        end

        for handler, object in pairs(handlers) do
            eventAbbr = handler:sub(1, 1):upper()
            if eventAbbr == "M" and handler:len() > 2 then
                temp = handler:sub(1, 3):upper()
                if eventAbbrToName[temp] ~= nill then
                    eventAbbr = temp
                end
            end
            eventAbbrLookup = eventAbbrToName[eventAbbr]
            arg = handler:sub(eventAbbrLookup[1]:len() + 1)
            eventName = eventAbbrLookup[2]
            for i = 3, 4 do
                partName = eventName.."_"..eventAbbrLookup[i][1]
                if arg:len() > 0 then
                    partName = partName.."_"..arg:upper()
                end
                eventHandlers[family..partName] = object[eventAbbrLookup[i][2]]
                print(family..partName, eventHandlers[family..partName])
            end
        end
    end
end



function inherit(this, ...)
    this = this or {}

    local item, current, base
    for i = select('#', ...), 1, -1 do
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





-- main function
;
(function()
    Setup()
    SetMode(mode1)
    --OnEvent("PROFILE_ACTIVATED", 0, "")
    --handlers.lhc.G1.Pressed()
    --handlers.lhc.G1.Pressed()

    --handlers.lhc.G1.Test()
end)()
