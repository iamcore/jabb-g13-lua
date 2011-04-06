--[[---------------------------------------------------------------------------
HISTORY
00.01   2011-04-05  Initial revision
--]]---------------------------------------------------------------------------

function Setup()
    poll = new(PollManager).Init("kb", 25)
    local pollModifiers = new(PollModifiers)
    local pollMouse = new(PollMouse)

    local mode1 = {
        kb = {
        },
        lhc = {
            G1 = function()
                return {
                    Pressed = function() OutputLogMessage("Handler G1 Pressed\n") end,
                    Released = function() OutputLogMessage("Handler G1 Released\n") end
                }
            end
        },
        G2 = function() OutputLogMessage("G2\n") end,
        P = function() OutputLogMessage("P\n") end
    }

    eventHandlers = mode1

    pollModifiers.Start()
    pollMouse.Start()
end

function ButtonHandler(this)
    local isPressed = false
    local pressTime = 0
    local tapCount = 0
    local isPolling = false
    local tapDuration = 0
    local tapMax = 0

    local function PollRoutine()
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

    function this.OnPressed() end
    function this.OnReleased() end
end

function PollManager(this)
    local pollFamily = "kb"
    local pollDelay = 25

    local pressCount = 1
    local pollMKeyState = 0
    local pollRoutines = {}
    local polling = false
    local initialized = false

    local function GetMKey(arg, family)
        if arg == nil or family == nil then return pollMKeyState end
        if family == pollFamily and pollMKeyState ~= arg then
            pollMKeyState = arg
        end
        return pollMKeyState
    end

    function this.Init(family, delay)
        pollFamily = family or "kb"
        pollDelay = delay or 25
        pollMKeyState = GetMKeyState(pollFamily)
        return this;
    end

    function this.OnEvent(event, arg, family)
        if event == "PROFILE_ACTIVATED" or (event == "M_RELEASED" and family == pollFamily) then
            polling = false

            local idx = 1
            local routine = pollRoutines[1]

            while routine ~= nil do
                if routine(event, arg, family) == false then
                    table.remove(pollRoutines, idx)
                    routine = pollRoutines[idx]
                else
                    polling = true
                    idx = idx + 1
                    routine = pollRoutines[idx]
                end
            end

            if polling then
                SetMKeyState(GetMKey(arg, family), pollFamily)
                Sleep(pollDelay)
            end
        end
    end

    function this.RegisterPollRoutine(routine)
        if type(routine) == "function" then
            table.insert(pollRoutines, routine)
            if polling == false then
                this.OnEvent("PROFILE_ACTIVATED")
            end
        end
    end
end

function PollModifiers(this)
    local isPolling = false
    local modKeys = {
        lalt = false,
        ralt = false,
        alt = false,
        lshift = false,
        rshift = false,
        shift = false,
        lctrl = false,
        rctrl = false,
        ctrl = false
    }

    local function PollRoutine()
        if isPolling == false then return false end

        for k, v in pairs(modKeys) do
            if IsModifierPressed(k) then
                if v == false then
                    modKeys[k] = true
                    OnEvent("MOD_PRESSED", k:upper(), "")
                end
            elseif v == true then
                modKeys[k] = false
                OnEvent("MOD_RELEASED", k:upper(), "")
            end
        end
        return true
    end

    function this.Start()
        if isPolling == false then
            isPolling = true
            poll.RegisterPollRoutine(PollRoutine)
        end
        return this
    end

    function this.Stop()
        isPolling = false
        return this
    end
end

function PollMouse(this)
    local isPolling = false
    local mouseButtons = { false, false, false, false, false }

    local function PollRoutine()
        if isPolling == false then return false end

        for i, v in ipairs(mouseButtons) do
            if IsMouseButtonPressed(i) then
                if v == false then
                    mouseButtons[i] = true
                    OnEvent("MOUSE_PRESSED", i, "")
                end
            elseif v == true then
                mouseButtons[i] = false
                OnEvent("MOUSE_RELEASED", i, "")
            end
        end

        return true
    end

    function this.Start()
        if isPolling == false then
            isPolling = true
            poll.RegisterPollRoutine(PollRoutine)
        end
        return this
    end

    function this.Stop()
        isPolling = false
        return this
    end
end

function inherit(this, ...)
    this = this or {}

    local item, current, base
    for i = 1, select('#', ...) do
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
    constructor(this)
    this.ctor = constructor
    return this
end

eventHandlers = {}

do -- begin OnEvent scope
    local eventLookup = {
        PROFILE_ACTIVATED = { "P", "Activated", true, false },
        PROFILE_DEACTIVATED = { "P", "Deactivated",nil, false },
        G_PRESSED = { "G", "Pressed", true },
        G_RELEASED = { "G", "Released" },
        M_PRESSED = { "M", "Pressed", true },
        M_RELEASED = { "M", "Released" },
        MOD_PRESSED = { "MOD", "Pressed", true },
        MOD_RELEASED = { "MOD", "Released" },
        MOUSE_PRESSED = { "MOUSE", "Pressed", true },
        MOUSE_RELEASED = { "MOUSE", "Released" },
    }

    local finishHandlers = {}

    function OnEvent(e, a, f)
        poll.OnEvent(e, a, f)

        local etable = eventLookup[e]
        local event = etable[1]
        if etable[4] ~= false then event = event..a end
        local method = etable[2]
        local isActivation = etable[3]

        --[[
        if e:sub(1, 2) ~= "M_" then
            OutputLogMessage(event.." "..method.." "..f.."\n")
        end
        ]]

        local handler

        if isActivation ~= true then
            handler = finishHandlers[event]
            if type(handler) == "table" and type(handler[method]) == "function" then
                handler[method](e, a, f)
            end
            return
        end

        local fhandler = eventHandlers[f] or eventHandlers
        local handler = fhandler[event]
        if handler == nil then handler = eventHandlers[event] end

        if type(handler) == "function" then
            handler = handler(e, a, f)
        end

        if type(handler) == "table" then
            if type(handler[method]) == "function" then
                handler[method](e, a, f)
                if isActivation == true then
                    finishHandlers[event] = handler
                end
            end
        end
    end
end -- end OnEvent scope

shiftKeys = {
    ["~"] = "tilde",
    ["!"] = "1",
    ["@"] = "2",
    ["#"] = "3",
    ["$"] = "4",
    ["%"] = "5",
    ["^"] = "6",
    ["&"] = "7",
    ["*"] = "8",
    ["("] = "9",
    [")"] = "0",
    ["_"] = "minus",
    ["+"] = "equal",
    ["{"] = "lbracket",
    ["}"] = "rbracket",
    ["|"] = "backslash",
    [":"] = "semicolon",
    ['"'] = "quote",
    ["<"] = "comma",
    [">"] = "period",
    ["?"] = "slash",
    ["A"] = "a",
    ["B"] = "b",
    ["C"] = "c",
    ["D"] = "d",
    ["E"] = "e",
    ["F"] = "f",
    ["G"] = "g",
    ["H"] = "h",
    ["I"] = "i",
    ["J"] = "j",
    ["K"] = "k",
    ["L"] = "l",
    ["M"] = "m",
    ["N"] = "n",
    ["O"] = "o",
    ["P"] = "p",
    ["Q"] = "q",
    ["R"] = "r",
    ["S"] = "s",
    ["T"] = "t",
    ["U"] = "u",
    ["V"] = "v",
    ["W"] = "w",
    ["X"] = "x",
    ["Y"] = "y",
    ["Z"] = "z"
}

noshiftKeys = {
    ["`"] = "tilde",
    ["-"] = "minus",
    ["="] = "equal",
    ["["] = "lbracket",
    ["]"] = "rbracket",
    ["\\"] = "backslash",
    [";"] = "semicolon",
    ["'"] = "quote",
    [","] = "comma",
    ["."] = "period",
    ["/"] = "slash",
    ["\t"] = "tab",
    ["\n"] = "enter",
    [" "] = "spacebar"
}

function GetKey(key)
    if key:len() == 1 then
        local k = shiftKeys[key]
        if k ~= nil then
            return k, true
        end

        local k = noshiftKeys[key]
        if k ~= nil then
            return k, false
        end

        return key, false
    end
    return key, false
end

Setup()
