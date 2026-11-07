local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Render = require(script.Parent:WaitForChild("Render"))
local RangeRing = require(script.Parent:WaitForChild("RangeRing"))
local TowerStats = require(ReplicatedStorage.Modules.TowerStats)
local TowerUtil = require(ReplicatedStorage.Modules.TowerUtil)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local TowerPanel = {}

local Accent = Color3.fromRGB(232,178,74)
local UpgradeColor = Color3.fromRGB(64,92,60)
local OffColor = Color3.fromRGB(50,52,58)

local Panel,ShowError
local selectedId
local busy = false

local outline = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("SelectOutline"):Clone()
outline.Parent = workspace

local ring = RangeRing.new(Accent)

local function Refresh()
	local tower = Render.Towers[selectedId]
	if not tower then
		TowerPanel.Close()
		return
	end
	local stats = TowerStats[tower.Type]
	local now = stats.Levels[tower.Level]
	local nextLevel = stats.Levels[tower.Level + 1]
	local rows = Panel.Stats

	Panel.Title.Text = stats.Name
	Panel.Level.Text = "Level "..tower.Level.." / "..#stats.Levels
	rows.Damage.Current.Text = now.Damage
	rows.Range.Current.Text = now.Range
	rows.Cooldown.Current.Text = now.Cooldown.."s"
	ring:Show(tower.Position,now.Range)

	local mine = tower.OwnerId == player.UserId
	Panel.Upgrade.Visible = mine
	Panel.Sell.Visible = mine
	if nextLevel then
		rows.Damage.Next.Text = "-> "..nextLevel.Damage
		rows.Range.Next.Text = "-> "..nextLevel.Range
		rows.Cooldown.Next.Text = "-> "..nextLevel.Cooldown.."s"
		Panel.Upgrade.Text = "Upgrade  $"..nextLevel.Price
		if (player:GetAttribute("Cash") or 0) >= nextLevel.Price then
			Panel.Upgrade.BackgroundColor3 = UpgradeColor
		else
			Panel.Upgrade.BackgroundColor3 = OffColor
		end
	else
		rows.Damage.Next.Text = ""
		rows.Range.Next.Text = ""
		rows.Cooldown.Next.Text = ""
		Panel.Upgrade.Text = "Max level"
		Panel.Upgrade.BackgroundColor3 = OffColor
	end
	Panel.Sell.Text = "Sell  $"..TowerUtil.GetSellValue(tower.Type,tower.Level)
end

local function Request(remote)
	if busy or not selectedId then return end
	busy = true
	local success,msg = remote:InvokeServer(selectedId)
	busy = false
	if not success then
		ShowError(msg)
	end
end

function TowerPanel.Open(model)
	local id = model:GetAttribute("TowerId")
	if not Render.Towers[id] then return end
	selectedId = id
	outline.Adornee = model
	outline.Enabled = true
	Panel.Visible = true
	Refresh()
end

function TowerPanel.Close()
	selectedId = nil
	outline.Adornee = nil
	outline.Enabled = false
	ring:Hide()
	if Panel then
		Panel.Visible = false
	end
end

function TowerPanel.Init(hud,showError)
	Panel = hud:WaitForChild("TowerPanel")
	ShowError = showError
	Panel.Close.Activated:Connect(TowerPanel.Close)
	Panel.Upgrade.Activated:Connect(function()
		Request(Remotes.UpgradeTower)
	end)
	Panel.Sell.Activated:Connect(function()
		Request(Remotes.SellTower)
	end)
	Render.TowerChanged.Event:Connect(function(id)
		if id == selectedId then Refresh() end
	end)
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		if selectedId then Refresh() end
	end)
end

return TowerPanel
