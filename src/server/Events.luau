-- Events: the market's timed events, alternating every 4 minutes.
-- Rush Hour: the conveyor runs twice as fast and a thief NPC raids a base.
-- Festival: all income x2 and the Golden mutation chance doubles.
-- Each event lasts 45 seconds. ForceEvent lets a reviewer (or TOUR.json)
-- trigger one on demand.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local ServerScriptService = game:GetService("ServerScriptService")
local Conveyor = require(ServerScriptService.Server.Conveyor)
local Steal = require(ServerScriptService.Server.Steal)

local Events = {}
Events.ActiveName = ""
Events.ActiveUntil = 0
Events.NextIndex = 1
Events.NAMES = { "RushHour", "Festival" }
Events.OnEventChanged = function(_, _) end

-- Whether an event is running right now.
function Events.IsActive(name)
	if name == nil then
		return Events.ActiveName ~= "" and os.time() < Events.ActiveUntil
	end
	return Events.ActiveName == name and os.time() < Events.ActiveUntil
end

-- Starts an event now, for Config.EventDuration seconds.
function Events.StartEvent(name)
	Events.ActiveName = name
	Events.ActiveUntil = os.time() + Config.EventDuration
	if name == "RushHour" then
		Conveyor.RushActive = true
		Steal.SpawnThief()
	elseif name == "Festival" then
		Conveyor.FestivalActive = true
	end
	Events.OnEventChanged(name, true)
	task.delay(Config.EventDuration, function()
		if Events.ActiveName == name then
			Events.ActiveName = ""
			Conveyor.RushActive = false
			Conveyor.FestivalActive = false
			Events.OnEventChanged(name, false)
		end
	end)
end

-- Forces one event to start immediately (reviewer / TOUR.json path).
function Events.ForceEvent(name)
	if name ~= "RushHour" and name ~= "Festival" then
		return false
	end
	Events.StartEvent(name)
	return true
end

-- The background timer: every EventInterval seconds, start the next event
-- in the rotation (Rush Hour, then Festival, then Rush Hour again...).
function Events.StartLoop()
	task.spawn(function()
		while true do
			task.wait(Config.EventInterval)
			local name = Events.NAMES[Events.NextIndex]
			Events.NextIndex = Events.NextIndex % #Events.NAMES + 1
			Events.StartEvent(name)
		end
	end)
end

return Events
