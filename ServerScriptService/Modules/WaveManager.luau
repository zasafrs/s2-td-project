local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyManager = require(script.Parent.EnemyManager)
local TowerManager = require(script.Parent.TowerManager)
local Economy = require(script.Parent.Economy)
local WaveData = require(ReplicatedStorage.Modules.WaveData)
local WaveSync = ReplicatedStorage.Remotes.WaveSync

local WaveManager = {}

local Difficulty = "Easy"
local StartLives = 3

local lives = StartLives
local running = false
local gameId = 0

local function SetState(s)
	workspace:SetAttribute("GameState",s)
	WaveSync:FireAllClients("State",s)
end

local function SetWave(wave)
	workspace:SetAttribute("Wave",wave)
	workspace:SetAttribute("WaveCount",#WaveData.Waves[Difficulty])
	WaveSync:FireAllClients("Wave",wave,#WaveData.Waves[Difficulty])
end

local function EndGame(result)
	gameId += 1
	running = false
	SetState(result)
	EnemyManager.Clear()
	local id = gameId
	task.wait(5)
	if gameId == id then
		WaveManager.Restart()
	end
end

EnemyManager.ReachedEnd.Event:Connect(function(damage)
	if workspace:GetAttribute("GameState") ~= "Playing" then return end
	lives = math.max(lives - damage,0)
	workspace:SetAttribute("Lives",lives)
	if lives == 0 then
		EndGame("Lost")
	end
end)

local function PlayWave(num,wave,id)
	SetWave(num)

	local list = {}
	for name,amount in pairs(wave.Enemies) do
		for i = 1,amount do
			if name == "Zombie" then
				table.insert(list,1,name)
			else
				table.insert(list,name)
			end
		end
	end

	for i,name in ipairs(list) do

		if gameId ~= id then return end
		EnemyManager.Spawn(name)
		if i < #list then
			task.wait(wave.Interval)
		end
	end
	repeat task.wait(0.25) until not next(EnemyManager.Enemies) or gameId ~= id
end

function WaveManager.StartGame()
	if running or workspace:GetAttribute("GameState") ~= "Playing" or #Players:GetPlayers() == 0 then return end
	running = true
	local id = gameId
	task.spawn(function()
		local waves = WaveData.Waves[Difficulty]
		for i,wave in ipairs(waves) do
			PlayWave(i,wave,id)
			if gameId ~= id then return end
			for _,plr in pairs(Players:GetPlayers()) do
				Economy.Add(plr,wave.Reward)
			end
			if i < #waves then
				task.wait(5)
			end
		end
		EndGame("Won")
	end)
end

function WaveManager.Restart()
	gameId += 1
	running = false
	EnemyManager.Clear()
	TowerManager.Clear()
	Economy.Reset()
	lives = StartLives
	workspace:SetAttribute("Lives",lives)
	SetWave(0)
	SetState("Playing")
	WaveManager.StartGame()
end

workspace:SetAttribute("Lives",lives)
SetWave(0)
SetState("Playing")

Players.PlayerRemoving:Connect(function()
	task.wait()
	if #Players:GetPlayers() == 0 then
		WaveManager.Restart()
	end
end)

function WaveManager.Start()
	Players.PlayerAdded:Connect(WaveManager.StartGame)
	WaveManager.StartGame()
end

return WaveManager
