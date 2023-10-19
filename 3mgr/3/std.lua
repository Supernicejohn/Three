--[[ Three standard library extension ]]
--[[ This file gets loaded before any other 
		in a given project, and can be disabled
		with 'three --no-std. ]]

local three = getThree()

--[[ Simplified file, keyboard, mouse, term
		handling through std.io ]]
this.io = {}

--[[ Sync can be used if you wish to sync
		execution across many coroutines.
		Create locks and execution orders ]]
this.sync = {}

--[[ Create and listen to custom events ]]
this.event = {
	listeners = {
		-- key is the string,
		-- value is a table with callbacks
	},
	queue = {
		-- key is the string,
		-- value is a table with event data
	}
}




-- EVENTS --

--[[ Register a callback to run when a string
		matching 'str' gets created.
		Note: no guarantees of which callback
		gets ran in what order.]]
this.event.onevent = function(str, callback)
	if type(str) ~= "string" then
		three.debug.WARN("'"..tostring(str)
			.."' is not a string! Avoid non"
			.."-string event keys")
		return
	end
	if not this.event[str] then
		this.event[str] = {}
	end
	this.event[str][#this.event[str]]
		= callback
end

--[[ Create an event for listeners to catch
		and execute function calls from. Ex:
		[string event key] <arguments>
		{[1] = [string key], <[2]=x, [3]=y..>}
		]]
this.event.pushevent = function(...)
	local args = {...}
	if not args[1] then
		three.debug.DEBUG("nil event pushed")
		return
	end
	local ev = {}
	if type(args[1]) == "table" then
		ev = args[1]
	elseif type(args[1]) == "string" then
		ev = args
	end
	if not three.event.queue[ev[1]] then
		three.event.queue[ev[1]] = {}
	end
	local index = #three.event.queue[ev[1]]+1
	local key = this.util.shift(ev)
	three.event.queue[ev[1]][index] = ev
	three.event._onpush()
end

--[[ Used to notify three that there are events
		that could be dispatched.]]
this.event._onpush = function()
	--TODO: time for dispatching instead of imm?
	this.event._dispatchall()
end

--[[ Dispatch all events to their respective
		callback handlers.]]
this.event._dispatchall = function()
	for etype, i in pairs(this.event.queue) do
	end
end

this.util.shift = function(tbl)
	local first = tbl[1]
	for i=1, #tbl do
		tbl[i] = tbl[i + 1]
	end
	return first
end


