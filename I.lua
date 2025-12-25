--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local localPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- 🔹 GROUP SETTINGS
local GROUP_ID = 35401545

-- 🔹 Roles to detect
local DETECT_ROLES = {
	["Analytics"] = true,
	["Administrator"] = true,
	["Developer"] = true,
	["Owner"] = true
}

-- 🔁 Rejoin function
local function rejoin()
	TeleportService:Teleport(PLACE_ID, localPlayer)
end

-- 🔍 Check player role
local function shouldRejoin(player)
	if player:IsInGroup(GROUP_ID) then
		local role = player:GetRoleInGroup(GROUP_ID)
		if DETECT_ROLES[role] then
			return true
		end
	end
	return false
end

-- 🔎 Check players already in server
for _, player in ipairs(Players:GetPlayers()) do
	if shouldRejoin(player) then
		rejoin()
		return
	end
end

-- 👀 Detect players joining later
Players.PlayerAdded:Connect(function(player)
	if shouldRejoin(player) then
		rejoin()
	end
end)
