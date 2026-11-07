local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(id,name,stats,path)
	local self = setmetatable({},Enemy)
	self.Id = id
	self.Type = name
	self.Health = stats.Health
	self.Armor = stats.Armor or 0
	self.Speed = stats.Speed
	self.Reward = stats.Reward
	self.LeakDamage = stats.LeakDamage
	self.SpawnTime = workspace:GetServerTimeNow()
	self.PendingDamage = 0
	self.Path = path
	return self
end

function Enemy:GetDistance()
	return (workspace:GetServerTimeNow() - self.SpawnTime) * self.Speed
end

function Enemy:GetPosition()
	return self.Path:CFrameAt(self:GetDistance()).Position
end

function Enemy:GetDamageTaken(amount)
	local dmg = amount - self.Armor
	if dmg < 1 then
		dmg = 1
	end
	return dmg
end

function Enemy:TakeDamage(amount)
	self.Health -= self:GetDamageTaken(amount)
	return self.Health <= 0
end

return Enemy
