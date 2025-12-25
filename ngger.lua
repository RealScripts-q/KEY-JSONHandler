local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer
local MaxPlayersAllowed = 4

-- Using a proxy because Roblox doesn't allow direct Http requests to its own domain
local ApiUrl = "https://games.roproxy.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

local function findAndHop()
    print("Searching for a smaller server...")
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(ApiUrl))
    end)

    if success and result and result.data then
        for _, server in ipairs(result.data) do
            -- Ensure we don't try to join the server we are already in
            if server.id ~= game.JobId and server.playing >= 1 and server.playing <= MaxPlayersAllowed then
                print("Found server with " .. server.playing .. " players. Hopping...")
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                return
            end
        end
        warn("No suitable servers found. Staying put for now.")
    else
        warn("API Error: Make sure your executor supports HttpGet and uses a proxy.")
    end
end

-- 1. Check immediately on script run
if #Players:GetPlayers() > MaxPlayersAllowed then
    findAndHop()
end

-- 2. Monitor for new players joining
Players.PlayerAdded:Connect(function()
    local currentCount = #Players:GetPlayers()
    print("Player joined. Current count: " .. currentCount)
    
    if currentCount > MaxPlayersAllowed then
        print("Server exceeded limit! Initiating hop...")
        findAndHop()
    end
end)

print("Auto-Hop script active. Limit: " .. MaxPlayersAllowed .. " players.")
