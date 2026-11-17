-- Base: the four player bases on the plaza, one per quadrant.
-- Each base is a 40x28 platform with 8 pads (2 rows x 4). Bases are handed
-- out in join order and freed when their owner leaves, so a later player
-- can take a base that opened up again.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Base = {}

-- Base names, centres and the Workspace pad part each slot maps to.
Base.BASES = {
	NW = { Center = Vector3.new(-30, 0, 12), PadPrefix = "PadNW" },
	NE = { Center = Vector3.new(30, 0, 12), PadPrefix = "PadNE" },
	SW = { Center = Vector3.new(-30, 0, -12), PadPrefix = "PadSW" },
	SE = { Center = Vector3.new(30, 0, -12), PadPrefix = "PadSE" },
}
Base.ORDER = { "NW", "NE", "SW", "SE" }

-- Owner map: base name -> player (or nil). Built by init.server.
Base.Owners = {}

-- Gives a joining player the first free base. Returns the base name, or
-- nil when all four bases are taken.
function Base.Assign(player)
	for _, name in ipairs(Base.ORDER) do
		if Base.Owners[name] == nil then
			Base.Owners[name] = player
			return name
		end
	end
	return nil
end

-- Frees a player's base when they leave, so the next joiner can take it.
function Base.Release(player)
	for _, name in ipairs(Base.ORDER) do
		if Base.Owners[name] == player then
			Base.Owners[name] = nil
			return name
		end
	end
	return nil
end

-- The base a player owns, or nil.
function Base.GetBaseOf(player)
	for _, name in ipairs(Base.ORDER) do
		if Base.Owners[name] == player then
			return name
		end
	end
	return nil
end

-- The player who owns a base, or nil.
function Base.GetOwner(baseName)
	return Base.Owners[baseName]
end

-- The CFrame of a pad part in the Workspace, so a placed model can sit on
-- it. Pad parts are named PadNW1..PadNW8 and so on in default.project.json.
function Base.GetPadCFrame(baseName, slotIndex)
	local info = Base.BASES[baseName]
	if info == nil then
		return nil
	end
	local part = workspace:FindFirstChild(info.PadPrefix .. tostring(slotIndex))
	if part == nil then
		return nil
	end
	return part.CFrame
end

-- Whether a base is locked right now (its owner's lock has not run out).
function Base.IsLocked(state)
	return state.LockUntil > os.time()
end

-- Buys a lock for a base: $1,500, holds 20 s, then a 30 s cooldown before
-- the next lock. Returns true on success, false with a reason otherwise.
function Base.BuyLock(state)
	local now = os.time()
	if state.LockUntil > now then
		return false, "Base is already locked"
	end
	if state.LockCooldownUntil > now then
		return false, "Lock is cooling down"
	end
	if state.Cash < Config.LockCost then
		return false, "Not enough cash for a lock"
	end
	state.Cash = state.Cash - Config.LockCost
	state.LockUntil = now + Config.LockDuration
	state.LockCooldownUntil = state.LockUntil + Config.LockCooldown
	return true, ""
end

return Base
