--[[
    Blox Community VN - Rebuild
    Source basis: user-provided raw.txt ideas/flows.

    Mục tiêu:
      - UI gọn, dễ bấm trên mobile.
      - Không dùng UI library bên ngoài.
      - Không dùng loadstring/HttpGet cho thư viện giao diện.
      - Có trạng thái lỗi thay vì toggle im lặng.
      - Tập trung vào Fishing, Chest, Fruit, Quest Navigation, ESP, Travel, Utility.

    Lưu ý:
      - Các remote nội bộ của game có thể đổi theo update.
      - Bản này không giả vờ đã được chạy trong client Roblox thật; chỉ kiểm tra cấu trúc
        và logic Lua tĩnh trong môi trường hiện tại.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:FindFirstChild("CommE")
local NetFolder = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
local FishReplicated = ReplicatedStorage:FindFirstChild("FishReplicated")
local FishingRequest = FishReplicated and FishReplicated:FindFirstChild("FishingRequest")
local JobsRemote = NetFolder and NetFolder:FindFirstChild("RF/JobsRemoteFunction")
local CraftRemote = NetFolder and NetFolder:FindFirstChild("RF/Craft")
local ServerBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")

local GuideModule
pcall(function()
    GuideModule = require(ReplicatedStorage:WaitForChild("GuideModule"))
end)

local GetWaterHeightAtLocation
pcall(function()
    local util = ReplicatedStorage:FindFirstChild("Util")
    local module = util and util:FindFirstChild("GetWaterHeightAtLocation")
    if module then
        GetWaterHeightAtLocation = require(module)
    end
end)

local Config = {
    QuestNavigation = false,
    AutoChest = false,
    AutoFruit = false,
    AutoFishing = false,
    AutoMaintainBait = false,
    AutoAnglerQuest = false,
    AutoSellFish = false,
    AutoESPPlayers = false,
    AutoESPChests = false,
    AutoESPFruits = false,
    AutoESPIslands = false,
    AntiAFK = true,
    NoFog = false,
    LowGraphics = false,
    ServerHopDelay = 0,
    TweenSpeed = 250,
    SelectedRod = "Fishing Rod",
    SelectedBait = "Basic Bait",
    MinBait = 3,
    AutoCatchChest = false,
    Team = "Pirates",
}

local Runtime = {
    Status = "Ready",
    LastError = "",
    LastQuestMob = "",
    ActiveLoops = {},
    ESPFolder = nil,
    OriginalFogEnd = Lighting.FogEnd,
    OriginalGlobalShadows = Lighting.GlobalShadows,
}

local Character
local Humanoid
local Root

local function refreshCharacter(char)
    Character = char
    Humanoid = char and char:FindFirstChildOfClass("Humanoid")
    Root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

refreshCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    refreshCharacter(char)
end)

local function safe(label, fn)
    local ok, result = xpcall(fn, function(err)
        return tostring(err) .. "\n" .. debug.traceback()
    end)
    if not ok then
        Runtime.LastError = label .. ": " .. tostring(result):split("\n")[1]
        Runtime.Status = "Error: " .. label
        warn("[Blox Community] " .. label .. "\n" .. tostring(result))
        return nil, result
    end
    return result
end

local function setStatus(text)
    Runtime.Status = tostring(text)
end

local function notify(title, text, duration)
    duration = duration or 3
    safe("Notify", function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration,
        })
    end)
end

local function getRoot(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart")
end

local function alive(model)
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function distanceTo(target)
    local r = Root
    if not r then return math.huge end
    local tr = getRoot(target)
    if not tr then return math.huge end
    return (r.Position - tr.Position).Magnitude
end

local function moveTo(target, offset)
    if not Root or not Root.Parent then return false end
    local cf
    if typeof(target) == "CFrame" then
        cf = target
    elseif typeof(target) == "Vector3" then
        cf = CFrame.new(target)
    elseif typeof(target) == "Instance" then
        local tr = getRoot(target)
        cf = tr and tr.CFrame or nil
    end
    if not cf then return false end
    offset = offset or Vector3.new(0, 3, 0)
    local dest = cf + offset
    local start = Root.CFrame
    local dist = (dest.Position - start.Position).Magnitude
    if dist <= 4 then
        Root.CFrame = dest
        return true
    end
    local speed = math.max(tonumber(Config.TweenSpeed) or 250, 20)
    local duration = math.clamp(dist / speed, 0.08, 8)
    local t0 = os.clock()
    while Root and Root.Parent and Humanoid and Humanoid.Health > 0 do
        local alpha = math.clamp((os.clock() - t0) / duration, 0, 1)
        Root.CFrame = start:Lerp(dest, alpha)
        if alpha >= 1 then break end
        RunService.Heartbeat:Wait()
    end
    return true
end

local function getDataFolder()
    return LocalPlayer:FindFirstChild("Data")
end

local function getLevel()
    local data = getDataFolder()
    local obj = data and data:FindFirstChild("Level")
    return obj and tonumber(obj.Value) or 1
end

local function getSeaName()
    local map = Workspace:GetAttribute("MAP")
    if map == "Sea1" then return "Sea 1" end
    if map == "Sea2" then return "Sea 2" end
    if map == "Sea3" then return "Sea 3" end
    return tostring(map or "Unknown")
end

local function getQuestMob()
    if GuideModule and GuideModule.Data and GuideModule.Data.QuestData then
        local q = GuideModule.Data.QuestData
        if q.Task then
            local text = tostring(q.Task)
            local match = text:match("Defeat%s+%d+%s+(.-)%s+%(" )
            if match and match ~= "" then return match end
        end
        if q.Name and tostring(q.Name) ~= "" then
            return tostring(q.Name)
        end
    end

    local main = PlayerGui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if quest and quest.Visible then
        local container = quest:FindFirstChild("Container")
        local title = container and container:FindFirstChild("QuestTitle")
        title = title and title:FindFirstChild("Title")
        local text = title and title.Text
        if text and text ~= "" then
            local match = text:match("Defeat%s+%d+%s+(.-)%s+%(") or text:match("Defeat%s+(.-)%s+%(")
            if match and match ~= "" then return match end
        end
    end
    return nil
end

local function findNearestByName(container, names)
    if not container then return nil end
    local lookup = {}
    if type(names) == "string" then
        lookup[names:lower()] = true
    elseif type(names) == "table" then
        for _, n in ipairs(names) do lookup[tostring(n):lower()] = true end
    end
    local best, bestD = nil, math.huge
    for _, obj in ipairs(container:GetChildren()) do
        if lookup[obj.Name:lower()] and obj:IsA("Model") then
            local r = getRoot(obj)
            if r and (not obj:FindFirstChildOfClass("Humanoid") or alive(obj)) then
                local d = distanceTo(obj)
                if d < bestD then
                    bestD = d
                    best = obj
                end
            end
        end
    end
    return best
end

local function getActiveQuestNPC()
    if not GuideModule or not GuideModule.Data or not GuideModule.Data.NPCList then return nil end
    local mob = getQuestMob()
    local level = getLevel()
    local best, bestScore
    for _, npc in pairs(GuideModule.Data.NPCList) do
        if type(npc) == "table" then
            local score = 10000
            if npc.Levels and table.find(npc.Levels, level) then score = 0 end
            if mob and npc.InternalQuestName and tostring(npc.InternalQuestName):lower():find(tostring(mob):lower(), 1, true) then
                score -= 5000
            end
            if score < (bestScore or math.huge) then
                bestScore = score
                best = npc
            end
        end
    end
    return best
end

local function npcCFrameFromEntry(npc)
    if not npc or not GuideModule or not GuideModule.Data or not GuideModule.Data.NPCList then return nil end
    for key, entry in pairs(GuideModule.Data.NPCList) do
        if entry == npc then
            local ok, result = pcall(function()
                if entry.CFrame and typeof(entry.CFrame) == "CFrame" then return entry.CFrame end
                if entry.Position and typeof(entry.Position) == "Vector3" then return CFrame.new(entry.Position) end
                if entry.NPCName then
                    local folder = Workspace:FindFirstChild("NPCs")
                    folder = folder or ReplicatedStorage:FindFirstChild("NPCs")
                    if folder then
                        local exact = folder:FindFirstChild(entry.NPCName, true)
                        local r = exact and getRoot(exact)
                        if r then return r.CFrame end
                    end
                end
                local folder = Workspace:FindFirstChild("NPCs")
                if folder and typeof(key) == "string" then
                    local exact = folder:FindFirstChild(key, true)
                    local r = exact and getRoot(exact)
                    if r then return r.CFrame end
                end
                return nil
            end)
            if ok and result then return result end
        end
    end
    return nil
end

local function stepQuestNavigation()
    local mob = getQuestMob()
    Runtime.LastQuestMob = mob or "None"
    if not mob then
        setStatus("Quest Helper: no active quest")
        return
    end
    local enemies = Workspace:FindFirstChild("Enemies")
    local target = findNearestByName(enemies, mob)
    if target then
        moveTo(target, Vector3.new(0, 18, 0))
        setStatus("Quest route: " .. mob)
        return
    end
    local npc = getActiveQuestNPC()
    local npcCF = npcCFrameFromEntry(npc)
    if npcCF then
        moveTo(npcCF, Vector3.new(0, 3, 0))
        setStatus("Quest NPC route")
    else
        setStatus("Quest found: " .. mob)
    end
end

local function detectChest()
    local tagged = CollectionService:GetTagged("_ChestTagged")
    local best, bestD
    for _, obj in ipairs(tagged) do
        if obj:IsA("BasePart") and obj.Parent and obj:GetAttribute("IsDisabled") ~= true then
            local d = Root and (Root.Position - obj.Position).Magnitude or math.huge
            if d < (bestD or math.huge) then
                bestD = d
                best = obj
            end
        end
    end
    return best
end

local function stepChest()
    local chest = detectChest()
    if not chest then
        setStatus("Chest: none nearby")
        return
    end
    moveTo(chest.CFrame, Vector3.new(0, 3, 2))
    setStatus("Chest: moving to nearest")
end

local function getFruitObjects()
    local list = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            local n = obj.Name:lower()
            if n:find("fruit", 1, true) or n:find("blox", 1, true) then
                table.insert(list, obj)
            end
        elseif obj:IsA("Model") and obj.Name:lower():find("fruit", 1, true) then
            table.insert(list, obj)
        end
    end
    return list
end

local function nearestFruit()
    local best, bestD
    for _, obj in ipairs(getFruitObjects()) do
        local r = getRoot(obj)
        if r then
            local d = distanceTo(obj)
            if d < (bestD or math.huge) then
                bestD = d
                best = obj
            end
        end
    end
    return best
end

local function stepFruit()
    local fruit = nearestFruit()
    if not fruit then
        setStatus("Fruit: none found")
        return
    end
    moveTo(fruit, Vector3.new(0, 2, 0))
    setStatus("Fruit: " .. fruit.Name)
end

local function getBaitQuantity(name)
    local quantity = 0
    if not NetFolder then return quantity end
    local rf
    pcall(function()
        rf = require(NetFolder):RemoteFunction("GetAllItemValues")
    end)
    if not rf then return quantity end
    local ok, items = pcall(function() return rf:InvokeServer() end)
    if not ok or type(items) ~= "table" then return quantity end

    for _, item in ipairs(items) do
        local label
        pcall(function()
            local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
            local result = ItemConfig.match(item.ItemId)
            if result and result:isOk() then
                local data = result:unwrap()
                local debugLabel = data and data.Index and data.Index.DebugLabel
                label = debugLabel and (tostring(debugLabel):match("^(.-)%s*%[") or tostring(debugLabel))
            end
        end)
        if label == name and item.Key == "Quantity" then
            quantity = quantity + (tonumber(item.Value) or 0)
        end
    end
    return quantity
end

local function ensureBait()
    if not Config.SelectedBait or Config.SelectedBait == "" then return false end
    local qty = getBaitQuantity(Config.SelectedBait)
    if qty >= Config.MinBait then return true end
    if CraftRemote then
        local canCraft = safe("Bait check", function()
            return CraftRemote:InvokeServer("Check", Config.SelectedBait)
        end)
        if canCraft then
            safe("Bait craft", function()
                CraftRemote:InvokeServer("Craft", Config.SelectedBait, 1, {})
            end)
            task.wait(0.8)
            qty = getBaitQuantity(Config.SelectedBait)
            if qty > 0 then
                setStatus("Bait: crafted " .. Config.SelectedBait)
                return true
            end
        end
    end
    setStatus("Bait: no verified craft route")
    return false
end

local function equipFishingRod()
    if not Character or not Humanoid then return false end
    local tool = Character:FindFirstChild(Config.SelectedRod)
    if tool then return true end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local candidate = backpack and backpack:FindFirstChild(Config.SelectedRod)
    if candidate then
        Humanoid:EquipTool(candidate)
        return true
    end
    if JobsRemote then
        safe("Fishing rod request", function()
            JobsRemote:InvokeServer("FishingNPC", "FirstTimeFreeRod")
        end)
    end
    safe("Load fishing rod", function()
        CommF:InvokeServer("LoadItem", Config.SelectedRod, { "Gear" })
    end)
    return Character:FindFirstChild(Config.SelectedRod) ~= nil
end

local function clickHold(seconds)
    seconds = seconds or 0.05
    safe("Fishing click", function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(seconds)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

local function stepFishing()
    if not equipFishingRod() then
        setStatus("Fishing: rod missing")
        return
    end
    if Config.AutoMaintainBait then
        ensureBait()
    end
    if not Root then return end

    local stateTool = Character:FindFirstChild(Config.SelectedRod)
    if not stateTool then return end
    local serverState = stateTool:GetAttribute("ServerState")
    local state = stateTool:GetAttribute("State")
    local reelingGui = PlayerGui:FindFirstChild("Fishing_Reeling")
    local biting = serverState == "Biting" or state == "Biting"

    if reelingGui and reelingGui.Enabled then
        local mini = reelingGui:FindFirstChild("Minigame")
        mini = mini and mini:FindFirstChild("Container")
        local reelZone = mini and mini:FindFirstChild("ReelZone")
        local fish = mini and mini:FindFirstChild("Fish")
        if reelZone and fish and fish.Visible then
            local fishCenter = fish.Position.X.Scale + fish.Size.X.Scale * 0.5
            local zoneCenter = reelZone.Position.X.Scale + reelZone.Size.X.Scale * 0.5
            local delta = fishCenter - zoneCenter
            if delta > 0.03 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            elseif delta < -0.03 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            else
                clickHold(0.02)
            end
        else
            clickHold(0.05)
        end

        if FishingRequest then
            safe("Fishing catch", function()
                if Config.AutoCatchChest then
                    FishingRequest:InvokeServer("Catch", 1, 1)
                else
                    FishingRequest:InvokeServer("Catch", 1)
                end
            end)
        end
        setStatus("Fishing: reeling")
        return
    end

    if biting then
        clickHold(0.08)
        task.wait(0.12)
        setStatus("Fishing: bite")
        return
    end

    if state == "ReeledIn" or serverState == "ReeledIn" or not serverState or serverState == "Waiting" then
        clickHold(0.08)
        task.wait(0.25)
        setStatus("Fishing: casting")
    else
        setStatus("Fishing: " .. tostring(serverState or state or "idle"))
    end
end

local function stepAnglerQuest()
    if not JobsRemote then return end
    local ok = safe("Angler quest", function()
        JobsRemote:InvokeServer("FishingNPC", "Angler", "CheckQuest")
        local response = JobsRemote:InvokeServer("FishingNPC", "Angler", "Speak")
        if response and (response.canAccept or not response.IsInQuest) then
            JobsRemote:InvokeServer("FishingNPC", "Angler", "AskQuest")
        end
    end)
    if ok then setStatus("Angler quest checked") end
end

local function stepSellFish()
    if not JobsRemote then return end
    safe("Sell fish", function()
        JobsRemote:InvokeServer("FishingNPC", "SellFish")
    end)
    setStatus("Fish sold")
end

local function serverHop(delay)
    delay = tonumber(delay) or 0
    if delay > 0 then task.wait(delay) end
    if ServerBrowser then
        safe("Server hop", function()
            ServerBrowser:InvokeServer("teleport")
        end)
        return
    end
    safe("Server hop", function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in ipairs(servers.data or {}) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end)
end

local function rejoin()
    safe("Rejoin", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

local function findLocations()
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    return origin and origin:FindFirstChild("Locations")
end

local function teleportToLocationByName(name)
    if not name or name == "" then return false end
    local locations = findLocations()
    if not locations then return false end
    for _, obj in ipairs(locations:GetChildren()) do
        if obj.Name:lower():find(name:lower(), 1, true) then
            return moveTo(obj.CFrame, Vector3.new(0, 10, 0))
        end
    end
    return false
end

local IslandNames = {
    "Starter Island", "Jungle", "Pirate Village", "Desert", "Frozen Village", "Marine Fortress",
    "Colosseum", "Skylands", "Prison", "Magma Village", "Underwater City", "Fountain City",
    "Kingdom of Rose", "Green Zone", "Graveyard", "Snow Mountain", "Hot and Cold", "Cursed Ship",
    "Ice Castle", "Forgotten Island", "Port Town", "Hydra Island", "Great Tree", "Floating Turtle",
    "Castle on the Sea", "Haunted Castle", "Sea of Treats", "Chocolate Island", "Cake Island",
    "Tiki Outpost", "Kitsune Island", "Mirage Island", "Prehistoric Island",
}

local function createESPLabel(parent, text, adornee, life)
    if not adornee then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "BCESP"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(150, 24)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 2500
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.45
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = gui

    if life then
        task.delay(life, function()
            if gui then gui:Destroy() end
        end)
    end
    return gui
end

local function clearESP()
    if Runtime.ESPFolder then
        Runtime.ESPFolder:Destroy()
    end
    Runtime.ESPFolder = Instance.new("Folder")
    Runtime.ESPFolder.Name = "BloxCommunityESP"
    Runtime.ESPFolder.Parent = PlayerGui
end

clearESP()

local function refreshESP()
    clearESP()
    local folder = Runtime.ESPFolder
    if not folder then return end

    if Config.AutoESPPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and alive(p.Character) then
                local r = getRoot(p.Character)
                if r then createESPLabel(folder, "Player: " .. p.Name, r) end
            end
        end
    end

    if Config.AutoESPChests then
        for _, obj in ipairs(CollectionService:GetTagged("_ChestTagged")) do
            if obj:IsA("BasePart") and obj.Parent then
                createESPLabel(folder, "Chest", obj)
            end
        end
    end

    if Config.AutoESPFruits then
        for _, obj in ipairs(getFruitObjects()) do
            local r = getRoot(obj)
            if r then createESPLabel(folder, "Fruit: " .. obj.Name, r) end
        end
    end

    if Config.AutoESPIslands then
        local locations = findLocations()
        if locations then
            for _, obj in ipairs(locations:GetChildren()) do
                if obj:IsA("BasePart") then
                    createESPLabel(folder, obj.Name, obj)
                end
            end
        end
    end
end

local function setNoFog(on)
    if on then
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
    else
        Lighting.FogEnd = Runtime.OriginalFogEnd
        Lighting.GlobalShadows = Runtime.OriginalGlobalShadows
    end
end

local function setLowGraphics(on)
    if on then
        safe("Low graphics", function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e9
            local effects = Lighting:GetChildren()
            for _, fx in ipairs(effects) do
                if fx:IsA("PostEffect") then fx.Enabled = false end
            end
        end)
    else
        setNoFog(Config.NoFog)
    end
end

local function stopAllLoops()
    table.clear(Runtime.ActiveLoops)
    for key, value in pairs(Config) do
        if type(value) == "boolean" and key ~= "AntiAFK" then
            Config[key] = false
        end
    end
end

local function launchLoop(name, interval, fn)
    if Runtime.ActiveLoops[name] then return end
    Runtime.ActiveLoops[name] = true
    task.spawn(function()
        while Runtime.ActiveLoops[name] do
            if (name == "AutoFishing" and not Config.AutoFishing)
                or (name == "Chest" and not Config.AutoChest)
                or (name == "Fruit" and not Config.AutoFruit)
                or (name == "Quest" and not Config.QuestNavigation)
                or (name == "Angler" and not Config.AutoAnglerQuest)
                or (name == "SellFish" and not Config.AutoSellFish)
            then
                break
            end
            safe(name, fn)
            task.wait(interval)
        end
        Runtime.ActiveLoops[name] = nil
    end)
end

-- ========================= UI =========================
local old = PlayerGui:FindFirstChild("BloxCommunityRebuild")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "BloxCommunityRebuild"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local UIScale = Instance.new("UIScale")
UIScale.Scale = 0.92
UIScale.Parent = Gui

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(48, 48)
Toggle.Position = UDim2.new(0, 16, 0.5, -24)
Toggle.BackgroundColor3 = Color3.fromRGB(75, 62, 145)
Toggle.Text = "BC"
Toggle.TextColor3 = Color3.new(1,1,1)
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 15
Toggle.AutoButtonColor = false
Toggle.Parent = Gui
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(540, 410)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(88, 72, 170)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.2
Stroke.Parent = Main

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 52)
Top.BackgroundTransparency = 1
Top.Parent = Main

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(16, 7)
Title.Size = UDim2.fromOffset(260, 20)
Title.BackgroundTransparency = 1
Title.Text = "BLOX COMMUNITY"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local SubTitle = Instance.new("TextLabel")
SubTitle.Position = UDim2.fromOffset(17, 27)
SubTitle.Size = UDim2.fromOffset(330, 18)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Rebuild • compact mobile UI"
SubTitle.TextColor3 = Color3.fromRGB(150, 145, 170)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -40, 0, 11)
Close.BackgroundColor3 = Color3.fromRGB(33, 33, 44)
Close.Text = "×"
Close.TextColor3 = Color3.new(1,1,1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 18
Close.AutoButtonColor = false
Close.Parent = Top
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Body = Instance.new("Frame")
Body.Position = UDim2.fromOffset(10, 56)
Body.Size = UDim2.new(1, -20, 1, -66)
Body.BackgroundTransparency = 1
Body.Parent = Main

local Nav = Instance.new("ScrollingFrame")
Nav.Size = UDim2.fromOffset(112, 1)
Nav.Position = UDim2.fromOffset(0, 0)
Nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
Nav.CanvasSize = UDim2.new()
Nav.BackgroundColor3 = Color3.fromRGB(22, 22, 31)
Nav.BorderSizePixel = 0
Nav.ScrollBarThickness = 2
Nav.Parent = Body
Instance.new("UICorner", Nav).CornerRadius = UDim.new(0, 10)

local NavList = Instance.new("UIListLayout")
NavList.Padding = UDim.new(0, 6)
NavList.SortOrder = Enum.SortOrder.LayoutOrder
NavList.Parent = Nav

local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(122, 0)
Content.Size = UDim2.new(1, -122, 1, 0)
Content.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
Content.BorderSizePixel = 0
Content.Parent = Body
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Position = UDim2.fromOffset(14, 10)
ContentTitle.Size = UDim2.new(1, -28, 0, 22)
ContentTitle.BackgroundTransparency = 1
ContentTitle.Text = "Home"
ContentTitle.TextColor3 = Color3.new(1,1,1)
ContentTitle.Font = Enum.Font.GothamBold
ContentTitle.TextSize = 14
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Parent = Content

local Scroll = Instance.new("ScrollingFrame")
Scroll.Position = UDim2.fromOffset(8, 38)
Scroll.Size = UDim2.new(1, -16, 1, -46)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new()
Scroll.Parent = Content

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 7)
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

local Pages = {}
local PageButtons = {}
local currentPage

local function clearScroll()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child ~= List then child:Destroy() end
    end
end

local function newPage(name)
    local page = { Name = name }
    Pages[name] = page
    return page
end

local function rowBase(height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, height or 38)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    row.BorderSizePixel = 0
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    return row
end

local function addLabel(text, small)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, small and 22 or 28)
    l.BackgroundTransparency = 1
    l.Text = tostring(text)
    l.TextColor3 = small and Color3.fromRGB(155, 150, 175) or Color3.new(1,1,1)
    l.Font = small and Enum.Font.Gotham or Enum.Font.GothamMedium
    l.TextSize = small and 10 or 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = Scroll
    return l
end

local function addButton(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(34, 33, 46)
    b.Text = tostring(text)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.AutoButtonColor = false
    b.Parent = Scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function()
        safe("Button: " .. tostring(text), function()
            if callback then callback() end
        end)
    end)
    return b
end

local function addToggle(text, key, default)
    Config[key] = Config[key] == nil and default or Config[key]
    local row = rowBase(44)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, 6)
    label.Size = UDim2.new(1, -84, 1, -12)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(58, 28)
    button.Position = UDim2.new(1, -68, 0.5, -14)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.AutoButtonColor = false
    button.Parent = row
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local function render(silent)
        local on = Config[key]
        button.Text = on and "ON" or "OFF"
        button.BackgroundColor3 = on and Color3.fromRGB(80, 150, 106) or Color3.fromRGB(55, 55, 67)
        if not silent then
            setStatus(text .. ": " .. (on and "ON" or "OFF"))
        end
    end

    button.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        render(false)
        if key == "QuestNavigation" and Config[key] then launchLoop("Quest", 0.5, stepQuestNavigation) end
        if key == "AutoChest" and Config[key] then launchLoop("Chest", 0.5, stepChest) end
        if key == "AutoFruit" and Config[key] then launchLoop("Fruit", 0.7, stepFruit) end
        if key == "AutoFishing" and Config[key] then launchLoop("AutoFishing", 0.1, stepFishing) end
        if key == "AutoAnglerQuest" and Config[key] then launchLoop("Angler", 2, stepAnglerQuest) end
        if key == "AutoSellFish" and Config[key] then launchLoop("SellFish", 2, stepSellFish) end
        if key == "NoFog" then setNoFog(Config.NoFog) end
        if key == "LowGraphics" then setLowGraphics(Config.LowGraphics) end
        if key == "AntiAFK" then end
        if key:find("ESP", 1, true) then refreshESP() end
    end)
    render(true)
    return row
end

local function addSlider(text, key, minV, maxV, step, suffix)
    local row = rowBase(58)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, 5)
    label.Size = UDim2.new(1, -24, 0, 17)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.fromOffset(28, 24)
    minus.Position = UDim2.fromOffset(8, 28)
    minus.Text = "−"
    minus.BackgroundColor3 = Color3.fromRGB(44, 43, 55)
    minus.TextColor3 = Color3.new(1,1,1)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.Parent = row
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 7)

    local plus = minus:Clone()
    plus.Text = "+"
    plus.Position = UDim2.new(1, -36, 0, 28)
    plus.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -84, 0, 8)
    bar.Position = UDim2.fromOffset(42, 36)
    bar.BackgroundColor3 = Color3.fromRGB(49, 48, 61)
    bar.BorderSizePixel = 0
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = Color3.fromRGB(95, 78, 175)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local value = tonumber(Config[key]) or minV
    local dragging = false
    local function quantize(v)
        local q = step or 1
        return math.clamp(math.floor((v - minV) / q + 0.5) * q + minV, minV, maxV)
    end
    local function render(callback)
        value = quantize(value)
        Config[key] = value
        local alpha = (value - minV) / math.max(maxV - minV, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        label.Text = tostring(text) .. ": " .. tostring(value) .. (suffix or "")
        if callback then callback(value) end
    end
    local function setFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        value = minV + (maxV - minV) * alpha
        render(function(v) setStatus(text .. ": " .. tostring(v)) end)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    minus.MouseButton1Click:Connect(function()
        value = value - (step or 1)
        render(function(v) setStatus(text .. ": " .. tostring(v)) end)
    end)
    plus.MouseButton1Click:Connect(function()
        value = value + (step or 1)
        render(function(v) setStatus(text .. ": " .. tostring(v)) end)
    end)
    render()
    return row
end

local function addDropdown(text, key, options)
    local row = rowBase(42)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, 5)
    label.Size = UDim2.new(0.55, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.42, -8, 0, 28)
    b.Position = UDim2.new(0.58, 0, 0.5, -14)
    b.BackgroundColor3 = Color3.fromRGB(42, 41, 53)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 9
    b.TextXAlignment = Enum.TextXAlignment.Center
    b.AutoButtonColor = false
    b.Parent = row
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

    local menu = Instance.new("Frame")
    menu.Visible = false
    menu.Size = UDim2.new(0.42, -8, 0, math.min(#options * 28, 140))
    menu.Position = UDim2.new(0.58, 0, 1, 3)
    menu.BackgroundColor3 = Color3.fromRGB(31, 30, 42)
    menu.ZIndex = 20
    menu.Parent = row
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 7)
    local ml = Instance.new("UIListLayout")
    ml.Parent = menu
    ml.Padding = UDim.new(0, 2)

    local value = Config[key] or options[1]
    local function setValue(v)
        value = v
        Config[key] = v
        b.Text = tostring(v)
        menu.Visible = false
        setStatus(text .. ": " .. tostring(v))
    end
    for _, option in ipairs(options) do
        local opt = Instance.new("TextButton")
        opt.Size = UDim2.new(1, 0, 0, 26)
        opt.BackgroundColor3 = Color3.fromRGB(38, 37, 50)
        opt.Text = tostring(option)
        opt.TextColor3 = Color3.new(1,1,1)
        opt.Font = Enum.Font.Gotham
        opt.TextSize = 9
        opt.AutoButtonColor = false
        opt.ZIndex = 21
        opt.Parent = menu
        opt.MouseButton1Click:Connect(function() setValue(option) end)
    end
    b.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
    setValue(value)
    return row
end

local function buildPage(pageName)
    clearScroll()
    ContentTitle.Text = pageName
    if pageName == "Home" then
        addLabel("Status", false)
        local statusLabel = addLabel("Ready", false)
        statusLabel.TextColor3 = Color3.fromRGB(190, 186, 214)
        task.spawn(function()
            while Main.Parent do
                if currentPage == "Home" then
                    statusLabel.Text = "Status: " .. Runtime.Status
                        .. "\nLevel: " .. getLevel()
                        .. " • " .. getSeaName()
                        .. "\nQuest: " .. (Runtime.LastQuestMob ~= "" and Runtime.LastQuestMob or (getQuestMob() or "None"))
                        .. (Runtime.LastError ~= "" and ("\nLast error: " .. Runtime.LastError) or "")
                end
                task.wait(0.5)
            end
        end)
        addLabel("Bản này ưu tiên UI ổn định, thao tác mobile và trạng thái rõ ràng. Những route chưa có remote xác thực sẽ báo thay vì giả vờ hoạt động.", true)
        addButton("Refresh ESP", refreshESP)
        addButton("Stop optional loops", function()
            Config.QuestNavigation = false
            Config.AutoChest = false
            Config.AutoFruit = false
            Config.AutoFishing = false
            Config.AutoAnglerQuest = false
            Config.AutoSellFish = false
            setStatus("Optional loops stopped")
        end)
    elseif pageName == "Farm" then
        addLabel("FARM / ROUTES", false)
        addToggle("Quest Navigation", "QuestNavigation", false)
        addToggle("Auto Chest", "AutoChest", false)
        addToggle("Auto Fruit", "AutoFruit", false)
        addSlider("Move Speed", "TweenSpeed", 50, 500, 10)
        addButton("Run quest route once", stepQuestNavigation)
        addButton("Go nearest chest", stepChest)
    elseif pageName == "Fishing" then
        addLabel("FISHING", false)
        addDropdown("Rod", "SelectedRod", {"Fishing Rod", "Gold Rod", "Shark Rod", "Shell Rod", "Treasure Rod", "Shark (Corrupted)", "Shell (Celestial)"})
        addDropdown("Bait", "SelectedBait", {"Basic Bait", "Kelp Bait", "Good Bait", "Abyssal Bait", "Frozen Bait", "Epic Bait", "Carnivore Bait"})
        addSlider("Minimum bait", "MinBait", 1, 20, 1)
        addToggle("Auto Fishing", "AutoFishing", false)
        addToggle("Auto maintain bait", "AutoMaintainBait", false)
        addToggle("Auto catch chest", "AutoCatchChest", false)
        addToggle("Auto Angler Quest", "AutoAnglerQuest", false)
        addToggle("Auto Sell Fish", "AutoSellFish", false)
        addButton("Check bait", function()
            local q = getBaitQuantity(Config.SelectedBait)
            setStatus(Config.SelectedBait .. " = " .. q)
            notify("Fishing", Config.SelectedBait .. " = " .. q, 3)
        end)
        addButton("Maintain bait now", ensureBait)
        addButton("Fishing step", stepFishing)
        addLabel("Bait route: bản nguồn có route craft xác thực; chưa có route mua trực tiếp được xác nhận nên script không đoán remote.", true)
    elseif pageName == "Visuals" then
        addLabel("ESP", false)
        addToggle("ESP Players", "AutoESPPlayers", false)
        addToggle("ESP Chests", "AutoESPChests", false)
        addToggle("ESP Fruits", "AutoESPFruits", false)
        addToggle("ESP Islands", "AutoESPIslands", false)
        addButton("Refresh all ESP", refreshESP)
        addButton("Clear ESP", clearESP)
    elseif pageName == "Travel" then
        addLabel("TRAVEL", false)
        addDropdown("Island", "TravelIsland", IslandNames)
        addButton("Teleport to selected island", function()
            local ok = teleportToLocationByName(Config.TravelIsland)
            setStatus(ok and ("Travel: " .. tostring(Config.TravelIsland)) or "Travel: location not found")
        end)
        addButton("Teleport to active quest mob", function()
            local mob = getQuestMob()
            local target = mob and findNearestByName(Workspace:FindFirstChild("Enemies"), mob)
            if target then moveTo(target, Vector3.new(0, 18, 0)) else setStatus("Quest mob not spawned") end
        end)
        addButton("Rejoin server", rejoin)
        addButton("Server hop", function() serverHop(Config.ServerHopDelay) end)
    elseif pageName == "Utility" then
        addLabel("UTILITY", false)
        addToggle("Anti AFK", "AntiAFK", true)
        addToggle("No Fog", "NoFog", false)
        addToggle("Low Graphics", "LowGraphics", false)
        addSlider("Server hop delay", "ServerHopDelay", 0, 30, 1, "s")
        addButton("Reset UI", function() Main.Position = UDim2.fromScale(0.5, 0.5) end)
        addButton("Copy Job ID", function()
            if setclipboard then safe("Clipboard", function() setclipboard(game.JobId) end) end
            setStatus("Job ID copied")
        end)
        addButton("Open Developer Console", function()
            safe("DevConsole", function()
                game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
            end)
        end)
    end
end

local tabs = {"Home", "Farm", "Fishing", "Visuals", "Travel", "Utility"}
for _, name in ipairs(tabs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 36)
    b.BackgroundColor3 = Color3.fromRGB(28, 27, 38)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(205, 201, 220)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 10
    b.AutoButtonColor = false
    b.Parent = Nav
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    PageButtons[name] = b
    b.MouseButton1Click:Connect(function()
        currentPage = name
        for n, btn in pairs(PageButtons) do
            btn.BackgroundColor3 = n == name and Color3.fromRGB(75, 62, 145) or Color3.fromRGB(28, 27, 38)
            btn.TextColor3 = n == name and Color3.new(1,1,1) or Color3.fromRGB(205, 201, 220)
        end
        buildPage(name)
    end)
end

local draggingMain = false
local dragStart
local startPos
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = false
    end
end)

local visible = true
local function setVisible(on)
    visible = on
    Main.Visible = on
    Toggle.Visible = not on
end
Toggle.MouseButton1Click:Connect(function() setVisible(true) end)
Close.MouseButton1Click:Connect(function() setVisible(false) end)

-- Anti AFK loop.
task.spawn(function()
    while Gui.Parent do
        task.wait(60)
        if Config.AntiAFK then
            safe("AntiAFK", function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end)
        end
    end
end)


-- Lightweight ESP refresh.
task.spawn(function()
    while Gui.Parent do
        task.wait(2)
        if Config.AutoESPPlayers or Config.AutoESPChests or Config.AutoESPFruits or Config.AutoESPIslands then
            refreshESP()
        end
    end
end)

currentPage = "Home"
PageButtons.Home.BackgroundColor3 = Color3.fromRGB(75, 62, 145)
buildPage("Home")

setStatus("Loaded")
notify("Blox Community", "Rebuild loaded", 3)
