-- Game.client: client entrypoint for Brainrot Night Market.
-- Builds the HUD and the conveyor shop, then wires them to the server:
-- StateSync refreshes money, income, base slots, lock, rebirth and the
-- carrying line; ConveyorSync refreshes the shop cards; EventPing shows
-- the event banner. Slot clicks place a carried brainrot or, with a second
-- click to confirm, sell what is in the slot. The client never decides
-- money: it only asks the server and renders what comes back.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local Hud = require(PlayerScripts.Client.Hud)
local Shop = require(PlayerScripts.Client.Shop)
local Effects = require(PlayerScripts.Client.Effects)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

Hud.Build(playerGui)
Shop.Build(playerGui)

local lastCash = 0
local lastSnapshot = nil
-- Sell confirmation: first click arms the slot, second click within 3 s sells.
local armedSellSlot = 0
local armedSellAt = 0

remotes.StateSync.OnClientEvent:Connect(function(snapshot)
	lastSnapshot = snapshot
	if snapshot.Cash < lastCash then
		Effects.PlayPurchase(Hud)
	end
	lastCash = snapshot.Cash
	Hud.SetMoney(snapshot)
	Hud.RefreshBase(snapshot)
	Hud.SetLock(snapshot)
	Hud.SetRebirth(snapshot)
	Hud.SetCarrying(snapshot)
	Shop.RefreshConveyor(Shop.LastSlots or {}, snapshot.Cash)
end)

remotes.ConveyorSync.OnClientEvent:Connect(function(slots)
	Shop.LastSlots = slots
	Shop.RefreshConveyor(slots, lastCash)
end)

remotes.EventPing.OnClientEvent:Connect(function(event)
	Hud.ShowBanner(event.Name, event.Active)
	Effects.PlayEvent(Hud)
end)

Shop.OnBuy = function(slot)
	remotes.BuyBrainrot:FireServer(slot)
end

for slot = 1, 8 do
	local button = Hud.SlotButtons[slot]
	if button ~= nil then
		button.MouseButton1Click:Connect(function()
			if lastSnapshot == nil then
				return
			end
			if lastSnapshot.Carrying ~= nil and lastSnapshot.Carrying ~= "" then
				remotes.PlaceBrainrot:FireServer(slot)
				return
			end
			-- Empty slot with empty hands: nothing to do.
			local occupied = false
			for _, placed in ipairs(lastSnapshot.Placed) do
				if placed.Slot == slot then
					occupied = true
					break
				end
			end
			if not occupied then
				return
			end
			-- Occupied slot: first click arms the sale, second confirms it.
			if armedSellSlot == slot and os.time() - armedSellAt <= 3 then
				remotes.SellBrainrot:FireServer(slot)
				armedSellSlot = 0
			else
				armedSellSlot = slot
				armedSellAt = os.time()
				button.Text = "Sell? Click again!"
			end
		end)
	end
end

if Hud.LockButton ~= nil then
	Hud.LockButton.MouseButton1Click:Connect(function()
		remotes.LockBase:FireServer()
	end)
end

if Hud.RebirthButton ~= nil then
	Hud.RebirthButton.MouseButton1Click:Connect(function()
		remotes.Rebirth:FireServer()
	end)
end

print("[Brainrot Night Market] client HUD ready")
