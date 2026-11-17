-- Economy: the server's single source of truth for player money.
-- Owns every PlayerState (cash, placed brainrots, what they carry, lock and
-- rebirth level), ticks income every second, and runs buy / place / sell /
-- rebirth. The client never touches money: it only asks, and this module
-- decides.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local Conveyor = require(ServerScriptService.Server.Conveyor)
local Base = require(ServerScriptService.Server.Base)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)

local Economy = {}
Economy.States = {}
Economy.IsFestival = function() return false end
Economy.AttachStealDetector = function(_, _, _) end
Economy.OnStateChanged = function(_) end
Economy.OnConveyorChanged = function() end

-- Wires the callbacks init.server provides: whether Festival is active
-- (income x2), what to do with a freshly placed model (steal detector),
-- and who to tell when a state or the conveyor changed.
function Economy.Init(hooks)
	if hooks.IsFestival ~= nil then
		Economy.IsFestival = hooks.IsFestival
	end
	if hooks.AttachStealDetector ~= nil then
		Economy.AttachStealDetector = hooks.AttachStealDetector
	end
	if hooks.OnStateChanged ~= nil then
		Economy.OnStateChanged = hooks.OnStateChanged
	end
	if hooks.OnConveyorChanged ~= nil then
		Economy.OnConveyorChanged = hooks.OnConveyorChanged
	end
end

-- A fresh player's state: $100, no rebirths, an empty base, hands empty.
function Economy.NewState()
	return {
		Cash = Config.StartCash,
		RebirthLevel = 0,
		Placed = {},
		Carrying = nil,
		CarryingMutation = "",
		CarryingIsStolen = false,
		CarryingFrom = nil,
		LockUntil = 0,
		LockCooldownUntil = 0,
		BaseName = nil,
	}
end

-- The state for a player, or nil when they have none.
function Economy.GetState(player)
	return Economy.States[player]
end

-- Income per second across everything a player has placed, after their
-- rebirth bonus and the Festival x2.
function Economy.GetIncomePerSec(state)
	local total = 0
	for _, placed in ipairs(state.Placed) do
		local def = BrainrotData.FindCharacter(placed.CharacterName)
		if def ~= nil then
			total = total + BrainrotData.IncomeFor(def, placed.Mutation, state.RebirthLevel)
		end
	end
	if Economy.IsFestival() then
		total = total * 2
	end
	return total
end

-- One income tick for every player. Called once a second from init.server.
function Economy.TickIncome()
	for player, state in pairs(Economy.States) do
		local income = Economy.GetIncomePerSec(state)
		if income > 0 then
			state.Cash = state.Cash + income
			Economy.OnStateChanged(player)
		end
	end
end

-- Finds the placed models folder in the Workspace, creating it once.
function Economy.PlacedFolder()
	local folder = workspace:FindFirstChild("PlacedModels")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "PlacedModels"
		folder.Parent = workspace
	end
	return folder
end

-- Buys the brainrot in a conveyor slot. It leaves the conveyor and is
-- carried by the player (slower walk speed) until they place it on a base
-- slot. Returns true on success, false with a reason otherwise.
function Economy.BuyBrainrot(player, conveyor, conveyorIndex)
	local state = Economy.States[player]
	if state == nil then
		return false, "No player state"
	end
	if state.BaseName == nil then
		return false, "No base assigned yet"
	end
	if state.Carrying ~= nil then
		return false, "Already carrying a brainrot"
	end
	local slot = Conveyor.GetSlot(conveyor, conveyorIndex)
	if slot == nil then
		return false, "That conveyor slot is empty"
	end
	if state.Cash < slot.Cost then
		return false, "Not enough cash"
	end
	local def = BrainrotData.FindCharacter(slot.CharacterName)
	if def == nil then
		return false, "Unknown character"
	end
	Conveyor.TakeSlot(conveyor, conveyorIndex)
	state.Cash = state.Cash - slot.Cost
	state.Carrying = slot.CharacterName
	state.CarryingMutation = slot.Mutation
	state.CarryingIsStolen = false
	state.CarryingFrom = nil
	Economy.AttachCarriedModel(player, def, slot.Mutation)
	Economy.OnStateChanged(player)
	Economy.OnConveyorChanged()
	return true, ""
end

-- Builds the carried model and welds it above the player's head.
function Economy.AttachCarriedModel(player, def, mutationName)
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root == nil or humanoid == nil then
		return
	end
	local income = BrainrotData.IncomeFor(def, mutationName, 0)
	local model = CharacterModels.BuildModel(def, mutationName, income)
	model.Name = "Carried_" .. def.Name
	local body = model.PrimaryPart
	body.Anchored = false
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = CFrame.new(0, 3.2, 0)
	weld.Parent = body
	model.Parent = character
	humanoid.WalkSpeed = 16 * Config.CarrySpeedMultiplier
end

-- Removes whatever model the player is carrying and restores walk speed.
-- Returns the carried character's name and mutation, or nil.
function Economy.DetachCarriedModel(player)
	local state = Economy.States[player]
	local character = player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.WalkSpeed = 16
		end
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Model") and string.sub(child.Name, 1, 8) == "Carried_" then
				child:Destroy()
			end
		end
	end
	if state == nil then
		return nil, ""
	end
	local name = state.Carrying
	local mutation = state.CarryingMutation
	state.Carrying = nil
	state.CarryingMutation = ""
	state.CarryingIsStolen = false
	state.CarryingFrom = nil
	return name, mutation
end

-- Places the carried brainrot on one of the player's own base slots.
-- The player must be near the pad (within 30 studs). Returns true on
-- success, false with a reason otherwise.
function Economy.PlaceBrainrot(player, slotIndex)
	local state = Economy.States[player]
	if state == nil then
		return false, "No player state"
	end
	if state.Carrying == nil then
		return false, "Not carrying anything"
	end
	if slotIndex < 1 or slotIndex > Config.BaseSlots then
		return false, "Bad slot"
	end
	for _, placed in ipairs(state.Placed) do
		if placed.Slot == slotIndex then
			return false, "That slot is already taken"
		end
	end
	local padCFrame = Base.GetPadCFrame(state.BaseName, slotIndex)
	if padCFrame == nil then
		return false, "No pad for that slot"
	end
	local character = player.Character
	if character ~= nil then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root ~= nil then
			local distance = (root.Position - padCFrame.Position).Magnitude
			if distance > 30 then
				return false, "Too far from that pad"
			end
		end
	end
	local def = BrainrotData.FindCharacter(state.Carrying)
	if def == nil then
		return false, "Unknown character"
	end
	local name = state.Carrying
	local mutation = state.CarryingMutation
	local stolen = state.CarryingIsStolen
	Economy.DetachCarriedModel(player)
	local income = BrainrotData.IncomeFor(def, mutation, state.RebirthLevel)
	local model = CharacterModels.BuildModel(def, mutation, income)
	model.Name = "Placed_" .. def.Name
	local body = model.PrimaryPart
	body.Anchored = true
	model:SetPrimaryPartCFrame(padCFrame * CFrame.new(0, 0.5 + 1.5 * def.Scale, 0))
	model.Parent = Economy.PlacedFolder()
	local placed = {
		CharacterName = name,
		Mutation = mutation,
		Slot = slotIndex,
		Model = model,
		Stolen = stolen,
	}
	table.insert(state.Placed, placed)
	Economy.AttachStealDetector(model, player, slotIndex)
	Economy.OnStateChanged(player)
	return true, ""
end

-- Sells a placed brainrot for a 50% refund of its cost.
function Economy.SellBrainrot(player, slotIndex)
	local state = Economy.States[player]
	if state == nil then
		return false, "No player state"
	end
	for index, placed in ipairs(state.Placed) do
		if placed.Slot == slotIndex then
			local def = BrainrotData.FindCharacter(placed.CharacterName)
			if def ~= nil then
				state.Cash = state.Cash + math.floor(def.Cost * Config.SellRefund)
			end
			if placed.Model ~= nil then
				placed.Model:Destroy()
			end
			table.remove(state.Placed, index)
			Economy.OnStateChanged(player)
			return true, ""
		end
	end
	return false, "Nothing in that slot"
end

-- The cash a rebirth costs at the player's next level.
function Economy.RebirthCost(state)
	local nextLevel = state.RebirthLevel + 1
	return Config.RebirthBaseCost * nextLevel * nextLevel
end

-- Whether a player can rebirth right now: a full base of 8 plus the cash.
function Economy.CanRebirth(state)
	return #state.Placed >= Config.BaseSlots and state.Cash >= Economy.RebirthCost(state)
end

-- Rebirths: clears the base and the cash, keeps a permanent +50% income
-- per level. Returns true on success, false with a reason otherwise.
function Economy.Rebirth(player)
	local state = Economy.States[player]
	if state == nil then
		return false, "No player state"
	end
	if #state.Placed < Config.BaseSlots then
		return false, "Fill all 8 base slots first"
	end
	local cost = Economy.RebirthCost(state)
	if state.Cash < cost then
		return false, "Not enough cash to rebirth"
	end
	for _, placed in ipairs(state.Placed) do
		if placed.Model ~= nil then
			placed.Model:Destroy()
		end
	end
	state.Placed = {}
	state.Cash = Config.StartCash
	state.RebirthLevel = state.RebirthLevel + 1
	Economy.OnStateChanged(player)
	return true, ""
end

-- A plain snapshot of a player's state for the client HUD.
function Economy.Snapshot(player)
	local state = Economy.States[player]
	if state == nil then
		return nil
	end
	local placed = {}
	for _, item in ipairs(state.Placed) do
		local def = BrainrotData.FindCharacter(item.CharacterName)
		local income = 0
		if def ~= nil then
			income = BrainrotData.IncomeFor(def, item.Mutation, state.RebirthLevel)
			if Economy.IsFestival() then
				income = income * 2
			end
		end
		table.insert(placed, {
			CharacterName = item.CharacterName,
			Mutation = item.Mutation,
			Slot = item.Slot,
			IncomePerSec = income,
		})
	end
	return {
		Cash = state.Cash,
		IncomePerSec = Economy.GetIncomePerSec(state),
		RebirthLevel = state.RebirthLevel,
		RebirthCost = Economy.RebirthCost(state),
		CanRebirth = Economy.CanRebirth(state),
		Carrying = state.Carrying,
		CarryingMutation = state.CarryingMutation,
		LockUntil = state.LockUntil,
		LockCooldownUntil = state.LockCooldownUntil,
		BaseName = state.BaseName,
		Placed = placed,
	}
end

return Economy
