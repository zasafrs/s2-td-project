local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseTower = require(script.Parent.BaseTower)
local EnemyManager = require(script.Parent.Parent.EnemyManager)
local Economy = require(script.Parent.Parent.Economy)
local Remotes = ReplicatedStorage.Remotes

local ArcherTower = setmetatable({},{__index = BaseTower})
ArcherTower.__index = ArcherTower

function ArcherTower.new(id,owner,pos,rot)
	return setmetatable(BaseTower.new(id,owner,"ArcherTower",pos,rot),ArcherTower)
end

function ArcherTower:Attack(enemy)
	local dmg = self:GetLevel().Damage
	local flyTime = (enemy:GetPosition() - self.Position).Magnitude / self.Stats.ProjectileSpeed
	local dealt = enemy:GetDamageTaken(dmg)
	enemy.PendingDamage += dealt
	Remotes.VFX:FireAllClients("Arrow",self.Id,enemy.Id,flyTime)

	task.wait(self.Stats.ReleaseTime + flyTime)
	enemy.PendingDamage -= dealt
	if self.Removed then return end
	if EnemyManager.Damage(enemy.Id,dmg) then
		Economy.Add(self.Owner,enemy.Reward)
	end
end

return ArcherTower
