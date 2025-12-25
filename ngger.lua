-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- SETTINGS
local MAX_PLAYERS = 4
local CHECK_INTERVAL = 1

--------------------------------------------------
-- GUI SETUP (FIXED)
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AutoCheckingGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 420, 0, 110)
label.Position = UDim2.new(0.5, -210, 0, 20)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255,255,255)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextWrapped = true
label.TextXAlignment = Left
label.TextYAlignment = Top
label.ZIndex = 10
label.Parent = gui

--------------------------------------------------
-- CURRENT SERVER SIZE
--------------------------------------------------
local function getCurrentServerSize()
	return #Players:GetPlayers()
end

--------------------------------------------------
-- FIND ABSOLUTE SMALLEST SERVER
--------------------------------------------------
local function findBestServer(currentSize)
	local cursor = nil
	local bestServerId = nil
	local bestCount = currentSize

	repeat
		local url =
			"https://games.roblox.com/v1/games/" .. PLACE_ID ..
			"/servers/Public?limit=100"

		if cursor then
			url ..= "&cursor=" .. cursor
		end

		local success, result = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)

		if not success or not result then
			break
		end

		for _, server in ipairs(result.data) do
			if server.id ~= game.JobId
				and server.playing > 0
				and server.playing <= MAX_PLAYERS
				and server.playing < bestCount then

				bestCount = server.playing
				bestServerId = server.id
			end
		end

		cursor = result.nextPageCursor
	until not cursor

	return bestServerId, bestCount
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
task.spawn(function()
	while true do
		local currentSize = getCurrentServerSize()

		label.Text =
			"Auto Checking (this helps it load)\n\n" ..
			"📉 Current Server: " .. currentSize .. " players\n" ..
			"Searching for smaller servers..."

		local serverId, serverSize = findBestServer(currentSize)

		if serverId and serverSize < currentSize then
			label.Text =
				"Auto Checking (this helps it load)\n\n" ..
				"📉 Current Server: " .. currentSize .. "\n" ..
				"✅ Found Smaller Server: " .. serverSize .. "\n" ..
				"Teleporting..."

			task.wait(1.5)
			TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, player)
			return
		end

		for i = CHECK_INTERVAL, 1, -1 do
			label.Text =
				"Auto Checking (this helps it load)\n\n" ..
				"📉 Current Server: " .. currentSize .. " players\n" ..
				"No smaller server found\n" ..
				"⏱ Rechecking in " .. i .. "s"

			task.wait(1)
		end
	end
end)
