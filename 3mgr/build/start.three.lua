-- First - Load Three
local args = {...}
if not args[1] then
	error("Nothing passed as argument, start script"..
		" needs an absolute path to Three.")
end
if not args[2] then
	error("No path to project for default start script")
end
local three = require(args[1])
if not three then
	error("Loading Three failed")
end
local this = {}

-- Three std will load 
-- after that this startup program loads the modules

--TODO: read in-args

--TODO: modify three runtime (diff require funcs etc.)

--TODO: read three.proj files in each dir, recursing


local root_dir = args[2] -- TODO: update

three.debug.INFO("Three loading init")
three.project.setroot(root_dir)
three.debug.INFO("Running on project root '"..root_dir.."'")
--three.project.loaddir(root_dir)
three.project.fromproj(root_dir.."three.proj")
three.debug.INFO("All modules loaded!")
three.debug.INFO("End of execution")
--TODO: use three file system 

--TODO: call post-shutdown code
