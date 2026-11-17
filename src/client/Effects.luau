-- Effects: small feedback flourishes for purchases, steals and events.
-- Visual only (tweens on the HUD): no sound assets are invented, so
-- nothing here can fail on a missing asset id.
local TweenService = game:GetService("TweenService")

local Effects = {}

-- Flashes the money label gold when a purchase lands.
function Effects.PlayPurchase(hud)
	if hud.MoneyLabel == nil then
		return
	end
	local label = hud.MoneyLabel
	local tween = TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextColor3 = Color3.fromRGB(140, 255, 140),
	})
	tween:Play()
	tween.Completed:Connect(function()
		TweenService:Create(label, TweenInfo.new(0.5), {
			TextColor3 = Color3.fromRGB(255, 215, 0),
		}):Play()
	end)
end

-- Flashes the steal alert red when someone steals from the player's base.
function Effects.PlayStealAlert(hud)
	if hud.AlertLabel == nil then
		return
	end
	hud.ShowAlert("Pencuri di base kamu! Tag them to make them drop it!")
	local tween = TweenService:Create(hud.AlertLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	})
	tween:Play()
end

-- Pulses the event banner when an event starts.
function Effects.PlayEvent(hud)
	if hud.EventBanner == nil or not hud.EventBanner.Visible then
		return
	end
	local banner = hud.EventBanner
	local grow = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(500, 40),
	})
	grow:Play()
	grow.Completed:Connect(function()
		TweenService:Create(banner, TweenInfo.new(0.3), {
			Size = UDim2.fromOffset(460, 36),
		}):Play()
	end)
end

return Effects
