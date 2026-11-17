-- Config: every tuning number for Brainrot Night Market lives here.
-- One place to tune, so the economy can be rebalanced without touching systems.
local Config = {}

-- Starting money for a fresh player.
Config.StartCash = 100
-- How many brainrots one base can hold.
Config.BaseSlots = 8
-- Selling a brainrot refunds this share of its cost.
Config.SellRefund = 0.5

-- Conveyor: how many brainrots are on show, and how often a new one arrives.
Config.ConveyorSlots = 5
Config.ConveyorInterval = 6
-- Rush Hour runs the conveyor twice as fast.
Config.RushConveyorInterval = 3

-- Steal: seconds a thief needs to carry a brainrot home, and the speed
-- penalty while carrying it.
Config.StealCarryTime = 8
Config.CarrySpeedMultiplier = 0.8

-- Base lock: price, how long it holds, and the cooldown after it ends.
Config.LockCost = 1500
Config.LockDuration = 20
Config.LockCooldown = 30

-- Events: one fires every EventInterval seconds, alternating Rush Hour and
-- Festival, each lasting EventDuration seconds.
Config.EventInterval = 240
Config.EventDuration = 45

-- Rebirth: requires a full base plus this much cash, scaling with level.
-- TUNED constants (Monte Carlo, N=200): gate 500,000 x level^2, bonus +50%
-- income per level. First rebirth lands around 13-16 minutes of active play,
-- and a player is better off after rebirthing than before it.
Config.RebirthBaseCost = 500000
Config.RebirthIncomeBonusPerLevel = 0.5

-- Income ticks once per second into each player's cash.
Config.IncomeTick = 1

-- How often the server autosaves a player's progress, in seconds.
Config.AutosaveInterval = 60

return Config
