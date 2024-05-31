
--[[ No need for require()'s, as all
	modules are available for the default
	configuration in Three ]]

local a = getThree()

this.hello = function()
	print("Hello World!")
end

this.abc = function()
	return "some string c: "
end

this.hi = function()
	print("three should be: ")
	print(getThree())
end
this.on_done = function()
	-- this runs when all modules are loaded,
	-- meaning that all packages will be
	-- available and callable (if conforming)
	print("done")
	a.debug.WARN("MOD: "..tostring(a.com.two.hello))
	a.debug.DEBUG("ABC in this mod: "..a.com.two.abc())
	a.debug.DEBUG("Hello from dummy, in two!")
	a.com.dummy.hello()
	a.debug.DEBUG("My file name is: "..this.__NAME)
end
this.on_load = function()
	-- this runs when this module is loaded,
	-- allowing some post-setup to occur before
	-- the main program is started up.
	print("loaded")
end
