--[[
	Three module loader
]]--


local three = {
	com = {} -- The com table
}

--[==[ DEBUGGING THREE ]==]

--[[ Three provides extensive debugging. To log
		to the standard output simply call 
		'three.debug.<severity>(<message>)' where
		severity is one of three.debug.levelnames.]]
three.debug = {
	write = function(level, msg)
		if three.debug.level < level-1 then
			return
		end
		local col = term.getTextColor()
		term.setTextColor(colors.purple)
		term.write("Three::")
		term.setTextColor(three.debug.colors[level])
		term.write(three.debug.levelnames[level]..": ")
		print(msg)
		term.setTextColor(col)
		if level == three.debug.levels.fatal then
			error("Three exited")
		end
	end,
	setlevel = function(level)
		three.debug.level = level
	end
}
three.debug.levels = {
	fatal = 0,
	err 	= 1,
	warn 	= 2,
	debug	= 3,
	info	= 4,
	fine	= 5
}
three.debug.levelnames = {
	"FATAL",
	"ERR",
	"WARN",
	"DEBUG",
	"INFO",
	"FINE"
}
--[[ create convenience log functions.]]
for k,v in pairs(three.debug.levelnames) do
	three.debug[v] = function(msg)
		three.debug.write(k, msg)
	end
end
three.debug.level = three.debug.levels.info
three.debug.colors = {
	colors.red,
	colors.red,
	colors.orange,
	colors.yellow,
	colors.blue,
	colors.green
}
--[==[ END DEBUGGING ]==]

--[[ _qualifiers is an internal function that
		replaces a 'path.to.module' with a
		{path, to, module} table.]]
three._qualifiers = function(path)
	local qualifiers = {}
	while true do
		local del = path:find("%.")
		if del then
			qualifiers[#qualifiers + 1] 
				= path:sub(1, del - 1)
			path = path:sub(del + 1, #path)
		else 
			if #path == 0 then
				break
			else
				qualifiers[#qualifiers + 1] = path
				break
			end
		end
	end
	return qualifiers
end

--[[ _walk is an internal function that walks
		over the com path tree for getting a
		module from a path.]]
three._walk = function(path)
	local qualifiers = three._qualifiers(path)
	if #qualifiers > 0 then
		local walk = three.com
		for i=1, #qualifiers - 1 do
			if not walk[qualifiers[i]] then
				walk[qualifiers[i]] = {}
			end
			walk = walk[qualifiers[i]]
		end
		return walk, qualifiers[#qualifiers]
	end
end

--[[ set is the function to use for manually
		setting the path for a loaded module.]]
three.set = function(path, mod)
	local qualifiers = three._qualifiers(path)
	if #qualifiers > 0 then
		local walk = three.com
		for i=1, #qualifiers - 1 do
			if not walk[qualifiers[i]] then
				walk[qualifiers[i]] = {}
			end
			walk = walk[qualifiers[i]]
		end
		walk[qualifiers[#qualifiers]] = mod
	end
end

--[[ ld is the 'load' function that takes in
		a module path, and a file path. This means
		that you can have a different entry in the
		com table than the specified file path.]]
three.ld = function(tpath, fpath)
	local mod = three.inload(fpath)
	if mod then
		three.set(tpath, mod)
	end
end

--[[ gt is the 'get' funciton that returns the
		module (or module tree node) at tpath,
		which is the module path.]]
three.gt = function(tpath)
	local walk, area = three._walk(tpath)
	return walk[area]
end

--[[ inload is the function used for manually
		loading a module from its file path+name.]]
three.inload = function(fileName, rel)
	if not fileName then
		three.debug.ERR("File name is nil, skipping!!")
		return
	end
	local f = fileName 
	if rel then
		f = shell.dir().."/"..f
	end
	if fs.exists(f..".lua") then
		f = f..".lua"
	end
	local l_ok, l_err = loadstring(
		three._load.wrap(f))
	if not l_ok then
		three.debug.ERR("loadstring errored: "..l_err
				.." skipping!!")
		return
	end
	local three_ref = function() return three end
	local proj_ref = function() return three.project end
	local c_ok, c_err = l_ok(three_ref, proj_ref)
	if not c_ok then
		three.debug.ERR(
			"call to loaded module file errored! "
				..c_err.." skipping!!")
		return
	else
		three._load.addevents(c_ok)
		return c_ok
	end
end

three._load = {}
three._load._prepend = [[
-- FALLBACK PREPENDER --
local args = {...}
local getThree = args[1]
local getProject = args[2]

local this = {}
]]
three._load._append = [[
-- FALLBACK APPENDER --
return this
]]

three._load.getfile = function(fileName)
	if not fs.exists(fileName) then
		three.debug.ERR("File "..fileName
			.." does not exist")
		return
	end
	local filestr = ""
	local fp = fs.open(fileName, "r")
	if not fp then
		three.debug.ERR("File "..fileName
			.." could not be read")
		return
	end
	while true do
		local line = fp.readLine()
		if not line then
			break
		end
		filestr = filestr..line.."\n"
	end
	fp.close()
	return filestr
end

three._load.wrap = function(fileName)
	local instr = three._load.getfile(fileName)
	if not instr then
		return
	end
	local outstr = ""
	outstr = three._load._prepend..instr
		..three._load._append
	return outstr
end

three._load.addevents = function(mod)
	if not mod then
		three.debug.WARN("Attempted to add event management\
			to a nil module")
		return
	end
	if mod.on_done then
		three.debug.INFO("Added an on_load callback")
		three.event.on_load_callbacks[
			#three.event.on_load_callbacks + 1]
			= mod.on_done
	end
	if mod.main and type(mod.main) == "function" then
		if three.project.main then
			three.debug.FATAL("Three refuses to work with"
				.." multiple modules with main methods!")
		end
		three.project.main = mod.main
		three.debug.INFO("Set main function")
	end
end

--[[ Three does basic event management, these are
		events that can be hooked on to for performing
		on module load an on module done initialization.]]
three.event = {
	on_done_callbacks = {},
	on_load_callbacks = {}
}

--[[ Modules should call this function once they are
		loaded, typically just before they return.]]
three.event.moduleloaded = function(path)
	-- ? congrats?
end

--[[ This function is called once all modules registered
		have been loaded, and will call the callbacks.]]
three.event.modulesloaded = function()
	for k, v in pairs(three.event.on_load_callbacks) do
		local ok, err = pcall(v)
		if not ok then
			three.debug.ERR(
			"Error during module loaded call: "..err)
		end
	end
	three.project.main()
end

--[[ This function registers a callback for a module that
		will run when all modules are loaded.]]
three.event.onmodulesloaded = function(callback)

end

--[[ This function is called when a specific module has
		finished its 'module loaded' section.]]
three.event.moduledone = function(path)
	
end

--[[ This function is called when all modules have
		finished their moduledone cleanup.]]
three.event.modulesdone = function()
	for k, v in pairs(three.event.on_done_callbacks) do
		local ok, err = pcall(v)
		if not ok then
			three.debug.ERR(
				"Error during module done call: "..err)
		end
	end
end

--[[ This function registers a callback for when
		all modules are done and cleaned up,
		use sparingly.]]
three.event.onmodulesdone = function(callback)
	on_done_callbacks[#on_done_callbacks + 1]
		= callback
end


--[[ The main feature of Three is the project
		building functionality. Specify configuration
		and module loading for a project and let
		Three load all files and perform initialization.
		See the README and utils directory in 3mgr for
		documentation and tools for setting up a project.]]
three.project = {}

--[[ The table that holds all information about the loaded
		project in Three.]]
three.project.com = {}
three.project.main = false -- is there a main() ?

--[[ Sets the root directory for the project ]]
three.project.setroot = function(path)
	three.project.root = path
end

three.project.walkdirs = function(cDir, mName)
	local entries = fs.list(cDir)
	local modules = {}
	for i=1, #entries do
		local dir = fs.combine(cDir, entries[i])
		local iName = mName.."."..fs.getName(dir)
		if fs.getName(dir):sub(1,1) ~= "." then
			if fs.isDir(dir) then
				three.project.walkdirs(dir, iName)
			elseif fs.exists(dir) then --normal file?
				three.ld(iName, dir)
			else
				three.debug.ERR("Could not walk to"
					.." file/dir: "..dir)
			end
		end
	end
end

--[[ Loads a project from a directory, with the
	specified options. ]]
three.project.loaddir = function(dir, opts)
	local opts = opts or {}
	if not opts[three.project.defs.NORMAL] then
		-- this indicates simplest possible execution,
		-- without proj files or excludes.
		three.project.walkdirs(dir, "")
		return
	end
end

--[[ Loads a project from a project file. ]]
three.project.fromproj = function(projFile)
	if not projFile or not fs.exists(projFile) then
		three.debug.FATAL("Project file missing")
	end
	
end

--[[ Three Project Defines -
	Describes options used for specifying loading
	the files in the project, and how they are run.
]]
three.project.defs = {
	NORMAL, -- if absent, Three does not take
	-- any care to load project files and similar.
	SAFE, -- if used, prompts Three to wrap
	-- more loading and execution in pcall's.
	EXPORT, -- if used, Three will instead of
	-- building in-place, export a finished executable
	-- to the root of the project directory.
	EXPORT_THREELESS, -- if used, Three will
	-- attempt to discard all of its own code when
	-- smashing the files.
	NO_STD, -- if used, no standard Three 
	-- library will be loaded on startup.
	SLAM, -- if used Three will prepare loading of
	-- modules after entering runtime.
}

return three
