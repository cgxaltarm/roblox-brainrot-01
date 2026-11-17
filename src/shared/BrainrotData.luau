-- BrainrotData: the catalogue of every character in Brainrot Night Market.
-- Original IP throughout: absurd Indonesian food mascots, invented here.
-- No names, characters or assets are copied from any other game.
local BrainrotData = {}

-- Rarity ladder. Chance is the conveyor roll weight (must sum to 1.0).
-- Multiplier is a reference for how income scales; each character's own
-- IncomePerSec below is the number the game actually pays.
BrainrotData.RARITIES = {
	Common = { Chance = 0.55, Multiplier = 1, Color = Color3.fromRGB(200, 200, 200) },
	Rare = { Chance = 0.25, Multiplier = 3, Color = Color3.fromRGB(80, 180, 255) },
	Epic = { Chance = 0.12, Multiplier = 8, Color = Color3.fromRGB(180, 90, 255) },
	Legendary = { Chance = 0.06, Multiplier = 20, Color = Color3.fromRGB(255, 180, 40) },
	Mythic = { Chance = 0.018, Multiplier = 50, Color = Color3.fromRGB(255, 70, 90) },
	Secret = { Chance = 0.002, Multiplier = 150, Color = Color3.fromRGB(40, 230, 200) },
}

-- Rarity roll order, from most to least common.
BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- Mutations roll on spawn, independent of rarity. A mutated brainrot earns
-- its income times the multiplier and shows its marker on its billboard.
BrainrotData.MUTATIONS = {
	Golden = { Chance = 0.04, Multiplier = 2, Marker = "★", Color = Color3.fromRGB(255, 215, 0) },
	Rainbow = { Chance = 0.008, Multiplier = 5, Marker = "◆", Color = Color3.fromRGB(255, 110, 220) },
	Diamond = { Chance = 0.0015, Multiplier = 10, Marker = "✦", Color = Color3.fromRGB(140, 230, 255) },
}
BrainrotData.MUTATION_ORDER = { "Golden", "Rainbow", "Diamond" }

-- The cast: 12 characters. Weight is the pick weight inside its rarity.
-- Scale grows with rarity so the rarest characters read as big on the plaza.
BrainrotData.CHARACTERS = {
	{ Name = "Tahu Gejrot", Rarity = "Common", Cost = 50, IncomePerSec = 1, Weight = 30, Scale = 1.0, Color = Color3.fromRGB(245, 220, 150) },
	{ Name = "Es Teh Manis", Rarity = "Common", Cost = 120, IncomePerSec = 2, Weight = 25, Scale = 1.0, Color = Color3.fromRGB(210, 140, 60) },
	{ Name = "Bakso Beranak", Rarity = "Common", Cost = 250, IncomePerSec = 4, Weight = 20, Scale = 1.1, Color = Color3.fromRGB(190, 130, 90) },
	{ Name = "Krupuk Terbang", Rarity = "Rare", Cost = 600, IncomePerSec = 12, Weight = 18, Scale = 1.1, Color = Color3.fromRGB(250, 230, 180) },
	{ Name = "Sate Klopo", Rarity = "Rare", Cost = 1000, IncomePerSec = 22, Weight = 14, Scale = 1.2, Color = Color3.fromRGB(160, 90, 40) },
	{ Name = "Nasi Goreng Gila", Rarity = "Epic", Cost = 2200, IncomePerSec = 60, Weight = 12, Scale = 1.3, Color = Color3.fromRGB(230, 150, 50) },
	{ Name = "Martabak Manis", Rarity = "Epic", Cost = 4000, IncomePerSec = 105, Weight = 9, Scale = 1.3, Color = Color3.fromRGB(120, 70, 30) },
	{ Name = "Durian Runtuh", Rarity = "Legendary", Cost = 9000, IncomePerSec = 260, Weight = 7, Scale = 1.5, Color = Color3.fromRGB(200, 210, 90) },
	{ Name = "Rendang Abadi", Rarity = "Legendary", Cost = 16000, IncomePerSec = 460, Weight = 5, Scale = 1.5, Color = Color3.fromRGB(110, 50, 25) },
	{ Name = "Kopi Tubruk Titan", Rarity = "Mythic", Cost = 45000, IncomePerSec = 1250, Weight = 4, Scale = 1.7, Color = Color3.fromRGB(60, 35, 20) },
	{ Name = "Sambal Petir", Rarity = "Mythic", Cost = 80000, IncomePerSec = 2300, Weight = 3, Scale = 1.8, Color = Color3.fromRGB(220, 40, 30) },
	{ Name = "Nasi Padang Semesta", Rarity = "Secret", Cost = 220000, IncomePerSec = 8500, Weight = 1, Scale = 2.0, Color = Color3.fromRGB(40, 200, 170) },
}

-- Find a character definition by name. Returns nil when there is none.
function BrainrotData.FindCharacter(name)
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.Name == name then
			return def
		end
	end
	return nil
end

-- IncomePerSec for a placed brainrot, after its mutation and the owner's
-- rebirth bonus. Festival doubles it again at the call site.
function BrainrotData.IncomeFor(def, mutationName, rebirthLevel)
	local income = def.IncomePerSec
	if mutationName ~= nil and mutationName ~= "" then
		local mutation = BrainrotData.MUTATIONS[mutationName]
		if mutation ~= nil then
			income = income * mutation.Multiplier
		end
	end
	income = income * (1 + 0.5 * rebirthLevel)
	return income
end

return BrainrotData
