--[[
	Three
]]--


local three = {
	com = {}, -- The com table
	coro = {}, -- The coroutines managed by Three
	project = {}, -- The project table
	reader = {}, -- The three file reader
	preprocessor = {}, -- The pre processor
}

--[==[ DEBUGGING THREE ]==]

--[[ Three provides extensive debugging. To log
		to the standard output simply call 
		'three.debug.<severity>(<message>)' where
		severity is one of three.debug.levelnames.]]
three.debug = {
	write = function(level, msg)
		if three.debug.level < level then
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
	fatal = 1,
	err 	= 2,
	warn 	= 3,
	debug	= 4,
	info	= 5,
	fine	= 6
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
	local walk = three.com
	if qualifiers[1] == "com" then
		table.remove(qualifiers, 1)
	end
	if #qualifiers > 0 then
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
	local mPath = mod.mod_path or tpath
	if mod then
		three.set(mPath, three.std.getrotable(mod))
		table.insert(three.project.modulenames, mPath)
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
		f = fs.combine(shell.dir(), f)
	end
	if fs.exists(f..".lua") then
		f = f..".lua"
	end
	local wrapped = three._load.wrap(f)
	local mPath = three.preprocessor.getModulePath(wrapped)
	print("mod path for "..fileName..":"
		..tostring(mPath))
	local l_ok, l_err = loadstring(wrapped)
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
	end
	three._load.checks(c_ok)
	three._load.addevents(c_ok)
	return {mod = c_ok, mod_path = mPath}
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
	local shortened = fileName:sub(#fileName - 12,
		#fileName)
	local prepend = "--"..shortened
		..three._load._prepend --fallback
	local append = three._load._append --fallback
	--TODO: custom loaders
	if prepend:find("FALLBACK") and 
		not three.project.nags.default_prepend then
		three.project.nags.default_prepend = true
		three.debug.DEBUG("Using fallback prepender in "
		.."loading! Consider generating a default one")
	end
	if append:find("FALLBACK") and
		not three.project.nags.default_append then
		three.project.nags.default_append = true
		three.debug.DEBUG("Using fallback appender in "
		.."loading! Consider generating a default one")
	end
	prepend = prepend.."\nthis.__NAME = \""..fileName.."\""
	local instr = three._load.getfile(fileName)
	if not instr then
		return
	end
	local outstr = ""
	outstr = prepend..instr..append
	print()
	return outstr
end

--[[ Three will perform some sanity checks for you ]]
three._load.checks = function(mod)
	if type(mod) ~= "table" then
		three.debug.ERROR("Can not check non-module!")
		return
	end
	-- finalized what to check TBD
end

three._load.addevents = function(mod)
	if not mod then
		three.debug.WARN("Attempted to add event management\
			to a nil module")
		return
	end
	if mod.on_done then
		three.event.on_done_callbacks[
			#three.event.on_done_callbacks + 1]
			= mod.on_done
	end
	if mod.on_load then
		three.event.on_load_callbacks[
			#three.event.on_load_callbacks + 1]
			= mod.on_load
	end
	if mod.main and type(mod.main) == "function" then
		if three.project.main then
			three.debug.FATAL("Three refuses to work with"
				.." multiple modules with main methods!")
		end
		three.project.main = mod.main
	end
end

--[[ Three does basic event management, these are
		events that can be hooked on to for performing
		on module load an on module done initialization.]]
three.event = {
	on_done_callbacks = {},
	on_load_callbacks = {}
}

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
	three.event.on_done_callbacks[
		#three.event.on_done_callbacks + 1]
			= callback
end

--[[ The Three standard library, for interfacing with
	events, I/O, buffers, synchronization et.c.
	]]
three.std = {}
three.std.getruntime = function()
	return shell
end
three.std.getrotable = function(handle)
	local rot = {} -- perfect name
	for k, v in pairs(handle) do
		rot[k] = handle[k]
	end
	local meta = {}
	meta.__index = function()
		three.debug.ERR("Readonly module")
	end
	
	return setmetatable(rot, meta)
end


--[[ The main feature of Three is the project
		building functionality. Specify configuration
		and module loading for a project and let
		Three load all files and perform initialization.
		See the README and utils directory in 3mgr for
		documentation and tools for setting up a project.]]

--[[ The table that holds all information about the loaded
		project in Three.]]
three.project.com = {}
three.project.main = false -- is there a main() ?
three.project.modulenames = {}

--[[ Sets the root directory for the project ]]
three.project.setroot = function(path)
	three.project.root = path
end

--[[ Sets the directory for the three files ]]
three.project.setthreedir = function(path)
	three.project.threedir = path
end

three.project.printmods = function()
	local function printmod(table, path)
		for k,v in pairs(table) do
			if type(v) == "table" then
				three.debug.INFO(path.."-> ")
				printmod(v, path.."."..k)
			else
				three.debug.INFO(path.."->"..k)
			end
		end
	end
	printmod(three.com, "")
end

three.project.walkproj = function(cDir, mName, opts)
	local entries = fs.list(cDir)
	local modules = {}
	for i=1, #entries do
		local dir = fs.combine(cDir, entries[i])
		local iName = ""
		if #mName > 0 then
			iName = mName.."."..fs.getName(dir)
		else
			iName = fs.getName(dir)
		end
		-- HACK!
		if iName:sub(#iName - 3, #iName) == ".lua" then
			iName = iName:sub(1, #iName - 4)
		elseif iName:sub(#iName - 3, #iName) == ".ext" then
			iName = iName:sub(1, #iName - 4)
		end
		-- won't be needed with next gen prepender
		if three.project.getchecker(dir, opts) then
			if fs.isDir(dir) then
				three.project.walkproj(dir, iName, opts)
			elseif fs.exists(dir) then
				three.ld(iName, dir)
				three.project.modulecount = 
					three.project.modulecount and
					three.project.modulecount + 1 or
					1
			else
				three.debug.ERR("Could not walk to"
				.." file/dir: "..dir)
			end
		end
	end
end

three.project.populatecom = function()
	for k,v in pairs(three.com) do
		three.project.com[k] = three.std.getrotable(v)
	end
end

three.project._three_whitelist = {
	"*.ext",
	"*/"
}
three.project._three_blacklist = {
	"three.lua",
	"*.swp"
}

--[[ Loads a project from a directory, with the
	specified options. ]]
three.project.loaddir = function(dir, opts)
	local opts = opts or {}
	if not opts[three.project.defs.NORMAL] then
		-- this indicates simplest possible execution,
		-- without proj files or excludes.
		three.debug.DEBUG("No project file")
		three.project.walkdirs(dir, "")
		return
	end
	-- attempt to load extra three files
	if three.project.threedir then
		local d = fs.getDir(three.project.threedir)
		three.debug.WARN(d)
		three.project.walkproj(d, "", {
			whitelist = three.project._three_whitelist,
			blacklist = three.project._three_blacklist
		})
	end

	-- we assume we have a valid project file, and
	-- if not, should fail out with an error message.
	three.project.walkproj(dir, "", opts)
	--three.project.printmods()
	three.project.populatecom()
	three.event.modulesloaded()
	three.event.modulesdone()
	if three.project.main then
		three.project.main()
	else
		three.debug.INFO("No main() method..")
	end
end

local function splitstr(str, denom)
	local lines = {}
	for s in str:gmatch("[^"..denom.."]+") do
		table.insert(lines, s)
	end
	return lines
end

--[[ Loads a project from a project file. 
	requires an absolute path to the project file.]]
three.project.fromproj = function(projFile)
	local obj = {}
	if not projFile or not fs.exists(projFile) then
		three.debug.FATAL("Project file missing: "..
		projFile)
	end
	local fp = fs.open(projFile, "r")
	if not fp then
		three.debug.FATAL("Error reading project file: "
			..tostring(projFile))
	end
	local lines = fp.readAll()
	fp.close()
	-- Is this the 'root' project file?
	obj.isRoot = false
	if lines:find("[Root]") then
		obj.isRoot = true
	end
	obj.root = fs.getDir(projFile)
	lines = splitstr(lines, "\n")
	
	obj[three.project.defs.NORMAL] = true 
	obj.whitelist = three.project.getwhite(lines)
	obj.blacklist = three.project.getblack(lines)

	three.project.loaddir(obj.root, obj)
end

--TODO fix location
local function lazymatch(match, str)
	if match:sub(#match, #match) == "/" then
		if fs.isDir(str) then
			return true
		end
	end
	local str = fs.getName(str)
	if match:sub(1,1) == "*" then
		if str:find(match:sub(2, #match)) then
			return true
		end
	elseif match:sub(#match, #match) == "*" then
		if str:sub(1, #match - 1) == match:sub(1, #match - 1) then
			return true
		end
	elseif str == match then
		return true
	end
	return false
end

three.project.getchecker = function(name, opts)
	local isWhitelisted = false
	local isBlacklisted = false
	for i=1, #opts.whitelist do
		if lazymatch(opts.whitelist[i], name) then
			isWhitelisted = true
			break;
		end
	end
	for i=1, #opts.blacklist do
		if lazymatch(opts.blacklist[i], name) then
			isBlacklisted = true
			break;
		end
	end
	return isWhitelisted and not isBlacklisted
end

three.project.getwhite = function(lines)
	local whitelist = {}
	local isIn = false
	for i=1, #lines do
		local l = lines[i]
		if l:find("%[Loading Whitelist%]") then
			isIn = true
		elseif isIn and l:sub(1,1) == "["
			and l:sub(#l, #l) == "]" then
			break
		elseif isIn and l:sub(1,1) ~= "#" then
			whitelist[#whitelist + 1] = l
		end
	end
	return whitelist
end

three.project.getblack = function(lines)
	local blacklist = {}
	local isIn = false
	for i=1, #lines do
		local l = lines[i]
		if l:find("%[Loading Blacklist%]") then
			isIn = true
		elseif isIn and l:sub(1,1) == "["
			and l:sub(#l, #l) == "]" then
			break
		elseif isIn and l:sub(1,1) ~= "#" then
			blacklist[#blacklist + 1] = l
		end
	end
	return blacklist
end

--[[ Gets the module path from the string
	representing a complete module file.
	Looks for --MOD: <str> 
	If not found returns nil]]
three.preprocessor.getModulePath = function(str)
	local mStr = "%-%-MOD:"
	local mLen = #mStr-2
	local off = str:find(mStr)
	if not off then
		return
	end
	str = str:sub(off, #str)
	local line = str:sub(
		str:find(mStr.."%s*%S+"))
	local s, e = line:sub(mLen + 1, #line):find("%S+")
	local path = line:sub(mLen + s, mLen + e)
	return path
end

--[[ Three reader, reads the lua files and 
	generates the necessary lua for the three
	instructions. ]]
--[[ Example:
#version 2.0
^ Specifies a minimum Three version to build.

#level WARN
^ Specifies a minimum log level.

#using three.std.stream.out as stdout
^ Generates:
	local stdout = getThree()._load().get(\
	"three.std.stream.out");

#using com.mymod.helper.tostring as tostring
^ Generates:
	local tostring = getThree()._load().get(\
	"com.mymod.helper.tostring");

#inline com.mymod.helper.tostring as tostring
^ Generates the function call stated above, 
	at all locations of "tostring" in the code.
	Useful where the module loaded is only
	available at runtime (which is dangerous).
]]



--[[ Three warnings/nags about project or module
	structure on load ]]
three.project.nags = {}

--[[ Three Project Defines -
	Describes options used for specifying loading
	the files in the project, and how they are run.
]]
three.project.defs = {
	NORMAL = 0x1, -- if absent, Three does not take
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
