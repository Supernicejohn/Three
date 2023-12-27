--[[
Three standard start file, v1
Run this file to call the default start script in three,
which starts three loading and running.
]]

-- Edit these to fit your project
local threeName = "THREE"
local threeLocation = "3mgr/three"
local startLocation = "3mgr/build/start.three.lua"
-- Get the current working directory
-- Modify if this breaks due to shell
local path = fs.getDir(shell.getRunningProgram())
-- Below is logic for locating dirs, modify if needed

-- Local vars
local wPath = path
local threePath = false

-- Find the path to Three
while true do
	if fs.getDir(wPath) ~= wPath then
		wPath = fs.getDir(wPath)
	else
		break
	end
	local dirs = fs.list(wPath)
	for _, v in pairs(dirs) do
		if v == threeName then
			threePath = fs.combine(wPath, v)
			break
		end
	end
	if wPath == "/" or threePath then
		break
	end
end

-- If all is well, skip
if not threePath then
	error("Three not found on the parent path!")
end

-- Set paths for starting three
local startPath = fs.combine(threePath, startLocation)
threePath = fs.combine(threePath, threeLocation)
local projPath = path

-- Hand over execution to Three
-- If no shell, require three in this file and 
-- run like the start.three.lua script does.
shell.run("/"..startPath, "/"..threePath, "/"..projPath)

