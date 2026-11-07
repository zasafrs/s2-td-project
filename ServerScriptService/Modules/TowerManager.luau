local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyManager = require(script.Parent.EnemyManager)
local Economy = require(script.Parent.Economy)
local TowerStats = require(ReplicatedStorage.Modules.TowerStats)
local Config = require(ReplicatedStorage.Modules.Config)
local PlacementRules = require(ReplicatedStorage.Modules.PlacementRules)
local Remotes = ReplicatedStorage.Remotes

local TowerManager = {}
TowerManager.Towers = {}

local TowerTypes = {
	["ArcherTower"] = require(script.Parent.Towers.ArcherTower),
	["SwordTower"] = require(script.Parent.Towers.SwordTower),
}

local rules = PlacementRules.new(EnemyManager.Path,workspace.Map:FindFirstChild("Decor"))
local lastId = 0
local towerCount = {}
local lastAction = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {workspace.Map,workspace:FindFirstChild("Baseplate")}

local function RoundOver()
	return workspace:GetAttribute("GameState") ~= "Playing"
end

local function GetGround(pos)
	local result = workspace:Raycast(Vector3.new(pos.X,200,pos.Z),Vector3.new(0,-400,0),rayParams)
	if result then
		return result.Position
	end
end

local function RemoveTower(id)
	local tower = TowerManager.Towers[id]
	if not tower then return end
	tower:Stop()
	TowerManager.Towers[id] = nil
	if towerCount[tower.Owner] then
		towerCount[tower.Owner] -= 1
	end
	Remotes.TowerSync:FireAllClients("Removed",id)
end

function TowerManager.Clear()
	for id,_ in pairs(TowerManager.Towers) do
		RemoveTower(id)
	end
	towerCount = {}
end

function TowerManager.Place(plr,towerName,pos,rot)
	if RoundOver() then
		return false,"Round is over"
	end
	local class = TowerTypes[towerName]
	if not class or typeof(pos) ~= "Vector3" then
		return false
	end
	if (towerCount[plr] or 0) >= Config.MaxTowers then
		return false,"Tower limit reached"
	end
	if rot ~= 90 and rot ~= 180 and rot ~= 270 then
		rot = 0
	end

	pos = GetGround(pos)
	if not pos then
		return false
	end
	local ok,err = rules:Check(pos,TowerManager.Towers)
	if not ok then
		return false,err
	end
	if not Economy.TrySpend(plr,TowerStats[towerName].PlaceCost) then
		return false,"Not enough cash"
	end

	lastId += 1
	local tower = class.new(lastId,plr,pos,rot)
	TowerManager.Towers[lastId] = tower
	towerCount[plr] = (towerCount[plr] or 0) + 1
	tower:Start()
	Remotes.TowerSync:FireAllClients("Placed",lastId,towerName,pos,rot,tower.Level,plr.UserId)
	return true,lastId
end

function TowerManager.Upgrade(plr,id)
	if RoundOver() then return false,"Round is over" end
	local tower = TowerManager.Towers[id]
	if not tower or tower.Owner ~= plr then
		return false,"That's not your tower"
	end
	local price = tower:GetUpgradePrice()
	if not price then
		return false,"Already max level"
	end
	if not Economy.TrySpend(plr,price) then
		return false,"Not enough cash"
	end
	tower:Upgrade()
	Remotes.TowerSync:FireAllClients("Upgraded",id,tower.Level)
	return true,tower.Level
end

function TowerManager.Sell(plr,id)
	if RoundOver() then return false,"Round is over" end
	local tower = TowerManager.Towers[id]
	if not tower or tower.Owner ~= plr then
		return false,"That's not your tower"
	end
	local refund = tower:GetSellValue()
	RemoveTower(id)
	Economy.Add(plr,refund)
	return true,refund
end

local function TooFast(plr)
	local now = os.clock()
	if lastAction[plr] and now - lastAction[plr] < 0.15 then
		return true
	end
	lastAction[plr] = now
	return false
end

Remotes.PlaceTower.OnServerInvoke = function(plr,towerName,pos,rot)
	if TooFast(plr) then return false,"Slow down" end
	return TowerManager.Place(plr,towerName,pos,rot)
end

Remotes.UpgradeTower.OnServerInvoke = function(plr,id)
	if TooFast(plr) then return false,"Slow down" end
	return TowerManager.Upgrade(plr,id)
end

Remotes.SellTower.OnServerInvoke = function(plr,id)
	if TooFast(plr) then return false,"Slow down" end
	return TowerManager.Sell(plr,id)
end

function TowerManager.Start()
	Players.PlayerAdded:Connect(function(plr)
		local list = {}
		for id,t in pairs(TowerManager.Towers) do
			table.insert(list,{id,t.Type,t.Position,t.Rotation,t.Level,t.Owner.UserId})
		end
		Remotes.TowerSync:FireClient(plr,"Load",list)
	end)
	Players.PlayerRemoving:Connect(function(plr)
		for id,t in pairs(TowerManager.Towers) do
			if t.Owner == plr then
				RemoveTower(id)
			end
		end
		towerCount[plr] = nil
		lastAction[plr] = nil
	end)
end

return TowerManager
