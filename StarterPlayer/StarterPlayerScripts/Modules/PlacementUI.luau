local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local PlaceTower = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlaceTower")
local TowerModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towers")
local TowerStats = require(ReplicatedStorage.Modules.TowerStats)
local PlacementRules = require(ReplicatedStorage.Modules.PlacementRules)
local Render = require(script.Parent:WaitForChild("Render"))
local TowerPanel = require(script.Parent:WaitForChild("TowerPanel"))
local RangeRing = require(script.Parent:WaitForChild("RangeRing"))
local player = Players.LocalPlayer

local PlacementUI = {}

local Keys = {
	[Enum.KeyCode.One] = "ArcherTower",
	[Enum.KeyCode.Two] = "SwordTower",
}
local KeyText = {
	ArcherTower = "1",
	SwordTower = "2",
}

local Green = Color3.fromRGB(110,200,110)
local Red = Color3.fromRGB(220,90,80)

local rules = PlacementRules.new(Render.Path,workspace.Map:WaitForChild("Decor"))
local ring = RangeRing.new(Green)

local selected,ghost,conn,lastHit,tint
local rotation = 0
local busy = false
local touchMode = false
local Toast,Hint,Slots,TouchBar
local toastId = 0

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local function ShowError(msg)
	toastId += 1
	local id = toastId
	Toast.Text = msg or "Can't place there"
	Toast.Visible = true
	task.delay(2,function()
		if toastId == id then
			Toast.Visible = false
		end
	end)
end

local function CastRay(ray)
	local result = workspace:Raycast(ray.Origin,ray.Direction * 1000,params)
	if result then
		return result.Position
	end
end

local function MouseHit(screenPos)
	local cam = workspace.CurrentCamera
	if screenPos then
		return CastRay(cam:ScreenPointToRay(screenPos.X,screenPos.Y))
	end
	local m = UIS:GetMouseLocation()
	return CastRay(cam:ViewportPointToRay(m.X,m.Y))
end

local function CenterHit()
	local cam = workspace.CurrentCamera
	return CastRay(cam:ViewportPointToRay(cam.ViewportSize.X / 2,cam.ViewportSize.Y / 2))
end

local function CanPlaceHere(pos)
	return rules:Check(pos,Render.Towers) and (player:GetAttribute("Cash") or 0) >= TowerStats[selected].PlaceCost
end

local function SelectTower(screenPos)
	local cam = workspace.CurrentCamera
	local mouse = UIS:GetMouseLocation()
	if screenPos then

		mouse = Vector2.new(screenPos.X,screenPos.Y) + GuiService:GetGuiInset()
	end
	local best
	local bestDist = 40
	for _,model in pairs(workspace.ClientTowers:GetChildren()) do
		local point,onScreen = cam:WorldToViewportPoint(model:GetPivot().Position + Vector3.new(0,2,0))
		local dist = (Vector2.new(point.X,point.Y) - mouse).Magnitude
		if onScreen and dist < bestDist then
			best = model
			bestDist = dist
		end
	end
	if best then
		TowerPanel.Open(best)
	else
		TowerPanel.Close()
	end
end

local function MoveGhost(pos)
	lastHit = pos
	ghost:PivotTo(CFrame.new(pos) * CFrame.Angles(0,math.rad(rotation),0))
	local color = Red
	if CanPlaceHere(pos) then
		color = Green
	end
	tint.FillColor = color
	tint.OutlineColor = color
	ring:SetColor(color)
	ring:Show(pos,TowerStats[selected].Levels[1].Range)
end

local function SetTouchMode(on)
	touchMode = on
	Hint.Visible = not on
	TouchBar.Visible = on
end

local function StopPlacing()
	if conn then
		conn:Disconnect()
		conn = nil
	end
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	ring:Hide()
	Hint.Visible = false
	TouchBar.Visible = false

	for _,slot in pairs(Slots:GetChildren()) do
		local mark = slot:FindFirstChild("Selected")
		if mark then
			mark.Visible = false
		end
	end
	tint = nil
	selected = nil
	lastHit = nil
end

local function StartPlacing(name)
	StopPlacing()
	TowerPanel.Close()
	if not TowerModels:FindFirstChild(name) then return end

	selected = name
	ghost = TowerModels[name]:Clone()
	for _,v in pairs(ghost:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = math.max(v.Transparency,0.5)
			v.CanQuery = false
			v.CastShadow = false
		end
	end
	tint = ReplicatedStorage.Assets.Effects.GhostTint:Clone()
	tint.Parent = ghost
	ghost.Parent = workspace
	local mark = Slots:FindFirstChild(name) and Slots[name]:FindFirstChild("Selected")
	if mark then
		mark.Visible = true
	end
	params.FilterDescendantsInstances = {workspace.Map,workspace:FindFirstChild("Baseplate")}

	Hint.Cancel.Key.Text = KeyText[name]
	SetTouchMode(UIS.TouchEnabled and not UIS.MouseEnabled)
	if touchMode then
		lastHit = CenterHit()
	end

	conn = RunService.PreRender:Connect(function()
		local hit = lastHit
		if not touchMode then
			local m = UIS:GetMouseLocation() - GuiService:GetGuiInset()
			Hint.Position = UDim2.fromOffset(m.X + 18,m.Y + 18)
			hit = MouseHit()
		end
		if hit then
			MoveGhost(hit)
		end
	end)
end

local function Toggle(name)
	if selected == name then
		StopPlacing()
	else
		StartPlacing(name)
	end
end

local function Rotate()
	rotation = (rotation + 90) % 360
end

local function TryPlace()
	if busy or not selected or not lastHit then return end
	busy = true
	local placed,err = PlaceTower:InvokeServer(selected,lastHit,rotation)
	busy = false
	if placed then
		StopPlacing()
	else
		ShowError(err)
	end
end

function PlacementUI.Start(hud)
	Toast = hud:WaitForChild("Toast")
	Hint = hud:WaitForChild("PlaceHint")
	Slots = hud:WaitForChild("Towers")
	TouchBar = hud:WaitForChild("TouchBar")
	TowerPanel.Init(hud,ShowError)

	UIS.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.R then
			Rotate()
		elseif Keys[input.KeyCode] then
			Toggle(Keys[input.KeyCode])
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if selected then
				TryPlace()
			else
				SelectTower()
			end
		end
	end)

	UIS.TouchTap:Connect(function(positions,gpe)
		if gpe then return end
		if not selected then
			SelectTower(positions[1])
			return
		end
		SetTouchMode(true)
		local hit = MouseHit(positions[1])
		if hit then
			MoveGhost(hit)
		end
	end)

	for _,button in pairs(Slots:GetChildren()) do
		if button:IsA("ImageButton") then
			button.Activated:Connect(function()
				Toggle(button.Name)
			end)
		end
	end

	TouchBar.Place.Activated:Connect(TryPlace)
	TouchBar.Rotate.Activated:Connect(Rotate)
	TouchBar.Cancel.Activated:Connect(StopPlacing)
end

return PlacementUI
