-- Game.client: client entrypoint for Brainrot Night Market.
-- Builds the HUD (money top-right, title top-centre, hint bottom-centre)
-- and keeps it clear of the top-left corner, where Roblox's menu sits.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -16)
hint.Size = UDim2.fromOffset(640, 36)
hint.BackgroundTransparency = 1
hint.Text = "Walk to the conveyor up north and buy your first brainrot!"
hint.TextColor3 = Color3.fromRGB(230, 230, 230)
hint.TextSize = 20
hint.Font = Enum.Font.Gotham
hint.Parent = gui

print("[Brainrot Night Market] client HUD ready")
