
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
	print("loaded")
end
this.main = function()
	print("main!")
end
