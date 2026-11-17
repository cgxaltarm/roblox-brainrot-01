-- init.server: server entrypoint for Brainrot Night Market.
-- Validates the catalogue, creates the remotes, wires the systems together
-- (Economy owns money, Conveyor sells, Base holds pads, Steal handles
-- theft, Events runs Rush Hour and Festival, Save persists progress), and
-- starts the loops: income ticks, conveyor spawns, event rotation, autosave.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ServerScriptService.Server.Economy)
local Conveyor = require(ServerScriptService.Server.Conveyor)
local ConveyorDisplay = require(ServerScriptService.Server.ConveyorDisplay)
local Base = require(ServerScriptService.Server.Base)
local Steal = require(ServerScriptService.Server.Steal)
local Events = require(ServerScriptService.Server.Events)
local Save = require(ServerScriptService.Server.Save)

-- The rarity chances must sum to 1.0, or the conveyor roll is biased.
local chanceSum = 0
for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
	chanceSum = chanceSum + BrainrotData.RARITIES[rarity].Chance
end
assert(math.abs(chanceSum - 1) < 0.001, "BrainrotData: rarity chances must sum to 1.0")

-- Remotes: the only way the client asks the server to do anything.
-- The server owns all state; the client only renders.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function makeRemote(name, isEvent)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end
local buyRemote = makeRemote("BuyBrainrot")
local placeRemote = makeRemote("PlaceBrainrot")
local sellRemote = makeRemote("SellBrainrot")
local lockRemote = makeRemote("LockBase")
local rebirthRemote = makeRemote("Rebirth")
local stateSync = makeRemote("StateSync")
local conveyorSync = makeRemote("ConveyorSync")
local eventPing = makeRemote("EventPing")

local conveyor = Conveyor.New()
-- The market must look full from the first second: build the 3D models
-- for all five conveyor offers now, before the first player joins.
ConveyorDisplay.Update(conveyor)

-- Broadcast helpers: one player's state to them, the conveyor to everyone,
-- an event start/stop to everyone.
local function sendState(player)
	local snapshot = Economy.Snapshot(player)
	if snapshot ~= nil then
		stateSync:FireClient(player, snapshot)
	end
end
local function sendConveyor()
	conveyorSync:FireAllClients(Conveyor.Snapshot(conveyor))
end
local function sendEvent(name, active)
	eventPing:FireAllClients({ Name = name, Active = active })
end

Economy.Init({
	IsFestival = function()
		return Events.IsActive("Festival")
	end,
	AttachStealDetector = function(model, owner, slotIndex)
		Steal.AttachDetector(model, owner, slotIndex)
	end,
	OnStateChanged = sendState,
	OnConveyorChanged = function()
		sendConveyor()
		ConveyorDisplay.Update(conveyor)
	end,
})
Steal.Init(Economy)
Events.OnEventChanged = sendEvent
Save.Init()

-- A player joining gets a state, a base, their save, and the first syncs.
local function onPlayerAdded(player)
	local state = Economy.NewState()
	Economy.States[player] = state
	state.BaseName = Base.Assign(player)
	Save.LoadPlayer(player, Economy)
	sendState(player)
	sendConveyor()
	player.CharacterAdded:Connect(function(character)
		-- Respawning re-attaches whatever the player was carrying.
		task.wait(1)
		local current = Economy.States[player]
		if current ~= nil and current.Carrying ~= nil then
			local def = BrainrotData.FindCharacter(current.Carrying)
			if def ~= nil then
				Economy.AttachCarriedModel(player, def, current.CarryingMutation)
			end
		end
		-- Tagging: touching a thief who carries a STOLEN brainrot makes
		-- them drop it (their own purchases are safe from tagging).
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root ~= nil then
			root.Touched:Connect(function(hit)
				local other = Players:GetPlayerFromCharacter(hit.Parent)
				if other ~= nil and other ~= player then
					local otherState = Economy.States[other]
					if otherState ~= nil and otherState.CarryingIsStolen then
						Steal.DropCarried(other)
					end
				end
			end)
		end
	end)
end

-- A player leaving saves, frees their base, and clears their models.
local function onPlayerRemoving(player)
	Save.SavePlayer(player, Economy)
	Base.Release(player)
	local state = Economy.States[player]
	if state ~= nil then
		for _, placed in ipairs(state.Placed) do
			if placed.Model ~= nil then
				placed.Model:Destroy()
			end
		end
	end
	Economy.States[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Remote handlers: validate through the owning module, then sync.
buyRemote.OnServerEvent:Connect(function(player, conveyorIndex)
	if typeof(conveyorIndex) ~= "number" then
		return
	end
	Economy.BuyBrainrot(player, conveyor, math.floor(conveyorIndex))
	sendState(player)
end)
placeRemote.OnServerEvent:Connect(function(player, slotIndex)
	if typeof(slotIndex) ~= "number" then
		return
	end
	Economy.PlaceBrainrot(player, math.floor(slotIndex))
	sendState(player)
end)
sellRemote.OnServerEvent:Connect(function(player, slotIndex)
	if typeof(slotIndex) ~= "number" then
		return
	end
	Economy.SellBrainrot(player, math.floor(slotIndex))
	sendState(player)
end)
lockRemote.OnServerEvent:Connect(function(player)
	local state = Economy.States[player]
	if state == nil then
		return
	end
	Base.BuyLock(state)
	sendState(player)
end)
rebirthRemote.OnServerEvent:Connect(function(player)
	Economy.Rebirth(player)
	sendState(player)
end)

-- Income ticks once a second.
task.spawn(function()
	while true do
		task.wait(Config.IncomeTick)
		Economy.TickIncome()
	end
end)

-- The conveyor refills its first empty slot on its interval (twice as fast
-- during Rush Hour).
task.spawn(function()
	while true do
		if Events.IsActive("RushHour") then
			task.wait(Config.RushConveyorInterval)
		else
			task.wait(Config.ConveyorInterval)
		end
		if Conveyor.SpawnNext(conveyor) then
			sendConveyor()
			ConveyorDisplay.Update(conveyor)
		end
	end
end)

Events.StartLoop()
Save.StartAutosave(Economy)

print("[Brainrot Night Market] server ready: " .. tostring(#BrainrotData.CHARACTERS) .. " characters, " .. tostring(#BrainrotData.RARITY_ORDER) .. " rarities")
