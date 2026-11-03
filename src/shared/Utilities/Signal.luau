--!strict

-- custom signal

local Signal = {}

Signal.__index = Signal

export type Connection = {

	Disconnect: (self: Connection) -> (),

	Connected: boolean,

}

export type Signal<T...> = {

	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,

	Fire: (self: Signal<T...>, T...) -> (),

	Destroy: (self: Signal<T...>) -> (),

	Wait: (self: Signal<T...>) -> T...,

}


function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_handlers = {} :: { (T...) -> () },
	}, Signal)

	return (self :: any) :: Signal<T...>
end


function Signal:Connect(handler: (...any) -> ()): Connection
	table.insert(self._handlers, handler)
	local connection = { Connected = true }

	function connection:Disconnect()

		if not self.Connected then return end
		self.Connected = false
		local idx = table.find(self._handlers, handler)

		if idx then
			table.remove(self._handlers, idx)
		end

	end

	return connection

end

function Signal:Fire(...: any)

	for _, handler in ipairs(table.clone(self._handlers)) do
		task.spawn(handler, ...)
	end

end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	local conn: Connection
	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()

end

function Signal:Destroy()
	table.clear(self._handlers)
end

return Signal
