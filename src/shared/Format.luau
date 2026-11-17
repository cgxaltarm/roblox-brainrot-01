-- Format: money formatting shared by server and client.
local Format = {}

-- Formats an amount as $1, $950, $1.2K, $3.4M. Amounts below 1,000 print
-- whole; larger ones print one decimal, trimming a trailing ".0".
function Format.Money(amount)
	local value = math.floor(amount + 0.5)
	if value < 1000 then
		return "$" .. tostring(value)
	end
	local suffixes = { "K", "M", "B", "T" }
	local scaled = value
	local suffixIndex = 0
	while scaled >= 1000 and suffixIndex < #suffixes do
		scaled = scaled / 1000
		suffixIndex = suffixIndex + 1
	end
	local text = string.format("%.1f", scaled)
	if string.sub(text, -2) == ".0" then
		text = string.sub(text, 1, -3)
	end
	return "$" .. text .. suffixes[suffixIndex]
end

return Format
