term.clear( )
term.setCursorPos( 1, 1 )
print( "Starting..." )
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

local function SelectEmpty()
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

local function FindModem()
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

local function QueueHandler()
    local tFilters = { }
    local eventData = { n = 0 }
    while true do
        table.sort( Queue, function( compare1, compare2 ) return compare1.Priority > compare2.Priority end )
        if #Queue > 0 then
            local r = Queue[ 1 ].Thread
            if r then
                if tFilters[ r ] == nil or tFilters[ r ] == eventData[ 1 ] or eventData[ 1 ] == "terminate" then
                    local ok, param = coroutine.resume( r, table.unpack( eventData, 1, eventData.n ) )
                    if not ok then
                        error( param, 0 )
                    else
                        tFilters[r] = param
                    end
                    if coroutine.status( r ) == "dead" then
                        table.remove( Queue, 1 )
                    end
                end
            end
            if r and coroutine.status( r ) == "dead" then
                table.remove( Queue, 1 )
            end
        end
        eventData = table.pack( os.pullEventRaw() )

        local ox, oy = term.getCursorPos( )
        term.setCursorPos( 1, height - 1 )
        term.clearLine( )

        if type( eventData ) == "table" then
            local decodedEvent = table.unpack( eventData )
            if type( decodedEvent ) == "table" then
                write( table.concat( decodedEvent, ", " ) )
            elseif type( decodedEvent ) == "string" or type( decodedEvent ) == "boolean" then
                write( tostring( decodedEvent ) )
            end
        elseif type( eventData ) == "string" or type( eventData ) == "boolean" then
            write( tostring( eventData ) )
        end
        term.setCursorPos( ox, oy )
    end
end

local function Listener()
    while true do
        local Event, ID, Channel, ReplyChannel, Run, Distance = os.pullEvent()
        if Event == "modem_message" then
            if type( Run ) == "table" then
                if type( Run.Action ) == "string" and type( Run.Priority ) == "number" then
                    table.insert( Queue, {
                        Priority = Run.Priority,
                        Thread = coroutine.create( Run.Action ),
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
