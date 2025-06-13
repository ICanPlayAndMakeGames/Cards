local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Maid = require(ReplicatedStorage.Maid)
local Signal = require(ReplicatedStorage.GoodSignal)

local CustomViewport = require(script.CustomViewport)
local CardModel = script.Card

local FlipInfo = TweenInfo.new(1,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)

local Cards = {}
local MainFunctions = {}
local Card = {}
Card.__index = Card



function Card.new(viewport,offset)
	
	local self = setmetatable({},Card)
	self.Card = CardModel:Clone()
	self._maid = Maid.new()
	
	self.IsFlipped = false
	
	
	
	
	self.CurrentOffset = offset
	
	if not viewport then
		
		self.Flipped = Signal.new()
		self.Clicked = Signal.new()
		
		self._maid:GiveTask(self.Card.ClickDetector.MouseClick:Once(function(player)
			self.Card.ClickDetector:Destroy()

			if self.Clicked then

				self.Clicked:Fire()

			end

			self:Flip()

		end))
		
	else
		
		self.Card.ClickDetector:Destroy()
		
		
		
	end
	
	self.Viewport = CustomViewport.new(self.Card,self.CurrentOffset,viewport)
	
	self.Parent = self.Card.Parent
	
	self._maid:GiveTask(self.Viewport)
	
	
	
	
	
	
	table.insert(Cards,self)
	
	return self
end

function Card:SetCorrect(correct)
	
	if correct then
	
		self.Card.Result.Texture = "rbxassetid://81025087578194"
	else
		self.Card.Result.Texture = "rbxassetid://130175362707146"
	end
end

function Card:Hide()
	
	self.Parent = self.Card.Parent
	
	self.Card.Parent = nil
end

function Card:Show()
	
	self.Card.Parent = self.Parent
	
end

function Card:Flip(trigger)
	
	local Holder = Instance.new("NumberValue")
	
	local Target = -180
	
	if self.IsFlipped then
		Target = 180
		Holder.Value = 0
	end
	

	self._maid.Holder = Holder
	
	local T = TweenService:Create(Holder,FlipInfo,{Value = Target})
	T:Play()
	
	self._maid.Tween = T
	self.IsFlipped = not self.IsFlipped
	
	local StartingOffset = self.CurrentOffset
	
	self._maid.SpinCon = RunService.Heartbeat:Connect(function(dt)
		
		self.CurrentOffset = StartingOffset * CFrame.Angles(0,0,math.rad(Holder.Value))
		
		
		self.Viewport:SetCFrame(self.CurrentOffset)
		
		
		
	end) 
	
	T.Completed:Once(function()
		
		if trigger or trigger == nil then
			
			if self.Flipped then
				
				self.Flipped:Fire()
				
			end
			
		end
		
		
		
		self._maid.Holder = nil
		self._maid.SpinCon = nil
		self._maid.Tween = nil
		
	end)
	
end

function Card:Destroy()
	
	table.remove(Cards,table.find(Cards,self))
	
	if self.Clicked then
		
		self.Clicked:DisconnectAll()
		self.Clicked = nil
		
	end
	
	if self.Flipped then
		
		self.Flipped:DisconnectAll()
		self.Flipped = nil
		
	end
	
	
	
	self._maid:Destroy()
	
	
	
	
	
end



return Card
