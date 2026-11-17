-- Conveyor: the market's moving shelf of brainrots for sale.
-- Five slots on the north edge; a new brainrot arrives every few seconds
-- into the first empty slot. Rolls are weighted: rarity first, then a
-- character inside that rarity, then an independent mutation roll.
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Conveyor = {}
Conveyor.RushActive = false
Conveyor.FestivalActive = false

-- Creates a fresh conveyor with all five slots filled.
function Conveyor.New()
	local conveyor = { Slots = {} }
	for _ = 1, Config.ConveyorSlots do
		table.insert(conveyor.Slots, Conveyor.RollCharacter())
	end
	return conveyor
end

-- Rolls one rarity from the catalogue chances (they sum to 1.0).
function Conveyor.RollRarity()
	local roll = math.random()
	local running = 0
	for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
		running = running + BrainrotData.RARITIES[rarity].Chance
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

-- Rolls one mutation. Rarest first, so a Diamond roll is never shadowed by
-- a Golden one. During Festival the Golden chance doubles (4% -> 8%).
function Conveyor.RollMutation()
	local roll = math.random()
	if roll <= BrainrotData.MUTATIONS.Diamond.Chance then
		return "Diamond"
	end
	if roll <= BrainrotData.MUTATIONS.Rainbow.Chance then
		return "Rainbow"
	end
	local goldenChance = BrainrotData.MUTATIONS.Golden.Chance
	if Conveyor.FestivalActive then
		goldenChance = goldenChance * 2
	end
	if roll <= goldenChance then
		return "Golden"
	end
	return ""
end

-- Rolls one full character offer: rarity, then a weighted character inside
-- that rarity, then a mutation.
function Conveyor.RollCharacter()
	local rarity = Conveyor.RollRarity()
	local pool = {}
	local totalWeight = 0
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.Rarity == rarity then
			table.insert(pool, def)
			totalWeight = totalWeight + def.Weight
		end
	end
	local pick = math.random() * totalWeight
	local chosen = pool[1]
	for _, def in ipairs(pool) do
		pick = pick - def.Weight
		if pick <= 0 then
			chosen = def
			break
		end
	end
	return {
		CharacterName = chosen.Name,
		Rarity = chosen.Rarity,
		Mutation = Conveyor.RollMutation(),
		Cost = chosen.Cost,
	}
end

-- Fills the first empty slot with a fresh roll. Returns true when a slot
-- was filled, false when the conveyor is already full.
function Conveyor.SpawnNext(conveyor)
	for index, slot in ipairs(conveyor.Slots) do
		if slot == nil then
			conveyor.Slots[index] = Conveyor.RollCharacter()
			return true
		end
	end
	return false
end

-- The offer in a slot, or nil when the slot is empty.
function Conveyor.GetSlot(conveyor, index)
	return conveyor.Slots[index]
end

-- Clears a slot (a player just bought what was in it).
function Conveyor.TakeSlot(conveyor, index)
	local slot = conveyor.Slots[index]
	conveyor.Slots[index] = nil
	return slot
end

-- A plain snapshot of the slots for the client shop UI.
function Conveyor.Snapshot(conveyor)
	local snapshot = {}
	for index, slot in ipairs(conveyor.Slots) do
		if slot ~= nil then
			snapshot[index] = {
				CharacterName = slot.CharacterName,
				Rarity = slot.Rarity,
				Mutation = slot.Mutation,
				Cost = slot.Cost,
			}
		end
	end
	return snapshot
end

return Conveyor
