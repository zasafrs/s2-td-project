local Players = game:GetService("Players")

local Economy = {}
Economy.Players = {}

local StartingCash = 200

local function SetCash(plr,amount)
	Economy.Players[plr].Cash = amount
	plr:SetAttribute("Cash",amount)
end

function Economy.SetupPlayer(plr)
	Economy.Players[plr] = {Cash = StartingCash}
	plr:SetAttribute("Cash",StartingCash)
end

function Economy.Get(plr)
	local data = Economy.Players[plr]
	return data and data.Cash or 0
end

function Economy.Add(plr,amount)
	if not Economy.Players[plr] then return end
	SetCash(plr,Economy.Players[plr].Cash + amount)
end

function Economy.TrySpend(plr,amount)
	local data = Economy.Players[plr]
	if not data then return false end
	local cash = data.Cash
	if cash < amount then
		return false
	end
	SetCash(plr,cash - amount)
	return true
end

function Economy.Reset()
	for plr,_ in pairs(Economy.Players) do
		SetCash(plr,StartingCash)
	end
end

Players.PlayerAdded:Connect(Economy.SetupPlayer)
Players.PlayerRemoving:Connect(function(plr)
	Economy.Players[plr] = nil
end)
for _,plr in pairs(Players:GetPlayers()) do
	Economy.SetupPlayer(plr)
end

return Economy
