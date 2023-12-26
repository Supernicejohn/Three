local args = {...}

local project_name = args[1] or "TODO"

local curDir = shell.dir()
local fileName = fs.combine(curDir, "three.proj")
if fileName:sub(1,1) ~= "/" then
	fileName = "/"..fileName
	--prepend a slash for absolute path.
end
if fs.exists(fileName) then
	error("Already a Three project at "..curDir)
end
local file = fs.open(fileName, "w")
if not file then
	error("Could not open file for writing: "..fileName)
end

local fileStr = [[
[Three Project File]
[Root]
[Epoch stamp=]]..os.epoch("utc")..[[]
[Project Name=]]..project_name..[[]
[Project Author=TODO]
[Project Type=TODO]
[Project Tags]
NORMAL
[Project Ignores]
.*
#Add/Remove project ignores to get Three to ignore
#parts of the directories (matches first-level)
#Note: Do not exclude non-runnable resources, 
#block them from loading with the Loading Blacklist if necessary.
[Loading Whitelist]
*.lua
#Add other filetypes, or file extensions.
#Note: only runnable Lua code should be included here.
[Loading Blacklist]
start.lua
.*
#Exclude code that should not be ran, like temporary tests.
[Loader]
#Specify a custom module loader, that is, function that loads the
#runnable code into the three environment. (path)
[End Three Project File]
]]

file.write(fileStr)
file.close()
print("Wrote a project file to "..fileName
	..". Thanks for using Three!")
