local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Render = require(script.Parent:WaitForChild("Render"))
local TowerStats = require(ReplicatedStorage.Modules.TowerStats)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Arrow = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Projectiles"):WaitForChild("Arrow")

local VFX = {}

local ArcHeight = 1.5

local arrows = {}
local folder

local function GetArcPos(from,to,a)
	return from:Lerp(to,a) + Vector3.new(0,math.sin(a * math.pi) * ArcHeight,0)
end

local function FlashEnemy(enemy)
	if not enemy.Model.Parent then return end
	local hl = ReplicatedStorage.Assets.Effects.HitFlash:Clone()
	hl.Parent = enemy.Model
	Debris:AddItem(hl,0.08)
end

local function FireArrow(tower,enemy,flyTime)
	if not tower.Muzzle or not enemy.Model.Parent then return end
	local from = tower.Muzzle.WorldPosition
	Render.PlaySound("Shoot",from)
	local arrow = Arrow:Clone()
	arrow.CFrame = CFrame.new(from)
	arrow.Parent = folder
	table.insert(arrows,{
		Part = arrow,
		From = from,
		To = enemy.Root.Position,
		Enemy = enemy,
		Start = os.clock(),
		Time = math.max(flyTime,0.05),
	})
end

local function FaceEnemy(tower,enemy)
	if not tower.Unit then return end
	local pos = tower.Unit:GetPivot().Position
	tower.Unit:PivotTo(CFrame.lookAt(pos,Vector3.new(enemy.Root.Position.X,pos.Y,enemy.Root.Position.Z)))
end

local function Slash(tower,enemy)
	FaceEnemy(tower,enemy)
	if tower.AttackTrack then
		tower.AttackTrack:Play(0.05)
	end
	local hitTime = TowerStats[tower.Type].HitTime
	task.wait(hitTime / 2)
	if tower.Trail then tower.Trail.Enabled = true end
	Render.PlaySound("Slash",tower.Position)
	task.wait(hitTime / 2 + 0.15)
	if tower.Trail then tower.Trail.Enabled = false end
end

local function Shoot(tower,enemy,flyTime)
	FaceEnemy(tower,enemy)
	if tower.AttackTrack then
		tower.AttackTrack:Play(0.05)
	end
	task.wait(TowerStats[tower.Type].ReleaseTime)
	if tower.Model.Parent then
		FireArrow(tower,enemy,flyTime)
	end
end

function VFX.Start()
	folder = workspace:WaitForChild("ClientVFX")

	Remotes.VFX.OnClientEvent:Connect(function(effect,towerId,enemyId,flyTime)
		local tower = Render.Towers[towerId]
		if not tower then return end

		if effect == "SlashHit" then
			for _,id in pairs(enemyId) do
				local e = Render.Enemies[id]
				if e then
					FlashEnemy(e)
					Render.PlaySound("Hit",e.Root.Position)
				end
			end
		elseif effect == "Slash" and Render.Enemies[enemyId] then
			Slash(tower,Render.Enemies[enemyId])
		elseif effect == "Arrow" and Render.Enemies[enemyId] then
			Shoot(tower,Render.Enemies[enemyId],flyTime)
		end
	end)

	RunService.PreRender:Connect(function()
		local now = os.clock()
		for i = #arrows,1,-1 do
			local v = arrows[i]
			if v.Enemy.Model.Parent then
				v.To = v.Enemy.Root.Position
			end
			local a = (now - v.Start) / v.Time
			if a >= 1 then
				v.Part:Destroy()
				table.remove(arrows,i)
				FlashEnemy(v.Enemy)
				Render.PlaySound("Hit",v.To)
			else
				local pos = GetArcPos(v.From,v.To,a)
				v.Part.CFrame = CFrame.lookAt(pos,GetArcPos(v.From,v.To,a + 0.05))
			end
		end
	end)
end

return VFX
