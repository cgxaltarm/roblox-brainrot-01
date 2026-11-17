-- Shop: the conveyor strip at the bottom of the screen.
-- Five cards, one per conveyor slot: character name, cost, rarity colour,
-- mutation marker. A card is greyed out while the player cannot afford it;
-- clicking a card buys what is in that slot.
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Format = require(game:GetService("ReplicatedStorage").Shared.Format)

local Shop = {}
Shop.Cards = {}
Shop.OnBuy = function(_) end
Shop.LastCash = 0

-- Builds the strip: five card buttons across the bottom-centre.
function Shop.Build(playerGui)
	local gui = playerGui:FindFirstChild("NightMarketGui")
	if gui == nil then
		return
	end
	local strip = Instance.new("Frame")
	strip.Name = "ConveyorStrip"
	strip.AnchorPoint = Vector2.new(0.5, 1)
	strip.Position = UDim2.new(0.5, 0, 1, -12)
	strip.Size = UDim2.fromOffset(760, 110)
	strip.BackgroundTransparency = 1
	strip.Parent = gui
	for slot = 1, 5 do
		local card = Instance.new("TextButton")
		card.Name = "Card" .. tostring(slot)
		card.Position = UDim2.new(0, (slot - 1) * 154, 0, 0)
		card.Size = UDim2.fromOffset(146, 104)
		card.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
		card.Text = "—"
		card.TextColor3 = Color3.fromRGB(255, 255, 255)
		card.TextSize = 18
		card.Font = Enum.Font.GothamBold
		card.TextWrapped = true
		card.Parent = strip
		card.MouseButton1Click:Connect(function()
			Shop.OnBuy(slot)
		end)
		Shop.Cards[slot] = card
	end
end

-- Refreshes the five cards from a conveyor snapshot. The player's cash
-- decides whether a card reads as affordable or greyed out.
function Shop.RefreshConveyor(slots, cash)
	Shop.LastCash = cash
	for slot = 1, 5 do
		local card = Shop.Cards[slot]
		if card ~= nil then
			local offer = slots[slot]
			if offer == nil then
				card.Text = "Coming soon..."
				card.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
			else
				local marker = ""
				if offer.Mutation ~= nil and offer.Mutation ~= "" then
					marker = " " .. BrainrotData.MUTATIONS[offer.Mutation].Marker
				end
				card.Text = offer.CharacterName .. marker .. "\n" .. offer.Rarity .. "\n" .. Format.Money(offer.Cost)
				local rarity = BrainrotData.RARITIES[offer.Rarity]
				if rarity ~= nil then
					card.BackgroundColor3 = rarity.Color
				end
				if cash < offer.Cost then
					card.TextColor3 = Color3.fromRGB(150, 150, 150)
				else
					card.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end
end

return Shop
