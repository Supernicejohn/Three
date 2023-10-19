local args = {...}
local three = require(args[1])
local debugFLAG = args[2]
if not debugFLAG or debugFLAG:len() == 0 then
	debugFLAG = three.debug.levels.fine
elseif debugFLAG then
	for k,v in pairs(three.debug.levelnames) do
		if debugFLAG == v then
			debugFLAG = k
			break
		end
	end
end
three.debug.setlevel(debugFLAG)

three.ld("three.test.dummy", "/CIMCOM/3mgr/_test/dummy")

--print(three.com.three.test.dummy)
three.debug.write(three.debug.levels.info,
	"Getting test mod")
local mod = three.gt("three.test.dummy")
mod.hello()
mod.hi()
three.event.modulesloaded()
three.debug.INFO("All done!")

