local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathUtil = require(ReplicatedStorage.Modules.PathUtil)
local EnemyStats = require(ReplicatedStorage.Modules.EnemyStats)
local Enemy = require(script.Parent.Enemy)
local EnemySync = ReplicatedStorage.Remotes.EnemySync

local EnemyManager = {}
EnemyManager.Enemies = {}
EnemyManager.Path = PathUtil.FromFolder(workspace.Map.Path.Waypoints)
EnemyManager.ReachedEnd = game:GetService("ServerStorage").Bindables.ReachedEnd

local lastId = 0

local function RemoveEnemy(enemy,reason)
	if not EnemyManager.Enemies[enemy.Id] then return end
	EnemyManager.Enemies[enemy.Id] = nil
	EnemySync:FireAllClients("Remove",enemy.Id,reason)
end

function EnemyManager.Spawn(name)
	local stats = EnemyStats[name]
	if not stats then
		warn("no enemy called",name)
		return
	end
	lastId += 1
	local enemy = Enemy.new(lastId,name,stats,EnemyManager.Path)
	EnemyManager.Enemies[lastId] = enemy
	EnemySync:FireAllClients("Spawn",lastId,name,enemy.SpawnTime,enemy.Speed)
	return enemy
end

function EnemyManager.Damage(id,amount)
	local enemy = EnemyManager.Enemies[id]
	if enemy and enemy:TakeDamage(amount) then
		RemoveEnemy(enemy,"Died")
		return true
	end
	return false
end

function EnemyManager.Clear()
	for _,e in pairs(EnemyManager.Enemies) do
		RemoveEnemy(e,"Clear")
	end
end

Players.PlayerAdded:Connect(function(plr)
	local list = {}
	for id,e in pairs(EnemyManager.Enemies) do
		table.insert(list,{id,e.Type,e.SpawnTime,e.Speed})
	end
	EnemySync:FireClient(plr,"Snapshot",list)
end)

RunService.Heartbeat:Connect(function()
	for _,e in pairs(EnemyManager.Enemies) do
		if e:GetDistance() >= EnemyManager.Path.Length then
			RemoveEnemy(e,"End")
			EnemyManager.ReachedEnd:Fire(e.LeakDamage)
		end
	end
end)

return EnemyManager
