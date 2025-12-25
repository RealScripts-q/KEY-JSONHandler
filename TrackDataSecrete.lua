-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- 🛡️ SECURITY CONFIGURATION
local SECRET_SALT = "D7_x92!kLp_99_SecureTracker_V2" 

-- Configuration
local PLAYER = Players.LocalPlayer
local FOLDER_NAME = "TrackedData"
local DATA_FILE = FOLDER_NAME .. "/PlayerData.json"
local SESSION_FILE = FOLDER_NAME .. "/mostcreditearnedsessonid.json"
local STAFF_FILE = FOLDER_NAME .. "/StaffData.json"

-- Withdraw Settings
local WITHDRAW_THRESHOLD = 148000
local WithdrawRequestEvent = ReplicatedStorage:WaitForChild("WithdrawRequestEvent")

-- Group Settings
local GROUP_ID = 35401545
local DETECT_ROLES = {["Analytics"] = true, ["Administrator"] = true, ["Developer"] = true, ["Owner"] = true}

-- Data Variables
local sessionTime, totalTime, mostCreditsEarned, startCredits = 0, 0, 0, 0
local lastBalance = 0
local bestSessionID = ""
local totalStaffJoins, maxStaffInOneSession, peakStaffSessionID = 0, 0, ""
local sessionWithdrawn, allTimeWithdrawn = 0, 0
local sessionSpent, allTimeSpent = 0, 0
local hasWithdrawnThisSession = false
local sessionEarnedOffset = 0 

---------------------------------------------------------
-- 🛡️ ENCRYPTION & VALIDATION HELPERS
---------------------------------------------------------

local function generateHash(dataString)
	local hash = 0
	local combined = dataString .. SECRET_SALT
	for i = 1, #combined do
		hash = (hash * 31 + string.byte(combined, i)) % 2^32
	end
	return tostring(hash)
end

local function safeWrite(path, tableData)
	if not writefile then return end
	local json = HttpService:JSONEncode(tableData)
	local signature = generateHash(json)
	local finalSave = { Payload = json, Signature = signature }
	writefile(path, HttpService:JSONEncode(finalSave))
end

local function safeRead(path)
	if not isfile or not isfile(path) then return nil end
	local success, content = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if success and content.Payload and content.Signature then
		if generateHash(content.Payload) == content.Signature then
			return HttpService:JSONDecode(content.Payload)
		end
	end
	return nil
end

---------------------------------------------------------
-- UI CONSTRUCTION
---------------------------------------------------------
local screenGui = Instance.new("ScreenGui", PLAYER.PlayerGui)
screenGui.Name = "AdvancedTracker_V2_Updated"
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 280, 0, 410) 
mainFrame.Position = UDim2.new(1, -300, 0.5, -205) 
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.2
mainFrame.ZIndex = 10
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame)

-- CONFIRMATION OVERLAY
local confirmOverlay = Instance.new("Frame", mainFrame)
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
confirmOverlay.BackgroundTransparency = 0.05
confirmOverlay.ZIndex = 50
confirmOverlay.Visible = false
Instance.new("UICorner", confirmOverlay)

local confirmTitle = Instance.new("TextLabel", confirmOverlay)
confirmTitle.Size = UDim2.new(1, 0, 0, 80)
confirmTitle.Position = UDim2.new(0, 0, 0.1, 0)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Text = "FORCE OVERWRITE RESET?\nThis wipes JSON files\nand re-zeros all stats."
confirmTitle.TextColor3 = Color3.new(1, 1, 1)
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextSize = 13
confirmTitle.ZIndex = 51

local yesBtn = Instance.new("TextButton", confirmOverlay)
yesBtn.Size = UDim2.new(0, 220, 0, 45)
yesBtn.Position = UDim2.new(0.5, -110, 0.5, -10)
yesBtn.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
yesBtn.Text = "CONFIRM HARD OVERWRITE"
yesBtn.TextColor3 = Color3.new(1, 1, 1)
yesBtn.Font = Enum.Font.GothamBold
yesBtn.ZIndex = 51
Instance.new("UICorner", yesBtn)

local cancelBtn = Instance.new("TextButton", confirmOverlay)
cancelBtn.Size = UDim2.new(0, 220, 0, 35)
cancelBtn.Position = UDim2.new(0.5, -110, 0.5, 45)
cancelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
cancelBtn.Text = "CANCEL"
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.ZIndex = 51
Instance.new("UICorner", cancelBtn)

-- Main UI Components
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
topBar.ZIndex = 11

local function createTopBtn(text, color, pos)
	local btn = Instance.new("TextButton", topBar)
	btn.Size = UDim2.new(0, 25, 0, 25)
	btn.Position = pos
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 14
	Instance.new("UICorner", btn)
	return btn
end

local closeBtn = createTopBtn("X", Color3.fromRGB(150, 0, 0), UDim2.new(1, -30, 0, 2))
local minBtn = createTopBtn("-", Color3.fromRGB(100, 100, 100), UDim2.new(1, -60, 0, 2))

local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 80, 0, 30)
openBtn.Position = UDim2.new(1, -100, 0.5, 0)
openBtn.Visible = false
openBtn.Text = "OPEN STATS"
openBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", openBtn)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ZIndex = 11

local uiList = Instance.new("UIListLayout", scroll)
uiList.Padding = UDim.new(0, 5)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local function createLabel(name, color, size, order)
	local lbl = Instance.new("TextLabel", scroll)
	lbl.Name = name
	lbl.Size = UDim2.new(1, -25, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color or Color3.new(1, 1, 1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = size or 11
	lbl.LayoutOrder = order or 0
	lbl.ZIndex = 12
	return lbl
end

local function createButton(name, text, color, order)
	local btn = Instance.new("TextButton", scroll)
	btn.Name = name
	btn.Size = UDim2.new(1, -35, 0, 26)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.LayoutOrder = order or 100
	btn.ZIndex = 13
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	return btn
end

-- Labels
local sessionTimerLabel = createLabel("Timer", nil, 12, 1)
local sessionCredLabel  = createLabel("Credits", Color3.fromRGB(255, 215, 0), 12, 2)
local mostEarnedLabel   = createLabel("BestEarned", Color3.fromRGB(0, 255, 150), 11, 3)
createLabel("Div1", Color3.fromRGB(100, 100, 100), 9, 10).Text = "--- FINANCIAL HISTORY ---"
local withdrawnLabel    = createLabel("WD", Color3.fromRGB(85, 255, 127), 11, 11)
local spentLabel        = createLabel("SP", Color3.fromRGB(255, 80, 80), 11, 12)
local withdrawStatusLabel = createLabel("WS", Color3.fromRGB(200, 200, 200), 10, 13)
createLabel("Div2", Color3.fromRGB(100, 100, 100), 9, 20).Text = "--- STAFF TRACKING ---"
local staffCountLabel   = createLabel("SJ", Color3.fromRGB(255, 100, 100), 11, 21)
local peakStaffLabel    = createLabel("PS", Color3.fromRGB(255, 150, 150), 11, 22)
createLabel("Div3", Color3.fromRGB(100, 100, 100), 9, 30).Text = "--- SESSION INFO ---"
local totalTimerLabel   = createLabel("TotalTimer", Color3.fromRGB(180, 180, 180), 11, 31)
local jobIDLabel        = createLabel("JobID", Color3.fromRGB(150, 150, 150), 9, 32)

local tpBestCreds = createButton("TPBest", "TP TO BEST CREDIT SESSION", Color3.fromRGB(0, 120, 215), 40)
local tpPeakStaff = createButton("TPStaff", "TP TO PEAK STAFF SESSION", Color3.fromRGB(140, 0, 215), 41)
local resetBtn = createButton("Reset", "FORCE WIPE ALL DATA", Color3.fromRGB(180, 0, 0), 42)

---------------------------------------------------------
-- LOGIC & PERSISTENCE
---------------------------------------------------------

local function isStaff(player)
	local success, role = pcall(function() return player:GetRoleInGroup(GROUP_ID) end)
	return success and DETECT_ROLES[role] or false
end

local function loadData()
	local pData = safeRead(DATA_FILE)
	if pData then 
		totalTime, mostCreditsEarned = pData.TotalTime or 0, pData.MostCreditsEarned or 0 
		if pData.SessionProgress and pData.SessionProgress[game.JobId] then
			sessionEarnedOffset = pData.SessionProgress[game.JobId]
		end
	end
	local sData = safeRead(SESSION_FILE)
	if sData then bestSessionID = sData.SessionID or "" end
	local stData = safeRead(STAFF_FILE)
	if stData then
		totalStaffJoins, maxStaffInOneSession, peakStaffSessionID = stData.TotalJoins or 0, stData.MaxStaff or 0, stData.PeakID or ""
		allTimeWithdrawn, allTimeSpent = stData.AllTimeWithdrawn or 0, stData.AllTimeSpent or 0
	end
end

local function saveData(earned)
	local pData = safeRead(DATA_FILE) or {}
	pData.TotalTime, pData.MostCreditsEarned = totalTime, mostCreditsEarned
	pData.SessionProgress = pData.SessionProgress or {}
	pData.SessionProgress[game.JobId] = earned
	safeWrite(DATA_FILE, pData)
	safeWrite(SESSION_FILE, {SessionID = bestSessionID})
	safeWrite(STAFF_FILE, {
		TotalJoins = totalStaffJoins, MaxStaff = maxStaffInOneSession, PeakID = peakStaffSessionID,
		AllTimeWithdrawn = allTimeWithdrawn, AllTimeSpent = allTimeSpent
	})
end

---------------------------------------------------------
-- BUTTON ACTIONS & RESET
---------------------------------------------------------

tpBestCreds.MouseButton1Click:Connect(function()
	if bestSessionID ~= "" and bestSessionID ~= game.JobId then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, bestSessionID, PLAYER)
	end
end)

tpPeakStaff.MouseButton1Click:Connect(function()
	if peakStaffSessionID ~= "" and peakStaffSessionID ~= game.JobId then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, peakStaffSessionID, PLAYER)
	end
end)

resetBtn.MouseButton1Click:Connect(function()
	confirmOverlay.Visible = true
end)

cancelBtn.MouseButton1Click:Connect(function()
	confirmOverlay.Visible = false
end)

yesBtn.MouseButton1Click:Connect(function()
	-- 1. Explicitly zero out all script variables
	sessionTime, totalTime, mostCreditsEarned = 0, 0, 0
	totalStaffJoins, maxStaffInOneSession = 0, 0
	allTimeWithdrawn, allTimeSpent = 0, 0
	bestSessionID, peakStaffSessionID = "", ""
	
	-- 2. Force Write blank data to bypass hash checks
	if writefile then
		safeWrite(DATA_FILE, {TotalTime = 0, MostCreditsEarned = 0, SessionProgress = {}})
		safeWrite(SESSION_FILE, {SessionID = ""})
		safeWrite(STAFF_FILE, {TotalJoins = 0, MaxStaff = 0, PeakID = "", AllTimeWithdrawn = 0, AllTimeSpent = 0})
	end
	
	-- 3. Attempt physical file deletion
	if isfile then
		pcall(function() delfile(DATA_FILE) end)
		pcall(function() delfile(SESSION_FILE) end)
		pcall(function() delfile(STAFF_FILE) end)
	end
	
	yesBtn.Text = "OVERWRITING..."
	task.wait(1)
	TeleportService:Teleport(game.PlaceId, PLAYER)
end)

---------------------------------------------------------
-- UI DRAGGING
---------------------------------------------------------
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true dragStart = input.Position startPos = mainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

---------------------------------------------------------
-- MAIN LOOP
---------------------------------------------------------
loadData()
startCredits = (PLAYER:FindFirstChild("leaderstats") and PLAYER.leaderstats.Credits.Value) or 0
lastBalance = startCredits

task.spawn(function()
	while true do
		task.wait(1)
		sessionTime += 1
		totalTime += 1
		
		local currentCount = 0
		for _, p in ipairs(Players:GetPlayers()) do if isStaff(p) then currentCount += 1 end end
		if currentCount > maxStaffInOneSession then maxStaffInOneSession, peakStaffSessionID = currentCount, game.JobId end

		local leaderstats = PLAYER:FindFirstChild("leaderstats")
		local currentCredits = (leaderstats and leaderstats:FindFirstChild("Credits") and leaderstats.Credits.Value) or 0
		
		if currentCredits < lastBalance then
			local diff = lastBalance - currentCredits
			if diff ~= WITHDRAW_THRESHOLD then sessionSpent += diff allTimeSpent += diff end
		end
		lastBalance = currentCredits
		
		local earned = (currentCredits - startCredits) + sessionEarnedOffset
		if earned > mostCreditsEarned then mostCreditsEarned, bestSessionID = earned, game.JobId end
		
		sessionTimerLabel.Text = "⏱ Session: " .. string.format("%02d:%02d:%02d", math.floor(sessionTime/3600), math.floor((sessionTime%3600)/60), sessionTime%60)
		totalTimerLabel.Text   = "⌛ Total: " .. string.format("%02d:%02d:%02d", math.floor(totalTime/3600), math.floor((totalTime%3600)/60), totalTime%60)
		sessionCredLabel.Text  = "💰 Session Earned: " .. earned
		mostEarnedLabel.Text   = "🏆 Best Credits Ser: " .. mostCreditsEarned
		withdrawnLabel.Text    = string.format("🏦 Withdrawn: %dk (S) / %dk (All)", sessionWithdrawn/1000, allTimeWithdrawn/1000)
		spentLabel.Text        = string.format("💸 Spent: %dk (S) / %dk (All)", sessionSpent/1000, allTimeSpent/1000)
		staffCountLabel.Text   = "👮 Staff Seen (Total): " .. totalStaffJoins
		peakStaffLabel.Text    = "📈 Max Staff (Peak): " .. maxStaffInOneSession
		jobIDLabel.Text        = "🆔 ID: " .. game.JobId
		
		saveData(earned)
	end
end)
