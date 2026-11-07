local Template = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("RangeRing")

local RangeRing = {}
RangeRing.__index = RangeRing

function RangeRing.new(color)
	local self = setmetatable({},RangeRing)
	self.Part = Template:Clone()
	self.Part.Color = color
	return self
end

function RangeRing:SetColor(color)
	self.Part.Color = color
end

function RangeRing:Show(pos,range)
	self.Part.Size = Vector3.new(0.15,range * 2,range * 2)
	self.Part.CFrame = CFrame.new(pos + Vector3.new(0,0.1,0)) * CFrame.Angles(0,0,math.rad(90))
	self.Part.Parent = workspace
end

function RangeRing:Hide()
	self.Part.Parent = nil
end

return RangeRing
