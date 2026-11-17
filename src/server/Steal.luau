-- Steal: stealing between players, and the roaming thief NPC.
-- Any player may grab a brainrot from another player's UNLOCKED base by
-- clicking it. The thief then carries it home (8 s, slower walk speed) and
-- anyone can tag them by touch to make them drop it. A locked base cannot
-- be stolen from. During Rush Hour a thief NPC raids a random unlocked base
-- the same way, so the threat is real even with one player in the game.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local ServerScriptService = game:GetService("ServerScriptService")
local Base = require(ServerScriptService.Server.Base)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)

local Steal = {}
Steal.Economy = nil

-- Wires the Economy module in (injected by init.server, so this module
-- never requires Economy back and no require cycle forms).
function Steal.Init(economy)
	Steal.Economy = economy
end

-- Puts a ClickDetector on a placed model: clicking it as a non-owner tries
-- a steal, clicking it as the owner does nothing (owners use the HUD).
function Steal.AttachDetector(model, owner, slotIndex)
	local body = model.PrimaryPart
	if body == nil then
		return
	end
	local detector = Instance.new("ClickDetector")
	detector.Name = "StealDetector"
	detector.MaxActivationDistance = 24
	detector.Parent = body
	detector.MouseClick:Connect(function(clicker)
		if clicker ~= owner then
			Steal.TrySteal(clicker, owner, slotIndex)
		end
	end)
end

-- Tries to steal one placed brainrot from a victim's base.
-- Returns true when the thief is now carrying it.
function Steal.TrySteal(thief, victim, slotIndex)
	local economy = Steal.Economy
	if economy == nil then
		return false
	end
	local thiefState = economy.States[thief]
	local victimState = economy.States[victim]
	if thiefState == nil or victimState == nil then
		return false
	end
	if thiefState.Carrying ~= nil then
		return false
	end
	if Base.IsLocked(victimState) then
		return false
	end
	local placedIndex = nil
	local placed = nil
	for index, item in ipairs(victimState.Placed) do
		if item.Slot == slotIndex then
			placedIndex = index
			placed = item
			break
		end
	end
	if placed == nil then
		return false
	end
	-- The thief must be standing near the victim's pad.
	local thiefCharacter = thief.Character
	if thiefCharacter == nil then
		return false
	end
	local root = thiefCharacter:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	local padCFrame = Base.GetPadCFrame(victimState.BaseName, slotIndex)
	if padCFrame == nil then
		return false
	end
	if (root.Position - padCFrame.Position).Magnitude > 24 then
		return false
	end
	local def = BrainrotData.FindCharacter(placed.CharacterName)
	if def == nil then
		return false
	end
	if placed.Model ~= nil then
		placed.Model:Destroy()
	end
	table.remove(victimState.Placed, placedIndex)
	thiefState.Carrying = placed.CharacterName
	thiefState.CarryingMutation = placed.Mutation
	thiefState.CarryingIsStolen = true
	thiefState.CarryingFrom = victim
	economy.AttachCarriedModel(thief, def, placed.Mutation)
	economy.OnStateChanged(thief)
	economy.OnStateChanged(victim)
	return true
end

-- Drops what a carrier is holding where they stand. The owner can pick it
-- back up by walking over it and clicking it... in this game the dropped
-- brainrot returns to its owner's first free base slot after 5 seconds if
-- nobody claims it, so a drop is a setback, not a loss.
function Steal.DropCarried(player)
	local economy = Steal.Economy
	if economy == nil then
		return
	end
	local state = economy.States[player]
	if state == nil or state.Carrying == nil then
		return
	end
	local name = state.Carrying
	local mutation = state.CarryingMutation
	local from = state.CarryingFrom
	economy.DetachCarriedModel(player)
	if from ~= nil then
		local ownerState = economy.States[from]
		if ownerState ~= nil then
			task.delay(5, function()
				if ownerState == nil then
					return
				end
				for slot = 1, Config.BaseSlots do
					local taken = false
					for _, placed in ipairs(ownerState.Placed) do
						if placed.Slot == slot then
							taken = true
							break
						end
					end
					if not taken then
						local def = BrainrotData.FindCharacter(name)
						if def ~= nil then
							local padCFrame = Base.GetPadCFrame(ownerState.BaseName, slot)
							if padCFrame ~= nil then
								local income = BrainrotData.IncomeFor(def, mutation, ownerState.RebirthLevel)
								local model = CharacterModels.BuildModel(def, mutation, income)
								model.Name = "Placed_" .. def.Name
								model.PrimaryPart.Anchored = true
								model:SetPrimaryPartCFrame(padCFrame * CFrame.new(0, 0.5 + 1.5 * def.Scale, 0))
								model.Parent = economy.PlacedFolder()
								table.insert(ownerState.Placed, {
									CharacterName = name,
									Mutation = mutation,
									Slot = slot,
									Model = model,
									Stolen = false,
								})
								Steal.AttachDetector(model, from, slot)
								economy.OnStateChanged(from)
							end
						end
						break
					end
				end
			end)
		end
	end
	economy.OnStateChanged(player)
end

-- Spawns the Rush Hour thief NPC: a dark figure that walks to a random
-- unlocked base, grabs its most valuable brainrot, and runs for the north
-- gate. Tag him by touch to make him drop it.
function Steal.SpawnThief()
	local economy = Steal.Economy
	if economy == nil then
		return nil
	end
	-- Pick the richest unlocked base that has something to steal.
	local bestVictim = nil
	local bestValue = 0
	local bestSlot = 0
	local bestName = ""
	local bestMutation = ""
	for player, state in pairs(economy.States) do
		if state.BaseName ~= nil and not Base.IsLocked(state) then
			for _, placed in ipairs(state.Placed) do
				local def = BrainrotData.FindCharacter(placed.CharacterName)
				if def ~= nil and def.Cost > bestValue then
					bestVictim = player
					bestValue = def.Cost
					bestSlot = placed.Slot
					bestName = placed.CharacterName
					bestMutation = placed.Mutation
				end
			end
		end
	end
	if bestVictim == nil then
		return nil
	end
	local victimState = economy.States[bestVictim]
	-- Take it off the victim's base right away.
	for index, placed in ipairs(victimState.Placed) do
		if placed.Slot == bestSlot then
			if placed.Model ~= nil then
				placed.Model:Destroy()
			end
			table.remove(victimState.Placed, index)
			break
		end
	end
	economy.OnStateChanged(bestVictim)

	local def = BrainrotData.FindCharacter(bestName)
	local model = Instance.new("Model")
	model.Name = "Pencuri Keliling"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Color = Color3.fromRGB(30, 30, 35)
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = CFrame.new(0, 3, -38)
	root.Parent = model
	model.PrimaryPart = root
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(40, 40, 50)
	torso.CFrame = CFrame.new(0, 3, -38)
	torso.Parent = model
	local torsoWeld = Instance.new("Weld")
	torsoWeld.Part0 = root
	torsoWeld.Part1 = torso
	torsoWeld.Parent = torso
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Color = Color3.fromRGB(30, 30, 35)
	head.CFrame = CFrame.new(0, 5, -38)
	head.Parent = model
	local headWeld = Instance.new("Weld")
	headWeld.Part0 = root
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(0, 2, 0)
	headWeld.Parent = head
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 14
	humanoid.Parent = model
	model.Parent = workspace

	-- The stolen brainrot rides above his head, marked STOLEN.
	local income = BrainrotData.IncomeFor(def, bestMutation, 0)
	local loot = CharacterModels.BuildModel(def, bestMutation, income)
	loot.Name = "Stolen_" .. def.Name
	local lootBody = loot.PrimaryPart
	lootBody.Anchored = false
	for _, part in ipairs(loot:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	local lootWeld = Instance.new("Weld")
	lootWeld.Part0 = root
	lootWeld.Part1 = lootBody
	lootWeld.C0 = CFrame.new(0, 3.4, 0)
	lootWeld.Parent = lootBody
	loot.Parent = model

	local tagged = false
	local function dropLoot()
		if tagged then
			return
		end
		tagged = true
		loot:Destroy()
		-- The loot returns to its owner's first free slot after 5 seconds.
		local ownerState = economy.States[bestVictim]
		if ownerState ~= nil then
			task.delay(5, function()
				for slot = 1, Config.BaseSlots do
					local taken = false
					for _, placed in ipairs(ownerState.Placed) do
						if placed.Slot == slot then
							taken = true
							break
						end
					end
					if not taken then
						local padCFrame = Base.GetPadCFrame(ownerState.BaseName, slot)
						if padCFrame ~= nil then
							local backIncome = BrainrotData.IncomeFor(def, bestMutation, ownerState.RebirthLevel)
							local back = CharacterModels.BuildModel(def, bestMutation, backIncome)
							back.Name = "Placed_" .. def.Name
							back.PrimaryPart.Anchored = true
							back:SetPrimaryPartCFrame(padCFrame * CFrame.new(0, 0.5 + 1.5 * def.Scale, 0))
							back.Parent = economy.PlacedFolder()
							table.insert(ownerState.Placed, {
								CharacterName = bestName,
								Mutation = bestMutation,
								Slot = slot,
								Model = back,
								Stolen = false,
							})
							Steal.AttachDetector(back, bestVictim, slot)
							economy.OnStateChanged(bestVictim)
						end
						break
					end
				end
			end)
		end
	end
	root.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if player ~= nil then
			dropLoot()
			humanoid.Health = 0
		end
	end)

	task.spawn(function()
		local padCFrame = Base.GetPadCFrame(victimState.BaseName, bestSlot)
		if padCFrame ~= nil then
			humanoid:MoveTo(padCFrame.Position)
			humanoid.MoveToFinished:Wait()
		end
		if tagged then
			return
		end
		-- Run for the north gate with the loot.
		humanoid:MoveTo(Vector3.new(0, 1, -44))
		humanoid.MoveToFinished:Wait()
		if not tagged then
			-- He escaped: the brainrot is gone for good.
			loot:Destroy()
		end
		model:Destroy()
	end)
	return model
end

return Steal
