local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script.Parent:WaitForChild("Modules")
local HUD = require(Modules:WaitForChild("HUD"))
local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HUD")
HUD.Start(gui)

ContentProvider:PreloadAsync({ReplicatedStorage:WaitForChild("Assets")})

local Render = require(Modules:WaitForChild("Render"))
local VFX = require(Modules:WaitForChild("VFX"))
local PlacementUI = require(Modules:WaitForChild("PlacementUI"))

Render.Start()
VFX.Start()
PlacementUI.Start(gui)
