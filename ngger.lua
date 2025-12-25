-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- PLAYER
local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- SETTINGS
local MAX_PLAYERS = 4
local CHECK_INTERVAL = 20 -- seconds between checks

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AutoServerCheckGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 450, 0, 120)
label.Position = UDim2.new(0.5, -225, 0.05, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255,255,255)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextWrapped = true
label.Parent = gui

--------------------------------------------------
-- CURRENT SERVER SIZE
--------------------------------------------------
local function getCurrentServerSize()
	return #Players:GetPlayers()
end

--------------------------------------------------
-- FIND SMALLER SERVER
--------------------------------------------------
local function findSmallerServer(currentSize)
	local cursor = nil
	local smallestServer = nil
	local smallestCount = currentSize

	repeat
		local url =
			"https://games.roblox.com/v1/games/" .. PLACE_ID ..
			"/servers/Public?sortOrder=Asc&limit=100"

		if cursor then
			url ..= "&cursor=" .. cursor
		end

		local success, response = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)

		if not success then
			return nil, nil
		end

		for _, server in ipairs(response.data) do
			if server.playing > 0
				and server.playing <= MAX_PLAYERS
				and server.playing < smallestCount
				and server.id ~= game.JobId then

				smallestCount = server.playing
				smallestServer = server.id
			end
		end

		cursor = response.nextPageCursor
	until not cursor

	return smallestServer, smallestCount
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
task.spawn(function()
	while true do
		local currentSize = getCurrentServerSize()

		local bestServer, bestSize = findSmallerServer(currentSize)

		if bestServer then
			label.Text =
				"Auto Checking (this helps it load)\n\n" ..
				"📉 Current Server: " .. currentSize .. " players\n" ..
				"📉 Better Server Found: " .. bestSize .. " players\n" ..
				"Teleporting..."

			task.wait(2)
			TeleportService:TeleportToPlaceInstance(PLACE_ID, bestServer, player)
			return
		else
			-- Countdown
			for i = CHECK_INTERVAL, 1, -1 do
				label.Text =
					"Auto Checking (this helps it load)\n\n" ..
					"📉 Current Server: " .. currentSize .. " players\n" ..
					"No smaller server found\n" ..
					"⏱ Rechecking in " .. i .. "s"

				task.wait(1)
			end
		end
	end
end)
