local TowerStats = require(script.Parent.TowerStats)

local TowerUtil = {}

function TowerUtil.GetSellValue(name,level)
	local stats = TowerStats[name]
	local spent = stats.PlaceCost
	for i = 2,level do
		spent += stats.Levels[i].Price
	end
	return math.floor(spent * stats.SellRefund)
end

return TowerUtil
