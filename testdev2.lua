function Setup()
    poll = new(PollManager).Init("kb", 25)
    local pollModifiers = new(PollModifiers)
    local pollMouse = new(PollMouse)

    local mode1 = {
        kb = {
        },
        lhc = {
            G1 = new(function(this)
                    this.Init(25, 3)
                    local tapKeys = { "a", "b", "c" }

                    function this.OnPressed(tapCount)
                        PressKey(tapKeys[tapCount])
                    end

                    function this.OnReleased(tapCount)
                        ReleaseKey(tapKeys[tapCount])
                    end
                end, ButtonHandler),
            G2 = BindMacro(tap("a"), tap("b", 50), tap("c"))
        },
        P = {
            Activated = function (event, arg, family) OutputLogMessage("Profile Activated\n") end,
            Deactivated = function () OutputLogMessage("Profile Activated\n") end
        },
        Mouse1 = new(function(this)
                this.Init(200, 2)
                local clickMessages = { "Mouse1 Clicked", "Mouse1 Double-Clicked" }
                function this.OnPressed(clickCount)
                    OutputLogMessage(clickMessages[clickCount].."\n")
                    if(clickCount == 1) then
                        pollModifiers.Stop()
                    else
                        pollModifiers.Start()
                    end
                end
            end, ButtonHandler),
        ModCtrl = new(function(this)
                function this.OnPressed() OutputLogMessage("Ctrl pressed\n") end
                function this.OnReleased() OutputLogMessage("Ctrl released\n") end
            end, ButtonHandler)
    }

    SetMode(mode1)

    pollModifiers.Start();
    pollMouse.Start();
end

function MacroKey(this)
    local key
    local delay = 0
    local cooldown = 0
    local lastRunTime = nil
    local isKeyDown = false

    function this.Init(k, d, c)
        key = k
        if type(d) == "number" then delay = d end
        if type(c) == "number" then cooldown = c end
        lastRunTime = -cooldown
        return this
    end

    function this.Run()
        local time = GetRunningTime()
        if time >= lastRunTime + cooldown then
            lastRunTime = time
            isKeyDown = this.OnRun(key)
        end

        return delay
    end

    function this.Release()
        if isKeyDown then this.OnRelease(key) end
    end 

    function this.IsKeyDown()
        return isKeyDown
    end

    function this.OnRun(key) end
    function this.OnRelease(key) end
end

function MacroKeyDown(this)
    inherit(this, MacroKey)
    
    function this.OnRun(key)
        PressKey(key)
        return true
    end

    function this.OnRelease(key)
        ReleaseKey(key)
    end
end

function MacroKeyUp(this)
    inherit(this, MacroKey)
    
    function this.OnRun(key)
        ReleaseKey(key)
        return false
    end
end

function MacroKeyTap(this)
    inherit(this, MacroKey)
    
    function this.OnRun(key)
        PressAndReleaseKey(key)
        return false
    end
end

function MacroMNudge(this)
    inherit(this, MacroKey)

    function this.OnRun(coord)
        MouseMoveRelative(coord[1], coord[2])
        return false
    end
end

function MacroMMove(this)
    inherit(this, MacroKey)

    function this.OnRun(coord)
        MouseMoveTo(coord[1], coord[2])
        return false
    end
end

function MacroMWheel(this)
    inherit(this, MacroKey)

    function this.OnRun(amount)
        MoveMouseWheel(amount)
        return false
    end
end

function MacroMButtonDown(this)
    inherit(this, MacroKey)
    
    function this.OnRun(button)
        PressMouseButton(button)
        return true
    end

    function this.OnRelease(button)
        ReleaseMouseButton(button)
        return true
    end
end

function MacroMButtonUp(this)
    inherit(this, MacroKey)

    function this.OnRun(button)
        ReleaseMouseButton(button)
        return false
    end
end

function MacroMButtonTap(this)
    inherit(this, MacroKey)

    function this.OnRun(button)
        PressAndReleaseMouseButton(button)
        return false
    end
end

function MacroMSavePos(this)
    inherit(this, MacroKey)
    local x = 0
    local y = 0

    function this.OnRun()
        x, y = GetMousePosition()
        return false
    end

    function this.Recall()
        MouseMoveTo(x, y)
    end

    function this.X(v) if v ~= nil then x = v return this end return x end
    function this.Y(v) if v ~= nil then y = v return this end return y end
end

function down(key, delay, cooldown) return new(MacroKeyDown).Init(key, delay, cooldown) end
function up(key, delay, cooldown) return new(MacroKeyUp).Init(key, delay, cooldown) end
function tap(key, delay, cooldown) return new(MacroKeyTap).Init(key, delay, cooldown) end
function mnudge(coord, delay, cooldown) return new(MacroMNudge).Init(coord, delay, cooldown) end
function mmove(coord, delay, cooldown) return new(MacroMMove).Init(coord, delay, cooldown) end
function mwheel(amount, delay, cooldown) return new(MacroMWheel).Init(amount, delay, cooldown) end
function mbdown(button, delay, cooldown) return new(MacroMButtonDown).Init(button, delay, cooldown) end
function mbup(button, delay, cooldown) return new(MacroMButtonUp).Init(button, delay, cooldown) end
function mbtap(button, delay, cooldown) return new(MacroMButtonTap).Init(button, delay, cooldown) end
function msave(delay, cooldown) return new(MacroMSavePos).Init(nil, delay, cooldown) end

function Macro(this)
    local steps = {}
    local unreleased = {}
    local loop = false
    local isPolling = false
    local currentStep
    local delayUntil
    local stepCount
    local loopCount
    
    local function PollRoutine()
        if isPolling == false then return false end
        
        if currentStep > stepCount then
            if loop == false then
                isPolling = false
                return false
            elseif type(loop) == "number" then
                if loopCount > loop then
                    isPolling = false
                    return false
                else
                    loopCount = loopCount + 1
                    currentStepCount = 1
                end
            end
        end

        local time = GetRunningTime()
        while time >= delayUntil and currentStep <= stepCount do
            delayUntil = time + steps[currentStep].Run()
            currentStep = currentStep + 1
        end
    end
    
    function this.Init(...)
        stepCount = select('#', ...)
        for i = 1, stepCount do
            local item = select(i, ...)
            table.insert(steps, item)
        end
        return this
    end
    
    function this.Loop(v) if v ~= nil then loop = v return this end return loop end
    
    function this.Run()
        if isPolling == false then
            isPolling = true
            currentStep = 1
            loopCount = 1
            delayUntil = -1
            poll.RegisterPollRoutine(PollRoutine)
        end
    end
    
    function this.Abort()
        isPolling = false
        for i = 1, stepCount do
            steps[i].Release()
        end
    end
end

function NewMacro(...)
    return new(Macro).Init(...)
end

function BindMacro(...)
    local this = new(Macro).Init(...);
    inherit(this, ButtonHandler)
    
    function this.OnPressed()
        this.Run()
    end

    function this.OnReleased()
        this.Abort()
    end
    return this
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
                    OnEvent("MOUSE", "PRESSED_"..i, "")
                end
            elseif v == true then
                mouseButtons[i] = false
                OnEvent("MOUSE", "RELEASED_"..i, "")
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
                    OnEvent("MOD", "PRESSED_"..k:upper(), "")
                end
            elseif v == true then
                modKeys[k] = false
                OnEvent("MOD", "RELEASED_"..k:upper(), "")
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

--[[ for testing:
    for k, v in pairs(eventHandlers) do
        OutputLogMessage(k.."\n")
    end
]]
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
eventCount = 0
function OnEvent(event, arg, family)
    poll.OnEvent(event, arg, family)
    if family == nil then family = "" end
    if arg == nil then arg = "" end
    if event:sub(1, 1) == "P" then arg = "" end
    local eventarg = event
    if type(arg) == "number" and arg > 0 then eventarg = event.."_"..arg
    elseif type(arg) == "string" and arg:len() > 0 then eventarg = event.."_"..arg
    end
    local fn = eventHandlers[family.."_"..eventarg]
    if type(fn) == "function" then fn(event, arg, family)
    else
        fn = eventHandlers[eventarg]
        if type(fn) == "function" then fn(event, arg, family)
        end
    end
    --OutputLogMessage(eventCount.." : "..family..eventarg.."\n")
    eventCount = eventCount + 1
end

Setup()