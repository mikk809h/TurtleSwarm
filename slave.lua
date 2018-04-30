term.clear( )
term.setCursorPos( 1, 1 )
print( "Starting..." )
if fs.exists("log") then fs.delete("log") end

local width, height = term.getSize( )
-- Get all peripherals
local Modem = nil
sleep( .05 )

for _,v in pairs( peripheral.getNames( ) ) do
    local tPeripheral = peripheral.getType( v )
    if tPeripheral == "turtle" or tPeripheral == "computer" then
        peripheral.call( v, "turnOn" )
    elseif tPeripheral == "modem" then
        Modem = peripheral.wrap( v )
    end
end

local function WriteAt( x, y, str, cll )
    local ox, oy = term.getCursorPos( ) term.setCursorPos( x, y )
    if cll then term.clearLine() end
    term.write( tostring( str ) ) term.setCursorPos( ox, oy )
end

local function PrintAt( x, y, str, cll )
    local ox, oy = term.getCursorPos( ) term.setCursorPos( x, y )
    if cll then term.clearLine() end
    print( tostring( str ) ) term.setCursorPos( ox, oy )
end

local function AppendFile( file, str )
    if not fs.exists( file ) then
        local handle = fs.open( file, "w" )
        handle.write( str .. "\n" )
        handle.close()
    else
        local handle = fs.open( file, "a" )
        handle.write( str .. "\n" )
        handle.close()
    end
end

local function SelectEmpty( )
    for i = 1, 16 do
        if turtle.getItemCount( i ) == 0 then
            turtle.select( i )
            return true
        end
    end
    for i = 1, 16 do
        if turtle.getItemCount( i ) > 0 then
            local e = turtle.getItemDetail( i )
            if e.name == "minecraft:cobblestone" or e.name == "minecraft:stone" or e.name == "minecraft:endstone" then
                turtle.select( i )
                turtle.drop( )
                return true
            end
        end
    end
    return false
end

local function FindModem( )
    for i = 1, 16 do
        if turtle.getItemCount( i ) > 0 then
            local e = turtle.getItemDetail( i )
            if e.name == "computercraft:peripheral" or e.name == "computercraft:modem" then
                turtle.select( i )
                turtle.equipRight()
            end
        end
    end
end

-- Validate modem
if not Modem then
    print( "Retrying modem..." )
    FindModem( )
    Modem = peripheral.wrap( "right" )
    while not Modem do
        print( "Retrying modem..." )
        SelectEmpty( )
        turtle.equipRight( )
        sleep( .5 )
        turtle.equipRight( )
        sleep( 1 )
        Modem = peripheral.wrap( "right" )
    end
end

print( "Modem initiated" )

Modem.open( 5261 )


local Queue = {}
--[[
    Queue:
    {
        Priority = 1,
        Thread = nil,
    }
]]

--

--[[
    Normal priority is added

    Then high priority is added.

    Then low priority is added.

EXPECTATION:
    Normal runs for 1 second and pauses while high priority is running.
    Then Normal should continue.
    When Normal is done Low priority should begin.

REALITY:
    Normal runs for 1 second and stops. Then high priority action is running.
    When high priority is done it runs the low priority action instead of continuing the normal priority.
]]

local function QueueHandler()
    local tFilters = { }
    local eventData = { n = 0 }
    while true do
        table.sort( Queue, function( compare1, compare2 ) return compare1.Priority > compare2.Priority end )


        WriteAt( math.ceil( width / 2 ), height, "#Q:" .. tostring( #Queue ) )
        local str = "P: "
        for k,v in pairs( Queue ) do
            str = str .. k .. ":" .. tostring( v.Priority ) .. " / "
        end
        WriteAt( 1, height - 1, str, true )
        local remove = false
        if #Queue > 0 then
            local r = Queue[ 1 ].Thread
            if r then
                if tFilters[ r ] == nil or tFilters[ r ] == eventData[ 1 ] or eventData[ 1 ] == "terminate" then
                    AppendFile( "log", "Resuming thread at Queue 1: " .. Queue[ 1 ].Priority )
                    local ok, param = coroutine.resume( r, table.unpack( eventData, 1, eventData.n ) )
                    if not ok then
                        error( param, 0 )
                    else
                        tFilters[r] = param
                    end
                    if coroutine.status( r ) == "dead" then
                        AppendFile( "log", "Queue 1, Priority: " .. Queue[ 1 ].Priority .. " is dead!" )
                        remove = true
                    end
                end
            end
            if r and coroutine.status( r ) == "dead" then
                AppendFile( "log", "Queue 1, Priority: " .. Queue[ 1 ].Priority .. " is dead!" )
                remove = true
            elseif not r then
                AppendFile( "log", "Queue 1, No thread exists. Removing contents by index 1" )
                remove = true
            end
            if remove then
                AppendFile( "log", "Removing table contents at 1. Content:\n  Priority = " .. Queue[ 1 ].Priority )
                table.remove( Queue, 1 )
            end
        end
        eventData = table.pack( os.pullEventRaw() )
        if type( eventData ) == "table" then
            local decodedEvent = table.unpack( eventData )
            if type( decodedEvent ) == "table" then
                WriteAt( 1, height, table.concat( decodedEvent, ", " ), true )
            elseif type( decodedEvent ) == "string" or type( decodedEvent ) == "boolean" then
                WriteAt( 1, height, tostring( decodedEvent ), true )
            end
        elseif type( eventData ) == "string" or type( eventData ) == "boolean" then
            WriteAt( 1, height, tostring( eventData ), true )
        end
    end
end

local function Listener()
    while true do
        local Event, ID, Channel, ReplyChannel, Run, Distance = os.pullEvent()
        if Event == "modem_message" then
            if type( Run ) == "table" then
                if type( Run.Action ) == "string" and type( Run.Priority ) == "number" then
                    AppendFile( "log", "Adding new action:\n  Priority = " .. Run.Priority .. "\n  Action = " .. Run.Action )
                    table.insert( Queue, {
                        Priority = Run.Priority,
                        Thread = coroutine.create( loadstring( Run.Action ) ),
                    } )
                    os.queueEvent( "BEGIN_THREAD" )
                end
            end
        end
    end
end

local function SelfHandler()
    while true do
        local FuelLevel = turtle.getFuelLevel( )
        os.setComputerLabel( "BoofySloofy|" .. tostring( FuelLevel ) )
        sleep( 2 )
    end
end



parallel.waitForAll( QueueHandler, Listener, SelfHandler )
