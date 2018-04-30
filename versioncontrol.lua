local rawUrl = "https://raw.githubusercontent.com/mikk809h/TurtleSwarm/master/"



local VersionControl = {}

-- Update slave file from github
function VersionControl:Slave()
    rawUrl = rawUrl .. "slave.lua"
    local handle = http.get(rawUrl)
    if handle then
        local server_version = handle.readAll()
        handle.close()
        local handle = fs.open("slave.lua", "r")
        local client_version = handle.readAll()
        handle.close()
        -- Compare versions
        if server_version ~= client_version then
            print("Update available")
            local handle = fs.open("slave.lua", "w")
            handle.write(server_version)
            handle.close()
            print("Update installed. Rebooting")
            error("REBOOT HERE", 0)
            --os.reboot()
        end
    end
    print("Done")
end

function VersionControl:Master()
    rawUrl = rawUrl .. "master.lua"
    local handle = http.get(rawUrl)
    if handle then
        local server_version = handle.readAll()
        handle.close()
        local handle = fs.open("master.lua", "r")
        local client_version = handle.readAll()
        handle.close()
        -- Compare versions
        if server_version ~= client_version then
            print("Update available")
            local handle = fs.open("master.lua", "w")
            handle.write(server_version)
            handle.close()
            print("Update installed. Rebooting")
            error("REBOOT HERE", 0)
            --os.reboot()
        end
    end
    print("Done")
end


return setmetatable(VersionControl, {})
