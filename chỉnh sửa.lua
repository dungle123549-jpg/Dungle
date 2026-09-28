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
    if inst.Parent == Boats then return false end
    if inst:GetAttribute("IsBoat") then return false end
    if inst.Name:find("Boat") or inst.Name:find("Ship") then return false end
    if inst.Parent == SeaBeasts then
        local hp = inst:FindFirstChild("Health")
        return hp and hp.Value > 0
    end
    local h = Util.GetHumanoid(inst)
    local r = Util.GetRoot(inst)
    return h and h.Health > 0 and r
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
    if not Character then return end
    if not Character:HasTag("Buso") then
        if Beli.Value >= 25000 then Util.FireInvoke("BuyHaki", "Buso") end
    elseif not Character:FindFirstChild("HasBuso") then
        Util.FireInvoke("Buso")
    end
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
    if reRegisterAttack then
        pcall(function() reRegisterAttack:FireServer(0.3) end)
    end
    if tool:FindFirstChild("LeftClickRemote") then
        pcall(function()
            tool.LeftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
        end)
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
    local lastQuestTick = 0
    while Config.AutoFarmLevel do
        task.wait(0.2)
        if not Util.IsAlive(Character) then task.wait(1) continue end
        local mob = Util.GetQuestMob()
        if not Util.HasQuest() then
            if mob and tick() - lastQuestTick > 2 then
                lastQuestTick = tick()
                local npcs = ReplicatedStorage:FindFirstChild("NPCs")
                if npcs then
                    for _, npc in ipairs(npcs:GetChildren()) do
                        if npc.Name:lower():find(mob:lower()) then
                            local npcRoot = Util.GetRoot(npc) or npc:FindFirstChildWhichIsA("BasePart")
                            if npcRoot then
                                Tween.To(npcRoot.CFrame)
                                task.wait(0.2)
                                Util.FireInvoke("StartQuest", "Quest", 1)
                            end
                            break
                        end
                    end
                end
            end
        else
            local found = false
            for _, enemy in ipairs(Enemies:GetChildren()) do
                if Util.IsReady(enemy) and mob and enemy.Name:lower():find(mob:lower()) then
                    local eRoot = Util.GetRoot(enemy)
                    if eRoot then
                        Util.AutoHaki()
                        Util.EquipWeapon(Config.SelectWeapon)
                        Tween.To(eRoot.CFrame * CFrame.new(0, 15, 0))
                        if Config.BringMonster and sethiddenproperty then
                            pcall(function() sethiddenproperty(LP, "SimulationRadius", Config.BringRadius) end)
                        end
                        task.wait(0.05)
                        if Config.FastAttack then FastAttack.Attack()
                        else Humanoid:ChangeState(Enum.HumanoidStateType.Attack) end
                        found = true
                    end
                    break
                end
            end
            if not found and mob then
                local sp = ReplicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder")
                if sp then
                    for _, part in ipairs(sp:GetChildren()) do
                        if part.Name == mob then
                            Tween.To(part.CFrame + Vector3.new(0, 15, 0))
                            break
                        end
                    end
                end
            end
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
        task.wait(0.3)
        if not Util.IsAlive(Character) then continue end
        local mat = Config.SelectMaterial
        local nearest, minDist = nil, 500
        local myRoot = Util.GetRoot(Character)
        for _, enemy in ipairs(Enemies:GetChildren()) do
            if Util.IsReady(enemy) then
                if enemy.Name:lower():find(mat:lower()) or mat:lower():find(enemy.Name:lower()) then
                    local eRoot = Util.GetRoot(enemy)
                    if eRoot then
                        local d = (eRoot.Position - myRoot.Position).Magnitude
                        if d < minDist then minDist = d nearest = enemy end
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

F.AutoFarmBoss = function()
    while Config.AutoFarmBoss do
        task.wait(0.5)
        if not Util.IsAlive(Character) then continue end
        local bossName = Config.SelectBoss
        local found = false
        for _, enemy in ipairs(Enemies:GetChildren()) do
            if Util.IsReady(enemy) and enemy.Name == bossName then
                local eRoot = Util.GetRoot(enemy)
                if eRoot then
                    Util.AutoHaki()
                    Util.EquipWeapon(Config.SelectWeapon)
                    Tween.To(eRoot.CFrame * CFrame.new(0, 15, 0))
                    task.wait(0.05)
                    FastAttack.Attack()
                    found = true
                end
                break
            end
        end
        if not found then task.wait(1) end
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
    while Config.AutoFarmElite do
        task.wait(0.5)
        if not Util.IsAlive(Character) then continue end
        local elites = {"Urban", "Deandre", "Diablo"}
        for _, elite in ipairs(elites) do
            for _, enemy in ipairs(Enemies:GetChildren()) do
                if Util.IsReady(enemy) and enemy.Name == elite then
                    local eRoot = Util.GetRoot(enemy)
                    if eRoot then
                        Util.AutoHaki()
                        Util.EquipWeapon(Config.SelectWeapon)
                        Tween.To(eRoot.CFrame * CFrame.new(0, 15, 0))
                        task.wait(0.05)
                        FastAttack.Attack()
                    end
                    break
                end
            end
        end
        pcall(function() Util.FireInvoke("EliteHunter") end)
    end
end

F.AutoRaid = function()
    while Config.AutoRaid do
        task.wait(0.5)
        if not Util.IsAlive(Character) then continue end
        local main = PlayerGui:FindFirstChild("Main")
        local hud = main and main:FindFirstChild("TopHUDList")
        local timer = hud and hud:FindFirstChild("RaidTimer")
        if timer and timer.Visible then
            local nearest, minDist = nil, 500
            local myRoot = Util.GetRoot(Character)
            for _, enemy in ipairs(Enemies:GetChildren()) do
                if Util.IsReady(enemy) then
                    local eRoot = Util.GetRoot(enemy)
                    if eRoot then
                        local d = (eRoot.Position - myRoot.Position).Magnitude
                        if d < minDist then minDist = d nearest = enemy end
                    end
                end
            end
            if nearest then
                local eRoot = Util.GetRoot(nearest)
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(eRoot.CFrame * CFrame.new(0, 15, 0))
                FastAttack.Attack()
            end
        else
            local hasChip = Util.HasTool("Special Microchip")
            if not hasChip then
                pcall(function() Util.FireInvoke("RaidsNpc", "Select", Config.SelectRaid) end)
                task.wait(1)
            else
                local ci = Map and Map:FindFirstChild("CircleIsland")
                local rs = ci and ci:FindFirstChild("RaidSummon2")
                if rs then
                    local btn = rs:FindFirstChild("Button")
                    btn = btn and btn:FindFirstChild("Main")
                    if btn and fireclickdetector then
                        Tween.To(btn.CFrame)
                        task.wait(0.5)
                        pcall(function() fireclickdetector(btn.ClickDetector) end)
                    end
                end
            end
        end
    end
end

F.AutoSeaEvents = function()
    while Config.AutoSeaEvents do
        task.wait(0.5)
        if not Util.IsAlive(Character) then continue end
        local targets = {"Terror Shark", "Sea Beast", "Shark", "Piranha", "Fish Crew Member", "Pirate Brigade", "Pirate Grand Brigade", "Ghost Ship"}
        local nearest, minDist = nil, 1500
        local myRoot = Util.GetRoot(Character)
        for _, sb in ipairs(SeaBeasts:GetChildren()) do
            if Util.IsReady(sb) then
                local sRoot = Util.GetRoot(sb) or sb:FindFirstChildWhichIsA("BasePart")
                if sRoot then
                    local d = (sRoot.Position - myRoot.Position).Magnitude
                    if d < minDist then minDist = d nearest = sb end
                end
            end
        end
        for _, enemy in ipairs(Enemies:GetChildren()) do
            if Util.IsReady(enemy) then
                for _, t in ipairs(targets) do
                    if enemy.Name:find(t) then
                        local eRoot = Util.GetRoot(enemy) or enemy:FindFirstChild("Engine")
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
            local nRoot = Util.GetRoot(nearest) or nearest:FindFirstChildWhichIsA("BasePart")
            if nRoot then
                local wy = Map and Map:FindFirstChild("WaterBase-Plane") and Map["WaterBase-Plane"].Position.Y or 0
                local yo = Config.AutoDodgeSea and 400 or 250
                Util.AutoHaki()
                Util.EquipWeapon(Config.SelectWeapon)
                Tween.To(CFrame.new(nRoot.Position.X, wy + yo, nRoot.Position.Z))
                task.wait(0.1)
                FastAttack.Attack()
            end
        end
    end
end

F.AutoFish = function()
    while Config.AutoFish do
        task.wait(0.3)
        if not Util.IsAlive(Character) then continue end
        Util.EquipWeapon("Fishing Rod")
        local rod = Character:FindFirstChild(Config.SelectRod) or Character:FindFirstChild("Fishing Rod")
        if not rod then task.wait(1) continue end
        local state = rod:GetAttribute("State")
        if state == "Biting" then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.15)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        else
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.5)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
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
        task.wait(0.3)
        local pts = Data:FindFirstChild("Points")
        if pts and pts.Value > 0 then
            for _, s in ipairs({"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}) do
                if Config["Stat" .. s] then
                    pcall(function() Util.FireInvoke("AddPoint", s, pts.Value) end)
                end
            end
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
PlayerTab:Toggle("Auto Stats", false, function(v)
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