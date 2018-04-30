-- Get all peripherals
local Modem = nil
sleep(.05)

for _,v in pairs(peripheral.getNames()) do
    local tPeripheral = peripheral.getType(v)
    if tPeripheral == "turtle" or tPeripheral == "computer" then
        peripheral.call(v, "turnOn")
    elseif tPeripheral == "modem" then
        Modem = peripheral.wrap(v)
    end
end

local function SelectEmpty()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            turtle.select(i)
            return true
        end
    end
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            local e = turtle.getItemDetail(i)
            if e.name == "minecraft:cobblestone" or e.name == "minecraft:stone" or e.name == "minecraft:endstone" then
                turtle.select(i)
                turtle.drop()
                return true
            end
        end
    end
    return false
end

local function FindModem()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            local e = turtle.getItemDetail(i)
            if e.name == "computercraft:peripheral" or e.name == "computercraft:modem" then
                turtle.select(i)
                turtle.equipRight()
            end
        end
    end
end

-- Validate modem
if not Modem then
    print("Retrying modem...")
    FindModem()
    Modem = peripheral.wrap("right")
    while not Modem do
        print("Retrying modem...")
        SelectEmpty()
        turtle.equipRight()
        sleep(.5)
        turtle.equipRight()
        sleep(1)
        Modem = peripheral.wrap("right")
    end
end
print("Modem initiated")

modem.open(5261)

local Queue = {}
--[[
    Queue:
    {
        Priority = 1,
        Thread = nil,
    }
]]

local function QueueHandler()
    while true do
        -- Sort by highest priority
        table.sort(Queue, function(compare1, compare2) return compare1.Priority > compare2.Priority end)

-- Only run the highest priority job
        if type(Queue[1]) == "table" then
            if type(Queue[1].Thread) == "thread" then
                local status = coroutine.status(Queue[1].Thread)
                if status == "suspended" then
                    coroutine.resume(Queue[1].Thread)
                elseif status == "dead" then
                    table.remove(1)
                end
            end
        end
        sleep(1)
    end
end

local function Listener()
    while true do
        local Event, ID, Channel, ReplyChannel, Run, Distance = os.pullEvent()
        if Event == "modem_message" then
            if type(Run) == "table" then
                if type(Run.Action) == "string" and type(Run.Priority) == "number" then
                    table.insert(Queue, {
                        Priority = Run.Priority,
                        Thread = coroutine.create(Run.Action),
                    })
                end
            end
        end
    end
end

local function SelfHandler()
    while true do
        local FuelLevel = turtle.getFuelLevel()
        os.setComputerLabel("BoofySloofy|" .. tostring(FuelLevel))
        sleep(2)
    end
end

local Threads = {
    coroutine.create(SelfHandler),
    coroutine.create(Listener),
    coroutine.create(QueueHandler),
}
-- Main loop
while true do
    for k, v in pairs(Threads) do
        local state = coroutine.status(v)
        if state == "suspended" then
            coroutine.resume(v)
        end
    end
end



local action = {}


function listener()
    while true do
        local event, a, b, c, run, e = os.pullEvent()
        if event == "modem_message" then
            if type(run) == "table" then
                if type(run.action) == "string" then
                    table.insert(action, run.action)
                end
            end
        end
    end
end

function runQueue()
    for k in pairs(action) do
        print("Running action: " .. tostring(k))
        local ok, err = pcall(loadstring(action[k]))
        if not ok then
            print("Action->Error: " .. tostring(err))
        end
        table.remove(action, k)
        break
    end
end

function one()
    while true do
        local ok, err = pcall(listener)
        if not ok then
            print("ERROR : " .. tostring(err))
        end
        sleep(1)
    end
end

function two()
    while true do
        local ok, err = pcall(runQueue)
        if not ok then
            print("ERROR : " .. tostring(err))
        end
        sleep(1)
    end
end

function draw()
    local oldFuel = -1
    local width, height = term.getSize()
    local u = 1
    local ox, oy, oz = -1, -1, -1
    while true do
        local currentfuel = turtle.getFuelLevel()
        if oldFuel ~= currentfuel then
            os.setComputerLabel("BoofySloofy_F:" .. currentfuel)
            oldFuel = currentfuel
        end
        local x, y, z = nil, nil, nil
        if u == 1 then
            x,y,z = gps.locate(2)
            ox, oy, oz = x, y, z
        end

        local pr = "F: " .. turtle.getFuelLevel()
        pr = pr .. " T: " .. textutils.formatTime(os.time(), true)
        if x == nil and y == nil and z == nil then
            pr = pr .. " L!:" .. tostring(ox) .. ", " .. tostring(oy) .. ", " .. tostring(oz)
        else
            pr = pr .. " L: " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z)
        end
        pr = pr .. " " .. tostring(u)
        pr = pr .. string.rep(" ", width-#pr)

        term.setCursorPos(1, height - 1)
        term.write(string.rep("=", width))
        term.setCursorPos(1, height)
        term.write(pr)

        term.setCursorPos(1, 1)
        sleep(1)
        u = u < 25 and u + 1 or 1
    end
end

parallel.waitForAll(one, two, draw)
