-- Save: loads and stores player progress in a DataStore.
-- Saved per player: cash, rebirth level, and every placed brainrot (name,
-- mutation, slot). Carried brainrots and lock timers are not saved: a
-- player rejoins with hands empty and their base unlocked. Every DataStore
-- call is wrapped in pcall, so a Studio session without DataStore access
-- still plays fine.
local DataStoreService = game:GetService("DataStoreService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local ServerScriptService = game:GetService("ServerScriptService")
local Base = require(ServerScriptService.Server.Base)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)

local Save = {}
Save.Store = nil

function Save.Init()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("BrainrotNightMarketV1")
	end)
	if ok then
		Save.Store = store
	else
		warn("[Brainrot Night Market] DataStore unavailable, progress will not save")
	end
end

-- Loads a player's saved progress into their state. Returns true when a
-- save was found and applied.
function Save.LoadPlayer(player, economy)
	if Save.Store == nil then
		return false
	end
	local ok, data = pcall(function()
		return Save.Store:GetAsync("player_" .. tostring(player.UserId))
	end)
	if not ok or data == nil then
		return false
	end
	local state = economy.States[player]
	if state == nil then
		return false
	end
	if typeof(data.Cash) == "number" then
		state.Cash = data.Cash
	end
	if typeof(data.RebirthLevel) == "number" then
		state.RebirthLevel = data.RebirthLevel
	end
	if typeof(data.Placed) == "table" then
		for _, saved in ipairs(data.Placed) do
			local def = BrainrotData.FindCharacter(saved.CharacterName)
			if def ~= nil and typeof(saved.Slot) == "number" then
				local slot = saved.Slot
				if slot >= 1 and slot <= Config.BaseSlots then
					local padCFrame = Base.GetPadCFrame(state.BaseName, slot)
					if padCFrame ~= nil then
						local mutation = saved.Mutation or ""
						local income = BrainrotData.IncomeFor(def, mutation, state.RebirthLevel)
						local model = CharacterModels.BuildModel(def, mutation, income)
						model.Name = "Placed_" .. def.Name
						model.PrimaryPart.Anchored = true
						model:SetPrimaryPartCFrame(padCFrame * CFrame.new(0, 0.5 + 1.5 * def.Scale, 0))
						model.Parent = economy.PlacedFolder()
						table.insert(state.Placed, {
							CharacterName = saved.CharacterName,
							Mutation = mutation,
							Slot = slot,
							Model = model,
							Stolen = false,
						})
						economy.AttachStealDetector(model, player, slot)
					end
				end
			end
		end
	end
	return true
end

-- Saves one player's progress now.
function Save.SavePlayer(player, economy)
	if Save.Store == nil then
		return false
	end
	local state = economy.States[player]
	if state == nil then
		return false
	end
	local placed = {}
	for _, item in ipairs(state.Placed) do
		table.insert(placed, {
			CharacterName = item.CharacterName,
			Mutation = item.Mutation,
			Slot = item.Slot,
		})
	end
	local data = {
		Cash = state.Cash,
		RebirthLevel = state.RebirthLevel,
		Placed = placed,
	}
	local ok, err = pcall(function()
		Save.Store:SetAsync("player_" .. tostring(player.UserId), data)
	end)
	if not ok then
		warn("[Brainrot Night Market] save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

-- Autosaves every player every Config.AutosaveInterval seconds.
function Save.StartAutosave(economy)
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for player, _ in pairs(economy.States) do
				Save.SavePlayer(player, economy)
			end
		end
	end)
end

return Save
