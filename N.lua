-- Generated Macro Script
local player = game:GetService('Players').LocalPlayer

-- Wait 2 seconds after game loads
task.wait(2)

local function click(btn)
    if getconnections then
        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
    end
end

task.wait(0.599)
pcall(function() click(player.PlayerGui["WheelGui"]["WheelButton"]) end)

task.wait(2.518)
pcall(function() click(player.PlayerGui["WheelGui"]["WheelFrame"]["ScrollingFrame"]["YellowBalloon"]["YellowButton"]) end)

task.wait(0.780)
pcall(function() click(player.PlayerGui["WheelGui"]["AreYouSureFrame"]["Frame"]["YesButton"]) end)

task.wait(0.1) -- Safety wait
