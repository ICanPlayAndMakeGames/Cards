local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Maid = require(ReplicatedStorage.Maid)


local CustomViewport = {}
CustomViewport.__index = CustomViewport




function CustomViewport.new(object:BasePart|Model,offset:CFrame?,Frame:ViewportFrame?)
	
	local self = {}
	
	
	
	
	
	
	self._maid = Maid.new()
	self.offset = offset or CFrame.new(0,0,0)
	self.object = object
	
	if Frame then

		self.Camera = Frame:FindFirstChildOfClass('Camera') or Instance.new("Camera")
		
		if not Frame:FindFirstChildOfClass('Camera') then
			
			self._maid:GiveTask(self.Camera)
			
		end
		
		self.Camera.Parent = Frame
		
		Frame.CurrentCamera = self.Camera
		
		
	else
		self.Camera = workspace.CurrentCamera
	end
	
	object.Parent = Frame or self.Camera
	object.CanCollide = false
	object.Anchored = true

	
	self._maid:GiveTask(object)
	
	object:PivotTo(self.Camera.CFrame * self.offset)
	
	self._maid:GiveTask(self.Camera:GetPropertyChangedSignal('CFrame'):Connect(function()
		
		object:PivotTo(self.Camera.CFrame * self.offset)
		
	end))
	
	return setmetatable(self,CustomViewport)
end

function CustomViewport:SetCFrame(newCF:CFrame)
	
	self.offset = newCF
	self.object:PivotTo(self.Camera.CFrame * self.offset)
end

function CustomViewport:Destroy()
	
	self._maid:Destroy()
	
end

return CustomViewport
