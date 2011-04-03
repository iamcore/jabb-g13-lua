function Setup()
    mode1 = {
        kb = {
        },
        lhc = {
            G1 = new (function(this)
                    this.Init(300, 3)
                    local tapKeys = { "a", "b", "c" }

                    function this.OnPressed(tapCount)
                        OutputLogMessage("test")
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
            Activated = function(event, arg, family) OutputLogMessage("Profile Activated\n") end,
            Deactivated = function() end
        }
    }
end


function OnEvent(event, arg, family)
    family = family or ""
    arg = string.format("%d",arg) or ""
    if event:sub(1, 1) == "P" then arg = "" end
    local eventarg = event
    if arg:len() > 0 then eventarg = event.."_"..arg end
    local fn = eventHandlers[family.."_"..eventarg]
    if type(fn) == "function" then fn(event, arg, family)
    else
        fn = eventHandlers[eventarg]
        if type(fn) == "function" then fn(event, arg, family)
        end
    end
    OutputLogMessage(family.."_"..eventarg.." : "..type(fn).."\n")
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

        -- don't poll when only single taps are allowed
		if tapMax <= 1 then
            pressTime = GetRunningTime()
            this.OnPressed(1)
            return
        end

        if tapCount < tapMax  then
            tapCount = tapCount + 1
        end

		if isPolling == false then
            pressTime = GetRunningTime()
            poll.RegisterPollRoutine(PollRoutine)
            isPolling = true
        end
    end

    function this.Released()
        isPressed = false

        -- don't poll when only single taps are allowed
        if tapMax <= 1 then
            this.OnReleased(1)
            return
        end

        if isPolling == false then
            this.OnReleased(tapCount)
            tapCount = 0
        end
    end

    function PollRoutine()
        local time = GetRunningTime() - pressTime
        if time < tapDuration and tapCount < tapMax then
            return true
        end

        isPolling = false
        this.OnPressed(tapCount)

        if isPressed == false then
            this.OnReleased(tapCount)
            tapCount = 0
        end

        return false
    end
end

function PollManager(this)
    local family = "kb"
    local delay = 25

    local pressCount
    local pollMKeyState = GetMKeyState(pollFamily)
    local pollRoutines = {}
    local polling = false
    local initialized = false

    function this.Init(f, d)
        family = f or "kb"
        delay = d or 25
    end

    function this.OnEvent(event, family)
        if family ~= pollFamily and event ~= "PROFILE_ACTIVATED" then
            return
        end

        if event == "M_PRESSED" then
            pressCount = pressCount + 1
        elseif event == "M_RELEASED" or event == "PROFILE_ACTIVATED" then
            initialized = true
            if pressCount == 1 then
                if RunPollRoutines(event, arg, family) == true then
                    SetMKeyState(GetMKey(arg, family), pollFamily)
                    Sleep(delay)
                end
            end
            pressCount = pressCount - 1
        end
    end

    function this.RegisterPollRoutine(routine)
        if type(routine) == "function" then
            table.insert(pollRoutines, routine)
            if initialized then
                OnEvent("PROFILE_ACTIVATED", family)
            end
        end
    end

    function GetMKey(arg, f)
        if f == family and pollMKeyState ~= arg then
            pollMKeyState = arg
        end
        return pollMKeyState
    end

    function RunPollRoutines(event, arg, family)
        polling = false

        local idx = 1
        local routine = pollRoutines[1]

        while routine ~= nil do
            polling = true

            if routine(event, arg, family) == false then
                table.remove(pollRoutines, idx)
                routine = pollRoutines[idx]
            else
                idx = idx + 1
                routine = pollRoutines[idx]
            end
        end
    end
end

poll = new(PollManager).Init("lhc", 25)

eventAbbrToName = {
    P = { "P", "PROFILE", { "ACTIVATED", "Activated" }, { "DEACTIVATED", "Deactivated" } },
    M = { "M", "M", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } },
    G = { "G", "G", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } },
    MOU = { "MOUSE", "MOUSE", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } },
    MOD = { "MOD", "MOD", { "PRESSED", "Pressed" }, { "RELEASED", "Released" } }
}

--[[
eventHandlers = {
    lhc_G_PRESSED_1 = handlers.lhc.G1.Pressed(),
    lhc_G_RELEASED_1 = handlers.lhc.G1.Released()
}
--]]

eventHandlers = {}

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
