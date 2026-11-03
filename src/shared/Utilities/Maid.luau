--!strict

-- connection cleanup

local Maid = {}

Maid.__index = Maid

export type Task = RBXScriptConnection | Instance | () -> () | { Destroy: (any) -> () } | { Disconnect: (any) -> () }


function Maid.new()

	return setmetatable({
		_tasks = {} :: { Task },
	}, Maid)
end

function Maid:GiveTask(task: Task): Task
	table.insert(self._tasks, task)

	return task
end

function Maid:DoCleaning()

	for _, task in ipairs(self._tasks) do
		local taskType = typeof(task)

		if taskType == "RBXScriptConnection" then
			(task :: RBXScriptConnection):Disconnect()
		elseif taskType == "Instance" then
			(task :: Instance):Destroy()
		elseif taskType == "function" then
			(task :: () -> ())()
		elseif taskType == "table" then
			local t = task :: any

			if type(t.Destroy) == "function" then
				t:Destroy()
			elseif type(t.Disconnect) == "function" then
				t:Disconnect()
			end

		end

	end

	table.clear(self._tasks)

end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
