-- CharacterModels: builds the 3D model for one brainrot character.
-- Every character is a rounded body in its own colour, a head, two eyes,
-- and a billboard showing its name, rarity colour, mutation marker and $/s.
-- No asset is copied from any other game: all of it is Parts built here.
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local CharacterModels = {}

-- Builds a model standing on the ground at the origin: the body centre sits
-- at y = 0, so the caller places it with SetPrimaryPartCFrame and adds the
-- pad height itself. Returns the Model, PrimaryPart set to the body.
function CharacterModels.BuildModel(def, mutationName, incomePerSec)
	local scale = def.Scale
	local bodyRadius = 1.5 * scale

	local model = Instance.new("Model")
	model.Name = def.Name
	model:SetAttribute("CharacterName", def.Name)
	model:SetAttribute("Mutation", mutationName or "")
	model:SetAttribute("IncomePerSec", incomePerSec)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(bodyRadius * 2, bodyRadius * 2, bodyRadius * 2)
	body.Color = def.Color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	local headRadius = 0.8 * scale
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(headRadius * 2, headRadius * 2, headRadius * 2)
	head.Color = def.Color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = false
	head.CFrame = body.CFrame * CFrame.new(0, bodyRadius + headRadius - 0.2 * scale, 0)
	head.Parent = model

	local eyeRadius = 0.25 * scale
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(eyeRadius * 2, eyeRadius * 2, eyeRadius * 2)
		eye.Color = Color3.fromRGB(20, 20, 20)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = false
		eye.CanCollide = false
		eye.CFrame = body.CFrame * CFrame.new(side * 0.5 * scale, 0.35 * scale, bodyRadius * 0.75)
		eye.Parent = model
		local weld = Instance.new("Weld")
		weld.Part0 = body
		weld.Part1 = eye
		weld.C0 = body.CFrame:Inverse() * eye.CFrame
		weld.Parent = eye
	end

	local headWeld = Instance.new("Weld")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.C0 = body.CFrame:Inverse() * head.CFrame
	headWeld.Parent = head

	-- Billboard: name + rarity colour on top, $/s under it.
	local rarity = BrainrotData.RARITIES[def.Rarity]
	local marker = ""
	if mutationName ~= nil and mutationName ~= "" then
		marker = " " .. BrainrotData.MUTATIONS[mutationName].Marker
	end
	local board = Instance.new("BillboardGui")
	board.Name = "Label"
	board.Size = UDim2.new(0, 150, 0, 64)
	board.StudsOffset = Vector3.new(0, bodyRadius + headRadius * 2 + 0.6, 0)
	board.AlwaysOnTop = true
	board.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name .. marker
	nameLabel.TextColor3 = rarity.Color
	nameLabel.TextSize = 20
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = board

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Position = UDim2.new(0, 0, 0.5, 0)
	incomeLabel.Size = UDim2.new(1, 0, 0.5, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$" .. tostring(incomePerSec) .. "/s  ·  " .. def.Rarity
	incomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	incomeLabel.TextSize = 18
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.Parent = board

	return model
end

-- Recolours a built model's billboard marker when a mutation is applied
-- after the fact. BuildModel already applies it at build time; this is for
-- the Festival path, which never changes an existing character's mutation.
function CharacterModels.ApplyMutation(model, mutationName)
	if mutationName == nil or mutationName == "" then
		return
	end
	local mutation = BrainrotData.MUTATIONS[mutationName]
	if mutation == nil then
		return
	end
	local body = model.PrimaryPart
	if body == nil then
		return
	end
	local board = body:FindFirstChild("Label")
	if board == nil then
		return
	end
	local nameLabel = board:FindFirstChild("NameLabel")
	if nameLabel ~= nil then
		nameLabel.Text = model.Name .. " " .. mutation.Marker
		nameLabel.TextColor3 = mutation.Color
	end
end

return CharacterModels
