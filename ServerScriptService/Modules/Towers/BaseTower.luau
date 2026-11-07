local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyManager = require(script.Parent.Parent.EnemyManager)
local TowerStats = require(ReplicatedStorage.Modules.TowerStats)
local TowerUtil = require(ReplicatedStorage.Modules.TowerUtil)
local PathUtil = require(ReplicatedStorage.Modules.PathUtil)

local Flat = PathUtil.Flat

local BaseTower = {}
BaseTower.__index = BaseTower

function BaseTower.new(id,owner,name,pos,rot)
	local self = setmetatable({},BaseTower)
	self.Id = id
	self.Owner = owner
	self.Type = name
	self.Stats = TowerStats[name]
	self.Level = 1
	self.Position = pos
	self.Rotation = rot
	return self
end

function BaseTower:GetLevel()
	return self.Stats.Levels[self.Level]
end


function BaseTower:FindTarget()
	local range = self:GetLevel().Range
	local target
	local furthest = -1
	for _,enemy in pairs(EnemyManager.Enemies) do
		local dist = enemy:GetDistance()
		if dist > furthest and enemy.Health - enemy.PendingDamage > 0 then
			if (Flat(enemy:GetPosition()) - Flat(self.Position)).Magnitude <= range then
				target = enemy
				furthest = dist
			end
		end
	end
	return target
end

function BaseTower:Start()
	task.spawn(function()
		while not self.Removed do
			local target = self:FindTarget()
			if target then
				task.spawn(function()
					self:Attack(target)
				end)
				task.wait(self:GetLevel().Cooldown)
			else
				task.wait(0.1)
			end
		end
	end)
end

function BaseTower:Stop()
	self.Removed = true
end

function BaseTower:GetUpgradePrice()
	if self.Stats.Levels[self.Level + 1] then
		return self.Stats.Levels[self.Level + 1].Price
	end
end

function BaseTower:Upgrade()
	self.Level += 1
end

function BaseTower:GetSellValue()
	return TowerUtil.GetSellValue(self.Type,self.Level)
end

return BaseTower
