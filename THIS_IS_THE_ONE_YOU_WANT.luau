--Forgot it had to be a round system for part 2

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
local MarketPlaceService = game:GetService('MarketplaceService')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local BadgeService = game:GetService('BadgeService')
local Analytics = game:GetService('AnalyticsService')

local ServerModules = ServerStorage.Modules

local Modules = ReplicatedStorage.Modules
local Network = ReplicatedStorage.Network

local Signal = require(Modules.GoodSignal)
local Networking = require(Modules.Networking)
local GridHandler = require(Modules.UiTiles)
local Tweener = require(Modules.UiEffects.Tweener)

local Profiles = require(ServerModules.Profiles)

local Maid = require(Modules.Maid)

local Bindables = Network.Bindables
local BindableEvents = Bindables.Events

local Screen = workspace.Screen
local ScreenGui = Screen.SurfaceGui

local ScreenGrid = ScreenGui.Grid
local ScreenIntermissionDisplay = ScreenGui.Intermission
local ScreenBar = ScreenGui.Bar

local DefaultThinkingTime = 5
local DefaultRememberTime = 5

local ActualScreenGrid = GridHandler.new(ScreenGrid,false,0)

local TriggerEvent = Networking.GetConnection("EventTrigger")
local UpdateGrid = Networking.GetConnection("UpdateGrid")
local GetInGame = Networking.GetConnection("GetInGame")
local DisplaySelection = Networking.GetConnection("DisplayRoundSelection")
local SendChatMessage = Networking.GetConnection("SendChatMessage")
local SendNotification = Networking.GetConnection("DisplayNotification")
local DisplayCards = Networking.GetConnection("DisplayCards")
local FlipCard = Networking.GetConnection("FlipCard")
local DoCamera = Networking.GetConnection("CameraShow")

local SetNextRoundEvent = BindableEvents.SetNextRound
local PlayerAdded = BindableEvents.PlayerAdded
local PlayerLeft = BindableEvents.PlayerLeft
local RevivePlayer = BindableEvents.Revive


local CorrectSound = SoundService.Correct
local WrongSound = SoundService.Wrong
local WonSound = SoundService.Winner

local Confetti = workspace.ConfettiStand

local Chairs = workspace.Chairs
local AvailableChairs = Chairs:GetChildren()

local RoundMaid = Maid.new()

local PlayerChairs = {}
local PeopleInGame = {}
local PickedRounds = {}
local PlayerSizes = {}


local DidComplete = Signal.new()

local ActivePlayer
local ActiveGamemode

local CorrectAnswer
local CurrentAnswer
local SpeedIncrease = 0


local IntermissionLength = 10
local SelectionLength = 5
local SelectionPause = 1

local BackLight = workspace.Backlight.SurfaceLight

local InGame = false

local DifficultyLabels = {

	[1] = {"Super Easy",Color3.fromRGB(0,255,0),2},
	[2] = {"Easy",Color3.fromRGB(98, 255, 0),4},
	[3] = {"Moderate",Color3.fromRGB(255, 255, 0),6},
	[4] = {"Hard",Color3.fromRGB(255, 0, 0),8},
	[5] = {"Insane",Color3.fromRGB(255, 102, 0),10},
	[6] = {"Expert",Color3.fromRGB(0, 255, 255),12},
	[8] = {"Mindmelting",Color3.fromRGB(255, 0, 221),14},
	[9] = {"Impossible", Color3.fromRGB(170, 0, 255),20}

}

local Colours = {}

local MinPlayers = 1

--[[if RunService:IsStudio() then
	
	MinPlayers = 1
	
end]]--

local PickerFunctions = {
	
	Order = function(Difficulty)
		
		local Current = 0

		CorrectAnswer = {}
		Colours = {}
		
		
		
		repeat

			for i = 1,4 do



				if math.random(1,5) == 2 then
					
					if CorrectAnswer[Current-1] then
						--table.insert(Colours)
						if CorrectAnswer[Current - 1] == i then
							
							continue
							
						end
					end
					
					table.insert(CorrectAnswer,i)

					Current += 1
					
				end

				if Current >= Difficulty then
					break
				end

			end

		until Current >= Difficulty

		
		
	end,
	
	Pattern = function(Difficulty)
		
		local Current = 0

		CorrectAnswer = {}

		
		repeat

			for i = 1,GridHandler.GetGridAmount(Difficulty) do



				if math.random(1,5) == 2 and not CorrectAnswer[i] then
					
					
					CorrectAnswer[i] = true

					Current += 1

				end

				if Current >= Difficulty then
					break
				end

			end

		until Current >= Difficulty
		
	
		
	end,
	
	Shuffle = function(Difficulty)
		
		CorrectAnswer = math.random(1,3)
		
	end,
}

local CheckerFunctions = {
	
	Order = function()
		
		for i,v in CorrectAnswer do
			
			if CurrentAnswer[i] then
				
				if CurrentAnswer[i] ~= v then
					
					return 0
					
				end
			else
				
				return false
				
			end
			
		end
		
		for i,v in CurrentAnswer do
			
			if CorrectAnswer[i] then
				
				if CorrectAnswer[i] ~= v then
					
					return 0
					
				end
			else
				return false
			end
			
		end
		
		

		return true
		
	end,

	Pattern = function()
		
		for i,v in CurrentAnswer do

			if not CorrectAnswer[i] then
				return false
			end

		end

		for i,v in CorrectAnswer do

			if not CurrentAnswer[i] then	
				return false
			end

		end
		
		return true
	end,

	Shuffle = function()
		
		if CurrentAnswer == CorrectAnswer then
			return true
		end
		
		return 0
	end,
	
	
}

local function GetDifficulty(difficulty)
	
	local Current = DifficultyLabels[1]
	local Last = Current[3]
	
	for index,info in DifficultyLabels do
		
		if difficulty >= info[3] and Last < info[3] then
			
			Current = info
			Last = info[3]
			
		end
		
	end
	
	return Current[1],Current[2]
end

local function teleportToChair(player:Player)

	if player then
		if table.find(PeopleInGame,player) then

			local chair = PlayerChairs[player]

			if chair then

				if player.Character then

					--print("Character exists")

					local Humanoid:Humanoid = player.Character:FindFirstChild('Humanoid')

					if Humanoid then

						if Humanoid.Health >= 0 then

							Humanoid.Sit = true

							pcall(function()
								player.Character:PivotTo(chair.Union.CFrame * CFrame.new(0,PlayerSizes[player] / 2,0) * CFrame.Angles(0,math.rad(-90),0))
								player.Character.HumanoidRootPart.Anchored = true
								player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
							end)




						end

					end
				end
			end
		end
	end

end

local function teleportToStand(player:Player)

	if player then
		if table.find(PeopleInGame,player) then

			if player.Character then

				--print("Character exists")

				local Humanoid:Humanoid = player.Character:FindFirstChild('Humanoid')

				if Humanoid then

					if Humanoid.Health >= 0 then

						Humanoid.Sit = false

						pcall(function()
							player.Character:PivotTo(workspace.End.CFrame * CFrame.new(0,PlayerSizes[player] + (workspace.End.Size.Y / 2),0))
						end)

					end
				end
			end
		end
	end


end

local function RemovePlayer(player:Player)

	local Position = table.find(PeopleInGame,player)
	
	
	if Position then

		table.remove(PeopleInGame,Position)

	end

	local Chair = PlayerChairs[player]

	if Chair then

		table.insert(AvailableChairs,Chair)
		PlayerChairs[player] = nil
	end

	if ActivePlayer == player then
		
		DidComplete:Fire(false)
		
	end

end

local function AddPlayer(player:Player)
	
	if not player:HasTag("FullyLoaded") or player:HasTag('CantJoin') then
		return
	end
	
	local Character = player.Character
	
	if not Character then
		
		return
		
	end
	
	local Humanoid = Character:FindFirstChild('Humanoid')
	
	if not Humanoid then
		return
	end
	
	if Humanoid.Health == 0 then
		return
	end
	
	table.insert(PeopleInGame,player)

	local ChairIndex = math.random(1,#AvailableChairs)
	local RandomChair = AvailableChairs[ChairIndex]

	table.remove(AvailableChairs,ChairIndex)

	PlayerChairs[player] = RandomChair

	teleportToChair(player)

end

local function FlashLights(colour,length)

	local DefaultC = BackLight.Color
	
	BackLight.Color = colour
	
	task.wait(length or 2)
	
	BackLight.Color = DefaultC
	
end

local function KillPlayer(player)
	
	if player then
	
		if table.find(PeopleInGame,player) then
			
			local Char = player.Character
			
			if Char then
				
				local Humanoid = Char:FindFirstChild('Humanoid')
				
				if Humanoid then
					
					Humanoid.Health = 0
					
					local explosion = Instance.new("Explosion")
					explosion.BlastPressure = 10
					explosion.DestroyJointRadiusPercent = 0
					explosion.Parent = Char
					explosion.Position = Char:GetPivot().Position
					
					
				end
				
			end
			
		end
		
	end
	
	WrongSound:Play()
	FlashLights(Color3.fromRGB(255,0,0))
	
end



local function RewardPlayer(player)
	
	local profile = Profiles[player]

	if profile then
		profile:SetValue("Correct",profile.Data.Correct + 1)
	end
	
	
	
	CorrectSound:Play()
	FlashLights(Color3.fromRGB(0,255,0))
	
end

local DefaultOrderColours = {
	
	Color3.fromRGB(124, 124, 0),
	Color3.fromRGB(0, 124, 0),
	Color3.fromRGB(124, 0, 0),
	Color3.fromRGB(0, 41, 124),
	
}

local FlashingOrderColours = {
	
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 208, 255),
	
}

local OrderSounds = {
	
	SoundService.Tiles.A4,
	SoundService.Tiles.C4,
	SoundService.Tiles.E4,
	SoundService.Tiles.G4
	
}

local Rounds = {
	
	Order = function(Difficulty)
		
		ScreenGui.ZOffset = 1
		
		ActualScreenGrid:AddTiles(3)
		
		for i = 1,4 do
			
			ActualScreenGrid:ChangeColour(i,DefaultOrderColours[i])
			
		end
		
		ScreenGrid.Visible = true
		
		
		
		ScreenBar.Size = UDim2.fromScale(1.1,0.05)
		
		task.wait(1)
		
		ScreenBar:TweenSize(UDim2.fromScale(0,0.05),Enum.EasingDirection.In,Enum.EasingStyle.Linear, DefaultRememberTime - SpeedIncrease)
		
		
		for _,tile in CorrectAnswer do
			
			ActualScreenGrid:ChangeColour(tile,FlashingOrderColours[tile])
			OrderSounds[tile]:Play()
			
			task.wait(((DefaultRememberTime - SpeedIncrease) / #CorrectAnswer) / 2)
			
			OrderSounds[tile]:Stop()
			ActualScreenGrid:ChangeColour(tile,DefaultOrderColours[tile])
			
			task.wait(((DefaultRememberTime - SpeedIncrease) / #CorrectAnswer) / 2)
			
		end


		UpdateGrid:FireClient(ActivePlayer,3)
		
	end,

	Pattern = function(Difficulty)
		
		
		ScreenGui.ZOffset = 1
		
		
		ActualScreenGrid:AddTiles(Difficulty)
		
		
		ScreenGrid.Visible = true
		
		
		ActualScreenGrid:ChangeColour(CorrectAnswer,Color3.fromRGB(0,255,0))
		
		ScreenBar.Size = UDim2.fromScale(1.1,0.05)
		ScreenBar:TweenSize(UDim2.fromScale(0,0.05),Enum.EasingDirection.In,Enum.EasingStyle.Linear,DefaultRememberTime-SpeedIncrease)
		
		task.wait(DefaultRememberTime - SpeedIncrease)
		
		ActualScreenGrid:ChangeColour(CorrectAnswer,Color3.fromRGB(255,0,0))
		
		UpdateGrid:FireClient(ActivePlayer,Difficulty)
		
		
	end,

	Shuffle = function(Difficulty,Speed)
		
		ScreenGui.ZOffset = -1
		
		local Starting = math.random(1,3)
		
		if Starting == CorrectAnswer then
			
			repeat 
				Starting = math.random(1,3)
			until Starting ~= CorrectAnswer
			
		end
		
		ScreenGrid.Visible = false
		
		ScreenBar.Size = UDim2.fromScale(1.1,0.05)
		
		DisplayCards:Fire(Difficulty,CorrectAnswer,Starting,Speed)
		
		task.wait(4)
	
		local WaitingTime = ((2 - Speed)) * Difficulty --+ (0.25 - (SpeedIncrease / 10))) * Difficulty
		WaitingTime += 0.1
		
		ScreenBar:TweenSize(UDim2.fromScale(0,0.05),Enum.EasingDirection.In,Enum.EasingStyle.Linear,  WaitingTime)
		
		task.wait(WaitingTime)
		
	end,
	
}

local PossibleRounds = {}

for name,round in Rounds do
	
	if typeof(round) == "function" then
		if tostring(name) and not tonumber(name) then
			
			table.insert(PossibleRounds,name)
			
		end
	end
	
end

function Rounds.Vote()
	
	
	local PickedRound = PickedRounds[1] or PossibleRounds[math.random(1,#PossibleRounds)]
	
	if PickedRounds[1] then
		
		local Name = PickedRound.Name
		
		PickedRound = PickedRound.Round
		
		
		table.remove(PickedRounds,1)
		
		SendNotification:Fire("This round was chosen by "..Name,nil,4)
		--SendChatMessage:Fire("This round was chosen by "..Name)
	else
		
		if PickedRound == ActiveGamemode then
			
			repeat
				
				PickedRound = PossibleRounds[math.random(1,#PossibleRounds)]
				
			until PickedRound ~= ActiveGamemode
			
		end
		
	end
	
	
	
	if not table.find(PossibleRounds,PickedRound) then
		
		PickedRound = PossibleRounds[math.random(1,#PossibleRounds)]
		
	end
	

	
	DisplaySelection:Fire(PickedRound,SelectionLength,SelectionPause)
	
	task.wait(SelectionLength + SelectionPause)
	
	if PickedRound == "Order" then
		ScreenIntermissionDisplay.TextLabel.Text = "The round is: Colours!"
	elseif PickedRound == "Shuffle" then
		
		ScreenIntermissionDisplay.TextLabel.Text = "The round is: Cards!"
	else
		
		ScreenIntermissionDisplay.TextLabel.Text = "The round is: "..PickedRound.."!"
	end
	
	
	
	task.wait(2)
	
	ActiveGamemode = PickedRound
	
	
	Rounds.Run()
	
	
end

local AmountOfPeople = #Players:GetPlayers()

function Rounds.Run()
	
	InGame = true
	
	AvailableChairs = Chairs:GetChildren()
	
	
	for _,player in Players:GetPlayers() do
		
		AddPlayer(player)
		
	end
	
	task.wait(1)
	
	ActivePlayer = nil
	SpeedIncrease = 0
	local Difficulty = 2
	
	
	
	ScreenIntermissionDisplay.Visible = false
	
	if ActiveGamemode == "Pattern" then
		ScreenGui.Tip.Text = "Memorize this pattern"
	elseif ActiveGamemode == "Order" then
		ScreenGui.Tip.Text = "Watch the colours flash"
	elseif ActiveGamemode == "Shuffle" then
		ScreenGui.Tip.Text = "Follow the correct card"
	end
	
	AmountOfPeople = #Players:GetPlayers()
	
	while (AmountOfPeople < 2 and #PeopleInGame > 0) or (AmountOfPeople >= 2 and #PeopleInGame > MinPlayers) do
		
		
		for _,player in PeopleInGame do
			
			
			
			local profile = Profiles[player]
			local PlayerDifficulty = Difficulty
			local PlayerSpeed = SpeedIncrease
			if profile then
				
				
				local HasImpossible = profile.Data.GivenImpossibles[1]
				

				if HasImpossible  then

					PlayerDifficulty = 50
					PlayerSpeed = 1
					
					if HasImpossible.Server ~= game.JobId then
						SendNotification:FireClient(player,HasImpossible.Name.." gave you an impossible challenge!" ,Color3.fromRGB(255,0,0),3)
					end

					table.remove(profile.Data.GivenImpossibles,1)
				end
				
			end
			
			
			
			
			local difficultyText,difficultyColour = GetDifficulty(PlayerDifficulty)

			ScreenGui.Difficulty.Text = difficultyText
			ScreenGui.Difficulty.TextColor3 = difficultyColour

			ScreenGui.PlayerName.Text = player.DisplayName
		
			ScreenGui.Tip.Visible = true
			ScreenGui.PlayerName.Visible = true
			ScreenGui.Difficulty.Visible = true
			
			CurrentAnswer = {}
			CorrectAnswer = {}
			
			ActivePlayer = player
			
			teleportToStand(player)
			
			task.wait(0.5)
			
			--for _,v in PeopleInGame do
			if player then
				DoCamera:FireClient(player,true)
			end
				
			--end
			
			
			
			PickerFunctions[ActiveGamemode](PlayerDifficulty)
			
			
			
			Rounds[ActiveGamemode](PlayerDifficulty,PlayerSpeed)
			
			if table.find(PeopleInGame,ActivePlayer) then
				TriggerEvent:FireClient(ActivePlayer,ActiveGamemode,true)
			end
			
			if player then
				DoCamera:FireClient(player,false)
			end

			ScreenBar.Size = UDim2.fromScale(1.1,0.05)
			local T = Tweener.new(ScreenBar,TweenInfo.new(DefaultThinkingTime-SpeedIncrease,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{Size = UDim2.fromScale(0,0.05)})
			T:Play()
			local CanGo = true

			local t = task.delay((DefaultThinkingTime - SpeedIncrease) + 0.1,function()

				if CanGo then
					DidComplete:Fire(false)
				end
			end)
			
			if not table.find(PeopleInGame,player) then
				
				if CanGo then
					task.delay(0.05,function() --allows the wait to connect
						DidComplete:Fire(false)
					end)
					
					
					
				end
				
			end
			
			local Wassuccess = DidComplete:Wait()

			local success,notSuccess = pcall(function() --Just incas
				T:Cancel()
				task.cancel(t)
			end)

			CanGo = false

			if not success then
				warn(notSuccess)
			end
			
			if ActiveGamemode == "Shuffle" then
				
				task.wait(1)
				
			elseif ActiveGamemode == "Order" then
				
				task.wait(0.2)
			else
				
				task.wait(0.1)
				
			end
			
			
			
			TriggerEvent:FireClient(ActivePlayer,ActiveGamemode,false)

			if not Wassuccess then

				KillPlayer(ActivePlayer)
				
			else
				
				RewardPlayer(ActivePlayer)
				
			end
			
			ActivePlayer = nil
			
			task.wait(1)
			
			teleportToChair(player)
			
			
		end
		
		
		Difficulty += 1
		
		--if ActiveGamemode == "Shuffle" then
			
			SpeedIncrease += 0.025
		--else
			--SpeedIncrease += 0.05
		--end
		
		
		
		task.wait(1)
	end
	
	ScreenGui.ZOffset = 1
	
	InGame = false
	
	
	
	ScreenIntermissionDisplay.Visible = true
	ScreenGrid.Visible = false
	ScreenGui.Tip.Visible = true
	ScreenGui.PlayerName.Visible = false
	ScreenGui.Difficulty.Visible = false
	
	local Winner = PeopleInGame[1]
	
	

	ScreenIntermissionDisplay.TextLabel.TextColor3 = Color3.fromRGB(0,255,0)
	ScreenIntermissionDisplay.TextLabel.UIStroke.Enabled = true
	
	if Winner then
	
		ScreenIntermissionDisplay.TextLabel.Text = Winner.Name.." Won!"
		
		teleportToStand(Winner)
		
		if not BadgeService:UserHasBadgeAsync(Winner.UserId,1481177772940306) then
			
			BadgeService:AwardBadge(Winner.UserId,1481177772940306)
			Analytics:LogOnboardingFunnelStepEvent(Winner,3,"Won")
		end
		
		for i,v:ParticleEmitter in Confetti:GetChildren() do
			
			if v:IsA('ParticleEmitter') then
				
				v.Enabled = true
				
			end
			
		end
		
		if Winner.Character then
			
			local Animator:Animator = Winner.Character:FindFirstChild('Animator',true)
			
			if Animator then
				
				local thing = Animator:LoadAnimation(script.Winner)
				
				thing:Play()
				
			end
			
		end
		
		WonSound:Play()
		
		
		local profile = Profiles[Winner]

		if profile then
			profile:SetValue("Wins",profile.Data.Wins + 5)
		end
		
	else
		
		ScreenIntermissionDisplay.TextLabel.Text = "No one won!"
		
	end
	
	PeopleInGame = {}
	
	task.wait(4)
	
	if Winner then
		
		for i,v:ParticleEmitter in Confetti:GetChildren() do

			if v:IsA('ParticleEmitter') then

				v.Enabled = false

			end

		end
		
		pcall(function()
			Winner:LoadCharacter()
		end)
		
		
		
	end
	
end

function Rounds.Intermission()
	
	ScreenGrid.Visible = false
	ScreenIntermissionDisplay.Visible = true
	ScreenIntermissionDisplay.TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	ScreenIntermissionDisplay.TextLabel.UIStroke.Enabled = false
	
	if #Players:GetPlayers() < MinPlayers then
		ScreenIntermissionDisplay.TextLabel.Text = "Waiting for another Player \n (Invite your friend!)"
		task.wait(1)
		return
	end
	
	for i = IntermissionLength,0,-1 do
		
		ScreenIntermissionDisplay.TextLabel.Text = "Intermission: "..i
		
		task.wait(1)
		
	end
	
	if #Players:GetPlayers() < MinPlayers then
		ScreenIntermissionDisplay.TextLabel.Text = "Waiting for another Player \n (Invite your friend!)"
	else
		Rounds.Vote()
	end
	
end

SetNextRoundEvent.Event:Connect(function(name,round)
	
	table.insert(PickedRounds,{Name = name,Round = round})
	
end)

PlayerAdded.Event:Connect(function(player:Player)
	
	if player.Character then
		
		local RootPart = player.Character:WaitForChild('HumanoidRootPart')
		local Humanoid:Humanoid = player.Character:WaitForChild('Humanoid')
		
		PlayerSizes[player] = (0.5 * RootPart.Size.Y) + Humanoid.HipHeight
		
		if InGame then

			if not table.find(PeopleInGame,player) and #PeopleInGame >= MinPlayers and AmountOfPeople > 1 then

				MarketPlaceService:PromptProductPurchase(player,3287568278)

			end

		end	
		
		Humanoid.Died:Once(function()
			RemovePlayer(player)
		end)
		
	end
	
	player.CharacterAdded:Connect(function()
		
		local RootPart = player.Character:WaitForChild('HumanoidRootPart')
		local Humanoid:Humanoid = player.Character:WaitForChild('Humanoid')

		PlayerSizes[player] = (0.5 * RootPart.Size.Y) + Humanoid.HipHeight
		
		if InGame then
			
			if not table.find(PeopleInGame,player) and #PeopleInGame >= MinPlayers and AmountOfPeople > 1 then
				
				MarketPlaceService:PromptProductPurchase(player,3287568278)
				
			end
			
		end		
		
		Humanoid.Died:Once(function()
			RemovePlayer(player)
		end)
		
	end)
	
end)

PlayerLeft.Event:Connect(function(player:Player)
	
	RemovePlayer(player)
	
	if PlayerSizes[player] then

		PlayerSizes[player] = nil

	end
	
end)

GetInGame.OnServerInvoke = function()
	return #PeopleInGame
end

UpdateGrid.OnServerEvent:Connect(function(player,index)
	
	if typeof(index) ~= "number" then
		
		return
		
	end
	
	index = math.floor(index)
	
	if ActiveGamemode == "Pattern" and player == ActivePlayer then
		
		if CurrentAnswer[index] then
		
			CurrentAnswer[index] = nil
			ActualScreenGrid:ChangeColour(index,Color3.fromRGB(255,0,0))
			
		else
			
			CurrentAnswer[index] = true
			ActualScreenGrid:ChangeColour(index,Color3.fromRGB(0,255,0))
			
		end
		
	elseif ActiveGamemode == "Order" and player == ActivePlayer then
		
		if index < 5 and index > 0 then
			
			
			ActualScreenGrid:ChangeColour(index,FlashingOrderColours[index])
			
			table.insert(CurrentAnswer,index)
			task.delay(0.2,function()
				ActualScreenGrid:ChangeColour(index,DefaultOrderColours[index])
			end)

			
		end
		
		
		
		
		
	end
	
	local WasCorrect = CheckerFunctions[ActiveGamemode]()
	
	if WasCorrect == true then
		
		DidComplete:Fire(true)
		
	elseif WasCorrect == 0 then
		
		DidComplete:Fire(false)
	
	end
	
end)

FlipCard.OnServerEvent:Connect(function(player,index)
	
	if typeof(index) ~= "number" then
		
		return
		
	end
	
	index = math.floor(index)
	
	if player == ActivePlayer and ActiveGamemode == "Shuffle" then
		
		if index < 4 and index > 0 then
			
			FlipCard:Fire(index)	
			
			CurrentAnswer = index
			
			
			
			local WasCorrect = CheckerFunctions[ActiveGamemode]()
			
			if WasCorrect == true then

				DidComplete:Fire(true)

			elseif WasCorrect == 0 then

				DidComplete:Fire(false)

			end
			
		end
	end
end)

RevivePlayer.Event:Connect(function(player)
	
	if InGame and #PeopleInGame >= MinPlayers then
		
		if not table.find(PeopleInGame,player) then
		
			AddPlayer(player)
			return
		end
	end
	
	SendNotification:FireClient(player,"Your revive was too late, take 15 wins!",nil,5)
	
	local profile = Profiles[player]
	
	if profile then
		
		profile:SetValue("Wins",profile.Data.Wins + 15)
		
	end
	
end)

return Rounds
