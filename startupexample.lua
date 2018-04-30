local VersionControl = loadfile("versioncontrol.lua")()

VersionControl:Slave()
shell.run("slave.lua")
