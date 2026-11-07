local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local WaveSync = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WaveSync")
local player = Players.LocalPlayer

local HUD = {}

local PopInfo = TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
local BannerTime = 2
local StateBanners = {
	Lost = {"YOU LOST",Color3.fromRGB(255,90,90)},
	Won = {"VICTORY",Color3.fromRGB(120,255,120)},
}

local Cash,Lives,Wave,Banner,BannerScale

local function UpdateUI()
	Cash.Amount.Text = "$"..(player:GetAttribute("Cash") or 0)
	Lives.Amount.Text = workspace:GetAttribute("Lives") or 0
	Wave.Amount.Text = (workspace:GetAttribute("Wave") or 0).." / "..(workspace:GetAttribute("WaveCount") or 0)
end

local function ShowBanner(text,color,stay)
	Banner.Text = text
	Banner.TextColor3 = color
	BannerScale.Scale = 0
	Banner.Visible = true
	TweenService:Create(BannerScale,PopInfo,{Scale = 1}):Play()
	if stay then return end
	task.delay(BannerTime,function()
		if Banner.Text == text then
			Banner.Visible = false
		end
	end)
end

local function ShowState(value)
	if StateBanners[value] then
		ShowBanner(StateBanners[value][1],StateBanners[value][2],true)
	else
		Banner.Visible = false
	end
end

function HUD.Start(gui)
	local top = gui:WaitForChild("Top")
	Cash = top:WaitForChild("Cash")
	Lives = top:WaitForChild("Lives")
	Wave = top:WaitForChild("Wave")
	Banner = gui:WaitForChild("Banner")
	BannerScale = Banner:WaitForChild("BannerScale")

	UpdateUI()
	workspace:GetAttributeChangedSignal("Wave"):Connect(UpdateUI)
	workspace:GetAttributeChangedSignal("WaveCount"):Connect(UpdateUI)
	workspace:GetAttributeChangedSignal("Lives"):Connect(UpdateUI)
	player:GetAttributeChangedSignal("Cash"):Connect(UpdateUI)

	if StateBanners[workspace:GetAttribute("GameState")] then
		ShowState(workspace:GetAttribute("GameState"))
	end

	WaveSync.OnClientEvent:Connect(function(kind,value)
		if kind == "Wave" then
			if value > 0 then
				ShowBanner("WAVE "..value,Color3.new(1,1,1))
			end
		elseif kind == "State" then
			ShowState(value)
		end
	end)
end

return HUD
