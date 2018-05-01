sleep( .05 )

local Modem = peripheral.find( "modem" )
local CurrentPriority = 10

local function Send( Action, AbortAll )
    Modem.transmit( 5261, 5261, { Action = Action, Priority = CurrentPriority, AbortAll = AbortAll } )
end

local width, height = term.getSize( )
local function Draw( )
    term.clear( )
    term.setCursorPos( 1, 1 )
    print( "Usage:" )
    print( "w: forward, s: back" )
    print( "a: turnLeft, d: turnRight" )
    print( "r: up, f: down" )
    print( "t: priority up, g: priority down" )

    term.setCursorPos( 1, height )
    write( "Priority: " .. CurrentPriority )
end

while true do
    Draw( )
    local event, a, b, c, d, e = os.pullEvent( )
    if event == "key_down" then
        if a == keys.w then
            -- forward
            Send( "turtle.forward()" )

        elseif a == keys.s then
            -- back
            Send( "turtle.back()" )

        elseif a == keys.a then
            -- turnLeft
            Send( "turtle.turnLeft()" )

        elseif a == keys.d then
            -- turnRight
            Send( "turtle.turnRight()" )

        elseif a == keys.r then
            -- up
            Send( "turtle.up()" )

        elseif a == keys.f then
            -- down
            Send( "turtle.down()" )

        elseif a == keys.t then
            -- priority up
            CurrentPriority = CurrentPriority + 1

        elseif a == keys.g then
            -- priority down
            CurrentPriority = CurrentPriority - 1

        end
    end

end
