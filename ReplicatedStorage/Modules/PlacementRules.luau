local PathUtil = require(script.Parent.PathUtil)
local Config = require(script.Parent.Config)

local Flat = PathUtil.Flat

local PlacementRules = {}
PlacementRules.__index = PlacementRules

function PlacementRules.new(path,decorFolder)
	local self = setmetatable({},PlacementRules)
	self.Path = path
	self.Decor = {}

	local first = path.Points[1]
	self.MinX,self.MaxX,self.MinZ,self.MaxZ = first.X,first.X,first.Z,first.Z
	for _,p in pairs(path.Points) do
		if p.X < self.MinX then self.MinX = p.X end
		if p.X > self.MaxX then self.MaxX = p.X end
		if p.Z < self.MinZ then self.MinZ = p.Z end
		if p.Z > self.MaxZ then self.MaxZ = p.Z end
	end

	if decorFolder then
		for _,part in pairs(decorFolder:GetChildren()) do
			self:AddDecor(part)
		end
		decorFolder.ChildAdded:Connect(function(part)
			self:AddDecor(part)
		end)
	end
	return self
end

function PlacementRules:AddDecor(part)
	if part:IsA("BasePart") then
		self.Decor[part] = {
			Position = Flat(part.Position),
			Radius = math.max(part.Size.X,part.Size.Z) / 2 + Config.DecorSpacing,
		}
	end
end

function PlacementRules:Check(pos,towers)
	local m = Config.BuildMargin
	if pos.X < self.MinX - m or pos.X > self.MaxX + m or pos.Z < self.MinZ - m or pos.Z > self.MaxZ + m then
		return false,"Can't place there"
	end
	local flat = Flat(pos)
	for _,d in pairs(self.Decor) do
		if (d.Position - flat).Magnitude < d.Radius then
			return false,"Something's in the way"
		end
	end
	if self.Path:DistanceToPath(pos) < Config.PathSpacing then
		return false,"Can't place on the path"
	end
	for _,t in pairs(towers) do
		if (Flat(t.Position) - flat).Magnitude < Config.TowerSpacing then
			return false,"Too close to another tower"
		end
	end
	return true
end

return PlacementRules
