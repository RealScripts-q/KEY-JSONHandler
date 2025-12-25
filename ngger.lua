-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- SETTINGS
local MIN_PLAYERS = 1
local MAX_PLAYERS = 4
local CHECK_INTERVAL = 1 -- seconds

--------------------------------------------------
-- GUI (ALWAYS VISIBLE)
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AutoCheckingGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 420, 0, 120)
label.Position = UDim2.new(0.5, -210, 0, 20)
label.BackgroundTransparency = 0
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.ZIndex = 10
label.Parent = gui

--------------------------------------------------
-- CURRENT SERVER SIZE
--------------------------------------------------
local function getCurrentServerSize()
	return #Players:GetPlayers()
end

--------------------------------------------------
-- FIND SMALLEST SERVER (1–4 ONLY)
--------------------------------------------------
local function findSmallestServer(currentSize)
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
			local count = server.playing

			if server.id ~= game.JobId
				and count >= MIN_PLAYERS
				and count <= MAX_PLAYERS
				and count < bestCount then

				bestCount = count
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
			"Searching servers (1–4 players)..."

		local serverId, serverSize = findSmallestServer(currentSize)

		-- TELEPORT ONLY IF SMALLER SERVER EXISTS
		if serverId and serverSize < currentSize then
			label.Text =
				"Auto Checking (this helps it load)\n\n" ..
				"📉 Current Server: " .. currentSize .. "\n" ..
				"✅ Smaller Server Found: " .. serverSize .. "\n" ..
				"Teleporting..."

			task.wait(1.5)
			TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, player)
			return
		end

		-- COUNTDOWN
		for i = CHECK_INTERVAL, 1, -1 do
			label.Text =
				"Auto Checking (this helps it load)\n\n" ..
				"📉 Current Server: " .. currentSize .. " players\n" ..
				"No smaller server (1–4) found\n" ..
				"⏱ Rechecking in " .. i .. "s"

			task.wait(1)
		end
	end
end)
