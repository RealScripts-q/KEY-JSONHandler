--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId
local MAX_PLAYERS = 4

--// Check current server
local function getCurrentServerCount()
	return #Players:GetPlayers()
end

--// Get smallest server ≤ MAX_PLAYERS
local function findSmallServer()
	local cursor = ""
	local smallestServer = nil

	repeat
		local url = string.format(
			"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
			PLACE_ID,
			cursor ~= "" and "&cursor=" .. cursor or ""
		)

		local response = HttpService:JSONDecode(
			HttpService:GetAsync(url)
		)

		for _, server in ipairs(response.data) do
			if server.playing <= MAX_PLAYERS and server.id ~= game.JobId then
				if not smallestServer or server.playing < smallestServer.playing then
					smallestServer = server
				end
			end
		end

		cursor = response.nextPageCursor or ""
	until cursor == "" or smallestServer

	return smallestServer
end

--// Main logic
task.wait(5) -- wait for player list to load

if getCurrentServerCount() > MAX_PLAYERS then
	local targetServer = findSmallServer()

	if targetServer then
		TeleportService:TeleportToPlaceInstance(
			PLACE_ID,
			targetServer.id,
			player
		)
	else
		warn("No small server found")
	end
end
