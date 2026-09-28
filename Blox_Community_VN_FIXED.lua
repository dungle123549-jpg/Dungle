-- ============================================================
-- BLOX FRUIT SCRIPT - BLOX COMMUNITY VN EDITION
-- Tác giả: Dungdx
-- Discord: Blox Community VN
-- Link: https://discord.gg/BQwcUEdWCW
-- ============================================================

local Services = setmetatable({}, {__index = function(self, name)
    local ok, service = pcall(game.GetService, game, name)
    if ok and service then rawset(self, name, service) return service end
    return nil
end})

local Players = Services.Players
local RunService = Services.RunService
local ReplicatedStorage = Services.ReplicatedStorage
local Workspace = Services.Workspace
local VirtualUser = Services.VirtualUser
local VirtualInputManager = Services.VirtualInputManager
local HttpService = Services.HttpService
local Lighting = Services.Lighting
local StarterGui = Services.StarterGui
local UserInputService = Services.UserInputService

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 10)
local Root = Character:WaitForChild("HumanoidRootPart", 10)
local Backpack = LP:WaitForChild("Backpack")
local PlayerGui = LP:WaitForChild("PlayerGui")
local Data = LP:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Beli = Data:WaitForChild("Beli")
local Fragments = Data:WaitForChild("Fragments")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:FindFirstChild("CommE")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local ItemConfig = ReplicatedStorage:WaitForChild("ItemConfig")
local Enemies = Workspace:WaitForChild("Enemies")
local SeaBeasts = Workspace:WaitForChild("SeaBeasts")
local Boats = Workspace:WaitForChild("Boats")
local Map = Workspace:FindFirstChild("Map")
local WorldOrigin = Workspace:FindFirstChild("_WorldOrigin")

LP.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    Root = newChar:WaitForChild("HumanoidRootPart", 10)
end)

local Config = {
    AutoFarmLevel = false,
    AutoFarmBones = false,
    AutoFarmMaterial = false,
    AutoFarmBoss = false,
    AutoFarmChest = false,
    AutoFarmElite = false,
    AutoRaid = false,
    AutoDungeon = false,
    AutoSeaEvents = false,
    AutoFish = false,
    AutoFishSlap = false,
    AutoObservation = false,
    AutoStoreFruit = false,
    AutoRandomFruit = false,
    AutoAwaken = false,
    AutoStats = false,
    StatTarget = "Melee",
    AutoSkills = false,
    AutoHaki = false,
    AutoObservationHaki = false,
    AutoBoat = false,
    AutoDodgeSea = false,
    ESPPlayer = false,
    ESPChest = false,
    ESPFruit = false,
    ESPIsland = false,
    ESPBerry = false,
    AntiAFK = true,
    AutoNoFog = false,
    AutoMemory = false,
    AutoHop30 = false,
    AutoHakiAlways = true,
    FarmMode = "Quest",
    SelectWeapon = "Melee",
    SelectBoss = "Greybeard",
    SelectMaterial = "Leather",
    SelectRaid = "Flame",
    SelectBoat = "PirateBrigade",
    SelectRod = "Fishing Rod",
    SelectBait = "Basic Bait",
    TweenSpeed = 250,
    BringMonster = true,
    BringRadius = 350,
    AttackMobs = true,
    AttackPlayers = false,
    FastAttack = true,
    MasteryFarm = false,
    Webhook = "",
    WebhookEnabled = false,
}

local Util = {}

function Util.GetRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

function Util.GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function Util.IsAlive(char)
    if not char or not char.Parent then return false end
    local h = Util.GetHumanoid(char)
    return h and h.Health > 0
end

function Util.IsReady(inst)
    if not inst or not inst.Parent then return false end
    if not inst:IsDescendantOf(Workspace) then return false end
    if inst:IsDescendantOf(Boats) and inst.Parent == Boats then return false end
    if inst:GetAttribute("IsBoat") and inst.Parent == Boats then return false end

    local h = Util.GetHumanoid(inst)
    local r = Util.GetRoot(inst) or inst:FindFirstChildWhichIsA("BasePart")

    if inst:IsDescendantOf(SeaBeasts) then
        local hp = inst:FindFirstChild("Health")
        if hp and hp:IsA("ValueBase") then
            return hp.Value > 0 and r ~= nil
        end
        return h and h.Health > 0 and r ~= nil
    end

    return h and h.Health > 0 and r ~= nil
end

function Util.FireInvoke(...)
    return CommF:InvokeServer(...)
end

function Util.Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Script",
            Text = text or "",
            Duration = duration or 5,
        })
    end)
end

function Util.EquipWeapon(weaponType)
    if not Backpack or not Humanoid then return end
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and (not weaponType or tool.ToolTip == weaponType) then
            Humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end

function Util.AutoHaki()
    if not Character or not Beli then return false end
    local active = false
    pcall(function() active = Character:FindFirstChild("HasBuso") ~= nil or Character:HasTag("Buso") end)
    if not active and Beli.Value >= 25000 then
        local ok = pcall(function() Util.FireInvoke("BuyHaki", "Buso") end)
        task.wait(0.1)
        pcall(function() Util.FireInvoke("Buso") end)
        return ok
    elseif not active then
        pcall(function() Util.FireInvoke("Buso") end)
    end
    return true
end

function Util.HasQuest()
    local main = PlayerGui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    return quest and quest.Visible
end

function Util.GetQuestMob()
    local main = PlayerGui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if not quest or not quest.Visible then return nil end
    local container = quest:FindFirstChild("Container")
    local title = container and container:FindFirstChild("QuestTitle") and container.QuestTitle:FindFirstChild("Title")
    if title and title.Text ~= "" then
        local mob = title.Text:match("Defeat%s+%d+%s+(.-)%s+%(") or title.Text:match("Defeat%s+(.-)%s+%(")
        if mob then return mob end
    end
    return nil
end

function Util.HasTool(toolName)
    if Character and Character:FindFirstChild(toolName) then return true end
    if Backpack and Backpack:FindFirstChild(toolName) then return true end
    return false
end

-- ==================== TARGET / FARM HELPERS ====================
local LevelMobRanges = {
    {1, 9, "Bandit"}, {15, 29, "Monkey"}, {30, 54, "Gorilla"},
    {55, 74, "Pirate"}, {75, 89, "Brute"}, {90, 119, "Desert Bandit"},
    {120, 149, "Desert Officer"}, {150, 189, "Snow Bandit"}, {190, 249, "Snowman"},
    {250, 299, "Chief Petty Officer"}, {300, 374, "Sky Bandit"}, {375, 399, "Dark Master"},
    {400, 449, "Prisoner"}, {450, 474, "Dangerous Prisoner"}, {475, 524, "Toga Warrior"},
    {525, 549, "Gladiator"}, {550, 624, "Military Soldier"}, {625, 649, "Military Spy"},
    {650, 699, "Fishman Warrior"},
    {700, 724, "Raider"}, {725, 774, "Mercenary"}, {775, 799, "Swan Pirate"},
    {800, 874, "Factory Staff"}, {875, 899, "Marine Lieutenant"}, {900, 949, "Marine Captain"},
    {950, 999, "Zombie"}, {1000, 1049, "Vampire"}, {1050, 1099, "Snow Trooper"},
    {1100, 1124, "Winter Warrior"}, {1125, 1174, "Lab Subordinate"}, {1175, 1199, "Horned Warrior"},
    {1200, 1249, "Magma Ninja"}, {1250, 1299, "Lava Pirate"}, {1300, 1324, "Ship Deckhand"},
    {1325, 1374, "Ship Engineer"}, {1375, 1399, "Ship Steward"}, {1400, 1449, "Ship Officer"},
    {1450, 1474, "Arctic Warrior"}, {1475, 1499, "Snow Lurker"},
    {1500, 1524, "Pirate Millionaire"}, {1525, 1574, "Pistol Billionaire"},
    {1575, 1599, "Dragon Crew Warrior"}, {1600, 1624, "Dragon Crew Archer"},
    {1625, 1649, "Female Islander"}, {1650, 1699, "Giant Islander"},
    {1700, 1724, "Marine Commodore"}, {1725, 1774, "Marine Rear Admiral"},
    {1775, 1799, "Fishman Raider"}, {1800, 1824, "Fishman Captain"},
    {1825, 1849, "Forest Pirate"}, {1850, 1899, "Mythological Pirate"},
    {1900, 1924, "Jungle Pirate"}, {1925, 1974, "Musketeer Pirate"},
    {1975, 1999, "Reborn Skeleton"}, {2000, 2049, "Living Zombie"},
    {2050, 2074, "Demonic Soul"}, {2075, 2099, "Posessed Mummy"},
    {2100, 2124, "Peanut Scout"}, {2125, 2149, "Peanut President"},
    {2150, 2174, "Ice Cream Chef"}, {2175, 2199, "Ice Cream Commander"},
    {2200, 2224, "Cookie Crafter"}, {2225, 2249, "Cake Guard"},
    {2250, 2274, "Baking Staff"}, {2275, 2299, "Head Baker"},
    {2300, 2324, "Cocoa Warrior"}, {2325, 2349, "Chocolate Bar Battler"},
    {2350, 2374, "Sweet Thief"}, {2375, 2399, "Candy Rebel"},
    {2400, 2449, "Candy Pirate"},
}

local MaterialMobs = {
    ["Leather"] = {"Gorilla", "Brute", "Pirate", "Desert Bandit", "Desert Officer", "Snow Bandit", "Snowman"},
    ["Scrap Metal"] = {"Pirate", "Brute", "Factory Staff", "Marine Lieutenant", "Marine Captain"},
    ["Leather + Scrap Metal"] = {"Gorilla", "Brute", "Pirate", "Factory Staff"},
    ["Angel Wings"] = {"God's Guard", "Shanda", "Royal Squad", "Royal Soldier"},
    ["Magma Ore"] = {"Military Soldier", "Military Spy", "Magma Ninja", "Lava Pirate"},
    ["Fish Tail"] = {"Fishman Warrior", "Fishman Commando", "Fishman Raider", "Fishman Captain", "Sea Soldier", "Water Fighter"},
    ["Radioactive Material"] = {"Factory Staff", "Lab Subordinate"},
    ["Ectoplasm"] = {"Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer", "Cursed Captain"},
    ["Mystic Droplet"] = {"Sea Soldier", "Water Fighter"},
    ["Vampire Fang"] = {"Vampire"},
    ["Demonic Wisp"] = {"Demonic Soul"},
    ["Conjured Cocoa"] = {"Cocoa Warrior", "Chocolate Bar Battler", "Sweet Thief"},
    ["Dragon Scale"] = {"Dragon Crew Warrior", "Dragon Crew Archer"},
    ["Gunpowder"] = {"Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer"},
    ["Mini Tusk"] = {"Mythological Pirate"},
    ["Nightmare Catcher"] = {"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"},
}

local BossAliases = {
    ["Greybeard"] = "Greybeard", ["Darkbeard"] = "Darkbeard", ["Cursed Captain"] = "Cursed Captain",
    ["rip_indra True Form"] = "rip_indra", ["Soul Reaper"] = "Soul Reaper",
}

local function NormalizeName(s)
    return tostring(s or ""):lower():gsub("[^%w]+", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

function Util.FindEnemy(names, radius)
    radius = radius or math.huge
    if type(names) == "string" then names = {names} end
    local root = Util.GetRoot(Character)
    if not root then return nil end
    local best, bestDist
    bestDist = radius
    local wanted = {}
    for _, n in ipairs(names or {}) do wanted[NormalizeName(n)] = true end
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if Util.IsReady(enemy) then
            local nn = NormalizeName(enemy.Name)
            local matched = wanted[nn]
            if not matched then
                for n in pairs(wanted) do
                    if nn:find(n, 1, true) or n:find(nn, 1, true) then matched = true break end
                end
            end
            if matched then
                local er = Util.GetRoot(enemy)
                if er then
                    local d = (er.Position - root.Position).Magnitude
                    if d < bestDist then best, bestDist = enemy, d end
                end
            end
        end
    end
    return best, bestDist
end

function Util.GetNearestEnemy(radius)
    radius = radius or 2500
    local root = Util.GetRoot(Character)
    if not root then return nil end
    local best, bestDist
    bestDist = radius
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if Util.IsReady(enemy) then
            local er = Util.GetRoot(enemy)
            if er then
                local d = (er.Position - root.Position).Magnitude
                if d < bestDist then best, bestDist = enemy, d end
            end
        end
    end
    return best, bestDist
end

function Util.GetLevelTarget(levelValue)
    for _, row in ipairs(LevelMobRanges) do
        if levelValue >= row[1] and levelValue <= row[2] then
            return row[3]
        end
    end
    return nil
end

function Util.TryStartLevelQuest(levelValue, mobName)
    -- Quest names used by the game's CommF_ endpoint. This is intentionally best-effort;
    -- farm still works without a quest via the mob fallback below.
    local q = {
        {1, 9, "BanditQuest1", 1, "Bandit"}, {15,29,"JungleQuest",1,"Monkey"}, {30,54,"JungleQuest",2,"Gorilla"},
        {55,74,"BuggyQuest1",1,"Pirate"}, {75,89,"BuggyQuest1",2,"Brute"}, {90,119,"DesertQuest",1,"Desert Bandit"},
        {120,149,"DesertQuest",2,"Desert Officer"}, {150,189,"SnowQuest",1,"Snow Bandit"}, {190,249,"SnowQuest",2,"Snowman"},
        {250,299,"MarineQuest2",1,"Chief Petty Officer"}, {300,374,"SkyQuest",1,"Sky Bandit"}, {375,399,"SkyQuest",2,"Dark Master"},
        {400,449,"PrisonerQuest",1,"Prisoner"}, {450,474,"PrisonerQuest",2,"Dangerous Prisoner"}, {475,524,"ColosseumQuest",1,"Toga Warrior"},
        {525,549,"ColosseumQuest",2,"Gladiator"}, {550,624,"MagmaQuest",1,"Military Soldier"}, {625,649,"MagmaQuest",2,"Military Spy"},
        {650,699,"FishmanQuest",1,"Fishman Warrior"},
        {700,724,"Area1Quest",1,"Raider"}, {725,774,"Area1Quest",2,"Mercenary"}, {775,799,"Area2Quest",1,"Swan Pirate"},
        {800,874,"Area2Quest",2,"Factory Staff"}, {875,899,"MarineQuest3",1,"Marine Lieutenant"}, {900,949,"MarineQuest3",2,"Marine Captain"},
        {950,999,"ZombieQuest",1,"Zombie"}, {1000,1049,"ZombieQuest",2,"Vampire"}, {1050,1099,"SnowMountainQuest",1,"Snow Trooper"},
        {1100,1124,"SnowMountainQuest",2,"Winter Warrior"}, {1125,1174,"IceSideQuest",1,"Lab Subordinate"}, {1175,1199,"IceSideQuest",2,"Horned Warrior"},
        {1200,1249,"FireSideQuest",1,"Magma Ninja"}, {1250,1299,"FireSideQuest",2,"Lava Pirate"},
        {1300,1324,"ShipQuest1",1,"Ship Deckhand"}, {1325,1374,"ShipQuest1",2,"Ship Engineer"}, {1375,1399,"ShipQuest2",1,"Ship Steward"}, {1400,1449,"ShipQuest2",2,"Ship Officer"},
        {1450,1474,"FrostQuest",1,"Arctic Warrior"}, {1475,1499,"FrostQuest",2,"Snow Lurker"},
        {1500,1524,"PiratePortQuest",1,"Pirate Millionaire"}, {1525,1574,"PiratePortQuest",2,"Pistol Billionaire"},
        {1575,1599,"AmazonQuest",1,"Dragon Crew Warrior"}, {1600,1624,"AmazonQuest",2,"Dragon Crew Archer"},
        {1625,1649,"FemaleIslandQuest",1,"Female Islander"}, {1650,1699,"FemaleIslandQuest",2,"Giant Islander"},
        {1700,1724,"DeepForestQuest",1,"Marine Commodore"}, {1725,1774,"DeepForestQuest",2,"Marine Rear Admiral"},
        {1775,1799,"DeepForestQuest",1,"Fishman Raider"}, {1800,1824,"DeepForestQuest",2,"Fishman Captain"},
        {1825,1849,"DeepForestQuest",1,"Forest Pirate"}, {1850,1899,"DeepForestQuest",2,"Mythological Pirate"},
        {1900,1924,"DeepForestQuest",1,"Jungle Pirate"}, {1925,1974,"DeepForestQuest",2,"Musketeer Pirate"},
        {1975,1999,"HauntedQuest1",1,"Reborn Skeleton"}, {2000,2049,"HauntedQuest1",2,"Living Zombie"},
        {2050,2074,"HauntedQuest2",1,"Demonic Soul"}, {2075,2099,"HauntedQuest2",2,"Posessed Mummy"},
        {2100,2124,"IceCreamIslandQuest",1,"Peanut Scout"}, {2125,2149,"IceCreamIslandQuest",2,"Peanut President"},
        {2150,2174,"IceCreamIslandQuest",1,"Ice Cream Chef"}, {2175,2199,"IceCreamIslandQuest",2,"Ice Cream Commander"},
        {2200,2224,"CakeQuest1",1,"Cookie Crafter"}, {2225,2249,"CakeQuest1",2,"Cake Guard"},
        {2250,2274,"CakeQuest2",1,"Baking Staff"}, {2275,2299,"CakeQuest2",2,"Head Baker"},
        {2300,2324,"CakeQuest2",1,"Cocoa Warrior"}, {2325,2349,"CakeQuest2",2,"Chocolate Bar Battler"},
        {2350,2374,"CakeQuest2",1,"Sweet Thief"}, {2375,2399,"CakeQuest2",2,"Candy Rebel"}, {2400,2449,"CandyQuest1",1,"Candy Pirate"},
    }
    for _, row in ipairs(q) do
        if levelValue >= row[1] and levelValue <= row[2] and (not mobName or NormalizeName(mobName) == NormalizeName(row[5])) then
            pcall(function() Util.FireInvoke("StartQuest", row[3], row[4]) end)
            return row[3], row[4]
        end
    end
    return nil
end

-- Tween
local Tween = {}
Tween._Cancel = false

function Tween.Stop()
    Tween._Cancel = true
end

function Tween.To(cframe, speed)
    if not Root or not Root.Parent then return end
    if typeof(cframe) == "Vector3" then cframe = CFrame.new(cframe) end
    Tween._Cancel = false
    local start = Root.CFrame
    local distance = (cframe.Position - start.Position).Magnitude
    if distance <= 5 then return end
    speed = speed or Config.TweenSpeed
    local duration = distance / speed
    local startTime = tick()
    while tick() - startTime < duration do
        if Tween._Cancel or not Root or not Root.Parent then break end
        if not Humanoid or Humanoid.Health <= 0 then break end
        local alpha = math.min((tick() - startTime) / duration, 1)
        Root.CFrame = start:Lerp(cframe, alpha)
        RunService.Heartbeat:Wait()
    end
    if Root and Root.Parent then Root.CFrame = cframe end
end

-- Fast Attack
local FastAttack = {}
local reRegisterAttack

pcall(function()
    local CombatUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatUtil"))
    if CombatUtil and CombatUtil.CanAttack and hookfunction then
        hookfunction(CombatUtil.CanAttack, function() return true end)
    end
    reRegisterAttack = Net:WaitForChild("RE/RegisterAttack")
end)

function FastAttack.GetHits(radius)
    radius = radius or 500
    local hits = {}
    local myRoot = Util.GetRoot(Character)
    if not myRoot then return hits end
    if Config.AttackMobs then
        for _, enemy in ipairs(Enemies:GetChildren()) do
            if Util.IsReady(enemy) then
                local eRoot = Util.GetRoot(enemy)
                if eRoot then
                    local dist = (eRoot.Position - myRoot.Position).Magnitude
                    if dist <= radius then
                        table.insert(hits, {enemy, eRoot, dist})
                    end
                end
            end
        end
    end
    if Config.AttackPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and Util.IsAlive(player.Character) then
                if not (player.Team and LP.Team and player.Team == LP.Team) then
                    local pRoot = Util.GetRoot(player.Character)
                    if pRoot then
                        local dist = (pRoot.Position - myRoot.Position).Magnitude
                        if dist <= radius then
                            table.insert(hits, {player.Character, pRoot, dist})
                        end
                    end
                end
            end
        end
    end
    table.sort(hits, function(a, b) return a[3] < b[3] end)
    local result = {}
    for i = 1, math.min(#hits, 5) do
        result[i] = {hits[i][1], hits[i][2]}
    end
    return result
end

local RegisterHit
pcall(function()
    local NetAPI = require(Net)
    RegisterHit = NetAPI:RemoteEvent("RegisterHit", true)
end)

function FastAttack.AttackTarget(target)
    if not target or not Util.IsReady(target) then return false end
    if not Character or not Humanoid or Humanoid.Health <= 0 then return false end
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then
        Util.EquipWeapon(Config.SelectWeapon)
        tool = Character:FindFirstChildOfClass("Tool")
        if not tool then return false end
    end
    local tr = Util.GetRoot(target)
    if not tr then return false end

    local hits = {{target, tr}}
    if reRegisterAttack then pcall(function() reRegisterAttack:FireServer(0.3) end) end

    if RegisterHit then
        pcall(function()
            RegisterHit:FireServer(tr, hits, nil, nil, tostring(LP.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
        end)
    end

    local left = tool:FindFirstChild("LeftClickRemote")
    if left then
        pcall(function() left:FireServer(Vector3.new(0.01, -500, 0.01), 1, true) end)
    end
    return true
end

function FastAttack.Attack()
    if not Character or not Humanoid or Humanoid.Health <= 0 then return end
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then
        Util.EquipWeapon(Config.SelectWeapon)
        tool = Character:FindFirstChildOfClass("Tool")
        if not tool then return end
    end
    if tool.ToolTip == "Gun" then return end
    local hits = FastAttack.GetHits(500)
    if #hits == 0 then return end

    if reRegisterAttack then pcall(function() reRegisterAttack:FireServer(0.3) end) end
    if RegisterHit then
        local firstRoot = hits[1][2]
        pcall(function()
            RegisterHit:FireServer(firstRoot, hits, nil, nil, tostring(LP.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
        end)
    end
    local left = tool:FindFirstChild("LeftClickRemote")
    if left then
        pcall(function() left:FireServer(Vector3.new(0.01, -500, 0.01), 1, true) end)
    end
end

-- ESP
local ESP = {}
ESP._Cache = setmetatable({}, {__mode = "k"})

function ESP.Clear(category)
    for inst, data in pairs(ESP._Cache) do
        if not category or data.Cat == category then
            if data.BB and data.BB.Parent then data.BB:Destroy() end
            ESP._Cache[inst] = nil
        end
    end
end

function ESP.Add(adornee, text, color, cat)
    if not adornee or ESP._Cache[adornee] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "DungdxESP"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 5000
    bb.Parent = adornee
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.RichText = true
    lbl.Text = text or ""
    lbl.Parent = bb
    ESP._Cache[adornee] = {BB = bb, Cat = cat}
end

function ESP.Update()
    if Config.ESPPlayer then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and Util.IsAlive(player.Character) then
                local head = player.Character:FindFirstChild("Head")
                if head and not ESP._Cache[head] then
                    local lvl = player:FindFirstChild("Data") and player.Data:FindFirstChild("Level")
                    ESP.Add(head, player.Name .. " [Lv." .. (lvl and lvl.Value or "?") .. "]", Color3.fromRGB(255, 80, 80), "Player")
                end
            end
        end
    else ESP.Clear("Player") end

    if Config.ESPChest then
        local cm = Workspace:FindFirstChild("ChestModels")
        if cm then
            for _, chest in ipairs(cm:GetChildren()) do
                local root = chest:FindFirstChild("RootPart")
                if root and not ESP._Cache[root] then
                    local n = chest.Name:lower()
                    local c, l = Color3.fromRGB(255, 255, 255), "Chest"
                    if n:find("silver") then c = Color3.fromRGB(200, 200, 220); l = "Silver"
                    elseif n:find("gold") then c = Color3.fromRGB(255, 215, 0); l = "Gold"
                    elseif n:find("diamond") then c = Color3.fromRGB(0, 220, 255); l = "Diamond" end
                    ESP.Add(root, l, c, "Chest")
                end
            end
        end
    else ESP.Clear("Chest") end

    if Config.ESPFruit then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name:find("Fruit") then
                local h = obj:FindFirstChild("Handle") or obj.PrimaryPart
                if h and not ESP._Cache[h] then
                    ESP.Add(h, obj.Name, Color3.fromRGB(255, 170, 0), "Fruit")
                end
            end
        end
    else ESP.Clear("Fruit") end

    if Config.ESPIsland then
        local locs = WorldOrigin and WorldOrigin:FindFirstChild("Locations")
        if locs then
            for _, loc in ipairs(locs:GetChildren()) do
                if loc:IsA("BasePart") and loc.Name ~= "Sea" and not ESP._Cache[loc] then
                    ESP.Add(loc, loc.Name, Color3.fromRGB(100, 200, 255), "Island")
                end
            end
        end
    else ESP.Clear("Island") end
end

-- Functions
local F = {}

F.AutoFarmLevel = function()
    while Config.AutoFarmLevel do
        task.wait(0.15)
        if not Util.IsAlive(Character) then task.wait(1) continue end

        local lvl = Level.Value
        local targetName = Util.GetLevelTarget(lvl)
        local target = targetName and Util.FindEnemy(targetName, 2500) or nil

        -- Never get stuck just because the quest UI is closed.
        if not target then
            target = Util.GetNearestEnemy(2500)
        end

        if target then
            local er = Util.GetRoot(target)
            if er then
                -- Quest start is best-effort; farming remains functional without it.
                if not Util.HasQuest() then Util.TryStartLevelQuest(lvl, targetName) end
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(er.CFrame * CFrame.new(0, 15, 0))
                if Config.BringMonster and sethiddenproperty then
                    pcall(function()
                        sethiddenproperty(LP, "SimulationRadius", math.max(Config.BringRadius, 350))
                        sethiddenproperty(LP, "MaxSimulationRadius", math.max(Config.BringRadius, 350))
                    end)
                end
                task.wait(0.03)
                if Config.FastAttack then FastAttack.AttackTarget(target) end
            end
        else
            task.wait(0.5)
        end
    end
end

F.AutoFarmBones = function()
    local list = {"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"}
    while Config.AutoFarmBones do
        task.wait(0.3)
        if not Util.IsAlive(Character) then continue end
        local nearest, minDist = nil, 500
        local myRoot = Util.GetRoot(Character)
        for _, enemy in ipairs(Enemies:GetChildren()) do
            if Util.IsReady(enemy) then
                for _, n in ipairs(list) do
                    if enemy.Name == n then
                        local eRoot = Util.GetRoot(enemy)
                        if eRoot then
                            local d = (eRoot.Position - myRoot.Position).Magnitude
                            if d < minDist then minDist = d nearest = enemy end
                        end
                        break
                    end
                end
            end
        end
        if nearest then
            local eRoot = Util.GetRoot(nearest)
            Util.AutoHaki()
            Util.EquipWeapon(Config.SelectWeapon)
            Tween.To(eRoot.CFrame * CFrame.new(0, 15, 0))
            task.wait(0.05)
            FastAttack.Attack()
        end
    end
end

F.AutoFarmMaterial = function()
    while Config.AutoFarmMaterial do
        task.wait(0.2)
        if not Util.IsAlive(Character) then continue end
        local mobs = MaterialMobs[Config.SelectMaterial] or {Config.SelectMaterial}
        local target = Util.FindEnemy(mobs, 2500)
        if target then
            local er = Util.GetRoot(target)
            if er then
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(er.CFrame * CFrame.new(0, 15, 0))
                task.wait(0.03)
                FastAttack.AttackTarget(target)
            end
        else
            task.wait(0.5)
        end
    end
end

F.AutoFarmBoss = function()
    local lastNotify = 0
    while Config.AutoFarmBoss do
        task.wait(0.25)
        if not Util.IsAlive(Character) then continue end
        local bossName = BossAliases[Config.SelectBoss] or Config.SelectBoss
        local target = Util.FindEnemy(bossName, 4000)
        if target then
            local er = Util.GetRoot(target)
            if er then
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(er.CFrame * CFrame.new(0, 18, 0))
                FastAttack.AttackTarget(target)
            end
        elseif tick() - lastNotify > 8 then
            lastNotify = tick()
            Util.Notify("Auto Boss", Config.SelectBoss .. " chưa spawn trong server này.", 4)
        end
    end
end

F.AutoChest = function()
    while Config.AutoFarmChest do
        task.wait(0.3)
        if not Util.IsAlive(Character) then continue end
        local cm = Workspace:FindFirstChild("ChestModels")
        if not cm then continue end
        local nearest, minDist = nil, 800
        local myRoot = Util.GetRoot(Character)
        for _, chest in ipairs(cm:GetChildren()) do
            local root = chest:FindFirstChild("RootPart")
            if root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < minDist then minDist = d nearest = root end
            end
        end
        if nearest then
            Tween.To(nearest.CFrame * CFrame.new(0, 3, 0))
            task.wait(0.1)
        end
    end
end

F.AutoElite = function()
    local elites = {"Urban", "Deandre", "Diablo"}
    local lastQuest = 0
    while Config.AutoFarmElite do
        task.wait(0.25)
        if not Util.IsAlive(Character) then continue end
        local target = Util.FindEnemy(elites, 2500)
        if target then
            local er = Util.GetRoot(target)
            if er then
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(er.CFrame * CFrame.new(0, 15, 0))
                FastAttack.AttackTarget(target)
            end
        elseif tick() - lastQuest > 2 then
            lastQuest = tick()
            pcall(function() Util.FireInvoke("EliteHunter") end)
        end
    end
end

F.AutoRaid = function()
    while Config.AutoRaid do
        task.wait(0.25)
        if not Util.IsAlive(Character) then continue end

        local raidActive = false
        if WorldOrigin then
            local locs = WorldOrigin:FindFirstChild("Locations")
            if locs then
                for _, part in ipairs(locs:GetChildren()) do
                    if part.Name:match("^Island %d+$") and (part:IsA("BasePart") or part:IsA("Model")) then
                        local pos = part:IsA("BasePart") and part.Position or part:GetPivot().Position
                        local r = Util.GetRoot(Character)
                        if r and (pos - r.Position).Magnitude < 3500 then raidActive = true break end
                    end
                end
            end
        end

        if raidActive then
            local target = Util.GetNearestEnemy(2500)
            if target then
                local er = Util.GetRoot(target)
                if er then
                    Util.AutoHaki()
                    Util.EquipWeapon(Config.SelectWeapon)
                    Tween.To(er.CFrame * CFrame.new(0, 15, 0))
                    FastAttack.AttackTarget(target)
                end
            end
        else
            if not Util.HasTool("Special Microchip") and not Util.HasTool("Microchip") then
                pcall(function() Util.FireInvoke("RaidsNpc", "Select", Config.SelectRaid) end)
                task.wait(0.8)
            end

            local summon = Map and (Map:FindFirstChild("RaidSummon2", true) or Map:FindFirstChild("RaidSummon", true))
            local click = summon and summon:FindFirstChild("ClickDetector", true)
            local main = summon and summon:FindFirstChild("Main", true)
            if not click and main then click = main:FindFirstChildOfClass("ClickDetector") end
            if click and fireclickdetector then
                local part = main or click.Parent
                if part and part:IsA("BasePart") then
                    Tween.To(part.CFrame)
                    task.wait(0.3)
                    pcall(function() fireclickdetector(click) end)
                end
            end
        end
    end
end

F.AutoSeaEvents = function()
    while Config.AutoSeaEvents do
        task.wait(0.2)
        if not Util.IsAlive(Character) then continue end
        local targetNames = {"terror shark", "sea beast", "shark", "piranha", "fish crew member", "pirate brigade", "pirate grand brigade", "ghost ship"}
        local myRoot = Util.GetRoot(Character)
        local target, bestDist
        if myRoot then
            for _, sb in ipairs(SeaBeasts:GetChildren()) do
                if Util.IsReady(sb) then
                    local sr = Util.GetRoot(sb) or sb:FindFirstChildWhichIsA("BasePart")
                    if sr then
                        local d = (sr.Position - myRoot.Position).Magnitude
                        if d < (bestDist or 1500) then target, bestDist = sb, d end
                    end
                end
            end
            for _, enemy in ipairs(Enemies:GetChildren()) do
                if Util.IsReady(enemy) then
                    local low = enemy.Name:lower()
                    for _, n in ipairs(targetNames) do
                        if low:find(n, 1, true) then
                            local er = Util.GetRoot(enemy) or enemy:FindFirstChild("Engine") or enemy:FindFirstChildWhichIsA("BasePart")
                            if er then
                                local d = (er.Position - myRoot.Position).Magnitude
                                if d < (bestDist or 1500) then target, bestDist = enemy, d end
                            end
                            break
                        end
                    end
                end
            end
        end

        if target then
            local nr = Util.GetRoot(target) or target:FindFirstChild("Engine") or target:FindFirstChildWhichIsA("BasePart")
            if nr then
                local waterY = 0
                local water = Map and Map:FindFirstChild("WaterBase-Plane")
                if water then waterY = water.Position.Y end
                local offsetY = Config.AutoDodgeSea and 400 or 250
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(CFrame.new(nr.Position.X, waterY + offsetY, nr.Position.Z))
                if target:IsDescendantOf(Enemies) then
                    FastAttack.AttackTarget(target)
                else
                    -- SeaBeasts often use a Health value rather than a Humanoid; still try the generic hit path.
                    FastAttack.AttackTarget(target)
                end
            end
        end
    end
end

F.AutoFish = function()
    while Config.AutoFish do
        task.wait(0.05)
        if not Util.IsAlive(Character) then continue end
        local rodName = Config.SelectRod or "Fishing Rod"
        local rod = Character:FindFirstChild(rodName) or Backpack:FindFirstChild(rodName) or Character:FindFirstChild("Fishing Rod") or Backpack:FindFirstChild("Fishing Rod")
        if not rod then
            pcall(function() Util.FireInvoke("LoadItem", rodName, {"Gear"}) end)
            task.wait(0.5)
            continue
        end
        if rod.Parent == Backpack then
            Humanoid:EquipTool(rod)
            task.wait(0.1)
        end

        local serverState = rod:GetAttribute("ServerState")
        local state = rod:GetAttribute("State")
        local reeling = PlayerGui:FindFirstChild("Fishing_Reeling")
        local req = ReplicatedStorage:FindFirstChild("FishReplicated") and ReplicatedStorage.FishReplicated:FindFirstChild("FishingRequest")

        if reeling and reeling.Enabled then
            local mini = reeling:FindFirstChild("Minigame")
            mini = mini and mini:FindFirstChild("Container")
            local zone = mini and mini:FindFirstChild("ReelZone")
            local fish = mini and mini:FindFirstChild("Fish")
            if zone and fish and fish.Visible then
                local delta = (fish.Position.X.Scale + fish.Size.X.Scale * 0.5) - (zone.Position.X.Scale + zone.Size.X.Scale * 0.5)
                if delta > 0.03 then
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                elseif delta < -0.03 then
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                else
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end
            end
            if req then pcall(function() req:InvokeServer("Catch", 1) end) end
        elseif serverState == "Biting" or state == "Biting" then
            VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait(0.08)
            VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            task.wait(0.12)
        else
            VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait(0.45)
            VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            task.wait(0.25)
        end
    end
end

F.AutoFishSlap = function()
    while Config.AutoFishSlap do
        task.wait(0.05)
        local mg = PlayerGui:FindFirstChild("FishSlapMinigame")
        if mg and mg.Enabled then
            local bar = mg:FindFirstChild("Bar")
            local gz = bar and bar:FindFirstChild("GreenZone")
            local tk = bar and bar:FindFirstChild("Tick")
            local btn = mg:FindFirstChild("SlapButton")
            if gz and tk and btn and firesignal then
                local ty = tk.AbsolutePosition.Y + tk.AbsoluteSize.Y * 0.5
                local zy = gz.AbsolutePosition.Y + gz.AbsoluteSize.Y * 0.5
                if math.abs(ty - zy) <= gz.AbsoluteSize.Y * 0.45 then
                    pcall(function() firesignal(btn.Activated) end)
                end
            end
        end
    end
end

F.AutoBoat = function()
    while Config.AutoBoat do
        task.wait(0.5)
        if not Util.IsAlive(Character) then continue end
        local myBoat = nil
        for _, boat in ipairs(Boats:GetChildren()) do
            local o = boat:FindFirstChild("Owner")
            if o and (o.Value == LP or tostring(o.Value) == LP.Name) then
                myBoat = boat
                break
            end
        end
        if not myBoat then
            Tween.To(CFrame.new(-16927, 9, 433))
            task.wait(0.5)
            pcall(function() Util.FireInvoke("BuyBoat", Config.SelectBoat) end)
        else
            local h = Util.GetHumanoid(Character)
            if h and not h.Sit then
                local seat = myBoat:FindFirstChildWhichIsA("VehicleSeat") or myBoat:FindFirstChild("VehicleSeat")
                if seat then
                    Tween.To(seat.CFrame * CFrame.new(0, 3, 0))
                    task.wait(0.3)
                end
            else
                local seat = myBoat:FindFirstChildWhichIsA("VehicleSeat") or myBoat:FindFirstChild("VehicleSeat")
                if seat then
                    local tp = Vector3.new(-10000000, 31, 37016)
                    local d = (seat.Position - tp).Magnitude
                    if d > 50 then
                        local dir = (tp - seat.Position).Unit
                        seat.CFrame = seat.CFrame + dir * 5
                    end
                end
            end
        end
    end
end

F.AutoStoreFruit = function()
    while Config.AutoStoreFruit do
        task.wait(1)
        for _, c in ipairs({Backpack, Character}) do
            if c then
                for _, tool in ipairs(c:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:find("Fruit") then
                        local fn = tool:GetAttribute("OriginalName") or tool.Name:match("^(.-)%-") or tool.Name
                        pcall(function() Util.FireInvoke("StoreFruit", fn, tool) end)
                        task.wait(0.3)
                    end
                end
            end
        end
    end
end

F.AutoRandomFruit = function()
    while Config.AutoRandomFruit do
        task.wait(1)
        pcall(function() Util.FireInvoke("Cousin", "DLCBoxData") end)
        local sp = PlayerGui:FindFirstChild("SpinnerWindow")
        if sp and firesignal then
            local ab = sp:FindFirstChild("AboveSpinner")
            local nv = ab and ab:FindFirstChild("Navigation")
            local cb = nv and nv:FindFirstChild("CloseButton")
            if cb and cb.Visible then
                pcall(function() firesignal(cb.Activated) end)
            end
        end
    end
end

F.AutoAwaken = function()
    while Config.AutoAwaken do
        task.wait(0.5)
        pcall(function()
            Util.FireInvoke("Awakener", "Check")
            Util.FireInvoke("Awakener", "Awaken")
        end)
    end
end

F.AutoStats = function()
    while Config.AutoStats do
        task.wait(0.25)
        local pts = Data:FindFirstChild("Points")
        local stat = Config.StatTarget or "Melee"
        if pts and pts.Value > 0 then
            pcall(function() Util.FireInvoke("AddPoint", stat, pts.Value) end)
        end
    end
end

F.AutoSkills = function()
    while Config.AutoSkills do
        task.wait(0.05)
        if not Util.IsAlive(Character) then continue end
        for _, k in ipairs({"Z", "X", "C", "V", "F"}) do
            if not Config.AutoSkills then break end
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                task.wait(0.03)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game)
            end)
            task.wait(0.08)
        end
    end
end

F.AutoHakiLoop = function()
    while Config.AutoHaki do
        task.wait(0.5)
        pcall(function() Util.AutoHaki() end)
    end
end

F.AutoObservationHaki = function()
    while Config.AutoObservationHaki do
        task.wait(0.5)
        pcall(function() if CommE then CommE:FireServer("Ken", true) end end)
    end
end

F.AutoAntiAFK = function()
    while Config.AntiAFK do
        task.wait(300)
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
    end
end

F.AutoNoFog = function()
    while Config.AutoNoFog do
        task.wait(2)
        pcall(function()
            Lighting.FogEnd = math.huge
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then sky:Destroy() end
        end)
    end
end

F.AutoMemory = function()
    while Config.AutoMemory do
        task.wait(60)
        pcall(function() if collectgarbage then collectgarbage("step", 200) end end)
    end
end

F.AutoHop30 = function()
    while Config.AutoHop30 do
        task.wait(1800)
        pcall(function()
            if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
                ReplicatedStorage.__ServerBrowser:InvokeServer("teleport")
            end
        end)
    end
end

-- ==================== UI ĐẸP + NÚT TOGGLE ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DungdxUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Nút mở/đóng UI
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 180)
ToggleBtn.Text = "DX"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local TS = Instance.new("UIStroke", ToggleBtn)
TS.Color = Color3.fromRGB(150, 120, 255)
TS.Thickness = 2

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 600, 0, 440)
Main.Position = UDim2.new(0.5, -300, 0.5, -220)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MS = Instance.new("UIStroke", Main)
MS.Color = Color3.fromRGB(110, 80, 220)
MS.Thickness = 2

-- Title bar
local Title = Instance.new("Frame")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(32, 28, 55)
Title.BorderSizePixel = 0
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1, -80, 1, 0)
TTitle.Position = UDim2.new(0, 15, 0, 0)
TTitle.BackgroundTransparency = 1
TTitle.Text = "🌊 BLOX FRUIT | Dungdx | Blox Community VN"
TTitle.TextColor3 = Color3.fromRGB(220, 200, 255)
TTitle.TextXAlignment = Enum.TextXAlignment.Left
TTitle.Font = Enum.Font.GothamBold
TTitle.TextSize = 14
TTitle.Parent = Title

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 26)
MinBtn.Position = UDim2.new(1, -70, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 140)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Parent = Title
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 26)
CloseBtn.Position = UDim2.new(1, -36, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Title
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Tab bar bên trái
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 140, 1, -50)
TabBar.Position = UDim2.new(0, 8, 0, 44)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 10)

local TL = Instance.new("UIListLayout")
TL.Padding = UDim.new(0, 4)
TL.SortOrder = Enum.SortOrder.LayoutOrder
TL.Parent = TabBar
local TP = Instance.new("UIPadding")
TP.PaddingTop = UDim.new(0, 8)
TP.PaddingLeft = UDim.new(0, 6)
TP.PaddingRight = UDim.new(0, 6)
TP.Parent = TabBar

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -155, 1, -50)
Content.Position = UDim2.new(0, 148, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Info bar
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 20)
Info.Position = UDim2.new(0, 10, 1, -24)
Info.BackgroundTransparency = 1
Info.Text = "💬 discord.gg/BQwcUEdWCW  |  Author: Dungdx"
Info.TextColor3 = Color3.fromRGB(150, 130, 255)
Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.Parent = Main

-- Drag
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle UI
local uiOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    uiOpen = not uiOpen
    Main.Visible = uiOpen
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    uiOpen = false
end)
MinBtn.MouseButton1Click:Connect(function()
    if Main.Size.Y.Offset > 100 then
        Main.Size = UDim2.new(0, 600, 0, 40)
    else
        Main.Size = UDim2.new(0, 600, 0, 440)
    end
end)

-- Tabs
local Tabs = {}
local ActiveTab = nil

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(40, 35, 65)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 190, 230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 200)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = Content

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = scroll
    local pp = Instance.new("UIPadding")
    pp.PaddingTop = UDim.new(0, 6)
    pp.PaddingLeft = UDim.new(0, 4)
    pp.PaddingRight = UDim.new(0, 4)
    pp.PaddingBottom = UDim.new(0, 6)
    pp.Parent = scroll

    local tab = {Btn = btn, Scroll = scroll}
    table.insert(Tabs, tab)

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do
            t.Btn.BackgroundColor3 = Color3.fromRGB(40, 35, 65)
            t.Btn.TextColor3 = Color3.fromRGB(200, 190, 230)
            t.Scroll.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(90, 70, 180)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        scroll.Visible = true
    end)

    if #Tabs == 1 then
        btn.BackgroundColor3 = Color3.fromRGB(90, 70, 180)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        scroll.Visible = true
    end

    -- Toggle
    function tab:Toggle(label, default, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 34)
        b.BackgroundColor3 = Color3.fromRGB(35, 32, 52)
        b.Text = "  " .. label .. ": " .. (default and "ON" or "OFF")
        b.TextColor3 = Color3.fromRGB(210, 210, 240)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Font = Enum.Font.Gotham
        b.TextSize = 13
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

        local state = default
        b.MouseButton1Click:Connect(function()
            state = not state
            b.Text = "  " .. label .. ": " .. (state and "ON" or "OFF")
            b.BackgroundColor3 = state and Color3.fromRGB(30, 130, 80) or Color3.fromRGB(35, 32, 52)
            b.TextColor3 = state and Color3.fromRGB(200, 255, 220) or Color3.fromRGB(210, 210, 240)
            if callback then pcall(callback, state) end
        end)
        return b
    end

    -- Button
    function tab:Button(label, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 34)
        b.BackgroundColor3 = Color3.fromRGB(65, 55, 110)
        b.Text = "  " .. label
        b.TextColor3 = Color3.fromRGB(240, 240, 255)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Font = Enum.Font.Gotham
        b.TextSize = 13
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        b.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
        return b
    end

    -- Dropdown
    function tab:Dropdown(label, options, default, callback)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, -8, 0, 34)
        c.BackgroundColor3 = Color3.fromRGB(35, 32, 52)
        c.Parent = scroll
        Instance.new("UICorner", c).CornerRadius = UDim.new(0, 7)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.4, 0, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = Color3.fromRGB(210, 210, 240)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Gotham
        l.TextSize = 12
        l.Parent = c

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.55, -10, 0, 26)
        b.Position = UDim2.new(0.45, 0, 0, 4)
        b.BackgroundColor3 = Color3.fromRGB(70, 60, 120)
        b.Text = tostring(default)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.Parent = c
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        local open = false
        local list
        b.MouseButton1Click:Connect(function()
            if open and list then list:Destroy() list = nil open = false return end
            open = true
            list = Instance.new("Frame")
            list.Size = UDim2.new(1, -8, 0, math.min(#options * 26, 180))
            list.Position = UDim2.new(0, 4, 1, 4)
            list.BackgroundColor3 = Color3.fromRGB(45, 40, 70)
            list.BorderSizePixel = 0
            list.ZIndex = 10
            list.Parent = c
            Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
            local li = Instance.new("UIListLayout")
            li.Parent = list
            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1, 0, 0, 26)
                ob.BackgroundColor3 = Color3.fromRGB(55, 50, 85)
                ob.Text = tostring(opt)
                ob.TextColor3 = Color3.fromRGB(255, 255, 255)
                ob.Font = Enum.Font.Gotham
                ob.TextSize = 12
                ob.Parent = list
                ob.MouseButton1Click:Connect(function()
                    b.Text = tostring(opt)
                    if list then list:Destroy() end
                    list = nil
                    open = false
                    if callback then pcall(callback, opt) end
                end)
            end
        end)
        return b
    end

    -- Slider
    function tab:Slider(label, min, max, default, callback)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, -8, 0, 48)
        c.BackgroundColor3 = Color3.fromRGB(35, 32, 52)
        c.Parent = scroll
        Instance.new("UICorner", c).CornerRadius = UDim.new(0, 7)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 20)
        l.Position = UDim2.new(0, 10, 0, 4)
        l.BackgroundTransparency = 1
        l.Text = label .. ": " .. tostring(default)
        l.TextColor3 = Color3.fromRGB(210, 210, 240)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Gotham
        l.TextSize = 12
        l.Parent = c

        local sf = Instance.new("Frame")
        sf.Size = UDim2.new(1, -20, 0, 10)
        sf.Position = UDim2.new(0, 10, 0, 30)
        sf.BackgroundColor3 = Color3.fromRGB(55, 50, 80)
        sf.BorderSizePixel = 0
        sf.Parent = c
        Instance.new("UICorner", sf).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / math.max(max - min, 1), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(140, 110, 240)
        fill.BorderSizePixel = 0
        fill.Parent = sf
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local dr = false
        sf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = true end end)
        sf.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = false end end)
        UserInputService.InputChanged:Connect(function(i)
            if dr and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rx = math.clamp((i.Position.X - sf.AbsolutePosition.X) / sf.AbsoluteSize.X, 0, 1)
                local v = math.floor(min + (max - min) * rx)
                fill.Size = UDim2.new(rx, 0, 1, 0)
                l.Text = label .. ": " .. v
                if callback then pcall(callback, v) end
            end
        end)
        return sf
    end

    -- Label
    function tab:Label(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -8, 0, 24)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(170, 160, 200)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Gotham
        l.TextSize = 12
        l.Parent = scroll
        return l
    end

    return tab
end

-- ==================== TABS ====================
local FarmTab = CreateTab("🌾 Farm")
FarmTab:Label("─ FARM SETTINGS ─")
FarmTab:Dropdown("Farm Mode", {"Quest", "No Quest", "Nearest"}, "Quest", function(v) Config.FarmMode = v end)
FarmTab:Dropdown("Weapon", {"Melee", "Sword", "Gun", "Blox Fruit"}, "Melee", function(v) Config.SelectWeapon = v end)
FarmTab:Slider("Tween Speed", 50, 500, 250, function(v) Config.TweenSpeed = v end)
FarmTab:Slider("Bring Radius", 100, 500, 350, function(v) Config.BringRadius = v end)
FarmTab:Toggle("Bring Monster", true, function(v) Config.BringMonster = v end)
FarmTab:Toggle("Auto Farm Level", false, function(v)
    Config.AutoFarmLevel = v
    if v then task.spawn(F.AutoFarmLevel) end
end)
FarmTab:Toggle("Auto Farm Bones", false, function(v)
    Config.AutoFarmBones = v
    if v then task.spawn(F.AutoFarmBones) end
end)
FarmTab:Dropdown("Material", {"Leather", "Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail", "Radioactive Material", "Ectoplasm", "Mystic Droplet", "Vampire Fang", "Demonic Wisp", "Conjured Cocoa", "Dragon Scale", "Gunpowder", "Mini Tusk", "Nightmare Catcher"}, "Leather", function(v) Config.SelectMaterial = v end)
FarmTab:Toggle("Auto Farm Material", false, function(v)
    Config.AutoFarmMaterial = v
    if v then task.spawn(F.AutoFarmMaterial) end
end)
FarmTab:Dropdown("Boss", {"The Gorilla King", "Chief", "Yeti", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Saw", "Diamond", "Jeremy", "Orbitus", "Smoke Admiral", "Awakened Ice Admiral", "Tide Keeper", "Don Swan", "Stone", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Cake Queen", "Greybeard", "Darkbeard", "Cursed Captain", "rip_indra True Form", "Soul Reaper"}, "The Gorilla King", function(v) Config.SelectBoss = v end)
FarmTab:Toggle("Auto Farm Boss", false, function(v)
    Config.AutoFarmBoss = v
    if v then task.spawn(F.AutoFarmBoss) end
end)
FarmTab:Toggle("Auto Chest", false, function(v)
    Config.AutoFarmChest = v
    if v then task.spawn(F.AutoChest) end
end)
FarmTab:Toggle("Auto Elite Hunter", false, function(v)
    Config.AutoFarmElite = v
    if v then task.spawn(F.AutoElite) end
end)

local CombatTab = CreateTab("⚔️ Combat")
CombatTab:Label("─ COMBAT ─")
CombatTab:Toggle("Fast Attack", true, function(v) Config.FastAttack = v end)
CombatTab:Toggle("Attack Mobs", true, function(v) Config.AttackMobs = v end)
CombatTab:Toggle("Attack Players", false, function(v) Config.AttackPlayers = v end)
CombatTab:Label("─ RAID ─")
CombatTab:Dropdown("Raid", {"Flame", "Ice", "Quake", "Light", "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand", "Bird", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Kitsune"}, "Flame", function(v) Config.SelectRaid = v end)
CombatTab:Toggle("Auto Raid", false, function(v)
    Config.AutoRaid = v
    if v then task.spawn(F.AutoRaid) end
end)

local SeaTab = CreateTab("🌊 Sea")
SeaTab:Label("─ SEA BOAT ─")
SeaTab:Dropdown("Boat", {"Dinghy", "PirateSloop", "PirateBrigade", "PirateGrandBrigade", "MarineSloop", "MarineBrigade", "MarineGrandBrigade", "Beast Hunter", "Lantern", "Guardian"}, "PirateBrigade", function(v) Config.SelectBoat = v end)
SeaTab:Toggle("Auto Boat", false, function(v)
    Config.AutoBoat = v
    if v then task.spawn(F.AutoBoat) end
end)
SeaTab:Toggle("Auto Sea Events", false, function(v)
    Config.AutoSeaEvents = v
    if v then task.spawn(F.AutoSeaEvents) end
end)
SeaTab:Toggle("Auto Dodge Sea Beast", false, function(v) Config.AutoDodgeSea = v end)

local PlayerTab = CreateTab("👤 Player")
PlayerTab:Label("─ CHARACTER ─")
PlayerTab:Toggle("Auto Haki", false, function(v)
    Config.AutoHaki = v
    if v then task.spawn(F.AutoHakiLoop) end
end)
PlayerTab:Toggle("Auto Ken Haki", false, function(v)
    Config.AutoObservationHaki = v
    if v then task.spawn(F.AutoObservationHaki) end
end)
PlayerTab:Toggle("Auto Skills", false, function(v)
    Config.AutoSkills = v
    if v then task.spawn(F.AutoSkills) end
end)
PlayerTab:Dropdown("Stat", {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, "Melee", function(v) Config.StatTarget = v end)
PlayerTab:Toggle("Auto Stats", false, function(v)
    Config.StatTarget = Config.StatTarget or "Melee"
    Config.AutoStats = v
    if v then task.spawn(F.AutoStats) end
end)
PlayerTab:Label("─ FRUIT ─")
PlayerTab:Toggle("Auto Store Fruit", false, function(v)
    Config.AutoStoreFruit = v
    if v then task.spawn(F.AutoStoreFruit) end
end)
PlayerTab:Toggle("Auto Random Fruit", false, function(v)
    Config.AutoRandomFruit = v
    if v then task.spawn(F.AutoRandomFruit) end
end)
PlayerTab:Toggle("Auto Awaken", false, function(v)
    Config.AutoAwaken = v
    if v then task.spawn(F.AutoAwaken) end
end)

local ESPTab = CreateTab("👁️ ESP")
ESPTab:Label("─ ESP ─")
ESPTab:Toggle("Player ESP", false, function(v) Config.ESPPlayer = v end)
ESPTab:Toggle("Chest ESP", false, function(v) Config.ESPChest = v end)
ESPTab:Toggle("Fruit ESP", false, function(v) Config.ESPFruit = v end)
ESPTab:Toggle("Island ESP", false, function(v) Config.ESPIsland = v end)
ESPTab:Button("Clear All ESP", function() ESP.Clear() end)

local FishTab = CreateTab("🎣 Fish")
FishTab:Label("─ FISHING ─")
FishTab:Dropdown("Rod", {"Fishing Rod", "Gold Rod", "Shark Rod", "Shell Rod", "Treasure Rod"}, "Fishing Rod", function(v) Config.SelectRod = v end)
FishTab:Dropdown("Bait", {"Basic Bait", "Kelp Bait", "Good Bait", "Abyssal Bait", "Frozen Bait", "Epic Bait", "Carnivore Bait"}, "Basic Bait", function(v) Config.SelectBait = v end)
FishTab:Toggle("Auto Fish", false, function(v)
    Config.AutoFish = v
    if v then task.spawn(F.AutoFish) end
end)
FishTab:Toggle("Auto Fish Slap", false, function(v)
    Config.AutoFishSlap = v
    if v then task.spawn(F.AutoFishSlap) end
end)

local MiscTab = CreateTab("⚙️ Misc")
MiscTab:Label("─ MISC ─")
MiscTab:Toggle("Anti AFK", true, function(v)
    Config.AntiAFK = v
    if v then task.spawn(F.AutoAntiAFK) end
end)
MiscTab:Toggle("Auto No Fog", false, function(v)
    Config.AutoNoFog = v
    if v then task.spawn(F.AutoNoFog) end
end)
MiscTab:Toggle("Auto Memory Clean", false, function(v)
    Config.AutoMemory = v
    if v then task.spawn(F.AutoMemory) end
end)
MiscTab:Toggle("Auto Hop 30 Min", false, function(v)
    Config.AutoHop30 = v
    if v then task.spawn(F.AutoHop30) end
end)

local TPTab = CreateTab("🚀 TP")
TPTab:Label("─ TELEPORT ─")
TPTab:Button("Teleport Sea 1", function() pcall(function() Util.FireInvoke("TravelMain") end) end)
TPTab:Button("Teleport Sea 2", function() pcall(function() Util.FireInvoke("TravelDressrosa") end) end)
TPTab:Button("Teleport Sea 3", function() pcall(function() Util.FireInvoke("TravelZou") end) end)
TPTab:Button("Rejoin Server", function()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
            ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
        end
    end)
end)
TPTab:Button("Server Hop", function()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
            ReplicatedStorage.__ServerBrowser:InvokeServer("teleport")
        end
    end)
end)
TPTab:Button("Copy JobID", function()
    pcall(function()
        if setclipboard then
            setclipboard(tostring(game.JobId))
            Util.Notify("Copied", "JobID copied", 3)
        end
    end)
end)

local CommunityTab = CreateTab("💬 Community")
CommunityTab:Label("─ BLOX COMMUNITY VN ─")
CommunityTab:Label("Tác giả: Dungdx")
CommunityTab:Label("Discord: Blox Community VN")
CommunityTab:Label("Link: discord.gg/BQwcUEdWCW")
CommunityTab:Button("Copy Discord Link", function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/BQwcUEdWCW")
            Util.Notify("Copied", "Discord link copied!", 3)
        end
    end)
end)
CommunityTab:Button("Join Discord", function()
    pcall(function()
        local req = request or http_request or (syn and syn.request)
        if req then
            req({
                Url = "http://127.0.0.1:6463/rpc?v=1",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json", ["Origin"] = "https://discord.com"},
                Body = HttpService:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    args = {code = "BQwcUEdWCW"},
                    nonce = tostring(math.random(100000, 999999))
                })
            })
        end
    end)
end)

-- ==================== MAIN LOOP ====================
task.spawn(function()
    while task.wait(0.15) do
        pcall(function()
            ESP.Update()
            if Config.AutoHakiAlways and Character and Character.Parent then
                Util.AutoHaki()
            end
            if Config.FastAttack and Config.AttackMobs and Character and Character.Parent then
                -- Fast Attack now works as a real independent toggle, not just a helper for farm loops.
                local nearest = Util.GetNearestEnemy(60)
                if nearest then FastAttack.AttackTarget(nearest) end
            end
        end)
    end
end)

task.spawn(function()
    task.wait(1)
    Util.Notify("Blox Community VN", "Script loaded! Author: Dungdx", 6)
    task.wait(2)
    Util.Notify("Discord Server", "Join: discord.gg/BQwcUEdWCW", 8)
end)

print("========================================")
print("  BLOX FRUIT SCRIPT - Dungdx")
print("  Discord: Blox Community VN")
print("  Link: https://discord.gg/BQwcUEdWCW")
print("========================================")