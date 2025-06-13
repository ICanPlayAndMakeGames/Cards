local CardObject = require(script.Card)
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Maid = require(ReplicatedStorage.Maid)

local Cards = {}
Cards.__index = Cards

local MaxPerLayer = 3

function getCenteredGridCFrame(index: number, spacing: number): CFrame


	local YSpacing = index // (MaxPerLayer + 1)
	local XSpacing

	index -= (YSpacing * MaxPerLayer)

	if index == 1 then
		XSpacing = CFrame.new(0-spacing,0,0)
	elseif index == 2 then
		XSpacing = CFrame.new(0,0,0)
	elseif index == 3 then

		XSpacing = CFrame.new(0+spacing,0,0)

	end



	return XSpacing * CFrame.new(0,YSpacing * spacing,0)
end

function Cards.new(amount,parent)
	
	local self = setmetatable({},Cards)
	
	self.NumberOfCards = amount
	self.Cards = {}
	self._maid = Maid.new()
	
	for i = 1,self.NumberOfCards do
		local Card = CardObject.new(parent,getCenteredGridCFrame(i,0.75) * CFrame.new(0,0,-1.75) * CFrame.Angles(math.rad(-90),0,0))
		table.insert(self.Cards,Card)
		Card.Id = i
		self._maid:GiveTask(Card)
	end
	
	
	
	return self
end

function Cards:DisableAll(ignore)

	for i,v in self.Cards do

		local ClickDetector = v.Card:FindFirstChild('ClickDetector')

		if ClickDetector then

			ClickDetector:Destroy()

		end

		v.Clicked:DisconnectAll()

		if v ~= ignore then
			v.Flipped:DisconnectAll()
		end



	end

end

function Cards:FlipAll(trigger)

	for i,v in self.Cards do


		v:Flip(trigger)

	end

end

function Cards:GetCardFromId(id)
	
	for _,card in self.Cards do
		
		if card.Id == id then
			return card
		end
		
	end
	return nil
end

function Cards:GetOtherCard(ignore)
	
	local C = self.Cards[math.random(1,#self.Cards)]

	if C == ignore then

		repeat
			C = self.Cards[math.random(1,#self.Cards)]
		until C ~= ignore
	end

	return C
end

function Cards:SetCorrect(card,correct)
	
	if typeof(card) == "number" then

		card = self:GetCardFromId(card)

	end
	
	card:SetCorrect(correct)
	
end

function Cards:HideAll()
	
	for _,card in self.Cards do
		
		card:Hide()
		
	end
	
end

function Cards:ShowAll()

	for _,card in self.Cards do

		card:Show()

	end

end


function Cards:Swap(card1,speed,card2)

	if not speed then

		speed = 0

	end

	local Co = coroutine.running()

	if typeof(card1) == "number" then
		
		card1 = self:GetCardFromId(card1)
		
	end
	
	
	local card2 = card2 or self:GetOtherCard(card1)
	
	local StartingOffset = card1.CurrentOffset
	
	local RecordedId = card1.Id

	card1.Id = card2.Id
	card2.Id = RecordedId

	local RandomCardOffset = card2.CurrentOffset

	local Holder1 = Instance.new("NumberValue")
	local Holder2 = Instance.new("NumberValue")
	local Holder3 = Instance.new("NumberValue")



	self._maid.Holder1 = Holder1
	self._maid.Holder2 = Holder2
	self._maid.Holder3 = Holder3

	local MoveInfo = TweenInfo.new(1 - speed,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)

	local T = TweenService:Create(Holder1,MoveInfo,{Value = 0})
	T:Play()

	local T2 = TweenService:Create(Holder2,MoveInfo,{Value = RandomCardOffset.Position.X - StartingOffset.Position.X})
	local T3 = TweenService:Create(Holder3,MoveInfo,{Value = StartingOffset.Position.X - RandomCardOffset.Position.X})

	local T4 = TweenService:Create(Holder1,MoveInfo,{Value = 0})

	self._maid.Tween1 = T
	self._maid.Tween2 = T2
	self._maid.Tween3 = T3
	self._maid.Tween4 = T4

	self._maid.MoveCon = RunService.Heartbeat:Connect(function(dt)



		card1.CurrentOffset = StartingOffset * CFrame.new(Holder2.Value,Holder1.Value,0)
		card2.CurrentOffset = RandomCardOffset * CFrame.new(Holder3.Value,0,0)

		card1.Viewport:SetCFrame(card1.CurrentOffset)
		card2.Viewport:SetCFrame(card2.CurrentOffset)


	end) 

	T.Completed:Once(function()



		--self._maid.MoveCon = nil
		self._maid.Tween1 = nil

		task.wait(0.1 - (speed / 10))

		T2:Play()
		T3:Play()

	end)

	T3.Completed:Once(function()

		self._maid.Holder2 = nil
		self._maid.Holder3 = nil

		self._maid.Tween2 = nil
		self._maid.Tween3 = nil

		task.wait(0.1 - (speed / 10))

		T4:Play()

	end)

	T4.Completed:Once(function()


		self._maid.Holder1 = nil
		self._maid.Tween4 = nil

		self._maid.MoveCon = nil

		coroutine.resume(Co)

	end)

	coroutine.yield()

end

function Cards:RemoveAll()



	for i,v in Cards do

		v:Destroy()

		self.NumberOfCards -= 1
	end



end

return Cards
