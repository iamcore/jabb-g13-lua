function PressKey(key)
    print("PressKey "..key)
end

function ReleaseKey(key)
    print("ReleaseKey "..key)
end



function Setup()
    testMode = {
        tapTest =
            new(function(this)
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






function Main()
    Setup()

    testMode.tapTest.Pressed()
    testMode.tapTest.Pressed()

    testMode.tapTest.Test()
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

Main()
