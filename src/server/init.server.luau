-- init.server: server entrypoint for Brainrot Night Market.
-- Validates the catalogue, creates the remotes the client talks to, and
-- prints a readiness line so Studio's output log shows the game booted.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

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

local remoteNames = { "BuyBrainrot", "SellBrainrot", "LockBase", "Rebirth", "StealAttempt", "EventPing" }
for _, name in ipairs(remoteNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

print("[Brainrot Night Market] server ready: " .. tostring(#BrainrotData.CHARACTERS) .. " characters, " .. tostring(#BrainrotData.RARITY_ORDER) .. " rarities")
