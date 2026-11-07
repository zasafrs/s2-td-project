local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local PathUtil = require(ReplicatedStorage.Modules.PathUtil)
local TowerStats = require(ReplicatedStorage.Modules.TowerStats)
local EnemyStats = require(ReplicatedStorage.Modules.EnemyStats)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local EnemyModels = Assets:WaitForChild("Enemies")
local TowerModels = Assets:WaitForChild("Towers")
local Anims = Assets:WaitForChild("Animations")
local Sounds = Assets:WaitForChild("Sounds")

local Render = {}
Render.Enemies = {}
Render.Towers = {}
Render.TowerChanged = ReplicatedStorage:WaitForChild("Bindables"):WaitForChild("TowerChanged")

local EnemyFolder = workspace:WaitForChild("ClientEnemies")
local TowerFolder = workspace:WaitForChild("ClientTowers")

local path = PathUtil.FromFolder(workspace:WaitForChild("Map"):WaitForChild("Path"):WaitForChild("Waypoints"))
Render.Path = path

local DeathTime = 0.35

function Render.PlaySound(name,pos)
	if not Sounds:FindFirstChild(name) then return end
	local holder = Assets.Effects.SoundHolder:Clone()
	holder.WorldPosition = pos
	holder.Parent = workspace.Terrain
	local sound = Sounds[name]:Clone()
	sound.Parent = holder
	sound:Play()
	Debris:AddItem(holder,sound.TimeLength + 0.5)
end

local function LoadAnim(rig,name)
	if not rig or not Anims:FindFirstChild(name) then return end
	local animator = rig:FindFirstChild("Animator",true)
	local anim = Anims[name]:FindFirstChildOfClass("Animation")
	if animator and anim then
		return animator:LoadAnimation(anim)
	end
end

local function SpawnEnemy(id,name,spawnTime,speed)
	if Render.Enemies[id] then return end
	if not EnemyModels:FindFirstChild(name) then
		warn("no enemy model for",name)
		return
	end
	local model = EnemyModels[name]:Clone()
	Render.Enemies[id] = {
		Model = model,
		Root = model.PrimaryPart,
		SpawnTime = spawnTime,
		Speed = speed,
		Offset = CFrame.new(0,model:GetAttribute("HeightOffset") or 0,0),
	}
	model.Parent = EnemyFolder

	local walk = LoadAnim(model,EnemyStats[name].WalkAnim)
	if walk then
		walk:Play(0)
		walk.TimePosition = math.random()
	end
end

local function KillEnemy(e)
	Render.PlaySound("Death",e.Root.Position)
	local parts = {}
	for _,v in pairs(e.Model:GetDescendants()) do
		if v:IsA("BasePart") and v ~= e.Root then
			table.insert(parts,v)
		elseif v:IsA("Animator") then
			for _,track in pairs(v:GetPlayingAnimationTracks()) do
				track:Stop(0.1)
			end
		end
	end

	local start = e.Root.CFrame
	local startTime = os.clock()
	local conn
	conn = RunService.PreRender:Connect(function()
		local a = (os.clock() - startTime) / DeathTime
		if a > 1 then a = 1 end
		e.Root.CFrame = start * CFrame.new(0,-1.5 * a,0)
		for _,p in pairs(parts) do
			p.Transparency = a
		end
		if a == 1 then
			conn:Disconnect()
			e.Model:Destroy()
		end
	end)
end

local function RemoveEnemy(id,died)
	local e = Render.Enemies[id]
	if not e then return end
	Render.Enemies[id] = nil
	if died then
		KillEnemy(e)
	else
		e.Model:Destroy()
	end
end

local function PlaceTower(id,name,pos,rot,level,ownerId)
	if Render.Towers[id] then return end
	if not TowerModels:FindFirstChild(name) then
		warn("no tower model for",name)
		return
	end
	local model = TowerModels[name]:Clone()
	model:PivotTo(CFrame.new(pos) * CFrame.Angles(0,math.rad(rot),0))
	model:SetAttribute("TowerId",id)
	local unit
	for _,child in pairs(model:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChildOfClass("AnimationController") then
			unit = child
		end
	end
	local tower = {
		Model = model,
		Unit = unit,
		Muzzle = model:FindFirstChild("Muzzle",true),
		Type = name,
		Level = level,
		OwnerId = ownerId,
		Position = pos,
		Trail = model:FindFirstChildWhichIsA("Trail",true),
	}
	Render.Towers[id] = tower
	model.Parent = TowerFolder

	local idle = LoadAnim(unit,TowerStats[name].IdleAnim)
	if idle then idle:Play() end
	tower.AttackTrack = LoadAnim(unit,TowerStats[name].AttackAnim)
end

local function RemoveTower(id)
	local tower = Render.Towers[id]
	if not tower then return end
	Render.Towers[id] = nil
	Render.TowerChanged:Fire(id)
	tower.Model:Destroy()
end

function Render.Start()
	Remotes.EnemySync.OnClientEvent:Connect(function(action,...)
		if action == "Spawn" then
			SpawnEnemy(...)
		elseif action == "Remove" then
			local id,reason = ...
			RemoveEnemy(id,reason == "Died")
		elseif action == "Snapshot" then
			for _,v in pairs((...)) do
				SpawnEnemy(v[1],v[2],v[3],v[4])
			end
		end
	end)

	Remotes.TowerSync.OnClientEvent:Connect(function(action,id,...)
		local args = {...}
		if action == "Placed" then
			PlaceTower(id,...)
		elseif action == "Removed" then
			RemoveTower(id)
		elseif action == "Upgraded" then
			if Render.Towers[id] then
				Render.Towers[id].Level = args[1]
				Render.TowerChanged:Fire(id)
			end
		elseif action == "Load" then
			for _,v in pairs(id) do
				PlaceTower(v[1],v[2],v[3],v[4],v[5],v[6])
			end
		end
	end)

	RunService.PreRender:Connect(function()
		local now = workspace:GetServerTimeNow()
		for _,e in pairs(Render.Enemies) do
			e.Root.CFrame = path:CFrameAt((now - e.SpawnTime) * e.Speed) * e.Offset
		end
	end)
end

return Render
