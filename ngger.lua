local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer
local MAX_PLAYERS = 4

-- Function to fetch server list using Synapse's optimized request method
local function getServers(cursor)
    local url = "https://games.roproxy.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    -- syn.request is specific to Synapse and much more reliable
    local response = syn.request({
        Url = url,
        Method = "GET"
    })

    if response.Success then
        return HttpService:JSONDecode(response.Body)
    end
    return nil
end

local function hop()
    print("Synapse: Searching for small server...")
    local nextCursor = nil
    
    while true do
        local data = getServers(nextCursor)
        if not data then break end
        
        for _, server in ipairs(data.data) do
            -- Find server with 1-4 players that isn't the current one
            if server.playing >= 1 and server.playing <= MAX_PLAYERS and server.id ~= game.JobId then
                print("Server found (" .. server.playing .. " players). Teleporting...")
                
                -- Synapse handles the teleport handshake automatically
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                return
            end
        end
        
        nextCursor = data.nextPageCursor
        if not nextCursor then break end
        task.wait(0.1) -- Small delay to prevent request throttling
    end
    warn("Synapse: No servers found. Retrying soon...")
end

-- Monitor for player count
Players.PlayerAdded:Connect(function()
    if #Players:GetPlayers() > MAX_PLAYERS then
        hop()
    end
end)

-- Execute immediately if the server you just joined is too full
if #Players:GetPlayers() > MAX_PLAYERS then
    hop()
end

print("Synapse Server Hopper Loaded. Limit: " .. MAX_PLAYERS)
