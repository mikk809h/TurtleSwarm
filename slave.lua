-- First try to update
sleep(.25)
local rawUrl = "https://raw.githubusercontent.com/mikk809h/TurtleSwarm/master/slave.lua"
local handle = http.get(rawUrl)
if handle then
    local server_version = handle.readAll()
    handle.close()
    local handle = fs.open(shell.getRunningProgram(), "r")
    local client_version = handle.readAll()
    handle.close()

    if server_version ~= client_version then
        print("Update available")
        local handle = fs.open(shell.getRunningProgram(), "w")
        handle.write(server_version)
        handle.close()
        print("Update installed. Rebooting")
        error("REBOOT HERE", 0)
        --os.reboot()
    end
end









sleep(1)
for k,v in pairs(peripheral.getNames()) do
    local _type = peripheral.getType(v)
    if _type == "turtle" or _type == "computer" then
        peripheral.call(v, "turnOn")
    end
end
function selectEmpty()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
        else
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
sleep(1)
modem = peripheral.wrap("right")
local e = 0
while modem == nil do
    if e == 5 then
        error("Modem error", 0)
    end
    print("Missing modem")
    print("Reequipping modem")
    selectEmpty()
    turtle.equipRight()
    sleep(2)
    turtle.equipRight()
    modem = peripheral.wrap("right")
    e = e + 1
end

modem.open(5261)
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
