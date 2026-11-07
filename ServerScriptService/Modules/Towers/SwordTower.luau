local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseTower = require(script.Parent.BaseTower)
local EnemyManager = require(script.Parent.Parent.EnemyManager)
local Economy = require(script.Parent.Parent.Economy)
local PathUtil = require(ReplicatedStorage.Modules.PathUtil)
local Remotes = ReplicatedStorage.Remotes

local Flat = PathUtil.Flat

local SwordTower = setmetatable({},{__index = BaseTower})
SwordTower.__index = SwordTower

function SwordTower.new(id,owner,pos,rot)
	return setmetatable(BaseTower.new(id,owner,"SwordTower",pos,rot),SwordTower)
end

function SwordTower:Attack(enemy)
	local level = self:GetLevel()
	Remotes.VFX:FireAllClients("Slash",self.Id,enemy.Id)

	task.wait(self.Stats.HitTime)
	if self.Removed then return end
	local hits = {}
	for _,e in pairs(EnemyManager.Enemies) do
		if e.Health - e.PendingDamage > 0 and (Flat(e:GetPosition()) - Flat(self.Position)).Magnitude <= level.Range then
			table.insert(hits,e)
		end
	end
	table.sort(hits,function(a,b)
		return a:GetDistance() > b:GetDistance()
	end)
	local ids = {}
	for i,e in ipairs(hits) do
		if i > self.Stats.MaxHits then break end
		table.insert(ids,e.Id)
		if EnemyManager.Damage(e.Id,level.Damage) then
			Economy.Add(self.Owner,e.Reward)
		end
	end
	Remotes.VFX:FireAllClients("SlashHit",self.Id,ids)
end

return SwordTower
