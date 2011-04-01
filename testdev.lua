--[[

Setup creates a table of families, and each family 
contains handlers for the various keyboard functions

For example, setup for the G13 left-handed controller
occurs in the lhc family; G keys begin with G and are
followed by the key number, while M keys begin with
(suprise!) M followed by the key number.

Profile activation/deactivation doesn't have a family
value, so those functions go under the "any" family.
Also, (at least on the G13) the controller passes
0 as the arg to OnEvent for Profile events - thus,
the Profile key is P0

--]]
function Setup()
    return {
        kb = {
        },
        lhc = {
            -- setup for the G1 key
            -- This inherits from ButtonHandler and implements
            -- the OnPressed and OnReleased functions. This sample
            -- will press and release the "a" key for a single tap,
            -- while a double tap of G1 will press/release "b"
            G1 = (function(this)
                    function this.OnPressed(tapCount)
                        if tapCount == 1 
                        then PressKey("a")
                        else PressKey("b")
                        end
                    end

                    function this.OnReleased(releaseCount)
                        if releaseCount == 1 
                        then ReleaseKey("a")
                        else ReleaseKey("b")
                        end
                    end

                    return this
                end)(ButtonHandler(200, 2))
        },
        any = {
            -- Profile activation/deactivation performed here
            P0 = {
                Activated = function() end,
                Deactivated = function() end
            }
        }
    }
end

--[[
ButtonHandler is a closure that returns a table - this is 
basically a means of emulating a class, where the function
itself is the constructor that returns the object created

ButtonHandler can handle multiple key taps - i.e. a different
action can be performed if a key is tapped twice in rapid
succession. Note that the single tap action is always performed
before a double tap action - this can be changed if a polling
mechanism is implemented
--]]
function ButtonHandler(
    multiTapSpan,   -- the number of milliseconds multiple key-taps must occur within
    maxTapCount     -- the maximum number of mulitple key-taps handled
    )
    -- private variables
    local this = {}         -- the object to return
    local isPressed = false -- whether or not the button is pressed
    local pressTime = 0     -- when the button was pressed
    local tapCount = 1      -- the number of key taps that have occurred
    local releaseCount = 1  -- the number of key releases (matches tapCount)

    -- set default values
    if multiTapSpan == nil then multiTapSpan = 0 end
    if maxTapCount == nil then maxTapCount = 0 end

    -- called when the button is pressed
    function this.Pressed()
        isPressed = true

        -- get the time since the last press time
        local time = GetRunningTime() - pressTime

        -- if time is within the multiTapSpan and the maximum tap count has
        -- not been reached, increment the tap count ...
        if time < multiTapSpan and tapCount < maxTapCount then
            tapCount = tapCount + 1
            releaseCount = tapCount
        -- ... otherwise, reset the last pressed time and the tap count
        else
            pressTime = GetRunningTime()
            tapCount = 1
            releaseCount = 1
        end

        -- call the subclass-supplied OnPressed function
        this.OnPressed(tapCount)
    end

    -- called when the button is released
    function this.Released()
        isPressed = false
        -- call the subclass-suppled OnReleased function
        this.OnReleased(releaseCount)
    end

    -- expose isPressed using a public getter function
    function this.IsPressed()
        return isPressed
    end

    -- subclasses can override (i.e. replace) these functions to implement
    -- specific actions
    function this.OnPressed(tapCount) end
    function this.OnReleased(releaseCount) end

    return this
end





-- setup the handlers
handlers = Setup()

--[[
NewHandler returns a function that finds the handler object-function (i.e. method)
in the handlers table for a given event, arg, and family. The name parameter
provides a means of distinguishing between press and release - so, for example,
G_PRESSED is divided into an event "G" and a name "Pressed". See the events table
for more.
-- ]]
function NewHandler(event, name)
    return function(arg, family)
        local familyTable = family ~= null and handlers[family] or handlers.any
        if type(familyTable) == "table" then
            local eventTable = arg ~= nil and familyTable[event..arg] or familyTable[event]
            if type(eventTable) == "table" then
                local fn = eventTable[name]
                if type(fn) == "function" then
                    fn()
                end
            end
        end
    end
end

-- divide controller events into event and name
events = {
    PROFILE_ACTIVATED = NewHandler("P", "Activated"),
    PROFILE_DEACTIVATED = NewHandler("P", "Deactivated"),
    G_PRESSED = NewHandler("G", "Pressed"),
    G_RELEASED = NewHandler("G", "Released"),
    M_PRESSED = NewHandler("M", "Pressed"),
    M_RELEASED = NewHandler("M", "Released")
}

-- entry point for logitech G* controllers
function OnEvent(event, arg, family)
    local fn = events[event]
    if type(fn) == "function" then fn(arg, family) end
end


--[[---------------------------------------------------------------------------
HISTORY

00.01   2011-03-31  Initial revision
--]]---------------------------------------------------------------------------
