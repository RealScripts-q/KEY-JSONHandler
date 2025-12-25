local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Detect request function
local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not requestFunc then error("No supported HTTP request function found! 😢") end

-- Minimal UI Setup
local LowServerFinder = Instance.new("ScreenGui")
LowServerFinder.Name = "ServerMonitorUI"
LowServerFinder.Parent = LocalPlayer:WaitForChild("PlayerGui")

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0, 250, 0, 70)
StatusFrame.Position = UDim2.new(0.5, -125, 0, 10)
StatusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = LowServerFinder

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 1, -10)
StatusLabel.Position = UDim2.new(0, 5, 0, 5)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 13
StatusLabel.TextWrapped = true
StatusLabel.Text = "Checking Server..."
StatusLabel.Parent = StatusFrame

local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    if cursor then url = url .. "&cursor=" .. cursor end
    local response = requestFunc({Url = url, Method = "GET"})
    if response and response.Body then return HttpService:JSONDecode(response.Body) end
end

local function monitorAndTeleport()
    while true do
        local currentCount = #Players:GetPlayers()
        
        -- Logic: Only act if current server is > 4
        if currentCount > 4 then
            StatusLabel.Text = string.format("Current: %d (Too High!)\nSearching for smaller...", currentCount)
            
            local cursor = nil
            local foundBetter = false
            
            local data = fetchServers(cursor)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    local targetCount = tonumber(server.playing)
                    
                    -- Only care about servers with 1-4 players
                    if targetCount >= 1 and targetCount <= 4 then
                        -- Check if the target is actually better (smaller) than current
                        if targetCount < currentCount then
                            StatusLabel.Text = string.format("Found Better: %d players\nTeleporting...", targetCount)
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                            foundBetter = true
                            break
                        end
                    end
                end
            end
            
            if not foundBetter then
                StatusLabel.Text = string.format("Current: %d\nNo better servers found yet.", currentCount)
            end
        else
            -- Current server is fine (1-4 players)
            StatusLabel.Text = string.format("Current Size: %d\n(Safe - No TP needed)", currentCount)
        end
        
        task.wait(10) -- Checks every 10 seconds to prevent lag/rate limits
    end
end

-- Run monitor
task.spawn(monitorAndTeleport)
