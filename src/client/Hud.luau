-- Hud: builds the whole screen interface and updates it from server state.
-- Top-right: money (gold, large) + income/sec (green) under it.
-- Top-centre: title, with the event banner and steal alert under it.
-- Left: the base panel, 8 slots (name + $/s, or "Empty").
-- Bottom-right: Lock Base and Rebirth buttons.
-- Everything stays clear of the top-left corner, where Roblox's menu sits.
local Format = require(game:GetService("ReplicatedStorage").Shared.Format)

local Hud = {}
Hud.MoneyLabel = nil
Hud.IncomeLabel = nil
Hud.EventBanner = nil
Hud.AlertLabel = nil
Hud.CarryingLabel = nil
Hud.LockButton = nil
Hud.RebirthButton = nil
Hud.SlotButtons = {}

-- Builds the HUD under the player's PlayerGui. Returns nothing; the
-- created labels and buttons live on the Hud table for the updaters below.
function Hud.Build(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "NightMarketGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 12)
	title.Size = UDim2.fromOffset(520, 44)
	title.BackgroundTransparency = 1
	title.Text = "PASAR MALAM BRAINROT"
	title.TextColor3 = Color3.fromRGB(163, 230, 53)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBlack
	title.Parent = gui

	local money = Instance.new("TextLabel")
	money.Name = "Money"
	money.AnchorPoint = Vector2.new(1, 0)
	money.Position = UDim2.new(1, -16, 0, 12)
	money.Size = UDim2.fromOffset(220, 44)
	money.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	money.BackgroundTransparency = 0.25
	money.Text = "$100"
	money.TextColor3 = Color3.fromRGB(255, 215, 0)
	money.TextSize = 30
	money.Font = Enum.Font.GothamBold
	money.Parent = gui
	Hud.MoneyLabel = money

	local income = Instance.new("TextLabel")
	income.Name = "Income"
	income.AnchorPoint = Vector2.new(1, 0)
	income.Position = UDim2.new(1, -16, 0, 60)
	income.Size = UDim2.fromOffset(220, 30)
	income.BackgroundTransparency = 1
	income.Text = "+$0/sec"
	income.TextColor3 = Color3.fromRGB(110, 230, 120)
	income.TextSize = 22
	income.Font = Enum.Font.GothamBold
	income.Parent = gui
	Hud.IncomeLabel = income

	local banner = Instance.new("TextLabel")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 64)
	banner.Size = UDim2.fromOffset(460, 36)
	banner.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	banner.BackgroundTransparency = 0.2
	banner.Text = ""
	banner.TextColor3 = Color3.fromRGB(255, 255, 255)
	banner.TextSize = 22
	banner.Font = Enum.Font.GothamBold
	banner.Visible = false
	banner.Parent = gui
	Hud.EventBanner = banner

	local alert = Instance.new("TextLabel")
	alert.Name = "Alert"
	alert.AnchorPoint = Vector2.new(0.5, 0)
	alert.Position = UDim2.new(0.5, 0, 0, 104)
	alert.Size = UDim2.fromOffset(460, 32)
	alert.BackgroundTransparency = 1
	alert.Text = ""
	alert.TextColor3 = Color3.fromRGB(255, 90, 90)
	alert.TextSize = 20
	alert.Font = Enum.Font.GothamBold
	alert.Visible = false
	alert.Parent = gui
	Hud.AlertLabel = alert

	local carrying = Instance.new("TextLabel")
	carrying.Name = "Carrying"
	carrying.AnchorPoint = Vector2.new(0.5, 1)
	carrying.Position = UDim2.new(0.5, 0, 1, -148)
	carrying.Size = UDim2.fromOffset(520, 32)
	carrying.BackgroundTransparency = 1
	carrying.Text = ""
	carrying.TextColor3 = Color3.fromRGB(255, 215, 0)
	carrying.TextSize = 22
	carrying.Font = Enum.Font.GothamBold
	carrying.Visible = false
	carrying.Parent = gui
	Hud.CarryingLabel = carrying

	-- Base panel: 8 slots down the left side.
	local panel = Instance.new("Frame")
	panel.Name = "BasePanel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.fromOffset(220, 340)
	panel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	panel.BackgroundTransparency = 0.3
	panel.Parent = gui

	local panelTitle = Instance.new("TextLabel")
	panelTitle.Name = "PanelTitle"
	panelTitle.Size = UDim2.new(1, 0, 0, 32)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Text = "MY BASE"
	panelTitle.TextColor3 = Color3.fromRGB(163, 230, 53)
	panelTitle.TextSize = 20
	panelTitle.Font = Enum.Font.GothamBlack
	panelTitle.Parent = panel

	for slot = 1, 8 do
		local button = Instance.new("TextButton")
		button.Name = "Slot" .. tostring(slot)
		button.Position = UDim2.new(0, 8, 0, 32 + (slot - 1) * 38)
		button.Size = UDim2.new(1, -16, 0, 34)
		button.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
		button.Text = "Empty"
		button.TextColor3 = Color3.fromRGB(200, 200, 200)
		button.TextSize = 18
		button.Font = Enum.Font.Gotham
		button.Parent = panel
		Hud.SlotButtons[slot] = button
	end

	-- Bottom-right action buttons.
	local lock = Instance.new("TextButton")
	lock.Name = "LockButton"
	lock.AnchorPoint = Vector2.new(1, 1)
	lock.Position = UDim2.new(1, -16, 1, -64)
	lock.Size = UDim2.fromOffset(200, 44)
	lock.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	lock.Text = "Lock Base ($1,500)"
	lock.TextColor3 = Color3.fromRGB(255, 255, 255)
	lock.TextSize = 20
	lock.Font = Enum.Font.GothamBold
	lock.Parent = gui
	Hud.LockButton = lock

	local rebirth = Instance.new("TextButton")
	rebirth.Name = "RebirthButton"
	rebirth.AnchorPoint = Vector2.new(1, 1)
	rebirth.Position = UDim2.new(1, -16, 1, -116)
	rebirth.Size = UDim2.fromOffset(200, 44)
	rebirth.BackgroundColor3 = Color3.fromRGB(120, 50, 160)
	rebirth.Text = "Rebirth"
	rebirth.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirth.TextSize = 20
	rebirth.Font = Enum.Font.GothamBold
	rebirth.Parent = gui
	Hud.RebirthButton = rebirth
end

-- Updates money and income from a server state snapshot.
function Hud.SetMoney(snapshot)
	if Hud.MoneyLabel ~= nil then
		Hud.MoneyLabel.Text = Format.Money(snapshot.Cash)
	end
	if Hud.IncomeLabel ~= nil then
		Hud.IncomeLabel.Text = "+" .. Format.Money(snapshot.IncomePerSec) .. "/sec"
	end
end

-- Refreshes the 8 base slots from a server state snapshot.
function Hud.RefreshBase(snapshot)
	local bySlot = {}
	for _, placed in ipairs(snapshot.Placed) do
		bySlot[placed.Slot] = placed
	end
	for slot = 1, 8 do
		local button = Hud.SlotButtons[slot]
		if button ~= nil then
			local placed = bySlot[slot]
			if placed ~= nil then
				local marker = ""
				if placed.Mutation ~= nil and placed.Mutation ~= "" then
					marker = " ★"
				end
				button.Text = placed.CharacterName .. marker .. "  $" .. tostring(placed.IncomePerSec) .. "/s"
				button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				button.Text = "Empty"
				button.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end
end

-- Updates the Lock button: price, active timer, or cooldown.
function Hud.SetLock(snapshot)
	if Hud.LockButton == nil then
		return
	end
	local now = os.time()
	if snapshot.LockUntil > now then
		local left = snapshot.LockUntil - now
		Hud.LockButton.Text = "Locked (" .. tostring(left) .. "s)"
		Hud.LockButton.BackgroundColor3 = Color3.fromRGB(30, 120, 60)
	elseif snapshot.LockCooldownUntil > now then
		local left = snapshot.LockCooldownUntil - now
		Hud.LockButton.Text = "Lock cooldown (" .. tostring(left) .. "s)"
		Hud.LockButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	else
		Hud.LockButton.Text = "Lock Base ($1,500)"
		Hud.LockButton.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	end
end

-- Updates the Rebirth button: next cost, level, and whether it is ready.
function Hud.SetRebirth(snapshot)
	if Hud.RebirthButton == nil then
		return
	end
	local level = snapshot.RebirthLevel
	if snapshot.CanRebirth then
		Hud.RebirthButton.Text = "REBIRTH! Lv" .. tostring(level + 1) .. " (+" .. tostring(50) .. "% income)"
		Hud.RebirthButton.BackgroundColor3 = Color3.fromRGB(180, 90, 220)
	else
		Hud.RebirthButton.Text = "Rebirth Lv" .. tostring(level + 1) .. " — " .. Format.Money(snapshot.RebirthCost)
		Hud.RebirthButton.BackgroundColor3 = Color3.fromRGB(120, 50, 160)
	end
end

-- Shows or hides the carrying line ("Carrying Tahu Gejrot — click a base
-- slot to place it").
function Hud.SetCarrying(snapshot)
	if Hud.CarryingLabel == nil then
		return
	end
	if snapshot.Carrying ~= nil and snapshot.Carrying ~= "" then
		Hud.CarryingLabel.Text = "Carrying " .. snapshot.Carrying .. " — click a base slot to place it!"
		Hud.CarryingLabel.Visible = true
	else
		Hud.CarryingLabel.Visible = false
	end
end

-- Shows the event banner ("RUSH HOUR!" / "FESTIVAL! 2x income") or hides it.
function Hud.ShowBanner(name, active)
	if Hud.EventBanner == nil then
		return
	end
	if not active then
		Hud.EventBanner.Visible = false
		return
	end
	if name == "RushHour" then
		Hud.EventBanner.Text = "RUSH HOUR! Thief on the loose — guard your base!"
		Hud.EventBanner.TextColor3 = Color3.fromRGB(255, 120, 90)
	elseif name == "Festival" then
		Hud.EventBanner.Text = "FESTIVAL! 2x income for 45 seconds!"
		Hud.EventBanner.TextColor3 = Color3.fromRGB(255, 215, 0)
	else
		Hud.EventBanner.Text = name
	end
	Hud.EventBanner.Visible = true
end

-- Shows a steal alert under the banner for a few seconds.
function Hud.ShowAlert(text)
	if Hud.AlertLabel == nil then
		return
	end
	Hud.AlertLabel.Text = text
	Hud.AlertLabel.Visible = true
	task.delay(4, function()
		Hud.AlertLabel.Visible = false
	end)
end

return Hud
