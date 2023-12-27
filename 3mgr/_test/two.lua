
--[[ No need for require()'s, as all
	modules are available for the default
	configuration in Three ]]

this.hello = function()
	print("Hello World!")
end
local a = getThree()
this.hi = function()
	print("three should be: ")
	print(getThree())
end
this.on_done = function()
	-- this runs when all modules are loaded,
	-- meaning that all packages will be
	-- available and callable (if conforming)
	print("done")
	a.debug.FINE("not printed")
	a.debug.INFO("printed")
	for k,v in pairs(a.com) do
		print("key: "..k..", val: "..tostring(v))
		for i,j in pairs(v) do
			print("key: "..i..", val: "..tostring(j))
		end
	end
end
this.on_load = function()
	-- this runs when this module is loaded,
	-- allowing some post-setup to occur before
	-- the main program is started up.
	print("loaded")
end
