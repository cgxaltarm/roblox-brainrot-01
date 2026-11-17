-- ConveyorDisplay: the 3D brainrots standing on the conveyor.
-- The shop UI sells what is on the conveyor, but a market where nothing
-- is visible is an empty market. This module mirrors the five conveyor
-- offers into real 3D models on the five slot parts (Slot1..Slot5 in the
-- Workspace), so a player sees five brainrots with name/rarity/$-per-sec
-- billboards the moment they join. Each model idles: it drifts a couple
-- of studs along the belt and bobs, so the conveyor looks alive.
-- Bought slots lose their model at once; refilled slots grow a new one.
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local ServerScriptService = game:GetService("ServerScriptService")
local CharacterModels = require(ServerScriptService.Server.CharacterModels)

local ConveyorDisplay = {}
ConveyorDisplay.Models = {}
ConveyorDisplay.BaseCFrames = {}

-- Builds the model for one conveyor slot and starts its idle motion.
function ConveyorDisplay.BuildSlotModel(index, slot)
	local def = BrainrotData.FindCharacter(slot.CharacterName)
	if def == nil then
		return nil
	end
	local income = BrainrotData.IncomeFor(def, slot.Mutation, 0)
	local model = CharacterModels.BuildModel(def, slot.Mutation, income)
	model.Name = "Conveyor_" .. def.Name
	local slotPart = workspace:FindFirstChild("Slot" .. tostring(index))
	if slotPart == nil then
		model:Destroy()
		return nil
	end
	local base = slotPart.CFrame * CFrame.new(0, 0.5 + 1.5 * def.Scale, 0)
	model:SetPrimaryPartCFrame(base)
	model.Parent = workspace
	ConveyorDisplay.BaseCFrames[index] = base
	-- Idle motion: drift along the belt and bob, so the conveyor reads as
	-- moving even before the next offer arrives.
	task.spawn(function()
		local t = math.random() * 6
		while model.Parent ~= nil do
			t = t + 0.05
			model:SetPrimaryPartCFrame(base * CFrame.new(math.sin(t) * 1.5, math.abs(math.sin(t * 2)) * 0.4, 0))
			task.wait(0.05)
		end
	end)
	return model
end

-- Reconciles the displayed models with the conveyor's current offers:
-- removes models for emptied slots, rebuilds models whose offer changed.
-- Cheap to call on every conveyor change and safe to call at startup,
-- when the conveyor is already full and the market must look full.
function ConveyorDisplay.Update(conveyor)
	for index = 1, Config.ConveyorSlots do
		local slot = conveyor.Slots[index]
		local existing = ConveyorDisplay.Models[index]
		if slot == nil then
			if existing ~= nil then
				existing:Destroy()
				ConveyorDisplay.Models[index] = nil
			end
		else
			local same = false
			if existing ~= nil then
				same = existing:GetAttribute("CharacterName") == slot.CharacterName
					and existing:GetAttribute("Mutation") == slot.Mutation
			end
			if not same then
				if existing ~= nil then
					existing:Destroy()
				end
				ConveyorDisplay.Models[index] = ConveyorDisplay.BuildSlotModel(index, slot)
			end
		end
	end
end

return ConveyorDisplay
