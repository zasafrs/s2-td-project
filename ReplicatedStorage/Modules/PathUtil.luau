local PathUtil = {}
PathUtil.__index = PathUtil

function PathUtil.Flat(v)
	return Vector3.new(v.X,0,v.Z)
end

function PathUtil.FromFolder(folder)
	local waypoints = {}
	for _,v in pairs(folder:GetChildren()) do
		if v:IsA("BasePart") and tonumber(v.Name) then
			table.insert(waypoints,v)
		end
	end
	table.sort(waypoints,function(a,b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	assert(#waypoints > 1,"not enough waypoints")

	local self = setmetatable({},PathUtil)
	self.Points = {}
	self.Distances = {0}
	for i,v in ipairs(waypoints) do
		self.Points[i] = v.Position
		if i > 1 then
			self.Distances[i] = self.Distances[i-1] + (self.Points[i] - self.Points[i-1]).Magnitude
		end
	end
	self.Length = self.Distances[#self.Distances]
	return self
end

function PathUtil:CFrameAt(dist)
	if dist > self.Length then
		dist = self.Length
	end
	for i = 2,#self.Points do
		if dist <= self.Distances[i] or i == #self.Points then
			local a,b = self.Points[i-1],self.Points[i]
			local alpha = (dist - self.Distances[i-1]) / (self.Distances[i] - self.Distances[i-1])
			local pos = a:Lerp(b,alpha)
			return CFrame.lookAt(pos,pos + (b - a))
		end
	end
end


function PathUtil:DistanceToPath(pos)
	pos = PathUtil.Flat(pos)
	local closest = math.huge
	for i = 2,#self.Points do
		local a = PathUtil.Flat(self.Points[i-1])
		local b = PathUtil.Flat(self.Points[i])
		local steps = math.ceil((b - a).Magnitude)
		for s = 0,steps do
			local d = (a:Lerp(b,s / steps) - pos).Magnitude
			if d < closest then
				closest = d
			end
		end
	end
	return closest
end

return PathUtil
