local pNames = {"TouchPart1", "TouchPart2", "TouchPart3", "TouchPart4", "TouchPart5", "TouchPart7"}
local p = game.Players.LocalPlayer
local rs = game:GetService("RunService")
local data = {}
local replaying = false
local idx = 1

-- Auto-Record first 10 seconds of player movement to use as ghost path
task.spawn(function()
    for i = 1, 600 do -- approx 10s at 60fps
        local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if root then table.insert(data, root.CFrame) end
        rs.Heartbeat:Wait()
    end
    replaying = true
end)

rs.Heartbeat:Connect(function()
    local char = p.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local target = root.CFrame
    if replaying and #data > 0 then
        target = data[idx]
        idx = (idx % #data) + 1
    end
    
    local offset = math.sin(tick() * 15) * 3
    for _, n in pairs(pNames) do
        local part = workspace:FindFirstChild(n, true)
        if part and part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = true
            part.CFrame = target * CFrame.new(0, offset, 0)
        end
    end
end)
