-- ================================================================
-- Syntax / XHanUI external UI bootstrap
-- UI library only; all feature logic below comes from the uploaded SyntaxNext script.
-- ================================================================
(function()
    local URL = "https://raw.githubusercontent.com/MilkShakeLove/XHanUI/refs/heads/main/XHanUI.lua"

    local okHttp, source = pcall(function()
        return game:HttpGet(URL)
    end)
    if not okHttp then
        warn("[Syntax] XHanUI download failed: " .. tostring(source))
        return
    end

    local loader, compileError = loadstring(source)
    if not loader then
        warn("[Syntax] XHanUI compile failed: " .. tostring(compileError))
        return
    end

    local okLib, XHanUI = pcall(loader)
    if not okLib or type(XHanUI) ~= "table" then
        warn("[Syntax] XHanUI load failed: " .. tostring(XHanUI))
        return
    end

    local NativeWindow = XHanUI:CreateWindow({
        Title = "XHanUI",
        Author = "Syntax",
        Folder = "Syntax",
        Size = UDim2.fromOffset(660, 490),
        MinSize = Vector2.new(560, 390),
        MaxSize = Vector2.new(900, 680),
        Theme = "XHanUI",
        -- Main-window background/shadow appearance is controlled by XHanUI.lua.
        Acrylic = false,
        HideSearchBar = false,
        HidePanelBackground = false,
        ToggleKey = Enum.KeyCode.RightShift,

        XHanUI = {
            DynamicIsland = {
                Brand = "Syntax",
                ServerText = "Roblox",
                Duration = 1.85,
                IdleWidth = 390,
                IdleHeight = 42,
                Width = 340,
                RowHeight = 46,
                AlertYOffset = 10,
            },
            FeatureList = {
                Title = "ArrayList",
                Mode = "Syntax",
                Display = "Split",
                Glow = true,
                ShadowStrength = 78,
                Palette = "Starlight",
                FlowSpeed = 3.0,
                Background = true,
                ShowHeader = false,
                RowHeight = 22,
                Gap = 3,
                TextSize = 15,
            },
        },
    })

    if not NativeWindow then
        warn("[Syntax] XHanUI window creation failed")
        return
    end

    local NativeFeatureList = NativeWindow:GetFeatureList()
    local Island = NativeWindow:CreateDynamicIsland()
    local RawIslandToggle = Island and Island.Toggle
    local NativeToggleTitles = {}
    local NativeTabs = {}
    local FeatureItems = {}

    -- Native XHanUI toggles already know how to animate themselves. Syntax feature
    -- state notifications are sent from the feature proxy below, so suppress the
    -- automatic native-toggle island event to avoid duplicate notifications.
    if Island and type(RawIslandToggle) == "function" then
        function Island:Toggle(name, state, duration)
            if NativeToggleTitles[tostring(name)] then
                return self
            end
            return RawIslandToggle(self, name, state, duration)
        end
    end

    local function copyTable(sourceTable)
        local result = {}
        for k, v in pairs(sourceTable or {}) do
            result[k] = v
        end
        return result
    end

    local function wrapTab(nativeTab)
        local tab = {}
        tab._native = nativeTab

        function tab:Section(options)
            options = options or {}
            return nativeTab:Paragraph({
                Title = options.Title or "Section",
                Desc = options.Desc or "",
            })
        end

        function tab:Paragraph(options)
            return nativeTab:Paragraph(options or {})
        end

        function tab:Button(options)
            return nativeTab:Button(options or {})
        end

        function tab:Toggle(options)
            local opts = copyTable(options)
            if opts.Value == nil then
                opts.Value = opts.Default == true
            end
            opts.Default = nil
            opts.Keybind = nil
            NativeToggleTitles[tostring(opts.Title or "Toggle")] = true
            return nativeTab:Toggle(opts)
        end

        function tab:Slider(options)
            local opts = copyTable(options)
            if opts.Step == nil then
                opts.Step = opts.Increment or 1
            end
            opts.Increment = nil
            return nativeTab:Slider(opts)
        end

        function tab:Dropdown(options)
            return nativeTab:Dropdown(copyTable(options))
        end

        function tab:AnimatedSelector(options)
            return nativeTab:Dropdown(copyTable(options))
        end

        return tab
    end

    local CompatWindow = {}
    CompatWindow._native = NativeWindow

    function CompatWindow:Tab(options)
        local nativeTab = NativeWindow:Tab(options or {})
        local wrapped = wrapTab(nativeTab)
        table.insert(NativeTabs, nativeTab)
        return wrapped
    end

    function CompatWindow:Notify(options)
        return XHanUI:Notify(options or {})
    end

    function CompatWindow:SetVisible(value)
        if value == false then
            NativeWindow:Close()
        else
            NativeWindow:Open()
        end
    end

    function CompatWindow:Open()
        return NativeWindow:Open()
    end

    function CompatWindow:Close()
        return NativeWindow:Close()
    end

    function CompatWindow:Toggle()
        return NativeWindow:Toggle()
    end

    CompatWindow.PageController = {
        SelectTab = function(_, index)
            local tab = NativeTabs[tonumber(index) or 1]
            if tab then
                pcall(function() NativeWindow:SelectTab(tab) end)
            end
        end,
    }

    local FeatureProxy = {}

    local function setItemWithoutIsland(item, enabled, mode)
        local savedWindowIsland = NativeWindow.DynamicIsland
        local savedLibraryIsland = XHanUI.DynamicIsland
        NativeWindow.DynamicIsland = nil
        XHanUI.DynamicIsland = nil
        local ok, result = pcall(function()
            return item:Set(enabled, mode)
        end)
        NativeWindow.DynamicIsland = savedWindowIsland
        XHanUI.DynamicIsland = savedLibraryIsland
        return ok, result
    end

    function FeatureProxy:Set(name, enabled, mode)
        name = tostring(name)
        local item = FeatureItems[name]

        if not item then
            item = NativeFeatureList:Get(name)
        end

        if not item then
            item = NativeWindow:RegisterFeature(name, {
                Enabled = enabled == true,
                Mode = mode,
            })
            FeatureItems[name] = item
            return item
        end

        FeatureItems[name] = item
        local changed = enabled ~= nil and (item.Enabled ~= (enabled == true))
        setItemWithoutIsland(item, enabled, mode)

        if changed and Island and type(RawIslandToggle) == "function" then
            task.defer(function()
                pcall(RawIslandToggle, Island, name, enabled == true)
            end)
        end

        return item
    end

    function FeatureProxy:SetMode(name, mode)
        name = tostring(name)
        local item = FeatureItems[name] or NativeFeatureList:Get(name)
        if not item then
            item = NativeWindow:RegisterFeature(name, {
                Enabled = false,
                Mode = mode,
            })
            FeatureItems[name] = item
            return item
        end
        FeatureItems[name] = item
        setItemWithoutIsland(item, nil, mode)
        return item
    end

    function FeatureProxy:RefreshColors()
        pcall(function()
            NativeFeatureList:SetPalette(NativeFeatureList.Palette or "Starlight")
        end)
    end

    setmetatable(FeatureProxy, {
        __index = function(_, key)
            local value = NativeFeatureList[key]
            if type(value) == "function" then
                return function(_, ...)
                    return value(NativeFeatureList, ...)
                end
            end
            return value
        end,
    })

    -- Permanent ArrayList label; registered silently so startup does not trigger island animation.
    local arrayItem = NativeFeatureList:Get("ArrayList")
    if not arrayItem then
        arrayItem = NativeWindow:RegisterFeature("ArrayList", {
            Enabled = true,
            Mode = "Syntax",
            Locked = true,
        })
    end
    FeatureItems["ArrayList"] = arrayItem

    _G.SyntaxNextUI = XHanUI
    _G.SyntaxNextNativeWindow = NativeWindow
    _G.SyntaxNextWindow = CompatWindow
    _G.NexusFeatureList = FeatureProxy
    _G.SyntaxNextIsland = Island

    _G.NexusHideMainUI = function()
        pcall(function() NativeWindow:Close() end)
    end
    _G.NexusShowMainUI = function()
        pcall(function() NativeWindow:Open() end)
    end

    -- Compatibility globals used only by the old UI-style callbacks.
    _G.ScreenGui = XHanUI.ScreenGui
    _G.IslandGui = XHanUI.ScreenGui
    _G.FeatureHUD = XHanUI.ScreenGui
end)()

if not _G.SyntaxNextWindow then
    warn("[Syntax] UI bootstrap did not finish; feature engine stopped before initialization.")
    return
end

-- SECTION 1: CORE SERVICES & CONFIGURATION FLAGS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local ContextActionService = game:GetService("ContextActionService") 

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

-- Master State Configuration Options
local HitboxEnabled = false
local HitboxSize = 10
local HitboxPartSelection = "Both"
local InfAmmoEnabled = false
local NoclipEnabled = false
local FullbrightEnabled = false
local GhostEnabled = false
local InfJumpEnabled = false
local InfStaminaEnabled = false
local ChamsEnabled = false
local VehicleEspEnabled = false 
local VentEspEnabled = false   
local BreakableEspEnabled = false 
local ZoomEnabled = false
local TracerEnabled = false
local HitmarkerMode = 0 
local DarkModeEnabled = true 
local ActiveChams = {}
local ActiveVehicleChams = {} 
local ActiveVentChams = {}    
local ActiveBreakableChams = {} 
local ActiveTags = {} 
local AutoMopEnabled = false
local AutoCleanEnabled = false
local AutoRepairEnabled = false

-- Destroy Devices / 破坏设备：完全按照现有功能的原生状态方式接入。
local BreakDeviceEnabled = false
local BreakDeviceRunning = false
local BreakDeviceAttackInterval = 0.80
local BreakDeviceMaxDistance = 100
local BreakDeviceUnlimitedMode = false

-- NaramoV3 standalone feature states
local VehicleFlyEnabled = false
local SpinBotEnabled = false
local SpinBotSpeed = 100
local InstantProximityEnabled = false

local AimbotEnabled = false
local AimbotTeamCheck = true
local AimbotWallCheck = true
local AimbotSmoothness = 0.15
local AimbotTargetPart = "Head"
local ShowAimbotFOV = false
local ShowSilentAimFOV = false
local ChatLogsEnabled = false
local IsRedeemingCodes = false
local GamePromoCodes = {"RELEASE", "FREEBUFF", "UPDATE1", "50KLIKES"}

-- Configurable Slider Value Allocations
local SpeedEnabled = false
local JumpEnabled = false
local FOVEnabled = false
local TargetWalkSpeed = 16   
local TargetJumpPower = 50   
local TargetFOV = 70
local AimbotFOV = 150
-- SECTION 2: GLOBAL UI POINTERS & REJOIN ENGINE
local frame, label, borderGlow, themeBtn
local hitBtn, sizeBtn, infAmBtn, noclipBtn, brightBtn, ghostBtn, vehicleEspBtn, ventEspBtn, breakableEspBtn
local rejoinBtn, chamsBtn, infJumpBtn, infStamBtn, zoomBtn, tracerBtn, hitmarkerBtn
local speedSlider, speedKnob, speedText
local jumpSlider, jumpKnob, jumpText
local zoomSlider, zoomKnob, zoomText

local NoclipConnection = nil
local GhostConnection = nil
local InfJumpConnection = nil
local InfStaminaConnection = nil
local GhostPart = nil
local VehicleFlyConnection = nil
local SpinBotConnection = nil
local AimbotConnection = nil
local AimbotTargetPlayer = nil
local ProximityAddedConnection = nil
local ChatLogsFrame = nil
local ChatLogsScroll = nil
local ChatLogsGlass = nil
local ChatPlayerConnections = {}
local AimbotFovCircle = nil

-- NaramoV3 mobile/keyboard movement helper
local function GetMobileMoveDirection()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude > 0 then
        return hum.MoveDirection
    end
    return Vector3.new(0, 0, 0)
end

-- Instant Direct Rejoin Engine
local function RejoinCurrentServer()
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end
-- SECTION 3: JUMP BYPASS & INFINITE STAMINA PIPELINES
local function ToggleInfJumpState()
    InfJumpEnabled = not InfJumpEnabled
    if InfJumpEnabled then
        if InfJumpConnection then InfJumpConnection:Disconnect() end
        InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not InfJumpEnabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum:ChangeState(Enum.HumanoidStateType.Jumping) 
            end
        end)
    else
        if InfJumpConnection then 
            InfJumpConnection:Disconnect() 
            InfJumpConnection = nil 
        end
    end
end

local function ToggleInfStaminaState()
    InfStaminaEnabled = not InfStaminaEnabled
    if InfStaminaEnabled then
        if InfStaminaConnection then InfStaminaConnection:Disconnect() end
        InfStaminaConnection = UserInputService.JumpRequest:Connect(function()
            if not InfStaminaEnabled then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, TargetJumpPower, root.AssemblyLinearVelocity.Z)
            end
        end)
    else
        if InfStaminaConnection then 
            InfStaminaConnection:Disconnect() 
            InfStaminaConnection = nil 
        end
    end
end
-- SECTION 4: INTEGRATED GUN FRAMEWORK SCRAPER
-- 无限弹药：完整恢复原版 NaramoV3 的多层处理。
-- 1) 扫描 GC 武器配置表；
-- 2) 扫描当前角色/背包中的 Tool；
-- 3) 处理 Setting ModuleScript 返回的配置表；
-- 4) 处理 ValueBase / Attributes；
-- 5) 监听新获得的 Tool 与新加入的弹药值；
-- 6) 周期性强制回填，防止游戏重新写回弹药。
local AMMO_MAX = 999999
local AmmoWatchedTools = setmetatable({}, {__mode = "k"})
local AmmoWatchedValues = setmetatable({}, {__mode = "k"})
local AmmoWatchedAttributes = setmetatable({}, {__mode = "k"})
local AmmoToolConnections = setmetatable({}, {__mode = "k"})
local AmmoRootConnections = {}

local function isNumberValueObject(obj)
    if not obj or not obj:IsA("ValueBase") then return false end
    local ok, value = pcall(function() return obj.Value end)
    return ok and type(value) == "number"
end

local function isAmmoName(name)
    name = tostring(name or ""):lower()
    return name == "ammo"
        or name == "currentammo"
        or name == "clip"
        or name == "mag"
        or name == "magsize"
        or name == "magazine"
        or name == "reserve"
        or name == "defaultreserve"
        or name == "maxammo"
        or name == "currentmag"
end

local function safeSetNumberValue(obj, value)
    if not obj or not obj.Parent then return end
    pcall(function()
        if isNumberValueObject(obj) then
            obj.Value = value
        end
    end)
end

local function patchAmmoTable(tbl)
    if type(tbl) ~= "table" then return end

    local fieldsZero = {
        "AmmoPerShot",
    }
    for _, field in ipairs(fieldsZero) do
        local ok, current = pcall(rawget, tbl, field)
        if ok and current ~= nil and type(current) == "number" then
            pcall(rawset, tbl, field, 0)
        end
    end

    local fieldsMax = {
        "MagSize",
        "Ammo",
        "CurrentAmmo",
        "Reserve",
        "DefaultReserve",
        "Clip",
        "Magazine",
        "CurrentMag",
        "MaxAmmo",
    }
    for _, field in ipairs(fieldsMax) do
        local ok, current = pcall(rawget, tbl, field)
        if ok and current ~= nil and type(current) == "number" then
            pcall(rawset, tbl, field, AMMO_MAX)
        end
    end
end

local function fixGCTables()
    if not InfAmmoEnabled or type(getgc) ~= "function" then return end
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" then
                patchAmmoTable(v)
            end
        end
    end)
end

local BindSilentAimTool

local function bindAmmoValue(desc)
    if not desc or not desc.Parent or not isNumberValueObject(desc) then return end
    if not isAmmoName(desc.Name) then return end

    if InfAmmoEnabled then
        safeSetNumberValue(desc, AMMO_MAX)
    end

    if AmmoWatchedValues[desc] then return end
    AmmoWatchedValues[desc] = true

    pcall(function()
        desc.Changed:Connect(function(newValue)
            if not InfAmmoEnabled or not desc.Parent then return end
            if type(newValue) == "number" and newValue ~= AMMO_MAX then
                safeSetNumberValue(desc, AMMO_MAX)
            end
        end)
    end)
end

local function bindAmmoAttribute(tool, attributeName)
    if not tool or not tool.Parent then return end
    local lower = tostring(attributeName):lower()
    if not isAmmoName(lower) then return end

    local key = tostring(attributeName)
    local bucket = AmmoWatchedAttributes[tool]
    if not bucket then
        bucket = {}
        AmmoWatchedAttributes[tool] = bucket
    end
    if bucket[key] then return end
    bucket[key] = true

    pcall(function()
        local value = tool:GetAttribute(attributeName)
        if InfAmmoEnabled and type(value) == "number" then
            tool:SetAttribute(attributeName, AMMO_MAX)
        end
    end)

    pcall(function()
        tool:GetAttributeChangedSignal(attributeName):Connect(function()
            if not InfAmmoEnabled or not tool.Parent then return end
            local current = tool:GetAttribute(attributeName)
            if type(current) == "number" and current ~= AMMO_MAX then
                pcall(function() tool:SetAttribute(attributeName, AMMO_MAX) end)
            end
        end)
    end)
end

local function processSettingsModule(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then return end
    local lowerName = moduleScript.Name:lower()
    if not lowerName:find("setting") then return end

    pcall(function()
        local settingsMod = require(moduleScript)
        if type(settingsMod) == "table" and InfAmmoEnabled then
            patchAmmoTable(settingsMod)
        end
    end)
end

local function enforceToolAmmo(tool)
    if not tool or not tool.Parent or not tool:IsA("Tool") then return end

    -- 原脚本的 SilentAim 工具钩子是可选的；没有实现时不能阻断后面的弹药处理。
    if type(BindSilentAimTool) == "function" then
        pcall(BindSilentAimTool, tool)
    end

    if InfAmmoEnabled then
        for _, desc in ipairs(tool:GetDescendants()) do
            if desc:IsA("ModuleScript") then
                processSettingsModule(desc)
            elseif desc:IsA("ValueBase") then
                bindAmmoValue(desc)
            end
        end

        for attributeName, value in pairs(tool:GetAttributes()) do
            if type(value) == "number" and isAmmoName(attributeName) then
                bindAmmoAttribute(tool, attributeName)
                pcall(function() tool:SetAttribute(attributeName, AMMO_MAX) end)
            end
        end
    else
        -- 即使关闭，也提前记录已有属性监听，下一次打开无需重新建立连接。
        for attributeName, value in pairs(tool:GetAttributes()) do
            if type(value) == "number" and isAmmoName(attributeName) then
                bindAmmoAttribute(tool, attributeName)
            end
        end
    end
end

local function processTool(tool, forceRecheck)
    if not tool or not tool:IsA("Tool") then return end

    local alreadyWatched = AmmoWatchedTools[tool] == true
    if not alreadyWatched or forceRecheck then
        enforceToolAmmo(tool)
    end

    if alreadyWatched then
        return
    end

    AmmoWatchedTools[tool] = true
    local conns = {}

    pcall(function()
        conns[#conns + 1] = tool.DescendantAdded:Connect(function(obj)
            if not InfAmmoEnabled then return end
            if obj:IsA("ModuleScript") then
                processSettingsModule(obj)
            elseif obj:IsA("ValueBase") then
                bindAmmoValue(obj)
            end
        end)
    end)

    -- 不只监听 Ammo：新属性只需在“新扫描/启用时”统一捕获，避免为每个 Tool 创建大量属性连接。
    AmmoToolConnections[tool] = conns
end

local function scanAllTools(forceRecheck)
    local character = LocalPlayer.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                processTool(child, forceRecheck == true)
            end
        end
    end

    local backpack = LocalPlayer.Backpack
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                processTool(child, forceRecheck == true)
            end
        end
    end
end

local function bindAmmoRoot(root)
    if not root or AmmoRootConnections[root] then return end
    local conns = {}
    pcall(function()
        conns[#conns + 1] = root.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") then
                task.defer(function()
                    processTool(obj)
                    if InfAmmoEnabled then enforceToolAmmo(obj) end
                end)
            end
        end)
    end)
    AmmoRootConnections[root] = conns
end

bindAmmoRoot(LocalPlayer.Backpack)
bindAmmoRoot(LocalPlayer.Character)

pcall(function()
    LocalPlayer.CharacterAdded:Connect(function(character)
        bindAmmoRoot(character)
        task.defer(scanAllTools)
    end)
end)

-- 低负载维护：Tool 弹药由 Changed/DescendantAdded 事件实时处理。
-- 仅保留低频 GC 配置补扫，避免反复遍历 Character/Backpack 与 GetDescendants()。
task.spawn(function()
    local nextGcScan = 0
    while true do
        local now = os.clock()
        if InfAmmoEnabled then
            if now >= nextGcScan then
                nextGcScan = now + 2.5
                pcall(fixGCTables)
            end
            task.wait(0.50)
        else
            nextGcScan = now + 2.5
            task.wait(0.80)
        end
    end
end)

-- SECTION 5: FREECAM GHOST ENGINE
local function ToggleGhostMode()
    GhostEnabled = not GhostEnabled
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if GhostEnabled then
        if not root then GhostEnabled = false return end
        root.Anchored = true
        GhostPart = Instance.new("Part")
        GhostPart.Size = Vector3.new(1, 1, 1)
        GhostPart.CFrame = root.CFrame
        GhostPart.Anchored = true
        GhostPart.CanCollide = false
        GhostPart.Transparency = 1
        GhostPart.Parent = workspace
        Camera.CameraSubject = GhostPart
        
        if GhostConnection then GhostConnection:Disconnect() end
        GhostConnection = RunService.RenderStepped:Connect(function()
            local moveDir = Vector3.new(0, 0, 0)
            local camCFrame = Camera.CFrame
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            local mobileDir = GetMobileMoveDirection()
            if mobileDir.Magnitude > 0 then
                moveDir = moveDir + Vector3.new(mobileDir.X, 0, mobileDir.Z)
            end

            if moveDir.Magnitude > 0 then
                GhostPart.CFrame = GhostPart.CFrame + (moveDir.Unit * 1.5)
            end
        end)
    else
        if GhostConnection then GhostConnection:Disconnect() GhostConnection = nil end
        if GhostPart then GhostPart:Destroy() GhostPart = nil end
        if root then root.Anchored = false end
        if char and char:FindFirstChildOfClass("Humanoid") then 
            Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid") 
        end
    end
end
-- SECTION 6: HITBOX & NOCLIP ENGINE
local function ApplyHitbox()
    if not HitboxEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team ~= LocalPlayer.Team then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if hum and hum.Health > 0 then
                if HitboxSize <= 0 then
                    continue
                end

                if (HitboxPartSelection == "Head" or HitboxPartSelection == "Both") and head then
                    head.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    head.Transparency = 1
                    head.CanCollide = false
                end

                if (HitboxPartSelection == "Body" or HitboxPartSelection == "Both") and root then
                    root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    root.Transparency = 1
                    root.CanCollide = false
                end
            end
        end
    end
end

local function ResetHitbox()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.Size, root.Transparency, root.CanCollide = Vector3.new(2, 2, 1), 1, true end
            if head then head.Size, head.Transparency, head.CanCollide = Vector3.new(2, 1, 1), 0, true end
        end
    end
end

local function ToggleHitboxState()
    HitboxEnabled = not HitboxEnabled
    if not HitboxEnabled then ResetHitbox() else ApplyHitbox() end
end

local function StartNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() end
    NoclipConnection = RunService.Stepped:Connect(function()
        if not NoclipEnabled then return end
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then 
                    part.CanCollide = false 
                end
            end
        end
    end)
end

local function StopNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                part.CanCollide = true 
            end
        end
    end
end

local function ToggleNoclipState()
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then StartNoclip() else StopNoclip() end
end

local function ToggleFullbrightState() 
    FullbrightEnabled = not FullbrightEnabled 
end
-- SECTION 7: ESP CHAMS & DISTANCE NAMETAG OVERLAYS
-- 说明：人物 / 载具透视核心实现保持原版；人物额外加入 Yeskid/GB 风格圆点，
--       并让名字随距离连续缩放，而不是因为距离远就隐藏人物透视或名字。
local PLAYER_NAME_FAR_DISTANCE = 1000
local PLAYER_NAME_NEAR_DISTANCE = 40
local PLAYER_NAME_FAR_SIZE = 9
local PLAYER_NAME_NEAR_SIZE = 18
local GB_PLAYER_MAX_DISTANCE = 1000
local GB_NAME_MIN_SIZE = 8
local GB_NAME_MAX_SIZE = 18

-- Forward declaration: WipeAllChams is defined before the helper implementation below.
local destroyPlayerESPData

local function WipeAllChams()
    for player, data in pairs(ActiveChams) do
        destroyPlayerESPData(data)
        ActiveChams[player] = nil
    end
    for player, gui in pairs(ActiveTags) do
        if gui then pcall(function() gui:Destroy() end) end
        ActiveTags[player] = nil
    end
end

local function WipeAllVehicleChams()
    for model, data in pairs(ActiveVehicleChams) do
        if data then
            if data.hl then pcall(function() data.hl:Destroy() end) end
            if data.nameTag then pcall(function() data.nameTag:Destroy() end) end
            if data.dotGui then pcall(function() data.dotGui:Destroy() end) end
        end
        ActiveVehicleChams[model] = nil
    end
end

local function WipeAllVentChams()
    for part, box in pairs(ActiveVentChams) do
        if box then box:Destroy() end
        ActiveVentChams[part] = nil
    end
end

local function WipeAllBreakableChams()
    for part, box in pairs(ActiveBreakableChams) do
        if box then box:Destroy() end
        ActiveBreakableChams[part] = nil
    end
end

local function ToggleChamsState() ChamsEnabled = not ChamsEnabled if not ChamsEnabled then WipeAllChams() end end

local VehicleEspConnection = nil
local VehicleScanBusy = false
local VehicleESPBindings = {}

local function IsVehicleModel(obj)
    if not obj or not obj:IsA("Model") then return false end
    return obj:FindFirstChild("DriveSeat") ~= nil
        or obj:FindFirstChild("Body") ~= nil
        or obj:FindFirstChild("A-Chassis Tune") ~= nil
end

local function getVehicleAnchor(model)
    if not model then return nil end
    local pri = model.PrimaryPart
    if pri and pri.Parent then return pri end
    local seat = model:FindFirstChild("DriveSeat", true)
    if seat and seat:IsA("BasePart") then return seat end
    local body = model:FindFirstChild("Body", true)
    if body and body:IsA("BasePart") then return body end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function destroyVehicleESPData(data)
    if not data then return end
    if data.dotGui then pcall(function() data.dotGui:Destroy() end) end
    if data.nameTag then pcall(function() data.nameTag:Destroy() end) end
    if data.hl then pcall(function() data.hl:Destroy() end) end
end

local function createVehicleDot(anchor, color)
    if not anchor or not anchor:IsA("BasePart") then return nil end

    local gui = Instance.new("BillboardGui")
    gui.Name = "GBVehicleESP_Dot"
    gui.Adornee = anchor
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(18, 18)
    gui.StudsOffset = Vector3.new(0, 0, 0)
    gui.Parent = game:GetService("CoreGui") or anchor

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.Size = UDim2.fromOffset(7, 7)
    dot.BackgroundColor3 = color
    dot.BackgroundTransparency = 0
    dot.BorderSizePixel = 0
    dot.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
    return gui
end

local function AddVehicleESP(obj)
    if not VehicleEspEnabled or not obj then return end

    local model = obj
    if not model:IsA("Model") then
        model = obj:FindFirstAncestorOfClass("Model")
    end
    if not model or not model:IsDescendantOf(workspace) or ActiveVehicleChams[model] then return end
    if not IsVehicleModel(model) then return end

    -- 保持载具原来的 Model-level Highlight；去掉描边，使用轻微填充避免“去掉描边后完全不可见”。
    local hl = Instance.new("Highlight")
    hl.Name = "VehicleESP"
    hl.Adornee = model
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Color3.fromRGB(180, 140, 255)
    hl.FillTransparency = 0.82
    hl.OutlineTransparency = 1
    hl.Parent = model

    local anchor = getVehicleAnchor(model)
    local dotGui = anchor and createVehicleDot(anchor, Color3.fromRGB(180, 140, 255)) or nil

    -- 载具原有名字保持，不增加新的距离逻辑；同时保留原名字的显示方式。
    local nameTag = nil
    if anchor then
        nameTag = Instance.new("BillboardGui")
        nameTag.Name = "VehicleNameTag"
        nameTag.Size = UDim2.new(0, 160, 0, 24)
        nameTag.AlwaysOnTop = true
        nameTag.ExtentsOffset = Vector3.new(0, 2.5, 0)
        nameTag.Adornee = anchor
        nameTag.Parent = game:GetService("CoreGui") or anchor

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 14
        tl.Text = model.Name
        tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.TextStrokeTransparency = 0.2
        tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        tl.Parent = nameTag
    end

    ActiveVehicleChams[model] = {hl = hl, nameTag = nameTag, dotGui = dotGui, anchor = anchor}

    -- 每辆载具只绑定一个轻量 AncestryChanged，不需要反复扫描 workspace。
    local connection
    connection = model.AncestryChanged:Connect(function(_, parent)
        if parent == nil and ActiveVehicleChams[model] then
            local data = ActiveVehicleChams[model]
            destroyVehicleESPData(data)
            ActiveVehicleChams[model] = nil
            if connection then pcall(function() connection:Disconnect() end) end
            VehicleESPBindings[model] = nil
        end
    end)
    VehicleESPBindings[model] = connection
end

local function RefreshVehicleESP()
    if VehicleScanBusy or not VehicleEspEnabled then return end
    VehicleScanBusy = true

    task.spawn(function()
        -- GB/Yeskid 思路：首次开启只做一次分批发现；之后依靠 DescendantAdded 增量发现。
        local list = workspace:GetDescendants()
        local count = 0
        for i = 1, #list do
            if not VehicleEspEnabled then break end
            local obj = list[i]
            if obj:IsA("Model") then
                AddVehicleESP(obj)
            end
            count += 1
            if count % 120 == 0 then
                task.wait()
            end
        end

        VehicleScanBusy = false
    end)
end

local function bindVehicleWatcher()
    if VehicleEspConnection then return end
    VehicleEspConnection = workspace.DescendantAdded:Connect(function(obj)
        if not VehicleEspEnabled then return end
        -- 仅延后一帧等模型结构补齐，避免反复完整扫描。
        task.defer(function()
            if VehicleEspEnabled then
                AddVehicleESP(obj)
            end
        end)
    end)
end

local function ToggleVehicleEspState()
    VehicleEspEnabled = not VehicleEspEnabled

    if not VehicleEspEnabled then
        WipeAllVehicleChams()
        if VehicleEspConnection then
            VehicleEspConnection:Disconnect()
            VehicleEspConnection = nil
        end
        for model, connection in pairs(VehicleESPBindings) do
            if connection then pcall(function() connection:Disconnect() end) end
            VehicleESPBindings[model] = nil
        end
        return
    end

    bindVehicleWatcher()
    RefreshVehicleESP()
end

-- 轻量清理：只遍历当前已缓存车辆，不再每 10 秒扫描整个 workspace。
task.spawn(function()
    while true do
        if VehicleEspEnabled then
            for model, data in pairs(ActiveVehicleChams) do
                if not model or not model.Parent then
                    destroyVehicleESPData(data)
                    ActiveVehicleChams[model] = nil
                end
            end
        end
        task.wait(2)
    end
end)

local function ToggleVentEspState()
    VentEspEnabled = not VentEspEnabled
    if not VentEspEnabled then 
        WipeAllVentChams() 
    else
        task.spawn(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not VentEspEnabled then break end
                if obj:IsA("BasePart") and obj.Transparency < 1 then
                    local lowerName = obj.Name:lower()
                    if lowerName:find("vent") or lowerName:find("ventshaft") or lowerName:find("ventilation") then
                        if not ActiveVentChams[obj] then
                            local box = Instance.new("BoxHandleAdornment")
                            box.Name = "amoVentVisualizer"
                            box.Size = obj.Size + Vector3.new(0.1, 0.1, 0.1)
                            box.Color3 = Color3.fromRGB(0, 210, 255)
                            box.Transparency = 0.5
                            box.AlwaysOnTop = true
                            box.ZIndex = 5
                            box.Adornee = obj
                            box.Parent = game:GetService("CoreGui") or obj
                            ActiveVentChams[obj] = box
                        end
                    end
                end
            end
        end)
    end
end

local function ToggleBreakableEspState()
    BreakableEspEnabled = not BreakableEspEnabled
    if not BreakableEspEnabled then 
        WipeAllBreakableChams() 
    else
        task.spawn(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not BreakableEspEnabled then break end
                if obj:IsA("BasePart") and obj.Transparency < 1 then
                    local lowerName = obj.Name:lower()
                    if lowerName:find("electrical") or lowerName:find("fusebox") or lowerName:find("breaker") or lowerName:find("pipe") then
                        if not ActiveBreakableChams[obj] then
                            local box = Instance.new("BoxHandleAdornment")
                            box.Name = "NaramoBreakableVisualizer"
                            box.Size = obj.Size + Vector3.new(0.1, 0.1, 0.1)
                            box.Color3 = Color3.fromRGB(180, 0, 255)
                            box.Transparency = 0.5
                            box.AlwaysOnTop = true
                            box.ZIndex = 6
                            box.Adornee = obj
                            box.Parent = game:GetService("CoreGui") or obj
                            ActiveBreakableChams[obj] = box
                        end
                    end
                end
            end
        end)
    end
end

-- SECTION 7.5: Puddle / Smudge text label ESP via BillboardGui no highlight
local PuddleEspEnabled = false
local SmudgeEspEnabled = false
local LabelESPBound = false

local function AddLabelToObject(obj, color, text, labelName)
    if not obj or not obj.Parent then return end
    local anchorPart
    if obj:IsA("BasePart") then
        anchorPart = obj
    elseif obj:IsA("Model") then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then
                anchorPart = child
                break
            end
        end
    end
    if not anchorPart then return end
    if anchorPart:FindFirstChild(labelName) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = labelName
    billboard.Adornee = anchorPart
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500

    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true

    billboard.Parent = anchorPart
end

local function RemoveLabelFromObject(obj, labelName)
    if not obj or not obj.Parent then return end
    local parts = {}
    if obj:IsA("BasePart") then
        table.insert(parts, obj)
    elseif obj:IsA("Model") then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
            end
        end
    end
    for _, part in ipairs(parts) do
        local label = part:FindFirstChild(labelName)
        if label then label:Destroy() end
    end
end

local function RefreshLabelESP()
    local cs = game:GetService("CollectionService")

    for _, obj in ipairs(cs:GetTagged("WaterPuddle")) do
        if PuddleEspEnabled and obj:GetAttribute("Active") == true then
            AddLabelToObject(obj, Color3.fromRGB(0, 150, 255), "水坑", "PuddleLabel")
        else
            RemoveLabelFromObject(obj, "PuddleLabel")
        end
    end

    for _, obj in ipairs(cs:GetTagged("GlassSmudge")) do
        if SmudgeEspEnabled and obj:GetAttribute("Active") == true then
            AddLabelToObject(obj, Color3.fromRGB(255, 50, 50), "污渍", "SmudgeLabel")
        else
            RemoveLabelFromObject(obj, "SmudgeLabel")
        end
    end
end

local function EnsureLabelESPListeners()
    if LabelESPBound then return end
    LabelESPBound = true
    local cs = game:GetService("CollectionService")

    local function bindPuddle(obj)
        obj:GetAttributeChangedSignal("Active"):Connect(function()
            if PuddleEspEnabled and obj:GetAttribute("Active") == true then
                AddLabelToObject(obj, Color3.fromRGB(0, 150, 255), "水坑", "PuddleLabel")
            else
                RemoveLabelFromObject(obj, "PuddleLabel")
            end
        end)
        if PuddleEspEnabled and obj:GetAttribute("Active") == true then
            AddLabelToObject(obj, Color3.fromRGB(0, 150, 255), "水坑", "PuddleLabel")
        end
    end

    local function bindSmudge(obj)
        obj:GetAttributeChangedSignal("Active"):Connect(function()
            if SmudgeEspEnabled and obj:GetAttribute("Active") == true then
                AddLabelToObject(obj, Color3.fromRGB(255, 50, 50), "污渍", "SmudgeLabel")
            else
                RemoveLabelFromObject(obj, "SmudgeLabel")
            end
        end)
        if SmudgeEspEnabled and obj:GetAttribute("Active") == true then
            AddLabelToObject(obj, Color3.fromRGB(255, 50, 50), "污渍", "SmudgeLabel")
        end
    end

    cs:GetInstanceAddedSignal("WaterPuddle"):Connect(bindPuddle)
    cs:GetInstanceAddedSignal("GlassSmudge"):Connect(bindSmudge)
    cs:GetInstanceRemovedSignal("WaterPuddle"):Connect(function(obj)
        RemoveLabelFromObject(obj, "PuddleLabel")
    end)
    cs:GetInstanceRemovedSignal("GlassSmudge"):Connect(function(obj)
        RemoveLabelFromObject(obj, "SmudgeLabel")
    end)

    for _, obj in ipairs(cs:GetTagged("WaterPuddle")) do bindPuddle(obj) end
    for _, obj in ipairs(cs:GetTagged("GlassSmudge")) do bindSmudge(obj) end
end

local function TogglePuddleEspState()
    PuddleEspEnabled = not PuddleEspEnabled
    EnsureLabelESPListeners()
    RefreshLabelESP()
end

local function ToggleSmudgeEspState()
    SmudgeEspEnabled = not SmudgeEspEnabled
    EnsureLabelESPListeners()
    RefreshLabelESP()
end

-- =========================
-- 人物透视：GB 风格实现 + 事件驱动扫描
-- 1) 人物本体逐 BasePart 使用 BoxHandleAdornment
-- 2) 圆点独立挂在 HumanoidRootPart，不属于名字控件
-- 3) 名字独立挂在 Head，只根据距离连续调整字号
-- 4) 新人物/新部件由事件增量加入，不重复全 Players / 全 Character 扫描
-- =========================
local function getESPPlayerColor(player)
    local ok, isFriend = pcall(function()
        return LocalPlayer:IsFriendsWith(player.UserId)
    end)
    if ok and isFriend then
        return Color3.fromRGB(255, 255, 255)
    end
    return Color3.fromRGB(53, 238, 135)
end

local function getPlayerHealthColor(healthPercent)
    healthPercent = tonumber(healthPercent) or 0
    if healthPercent > 50 then
        return Color3.fromRGB(46, 204, 113)
    elseif healthPercent > 20 then
        return Color3.fromRGB(241, 196, 15)
    else
        return Color3.fromRGB(231, 76, 60)
    end
end

destroyPlayerESPData = function(data)
    if not data then return end
    if data.charConnection then pcall(function() data.charConnection:Disconnect() end) end
    if data.descConnection then pcall(function() data.descConnection:Disconnect() end) end
    if data.ancestryConnection then pcall(function() data.ancestryConnection:Disconnect() end) end
    if data.teamConnection then pcall(function() data.teamConnection:Disconnect() end) end

    if data.boxes then
        for _, box in ipairs(data.boxes) do
            if box then pcall(function() box:Destroy() end) end
        end
    end
    if data.dotGui then
        pcall(function() data.dotGui:Destroy() end)
    end
    if data.nameGui then
        pcall(function() data.nameGui:Destroy() end)
    end
end

local function createGBPlayerBox(part, color)
    if not part or not part:IsA("BasePart") then return nil end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "GBPlayerESPBox"
    box.Size = part.Size
    box.AlwaysOnTop = true
    box.ZIndex = 1
    box.Transparency = 0.80
    box.Color3 = color
    box.Adornee = part
    pcall(function()
        box.AdornCullingMode = Enum.AdornCullingMode.Never
    end)
    box.Parent = game:GetService("CoreGui") or part
    return box
end

local function createGBPlayerDot(root, color)
    if not root or not root:IsA("BasePart") then return nil end

    local dotGui = Instance.new("BillboardGui")
    dotGui.Name = "GBPlayerESP_Dot"
    dotGui.Adornee = root
    dotGui.AlwaysOnTop = true
    dotGui.Size = UDim2.fromOffset(18, 18)
    dotGui.StudsOffset = Vector3.new(0, 0, 0)
    dotGui.MaxDistance = GB_PLAYER_MAX_DISTANCE
    dotGui.Parent = game:GetService("CoreGui") or root

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.Size = UDim2.fromOffset(7, 7)
    dot.BackgroundColor3 = color
    dot.BackgroundTransparency = 0
    dot.BorderSizePixel = 0
    dot.Parent = dotGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot

    return dotGui
end

local function createGBPlayerName(player, head, color)
    if not head or not head:IsA("BasePart") then return nil, nil end

    local nameGui = Instance.new("BillboardGui")
    nameGui.Name = "GBPlayerESP_Name"
    nameGui.Adornee = head
    nameGui.AlwaysOnTop = true
    nameGui.Size = UDim2.fromOffset(400, 100)
    nameGui.StudsOffset = Vector3.new(0, 2.5, 0)
    nameGui.MaxDistance = GB_PLAYER_MAX_DISTANCE
    nameGui.Parent = game:GetService("CoreGui") or head

    local label = Instance.new("TextLabel")
    label.Name = "Name"
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.Size = UDim2.fromOffset(340, 58)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = false
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = nameGui

    return nameGui, label
end

local function updateGBNameSize(label, distance)
    local size = math.clamp(1000 / math.max(distance, 1), GB_NAME_MIN_SIZE, GB_NAME_MAX_SIZE)
    local rounded = math.floor(size + 0.5)
    if label.TextSize ~= rounded then
        label.TextSize = rounded
    end
end

local function addGBPlayerPartBox(data, part)
    if not data or not data.char or part.Parent == nil then return end
    if not part:IsA("BasePart") or part.Transparency >= 1 then return end
    if data.partSet[part] then return end

    local box = createGBPlayerBox(part, data.color)
    if box then
        data.partSet[part] = box
        data.boxes[#data.boxes + 1] = box
    end
end

local function disconnectPlayerCharacterEvents(data)
    if not data then return end
    if data.descConnection then pcall(function() data.descConnection:Disconnect() end) end
    if data.ancestryConnection then pcall(function() data.ancestryConnection:Disconnect() end) end
    data.descConnection = nil
    data.ancestryConnection = nil
end

local function buildGBPlayerESP(player, char, root, head, color)
    local data = {
        char = char,
        color = color,
        boxes = {},
        partSet = {},
        dotGui = nil,
        nameGui = nil,
        nameLabel = nil,
        descConnection = nil,
        ancestryConnection = nil,
    }

    -- 初次角色生成时只扫描这一次；之后靠 DescendantAdded 增量加入新部件。
    for _, part in ipairs(char:GetDescendants()) do
        addGBPlayerPartBox(data, part)
    end

    data.dotGui = createGBPlayerDot(root, color)
    data.nameGui, data.nameLabel = createGBPlayerName(player, head, color)

    data.descConnection = char.DescendantAdded:Connect(function(obj)
        if not ChamsEnabled or data.char ~= char then return end
        if obj:IsA("BasePart") then
            addGBPlayerPartBox(data, obj)
        end
        if obj.Name == "Head" or obj.Name == "HumanoidRootPart" then
            -- 结构变化时由轻量 refresh 重新确认 Adornee，不做整角色重扫。
        end
    end)

    data.ancestryConnection = char.AncestryChanged:Connect(function(_, parent)
        if parent == nil and ActiveChams[player] == data then
            destroyPlayerESPData(data)
            ActiveChams[player] = nil
        end
    end)

    return data
end

local function ClearPlayerChams(player)
    local data = ActiveChams[player]
    if data then
        destroyPlayerESPData(data)
        ActiveChams[player] = nil
    end

    if ActiveTags[player] then
        pcall(function() ActiveTags[player]:Destroy() end)
        ActiveTags[player] = nil
    end
end

local PlayerESPBindings = {}

local function rebuildPlayerESP(player)
    if not ChamsEnabled or player == LocalPlayer then
        ClearPlayerChams(player)
        return
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not head or not hum or hum.Health <= 0 or player.Team == LocalPlayer.Team then
        ClearPlayerChams(player)
        return
    end

    local old = ActiveChams[player]
    if old and old.char == char then
        return
    end
    if old then
        destroyPlayerESPData(old)
    end

    local color = getESPPlayerColor(player)
    ActiveChams[player] = buildGBPlayerESP(player, char, root, head, color)
end

local function bindPlayerESP(player)
    if PlayerESPBindings[player] then return end

    local binding = {}
    binding.character = player.CharacterAdded:Connect(function()
        if ChamsEnabled then
            task.defer(function()
                rebuildPlayerESP(player)
            end)
        end
    end)
    binding.team = player:GetPropertyChangedSignal("Team"):Connect(function()
        if ChamsEnabled then
            task.defer(function()
                rebuildPlayerESP(player)
            end)
        end
    end)
    PlayerESPBindings[player] = binding
end

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayerESP(player)
end

Players.PlayerAdded:Connect(function(player)
    bindPlayerESP(player)
    if ChamsEnabled then
        task.defer(function()
            rebuildPlayerESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    ClearPlayerChams(player)
    local binding = PlayerESPBindings[player]
    if binding then
        if binding.character then pcall(function() binding.character:Disconnect() end) end
        if binding.team then pcall(function() binding.team:Disconnect() end) end
        PlayerESPBindings[player] = nil
    end
end)

local function UpdateChams()
    if not ChamsEnabled then
        WipeAllChams()
        return
    end

    local lChar = LocalPlayer.Character
    local lRoot = lChar and (lChar:FindFirstChild("HumanoidRootPart") or lChar:FindFirstChild("Head"))
    if not lRoot then return end

    -- 只遍历已经建立的 ESP 数据，不扫描 Players / Character。
    for player, data in pairs(ActiveChams) do
        local char = data and data.char
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not data or not char or not char.Parent or not root or not head or not hum or hum.Health <= 0 then
            ClearPlayerChams(player)
        else
            local distance = (lRoot.Position - root.Position).Magnitude
            if distance > GB_PLAYER_MAX_DISTANCE then
                -- 远距离只停止本地更新，不销毁 ESP；重新靠近时仍能立即恢复。
                if data.dotGui then data.dotGui.Enabled = false end
                if data.nameGui then data.nameGui.Enabled = false end
                for _, box in ipairs(data.boxes) do
                    if box then box.Visible = false end
                end
            else
                local healthPercent = 0
                if hum.MaxHealth and hum.MaxHealth > 0 then
                    healthPercent = math.clamp(math.round((hum.Health / hum.MaxHealth) * 100), 0, 100)
                end
                local healthColor = getPlayerHealthColor(healthPercent)

                if data.dotGui then
                    data.dotGui.Enabled = true
                    data.dotGui.Adornee = root
                    local dot = data.dotGui:FindFirstChild("Dot")
                    if dot then dot.BackgroundColor3 = healthColor end
                end
                if data.nameGui then
                    data.nameGui.Enabled = true
                    data.nameGui.Adornee = head
                end
                if data.nameLabel then
                    data.nameLabel.Text = string.format(
                        "%s\n[HP: %d%%] | [%d Studs]",
                        player.Name,
                        healthPercent,
                        math.round(distance)
                    )
                    data.nameLabel.TextColor3 = healthColor
                    updateGBNameSize(data.nameLabel, distance)
                end

                if not data._lastColorCheck or os.clock() - data._lastColorCheck > 1 then
                    data._lastColorCheck = os.clock()
                    local color = getESPPlayerColor(player)
                    if color.R ~= data.color.R or color.G ~= data.color.G or color.B ~= data.color.B then
                        data.color = color
                        for _, box in ipairs(data.boxes) do
                            if box then box.Color3 = color end
                        end
                        -- 方框继续使用 GB 的好友/玩家颜色；名字与圆点保持血量颜色。
                    end
                end
            end
        end
    end

    -- 这里只处理已出现但尚未创建的角色，极低频且数量仅为玩家数。
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and ChamsEnabled and not ActiveChams[player] then
            rebuildPlayerESP(player)
        end
    end
end

-- SECTION 8: ACCELERATED FX PROCEDURAL PIPELINES
local function CreateLocalHitmarker()
    if HitmarkerMode == 0 then return end
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pGui then return end
    
    local mainUI = pGui:FindFirstChild("Darrens hub") or Instance.new("ScreenGui", pGui)
    local hold = Instance.new("Frame")
    hold.Size, hold.Position = UDim2.new(0, 40, 0, 40), UDim2.new(0.5, -20, 0.5, -20)
    hold.BackgroundTransparency, hold.Parent = 1, mainUI
    
    local directions = { {45, -12, -12}, {135, 4, -12}, {225, 4, 4}, {315, -12, 4} }
    local lines = {}
    
    for _, def in ipairs(directions) do
        local b = Instance.new("Frame")
        b.Size, b.BorderSizePixel = UDim2.new(0, 8, 0, 2), 0
        b.Rotation = def
        b.Position = UDim2.new(0.5, def, 0.5, def)
        b.BackgroundColor3 = (HitmarkerMode == 1) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
        b.Parent = hold
        table.insert(lines, b)
    end
    
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Linear)
    for _, bar in ipairs(lines) do
        TweenService:Create(bar, tweenInfo, {BackgroundTransparency = 1}):Play()
    end
    task.delay(0.35, function() hold:Destroy() end)
end

local function DrawNaramoRGBTracer(origin, target)
    if not TracerEnabled then return end
    if typeof(origin) ~= "Vector3" or typeof(target) ~= "Vector3" then return end

    local delta = (target - origin).Magnitude
    if delta <= 0.05 or delta > 1500 then return end

    local track = Instance.new("Part")
    track.Name = "NaramoRGBTracer"
    track.Size = Vector3.new(0.055, 0.055, delta)
    track.CFrame = CFrame.lookAt((origin + target) / 2, target)
    track.Anchored = true
    track.CanCollide = false
    track.CanTouch = false
    track.CanQuery = false
    track.CastShadow = false
    track.Material = Enum.Material.Neon
    track.Transparency = 0.05
    track.Color = Color3.fromHSV((os.clock() * 0.35) % 1, 1, 1)
    track.Parent = workspace

    local born = os.clock()
    local lifetime = 0.65

    task.spawn(function()
        while track.Parent and (os.clock() - born) < lifetime do
            track.Color = Color3.fromHSV((os.clock() * 0.7) % 1, 1, 1)
            RunService.RenderStepped:Wait()
        end
    end)

    local tween = TweenService:Create(
        track,
        TweenInfo.new(lifetime, Enum.EasingStyle.Linear),
        {Transparency = 1}
    )
    tween:Play()
    tween.Completed:Connect(function()
        if track then
            track:Destroy()
        end
    end)
end
-- SECTION 9: NARAMOV3 CAMERA AIMBOT + STANDALONE SILENT AIM + CLICK FX

-- ============================================================================
-- STANDALONE NARAMO SILENT AIM
-- Based on the uploaded Naramo-Nuclear-Plant(1).lua source.
-- Kept isolated from the camera aimbot so it can be enabled/disabled independently.
-- ============================================================================
local NaramoSilentAim = {
    Enabled = false,
    FOV = 150,
    TargetPart = "Head",
    TeamCheck = true,
    WallCheck = true,
    Target = nil,
    FovCircle = nil,
    NetRayEvent = nil,
}

function NaramoSilentAim:GetTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local mouse2D = Vector2.new(mousePos.X, mousePos.Y)
    local closestPlayer, closestDistance = nil, self.FOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = plr.Character:FindFirstChild(self.TargetPart)
            local passTeam = (not self.TeamCheck) or (plr.Team ~= LocalPlayer.Team)
            local visible = true

            if self.WallCheck and targetPart then
                local origin = Camera.CFrame.Position
                local direction = targetPart.Position - origin
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                local result = workspace:Raycast(origin, direction, params)
                visible = (not result) or result.Instance:IsDescendantOf(plr.Character)
            end

            if hum and hum.Health > 0 and targetPart and passTeam and visible then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mouse2D).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = plr
                    end
                end
            end
        end
    end

    self.Target = closestPlayer
    return closestPlayer
end

function NaramoSilentAim:GetBarrel()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    return tool:FindFirstChild("Barrel") or tool:FindFirstChild("1Barrel") or tool
end

function NaramoSilentAim:Fire(targetPart)
    if not self.Enabled or not targetPart or not targetPart.Parent then return false end

    local barrel = self:GetBarrel()
    if not barrel or not barrel:IsA("BasePart") then return false end

    local event = self.NetRayEvent
    if not event or not event.Parent then
        event = ReplicatedStorage:FindFirstChild("NetRay_RELIABLE")
        self.NetRayEvent = event
    end
    if not event or not event:IsA("RemoteEvent") then return false end

    local origin = barrel.Position
    local hitPos = targetPart.Position
    local delta = hitPos - origin
    if delta.Magnitude <= 0.001 then return false end

    local hitNormal = delta.Unit
    local ok = pcall(function()
        -- Exact 41-byte packet layout used by the uploaded Naramo source.
        local buf = buffer.create(41)
        buffer.writeu8(buf, 0, 6)
        buffer.writeu8(buf, 1, 31)
        buffer.writeu8(buf, 2, 1)
        buffer.writef32(buf, 3, origin.X)
        buffer.writef32(buf, 7, origin.Y)
        buffer.writef32(buf, 11, origin.Z)
        buffer.writef32(buf, 15, hitPos.X)
        buffer.writef32(buf, 19, hitPos.Y)
        buffer.writef32(buf, 23, hitPos.Z)
        buffer.writeu8(buf, 27, 1)
        buffer.writef32(buf, 28, hitNormal.X)
        buffer.writef32(buf, 32, hitNormal.Y)
        buffer.writef32(buf, 36, hitNormal.Z)
        buffer.writeu8(buf, 40, 1)
        event:FireServer(buf, {2}, {barrel}, {targetPart})
    end)

    return ok
end

function NaramoSilentAim:EnsureFovCircle()
    if self.FovCircle or not Drawing then return self.FovCircle end
    local ok, circle = pcall(function() return Drawing.new("Circle") end)
    if not ok or not circle then return nil end

    circle.Thickness = 1.5
    circle.NumSides = 64
    circle.Filled = false
    circle.Transparency = 1
    circle.Radius = self.FOV
    circle.Visible = false
    self.FovCircle = circle
    return circle
end


-- Used only by the tracer/hitmarker visual pipeline; kept separate from silent-aim targeting.
local function GetWeaponShotOrigin()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        local muzzle = tool:FindFirstChild("Muzzle", true)
        if muzzle then
            if muzzle:IsA("Attachment") then return muzzle.WorldPosition end
            if muzzle:IsA("BasePart") then return muzzle.Position end
        end
        local handle = tool:FindFirstChild("Handle", true)
        if handle and handle:IsA("BasePart") then return handle.Position end
    end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return root and root.Position or Camera.CFrame.Position
end

function NaramoSilentAim:SetFOV(value)
    self.FOV = math.clamp(tonumber(value) or 150, 25, 500)
end

local function FireNaramoSilentShot()
    if not NaramoSilentAim.Enabled then return false end
    local target = NaramoSilentAim:GetTarget()
    local char = target and target.Character
    local part = char and char:FindFirstChild(NaramoSilentAim.TargetPart)
    if not part then return false end
    return NaramoSilentAim:Fire(part)
end
-- 触发方式：沿用 NNPP 原有“开火状态判断”。
-- 只有 MouseButton1 按住（移动端有触摸输入）且当前角色持有武器时，
-- 才会调用 Naramo 的 Fire()；松开开火键立即停止。
local SilentAimFireHeld = false
local SilentAimLastFire = 0
local SilentAimFireInterval = 0.10

local function IsSilentAimFireDown()
    local down = false
    pcall(function()
        down = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end)
    if UserInputService.TouchEnabled then
        local ok, touches = pcall(function()
            return UserInputService:GetTouches()
        end)
        if ok and touches and #touches > 0 then
            down = true
        end
    end
    return down
end

local function HasEquippedWeapon()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool ~= nil
end

function NaramoSilentAim:SetEnabled(enabled)
    self.Enabled = enabled == true
    self.Target = nil
    if self.FovCircle then
        self.FovCircle.Visible = ShowSilentAimFOV and self.Enabled
    end
end

-- 与 NNPP 的原始开火状态判断同步：只在实际按住开火键时触发。
RunService.Heartbeat:Connect(function()
    if not NaramoSilentAim.Enabled then
        SilentAimFireHeld = false
        return
    end

    SilentAimFireHeld = IsSilentAimFireDown() and HasEquippedWeapon()
    if not SilentAimFireHeld then return end

    local now = os.clock()
    if now - SilentAimLastFire < SilentAimFireInterval then return end
    SilentAimLastFire = now

    pcall(function()
        FireNaramoSilentShot()
    end)
end)


local function IsAimbotTargetVisible(targetChar)
    if not AimbotWallCheck or not targetChar then return true end
    local targetPart = targetChar:FindFirstChild(AimbotTargetPart)
    if not targetPart then return false end

    local origin = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    local result = workspace:Raycast(origin, targetPart.Position - origin, params)
    return result == nil
end

local function GetClosestAimbotTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = plr.Character:FindFirstChild(AimbotTargetPart)
            local passTeam = (not AimbotTeamCheck) or plr.Team ~= LocalPlayer.Team
            if hum and hum.Health > 0 and targetPart and passTeam and IsAimbotTargetVisible(plr.Character) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distance < AimbotFOV and distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = plr
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function StopAimbotEngine()
    if AimbotConnection then
        AimbotConnection:Disconnect()
        AimbotConnection = nil
    end
    AimbotTargetPlayer = nil
end

local function StartAimbotEngine()
    StopAimbotEngine()
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not AimbotEnabled then return end

        local inputDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if UserInputService.TouchEnabled then
            local okTouches, touches = pcall(function() return UserInputService:GetTouches() end)
            if okTouches and touches and #touches > 0 then inputDown = true end
        end
        if not inputDown then
            AimbotTargetPlayer = nil
            return
        end

        AimbotTargetPlayer = GetClosestAimbotTarget()
        local char = AimbotTargetPlayer and AimbotTargetPlayer.Character
        local targetPart = char and char:FindFirstChild(AimbotTargetPart)
        if targetPart then
            local currentLook = Camera.CFrame.LookVector
            local targetLook = (targetPart.Position - Camera.CFrame.Position).Unit
            local smoothLook = currentLook:Lerp(targetLook, math.clamp(AimbotSmoothness, 0.01, 1))
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + smoothLook)
        end
    end)
end

local function SetAimbotEnabled(enabled)
    AimbotEnabled = enabled == true
    if AimbotEnabled then
        StartAimbotEngine()
    else
        StopAimbotEngine()
    end
end

local function ToggleAimbotState()
    SetAimbotEnabled(not AimbotEnabled)
end

local function SetVehicleFlyEnabled(enabled)
    VehicleFlyEnabled = enabled == true
    if VehicleFlyConnection then
        VehicleFlyConnection:Disconnect()
        VehicleFlyConnection = nil
    end
    if not VehicleFlyEnabled then return end

    VehicleFlyConnection = RunService.RenderStepped:Connect(function()
        if not VehicleFlyEnabled then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local seat = humanoid and humanoid.SeatPart
        if seat and seat:IsA("Seat") then
            local vehicle = seat:FindFirstAncestorOfClass("Model")
            local root = vehicle and (vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart", true)) or seat
            if not root or not root:IsA("BasePart") then root = seat end
            local move = GetMobileMoveDirection()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
            root.AssemblyLinearVelocity = move.Magnitude > 0 and move.Unit * TargetWalkSpeed or Vector3.new(0, 0, 0)
        end
    end)
end

local function SetSpinBotEnabled(enabled)
    SpinBotEnabled = enabled == true
    if SpinBotConnection then
        SpinBotConnection:Disconnect()
        SpinBotConnection = nil
    end
    if not SpinBotEnabled then return end

    SpinBotConnection = RunService.RenderStepped:Connect(function(dt)
        if not SpinBotEnabled then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(SpinBotSpeed) * dt, 0)
        end
    end)
end

local proximityOriginal = setmetatable({}, {__mode = "k"})
local function ApplyInstantProximityToPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if proximityOriginal[prompt] == nil then
        proximityOriginal[prompt] = prompt.HoldDuration
    end
    prompt.HoldDuration = 0
end

local function SetInstantProximityEnabled(enabled)
    InstantProximityEnabled = enabled == true
    if ProximityAddedConnection then
        ProximityAddedConnection:Disconnect()
        ProximityAddedConnection = nil
    end

    if InstantProximityEnabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                pcall(ApplyInstantProximityToPrompt, obj)
            end
        end
        ProximityAddedConnection = workspace.DescendantAdded:Connect(function(obj)
            if InstantProximityEnabled and obj:IsA("ProximityPrompt") then
                task.defer(function() pcall(ApplyInstantProximityToPrompt, obj) end)
            end
        end)
    else
        for prompt, original in pairs(proximityOriginal) do
            if prompt and prompt.Parent then
                pcall(function() prompt.HoldDuration = original end)
            end
        end
    end
end

local function UpdateAimFovCircles()
    if not Drawing then return end

    if not AimbotFovCircle then
        local ok, circle = pcall(function()
            return Drawing.new("Circle")
        end)
        if ok and circle then
            AimbotFovCircle = circle
            AimbotFovCircle.Thickness = 1.5
            AimbotFovCircle.NumSides = 64
            AimbotFovCircle.Filled = false
            AimbotFovCircle.Transparency = 1
            AimbotFovCircle.Color = Color3.fromRGB(255, 255, 255)
        end
    end

    if AimbotFovCircle then
        AimbotFovCircle.Radius = AimbotFOV
        AimbotFovCircle.Position = Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
        AimbotFovCircle.Visible = ShowAimbotFOV
    end

    -- 静默瞄准 FOV：以鼠标位置为圆心，并实时跟随鼠标移动
    NaramoSilentAim:EnsureFovCircle()
    if NaramoSilentAim.FovCircle then
        local mousePos = UserInputService:GetMouseLocation()
        NaramoSilentAim.FovCircle.Radius = NaramoSilentAim.FOV
        NaramoSilentAim.FovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        NaramoSilentAim.FovCircle.Color = Color3.fromHSV((os.clock() * 0.18) % 1, 0.9, 1)
        NaramoSilentAim.FovCircle.Visible = ShowSilentAimFOV and NaramoSilentAim.Enabled
    end
end

RunService.RenderStepped:Connect(UpdateAimFovCircles)

-- Silent aim / hitmarker / rainbow tracer click pipeline.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        and (NaramoSilentAim.Enabled or TracerEnabled or HitmarkerMode > 0) then

        local char = LocalPlayer.Character
        local origin = GetWeaponShotOrigin()

        if origin then
            local destination = nil
            local silentPart = nil
            local rayResult = nil

            -- 静默自瞄由上方 NNPP 开火状态循环触发；此处仅负责弹道/命中标记视觉效果。
            if not destination then
                local mousePos = UserInputService:GetMouseLocation()
                local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {char}

                rayResult = workspace:Raycast(ray.Origin, ray.Direction * 1500, params)
                destination = rayResult and rayResult.Position or (ray.Origin + ray.Direction * 1500)
            end

            -- 彩色弹道“视觉吸附”：
            -- 仅改变本地弹道显示的终点，不修改真实射击方向、射线或静默自瞄攻击包。
            if TracerEnabled then
                local tracerDestination = destination
                if NaramoSilentAim.Enabled then
                    local visualTarget = NaramoSilentAim:GetTarget()
                    local visualChar = visualTarget and visualTarget.Character
                    local visualPart = visualChar and visualChar:FindFirstChild(NaramoSilentAim.TargetPart)
                    if visualPart then
                        tracerDestination = visualPart.Position
                    end
                end
                DrawNaramoRGBTracer(origin, tracerDestination)
            end

            local shouldHitmarker = false
            if silentPart then
                shouldHitmarker = true
            elseif rayResult and rayResult.Instance then
                local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                local hitPlayer = model and Players:GetPlayerFromCharacter(model)
                shouldHitmarker = hum ~= nil
                    and hitPlayer ~= nil
                    and hitPlayer ~= LocalPlayer
                    and ((not AimbotTeamCheck) or hitPlayer.Team ~= LocalPlayer.Team)
            end

            if shouldHitmarker then
                CreateLocalHitmarker()
            end
        end
    end

    -- 不再保留任何默认功能快捷键。
    -- 所有功能键盘操作统一由 Keybind 组件处理；未绑定按键时不执行任何功能。
end)

-- Quick HUD and Chat Logs are NaramoV3 features, default OFF.
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragInput = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and dragStart and startPos then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local TranslationCache = {}
local TranslationInFlight = {}

local function DecodeGoogleTranslation(data)
    if type(data) ~= "table" or type(data[1]) ~= "table" then return nil end
    local chunks = {}
    for _, row in ipairs(data[1]) do
        if type(row) == "table" and type(row[1]) == "string" then
            table.insert(chunks, row[1])
        end
    end
    local result = table.concat(chunks)
    return result ~= "" and result or nil
end

local function TranslateToChinese(message)
    message = tostring(message or "")
    if message == "" then return message end
    if TranslationCache[message] then return TranslationCache[message] end
    if TranslationInFlight[message] then return message end

    -- Pure ASCII messages are usually English; punctuation/numbers-only are left alone.
    -- The API auto-detects the source language and returns simplified Chinese.
    TranslationInFlight[message] = true
    local encoded = HttpService:UrlEncode(message)
    local translated
    pcall(function()
        local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=" .. encoded
        local body = game:HttpGet(url)
        local data = HttpService:JSONDecode(body)
        translated = DecodeGoogleTranslation(data)
    end)
    TranslationInFlight[message] = nil

    if translated and translated ~= "" then
        TranslationCache[message] = translated
        return translated
    end
    return message
end

local function AddChatLogMessage(playerObj, message)
    if not ChatLogsScroll or not playerObj then return end
    local originalMessage = tostring(message or "")
    if originalMessage == "" then return end

    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1, -8, 0, 26)
    line.AutomaticSize = Enum.AutomaticSize.Y
    line.BackgroundTransparency = 1
    line.Font = Enum.Font.GothamMedium
    line.TextSize = 11
    line.TextWrapped = true
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.TextYAlignment = Enum.TextYAlignment.Top
    line.TextColor3 = Color3.fromRGB(25, 25, 25)
    line.Text = string.format("[%s] %s (@%s): %s", os.date("%H:%M:%S"), playerObj.DisplayName, playerObj.Name, originalMessage)
    line.Parent = ChatLogsScroll

    task.spawn(function()
        local translated = TranslateToChinese(originalMessage)
        if line and line.Parent then
            line.Text = string.format("[%s] %s (@%s): %s", os.date("%H:%M:%S"), playerObj.DisplayName, playerObj.Name, translated)
        end
    end)

    task.defer(function()
        -- Chat UI may be destroyed/recreated between scheduling and execution.
        local scroll = ChatLogsScroll
        if not scroll or not scroll.Parent then return end
        local layout = scroll:FindFirstChildOfClass("UIListLayout")
        if layout then
            scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
            scroll.CanvasPosition = Vector2.new(0, math.max(0, layout.AbsoluteContentSize.Y))
        end
    end)
end

local ChatServiceConnection = nil
local RecentChatMessages = {}

local function ShouldAddChatMessage(playerObj, message)
    local key = tostring(playerObj.UserId) .. "|" .. tostring(message)
    local now = os.clock()
    local last = RecentChatMessages[key]
    RecentChatMessages[key] = now
    return not last or (now - last) > 0.75
end

local function HookChatPlayer(plr)
    if ChatPlayerConnections[plr] then return end
    ChatPlayerConnections[plr] = plr.Chatted:Connect(function(message)
        if ChatLogsEnabled and ShouldAddChatMessage(plr, message) then AddChatLogMessage(plr, message) end
    end)
end

local function HookTextChatService()
    if ChatServiceConnection then return end
    pcall(function()
        if TextChatService and TextChatService.MessageReceived then
            ChatServiceConnection = TextChatService.MessageReceived:Connect(function(message)
                if not ChatLogsEnabled then return end
                local text = message.Text
                if not text or text == "" then return end
                local source = message.TextSource
                local plr = source and Players:GetPlayerByUserId(source.UserId)
                if plr and ShouldAddChatMessage(plr, text) then
                    AddChatLogMessage(plr, text)
                end
            end)
        end
    end)
end

local function CreateChatLogs()
    if ChatLogsFrame and ChatLogsFrame.Parent then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "NaramoChatLogs"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(320, 230)
    frame.Position = UDim2.new(0.06, 0, 0.52, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.22
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundTransparency = 1
    title.Text = "聊天日志"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextColor3 = Color3.fromRGB(20, 20, 20)
    title.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -42)
    scroll.Position = UDim2.fromOffset(8, 36)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    ChatLogsFrame = frame
    ChatLogsScroll = scroll
    MakeDraggable(frame, title)

    for _, plr in ipairs(Players:GetPlayers()) do HookChatPlayer(plr) end
    HookTextChatService()
    Players.PlayerAdded:Connect(HookChatPlayer)
    Players.PlayerRemoving:Connect(function(plr)
        local c = ChatPlayerConnections[plr]
        if c then c:Disconnect() end
        ChatPlayerConnections[plr] = nil
    end)
end

local function SetChatLogsEnabled(enabled)
    ChatLogsEnabled = enabled == true
    CreateChatLogs()
    if ChatLogsFrame then ChatLogsFrame.Visible = ChatLogsEnabled end
end

local function PanicDisableAddedFeatures()
    SetAimbotEnabled(false)
    NaramoSilentAim:SetEnabled(false)
    SetVehicleFlyEnabled(false)
    SetSpinBotEnabled(false)
    SetInstantProximityEnabled(false)
    InfAmmoEnabled = false
    ShowAimbotFOV = false
        SetChatLogsEnabled(false)
    BreakDeviceEnabled = false
    if AimbotFovCircle then AimbotFovCircle.Visible = false end
    if NaramoSilentAim.FovCircle then NaramoSilentAim.FovCircle.Visible = false end
end

local function FireGamePromoCodes()
    -- NaramoV3 only contains a placeholder for this feature; keep the same behavior.
    if IsRedeemingCodes then return end
    IsRedeemingCodes = true
    task.delay(1, function() IsRedeemingCodes = false end)
end

CreateChatLogs()

-- SECTION 10: AUTOMATION OPERATION CONTROL PIPELINE
task.spawn(function()
    local lastHeavyUpdate = 0
    while true do
        pcall(function()
            local now = os.clock()
            
            if now - lastHeavyUpdate >= 0.3 then
                UpdateChams()
                ApplyHitbox()
                lastHeavyUpdate = now
            end
            
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and not GhostEnabled then
                if SpeedEnabled then
                    if hum.WalkSpeed ~= TargetWalkSpeed then
                        hum.WalkSpeed = TargetWalkSpeed
                    end
                end

                if JumpEnabled then
                    if hum.JumpPower ~= TargetJumpPower then
                        hum.JumpPower = TargetJumpPower
                    end
                end
            end
            if GhostEnabled then settings().Rendering.DrawDistance = 100000 end
            if FullbrightEnabled then
                Lighting.Brightness = 2 
                Lighting.ClockTime = 14 
                Lighting.FogEnd = 1000000 
                Lighting.FogStart = 1000000 
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) 
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            end
            if FOVEnabled then
                Camera.FieldOfView = TargetFOV
            else
                Camera.FieldOfView = 70
            end
            
            local activeGreen = Color3.fromRGB(46, 204, 113)
            local inactiveColor = DarkModeEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
            
            if hitBtn then hitBtn.Text = "HITBOX EXPARNDER [" .. (HitboxEnabled and "ON" or "OFF") .. "]" hitBtn.TextColor3 = HitboxEnabled and activeGreen or inactiveColor end
            if sizeBtn then sizeBtn.Text = "HITBOX SIZE: " .. tostring(HitboxSize) end
            if infAmBtn then infAmBtn.Text = "INF AM [" .. (InfAmmoEnabled and "ON" or "OFF") .. "]" infAmBtn.TextColor3 = InfAmmoEnabled and activeGreen or inactiveColor end
            if noclipBtn then noclipBtn.Text = "NOCLIP [" .. (NoclipEnabled and "ON" or "OFF") .. "]" noclipBtn.TextColor3 = NoclipEnabled and activeGreen or inactiveColor end
            if infJumpBtn then infJumpBtn.Text = "INF JUMP [" .. (InfJumpEnabled and "ON" or "OFF") .. "]" infJumpBtn.TextColor3 = InfJumpEnabled and activeGreen or inactiveColor end
            if brightBtn then brightBtn.Text = "FULLBRIGHT [" .. (FullbrightEnabled and "ON" or "OFF") .. "]" brightBtn.TextColor3 = FullbrightEnabled and activeGreen or inactiveColor end
            if ghostBtn then ghostBtn.Text = "GHOST MODE [" .. (GhostEnabled and "ON" or "OFF") .. "]" ghostBtn.TextColor3 = GhostEnabled and activeGreen or inactiveColor end
            if chamsBtn then chamsBtn.Text = "CHAMS ESP [" .. (ChamsEnabled and "ON" or "OFF") .. "]" chamsBtn.TextColor3 = ChamsEnabled and activeGreen or inactiveColor end
            if vehicleEspBtn then vehicleEspBtn.Text = "VEHICLE ESP [" .. (VehicleEspEnabled and "ON" or "OFF") .. "]" vehicleEspBtn.TextColor3 = VehicleEspEnabled and activeGreen or inactiveColor end
            if ventEspBtn then ventEspBtn.Text = "VENT ESP [" .. (VentEspEnabled and "ON" or "OFF") .. "]" ventEspBtn.TextColor3 = VentEspEnabled and activeGreen or inactiveColor end
            if breakableEspBtn then breakableEspBtn.Text = "BREAKABLES ESP [" .. (BreakableEspEnabled and "ON" or "OFF") .. "]" breakableEspBtn.TextColor3 = BreakableEspEnabled and activeGreen or inactiveColor end
            if infStamBtn then infStamBtn.Text = "INF STAMINA [" .. (InfStaminaEnabled and "ON" or "OFF") .. "]" infStamBtn.TextColor3 = InfStaminaEnabled and activeGreen or inactiveColor end
            if zoomBtn then zoomBtn.Text = "COMBAT ZOOM [" .. (ZoomEnabled and "ON" or "OFF") .. "]" zoomBtn.TextColor3 = ZoomEnabled and activeGreen or inactiveColor end
            if tracerBtn then tracerBtn.Text = "RGB TRACERS [" .. (TracerEnabled and "ON" or "OFF") .. "]" tracerBtn.TextColor3 = TracerEnabled and activeGreen or inactiveColor end
            
            if hitmarkerBtn then
                local labelText = "HITMARKER [OFF]"
                if HitmarkerMode == 1 then labelText = "HITMARKER [NORMAL]" elseif HitmarkerMode == 2 then labelText = "HITMARKER [RGB]" end
                hitmarkerBtn.Text = labelText
                hitmarkerBtn.TextColor3 = (HitmarkerMode > 0) and activeGreen or inactiveColor
            end
        end)
        task.wait(0.2)
    end
end)

-- SECTION 10B: Work automation auto mop auto glass auto power order auto repair
local AutoMopRunning = false
local AutoCleanRunning = false
local AutoRepairRunning = false

-- ===================== Auto Mop =====================
local function AutoMopGetTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Mop")
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

local function RunAutoMop()
    if AutoMopRunning then return end
    AutoMopRunning = true

    local CollectionService = game:GetService("CollectionService")
    local CleanPuddleRemote = nil
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs and rs:FindFirstChild("Remotes")
    local mop = remotes and remotes:FindFirstChild("Mop")
    CleanPuddleRemote = mop and mop:FindFirstChild("CleanPuddleRemote")

    if not CleanPuddleRemote then
        warn("[自动拖地] 未找到 CleanPuddleRemote，已停止")
        AutoMopRunning = false
        AutoMopEnabled = false
        return
    end

    while AutoMopEnabled do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local tool = AutoMopGetTool()
        if root and tool then
            local nearby = {}
            for _, part in ipairs(CollectionService:GetTagged("WaterPuddle")) do
                if part:GetAttribute("Active") == true then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist <= 8 then
                        table.insert(nearby, {part = part, distance = dist})
                    end
                end
            end
            table.sort(nearby, function(a, b) return a.distance < b.distance end)

            if #nearby > 0 then
                for _, entry in ipairs(nearby) do
                    if not AutoMopEnabled then break end
                    pcall(function() CleanPuddleRemote:FireServer(tool, entry.part) end)
                    task.wait(0.01)
                end
            else
                task.wait(0.01)
            end
        else
            task.wait(0.01)
        end
    end

    AutoMopRunning = false
end

-- ===================== Auto Glass =====================
local function AutoCleanGetTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Towel")
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

local function RunAutoClean()
    if AutoCleanRunning then return end
    AutoCleanRunning = true

    local CollectionService = game:GetService("CollectionService")
    local CleanSmudgeRemote = nil
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs and rs:FindFirstChild("Remotes")
    local towel = remotes and remotes:FindFirstChild("Towel")
    CleanSmudgeRemote = towel and towel:FindFirstChild("CleanSmudgeRemote")

    if not CleanSmudgeRemote then
        warn("[自动擦玻璃] 未找到 CleanSmudgeRemote，已停止")
        AutoCleanRunning = false
        AutoCleanEnabled = false
        return
    end

    while AutoCleanEnabled do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local tool = AutoCleanGetTool()
        if root and tool then
            local best = nil
            local bestDist = 25
            for _, part in ipairs(CollectionService:GetTagged("GlassSmudge")) do
                if part:GetAttribute("Active") == true then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist <= 25 and (not best or dist < bestDist) then
                        best = part
                        bestDist = dist
                    end
                end
            end
            if best then
                pcall(function() CleanSmudgeRemote:FireServer(tool, best) end)
                task.wait(0.01)
            else
                task.wait(0.01)
            end
        else
            task.wait(0.01)
        end
    end

    AutoCleanRunning = false
end

-- ===================== Auto Repair =====================
local function AutoRepairGetTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Wrench")
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

local function RunAutoRepair()
    if AutoRepairRunning then return end
    AutoRepairRunning = true

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local RepairRemote, RequestRepair
    local RepairZoneParser, RepairInstance
    local RepairMinigame, WeldMinigame, WireMinigame, IsolationMinigame

    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local rsSys = remotes and remotes:FindFirstChild("RepairSystem")
        RepairRemote = rsSys and rsSys:FindFirstChild("Repair")
        RequestRepair = rsSys and rsSys:FindFirstChild("RequestRepair")

        local cm = ReplicatedStorage:FindFirstChild("ClientModules")
        if cm then
            RepairZoneParser = require(cm:FindFirstChild("RepairZoneParser"))
            local h = cm:FindFirstChild("RepairToolHandler")
            if h then
                RepairInstance = require(h:FindFirstChild("RepairInstance"))
                RepairMinigame = require(h:FindFirstChild("RepairMinigame"))
                WeldMinigame = require(h:FindFirstChild("WeldMinigame"))
                WireMinigame = require(h:FindFirstChild("WireMinigame"))
                IsolationMinigame = require(h:FindFirstChild("IsolationMinigame"))
            end
        end
    end)

    if not RepairZoneParser or not RepairZoneParser.RepairZones then
        warn("[自动修理] 未找到 RepairZoneParser，已停止")
        AutoRepairRunning = false
        AutoRepairEnabled = false
        return
    end

    local RANGE_OVERRIDES = { ["Turbine"] = 50, ["Feedwater"] = 50 }
    local DEFAULT_REPAIR_RANGE = 15
    local CLEAN_COOLDOWN = 0.01

    local function getMinigameModule(repairType)
        if repairType == "Weld" then
            return WeldMinigame
        elseif repairType == "Wire" then
            return WireMinigame
        elseif repairType == "Isolation" then
            return IsolationMinigame
        else
            return RepairMinigame
        end
    end

    local function forceCompleteMinigame(minigame, repairType)
        if not minigame then return false end

        if repairType == "Weld" then
            if minigame.CrackPath and #minigame.CrackPath > 0 then
                minigame.CurrentPathIndex = #minigame.CrackPath
                minigame.CompletionProgress = 1
                pcall(function()
                    if RepairRemote then
                        RepairRemote:FireServer(minigame.Tool, minigame.RepairObject.BasePart, "Durability")
                    end
                    minigame.FixedSignal:Fire()
                    minigame:Dispose()
                end)
                return true
            end
            return false
        elseif repairType == "Wire" then
            if minigame.NumConnections then
                minigame.CompletedConnections = minigame.NumConnections
                pcall(function() minigame:Success() end)
                return true
            end
            return false
        elseif repairType == "Isolation" then
            minigame.DamageCount = 0
            minigame.IsolatedCount = 1
            pcall(function() minigame:Step() end)
            return true
        else
            if minigame.MinigameProgress ~= nil then
                minigame.MinigameProgress = 3.1
                pcall(function() minigame:Update(0) end)
                return true
            end
            return false
        end
    end

    while AutoRepairEnabled do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local tool = AutoRepairGetTool()
        if not tool then
            warn("[自动修理] 未装备修理工具（扳手），等待 3 秒")
            task.wait(3)
        elseif not root then
            task.wait(1)
        else
            for basePart, repairZoneData in pairs(RepairZoneParser.RepairZones) do
                if not AutoRepairEnabled then break end
                local durability = repairZoneData:GetAttributeValue("Durability")
                local maxDurability = repairZoneData:GetAttributeMaxValue("Durability")
                if durability and maxDurability and durability < maxDurability then
                    local targetPart = basePart or repairZoneData.RepairZonePart
                    if targetPart and RepairInstance then
                        local repairName = repairZoneData.RepairName or ""
                        local maxRange = RANGE_OVERRIDES[repairName] or DEFAULT_REPAIR_RANGE
                        local dist = (root.Position - targetPart.Position).Magnitude
                        if dist <= maxRange then
                            local repairType = repairZoneData.RepairType or "Default"
                            local minigameModule = getMinigameModule(repairType)
                            if minigameModule then
                                pcall(function()
                                    local repairInstance = RepairInstance.new(basePart, repairZoneData)
                                    local minigame = minigameModule.new(repairInstance, targetPart.Position, tool)
                                    if minigame then
                                        forceCompleteMinigame(minigame, repairType)
                                    end
                                end)
                                task.wait(CLEAN_COOLDOWN)
                            end
                        end
                    end
                end
            end
            task.wait(0.01)
        end
    end

    AutoRepairRunning = false
end

-- ===================== Auto Power Order =====================
local function StartAutoPowerOrder()
--[[
Auto power order gear detection durability protection UI version
Final fix precise paths durability read compatibility and distance bonus 20
]]

local CONFIG = {
    TOLERANCE = 1000,
    FINE_ZONE = 1100,
    SAMPLE_DELAY = 0.08,
    MIN_STEP_INTERVAL = 0.45,
    CONTROL_COOLDOWN = 0.20,
    STABLE_DELTA_MAX = 99,
    STABLE_WINDOW = 0.70,
    RATE_WINDOW = 0.60,
    RATE_MIN_DELTA = 100,
    GEAR2_RATE_RATIO = 1.60,
    GEAR2_FALLBACK_RATE = 1800,
    GEAR1_LEARN_ALPHA = 0.28,
    GEAR1_LEARN_MIN_RATE = 120,
    GEAR_DETECT_GRACE_AFTER_CLICK = 0.85,
    GEAR_MISMATCH_CONFIRM = 0.65,
    MOTION_CHECK_DELAY = 0.45,
    MAX_NEUTRAL_CORRECTIONS = 2,
    DURABILITY_LIMIT = 25,
    DURABILITY_RECHECK_NEUTRAL = 1.20,
    WATER_LEVEL_NORMAL = 100,
    ZERO_POWER_THRESHOLD = 0,
    DISTANCE_BONUS = 20,
    FALLBACK_MAX_DISTANCE = 32,
    INCREMENT_RAISES_POWER = true,
    DEBUG = false,
}

-- 自动订单模块与 Nexus UI 共用同一个执行环境。
-- 这样“启动 / 停止 / 显示状态控制台”都能指向同一个控制器和状态对象。
local autoOrderSharedEnv = (type(getgenv) == "function" and getgenv()) or _G
local uiLogCallback = nil

local function joinArgs(...)
    local out = {}
    for i = 1, select("#", ...) do
        out[i] = tostring(select(i, ...))
    end
    return table.concat(out, " ")
end

local function log(...)
    -- Silent version no output to the Roblox console
    -- white UI updates live through UIState and refreshStatus
    if uiLogCallback then
        uiLogCallback("INFO", joinArgs(...))
    end
end

local function warnLog(...)
    -- Silent version no warnings to the Roblox console
    if uiLogCallback then
        uiLogCallback("WARN", joinArgs(...))
    end
end

if type(fireclickdetector) ~= "function" then
    error("[自动完成电力订单] 当前执行环境不支持 fireclickdetector()")
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[自动完成电力订单] 找不到 LocalPlayer")
end


-- ==================== White status UI ====================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldConsole = PlayerGui:FindFirstChild("AutoPowerOrderConsole")
if oldConsole then oldConsole:Destroy() end

local oldStatus = PlayerGui:FindFirstChild("AutoPowerOrderStatus")
if oldStatus then oldStatus:Destroy() end

pcall(function()
    local cg = game:GetService("CoreGui")
    local oldCoreConsole = cg:FindFirstChild("AutoPowerOrderConsole")
    if oldCoreConsole then oldCoreConsole:Destroy() end
    local oldCoreStatus = cg:FindFirstChild("AutoPowerOrderStatus")
    if oldCoreStatus then oldCoreStatus:Destroy() end
end)

local ConsoleGui = Instance.new("ScreenGui")
ConsoleGui.Name = "AutoPowerOrderStatus"
ConsoleGui.ResetOnSpawn = false
ConsoleGui.IgnoreGuiInset = false
ConsoleGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ConsoleGui.DisplayOrder = 100010

-- 原版状态控制台的外观、尺寸、文字和拖动方式均保留；
-- 这里只优先挂到 CoreGui，避免被游戏自身的 PlayerGui 层级遮住。
local consoleParented = false
pcall(function()
    local cg = game:GetService("CoreGui")
    ConsoleGui.Parent = cg
    consoleParented = ConsoleGui.Parent == cg
end)
if not consoleParented then
    ConsoleGui.Parent = PlayerGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.fromOffset(430, 315)
MainFrame.Position = UDim2.new(0, 14, 0, 70)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BackgroundTransparency = 0.22
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ConsoleGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Transparency = 0.25
MainStroke.Color = Color3.fromRGB(150, 150, 150)
MainStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.BackgroundTransparency = 0.08
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(20, 20, 20)
Title.TextTransparency = 0.04
Title.Text = "自动完成电力订单"
Title.Parent = TitleBar

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 0, 38)
Divider.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

local StopButton = Instance.new("TextButton")
StopButton.Name = "Stop"
StopButton.Size = UDim2.fromOffset(58, 26)
StopButton.Position = UDim2.new(1, -68, 0, 6)
StopButton.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
StopButton.BorderSizePixel = 0
StopButton.Font = Enum.Font.GothamMedium
StopButton.TextSize = 12
StopButton.TextColor3 = Color3.fromRGB(35, 35, 35)
StopButton.Text = "停止"
StopButton.Parent = TitleBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 5)
StopCorner.Parent = StopButton

local StopStroke = Instance.new("UIStroke")
StopStroke.Thickness = 1
StopStroke.Transparency = 0.45
StopStroke.Color = Color3.fromRGB(160, 160, 160)
StopStroke.Parent = StopButton

local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, -24, 1, -56)
StatusText.Position = UDim2.fromOffset(12, 48)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.Code
StatusText.TextSize = 13
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextYAlignment = Enum.TextYAlignment.Top
StatusText.TextColor3 = Color3.fromRGB(20, 20, 20)
StatusText.TextTransparency = 0.08
StatusText.TextWrapped = false
StatusText.Text = "正在初始化..."
StatusText.Parent = MainFrame

uiLogCallback = nil

local UIState = {
    running = true,
    order = nil,
    current = nil,
    difference = nil,
    waterLevel = nil,
    commandGear = 0,
    detectedGear = 0,
    targetGear = 0,
    powerRate = 0,
    learnedGear1Rate = nil,
    stable = false,
    stableRange = 0,
    alphaDistance = nil,
    alphaAllowed = nil,
    betaDistance = nil,
    betaAllowed = nil,
    inRange = false,
    alphaDurability = nil,
    betaDurability = nil,
    durabilitySafe = true,
    protection = "正常",
    action = "初始化",
}

-- 把原版自动订单控制台和实时状态公开给 Nexus UI 控制层。
autoOrderSharedEnv.NexusAutoPowerOrderConsole = ConsoleGui
autoOrderSharedEnv.NexusAutoPowerOrderUIState = UIState
autoOrderSharedEnv.NexusAutoPowerOrderShow = function()
    pcall(function()
        if ConsoleGui and ConsoleGui.Parent then
            ConsoleGui.Enabled = true
            MainFrame.Visible = true
        end
    end)
end
autoOrderSharedEnv.NexusAutoPowerOrderHide = function()
    pcall(function()
        if ConsoleGui and ConsoleGui.Parent then
            ConsoleGui.Enabled = false
        end
    end)
end

local function fmt0(v)
    if v == nil then return "--" end
    return string.format("%.0f", v)
end

local function fmt1(v)
    if v == nil then return "--" end
    return string.format("%.1f", v)
end

local function refreshStatus()
    if not StatusText.Parent then return end

    local runText = UIState.running and "运行中" or "已停止"
    local rangeText = UIState.inRange and "可操作" or "距离不足"
    local stableText = UIState.stable and "稳定" or "变化中"
    local durabilityText = UIState.durabilitySafe and "正常" or "危险"

    StatusText.Text = table.concat({
        "状态      : " .. runText .. "    保护: " .. tostring(UIState.protection),
        "订单功率  : " .. fmt0(UIState.order) .. " kW",
        "当前功率  : " .. fmt0(UIState.current) .. " kW",
        "功率差    : " .. fmt0(UIState.difference) .. " kW",
        "反应堆水位: " .. fmt1(UIState.waterLevel) .. "%    正常: " .. fmt0(CONFIG.WATER_LEVEL_NORMAL) .. "%",
        "",
        "脚本挡位  : " .. tostring(UIState.commandGear)
            .. "    检测挡位: " .. tostring(UIState.detectedGear)
            .. "    目标: " .. tostring(UIState.targetGear),
        "功率速度  : " .. fmt0(UIState.powerRate) .. " kW/s",
        "一挡速度  : " .. fmt0(UIState.learnedGear1Rate) .. " kW/s",
        "稳定检测  : " .. stableText .. "    窗口变化: " .. fmt0(UIState.stableRange) .. " kW",
        "",
        "Alpha耐久 : " .. fmt0(UIState.alphaDurability)
            .. "    Beta耐久: " .. fmt0(UIState.betaDurability)
            .. "    " .. durabilityText,
        "Alpha距离 : " .. fmt1(UIState.alphaDistance) .. " / " .. fmt1(UIState.alphaAllowed),
        "Beta距离  : " .. fmt1(UIState.betaDistance) .. " / " .. fmt1(UIState.betaAllowed)
            .. "    " .. rangeText,
        "",
        "最近动作  : " .. tostring(UIState.action),
    }, "\n")
end

local function setAction(s)
    UIState.action = tostring(s)
    refreshStatus()
end

local dragging = false
local dragStart = nil
local startPos = nil
local dragInput = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput and dragStart and startPos then
        local delta = input.Position - dragStart

        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)


-- ==================== Precise path fetching ====================
local FacilitySystems = workspace:WaitForChild("FacilitySystems")

local Controls = FacilitySystems:WaitForChild("Controls")
local ControlTurbines = Controls:WaitForChild("Turbines")

local AlphaSwitch = ControlTurbines:WaitForChild("TurbAlphaValveSwitch")
local BetaSwitch = ControlTurbines:WaitForChild("TurbBetaValveSwitch")

local AlphaLeft = AlphaSwitch:WaitForChild("Decrement"):WaitForChild("ClickDetector")
local AlphaRight = AlphaSwitch:WaitForChild("Increment"):WaitForChild("ClickDetector")
local BetaLeft = BetaSwitch:WaitForChild("Decrement"):WaitForChild("ClickDetector")
local BetaRight = BetaSwitch:WaitForChild("Increment"):WaitForChild("ClickDetector")

local ControlPanels = FacilitySystems:WaitForChild("ControlPanels")
local BigSignThing = ControlPanels:WaitForChild("BigSignThing")

local PowerOrder = BigSignThing:WaitForChild("PowerOrder"):WaitForChild("Part"):WaitForChild("SurfaceGui"):WaitForChild("TextLabel")
local CurrentPower = BigSignThing:WaitForChild("ExcessPower"):WaitForChild("Part"):WaitForChild("SurfaceGui"):WaitForChild("TextLabel")

-- reactor water level using the exact path
local ReactorMainPanels = ControlPanels:WaitForChild("ReactorMainPanels")
local ReactorTextContainer = ReactorMainPanels:WaitForChild("Text")
local ReactorTextChildren = ReactorTextContainer:GetChildren()
local WaterLevelPart = ReactorTextChildren[24]
if not WaterLevelPart then
    error("[自动完成电力订单] ReactorMainPanels.Text:GetChildren()[24] 不存在")
end
local WaterLevelLabel = WaterLevelPart:WaitForChild("SurfaceGui"):WaitForChild("TextLabel")

-- turbine durability using the exact path
local PhysicalTurbines = FacilitySystems:WaitForChild("Turbines")

local AlphaDurability = PhysicalTurbines:WaitForChild("TurbineAlpha"):WaitForChild("Repair"):WaitForChild("Values"):WaitForChild("Durability")
local BetaDurability = PhysicalTurbines:WaitForChild("TurbineBeta"):WaitForChild("Repair"):WaitForChild("Values"):WaitForChild("Durability")

-- print fetched object types for confirmation
-- Silent version no object type debug output

-- ==================== Number reading ====================
local function readNumberFromText(text)
    text = tostring(text or "")
    text = text:gsub(",", ""):gsub("，", ""):gsub("−", "-"):gsub("–", "-"):gsub("—", "-"):gsub("kW", ""):gsub("KW", ""):gsub("kw", "")
    local number = text:match("[-+]?%d+%.?%d*")
    if not number then return nil end
    return tonumber(number)
end

local function getOrder()
    return readNumberFromText(PowerOrder.Text)
end

local function getCurrentPower()
    return readNumberFromText(CurrentPower.Text)
end

local function getWaterLevel()
    return readNumberFromText(WaterLevelLabel.Text)
end

-- durability reading compatible with several types
local function readValueObject(obj)
    if not obj then return nil end
    local ok, value = pcall(function()
        if obj:IsA("ValueBase") then
            return obj.Value
        elseif obj:IsA("BasePart") then
            return obj:GetAttribute("Durability")
        elseif obj:IsA("NumberValue") or obj:IsA("IntValue") then
            return obj.Value
        else
            return tonumber(obj.Value) or tonumber(obj)
        end
    end)
    if not ok then
        -- Silent version no console spam on read failure
        return nil
    end
    return tonumber(value)
end

local function getDurability()
    local a = readValueObject(AlphaDurability)
    local b = readValueObject(BetaDurability)
    if a == nil or b == nil then
        -- Silent version assume 100 on durability read failure
        return 100, 100
    end
    return a, b
end

local function durabilityIsSafe()
    local a, b = getDurability()
    if a == nil or b == nil then
        return true, 100, 100
    end
    return a > CONFIG.DURABILITY_LIMIT and b > CONFIG.DURABILITY_LIMIT, a, b
end

-- ==================== Distance check ====================
local function getRootPart()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function getDetectorPosition(detector)
    if not detector then return nil end
    local p = detector.Parent
    if p and p:IsA("BasePart") then
        return p.Position
    end
    if p then
        local part = p:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    return nil
end

local function detectorIsInRange(detector)
    local root = getRootPart()
    local pos = getDetectorPosition(detector)
    if not root or not pos then
        return false, nil, nil
    end
    local distance = (root.Position - pos).Magnitude
    local maxDistance = tonumber(detector.MaxActivationDistance) or CONFIG.FALLBACK_MAX_DISTANCE
    local allowed = math.max(0, maxDistance + CONFIG.DISTANCE_BONUS)
    return distance <= allowed, distance, allowed
end

local function pairIsInRange(alphaDetector, betaDetector)
    local aOK, aDist, aAllowed = detectorIsInRange(alphaDetector)
    local bOK, bDist, bAllowed = detectorIsInRange(betaDetector)
    return aOK and bOK, aDist, aAllowed, bDist, bAllowed
end

local function allControlsInRange()
    local al = detectorIsInRange(AlphaLeft)
    local ar = detectorIsInRange(AlphaRight)
    local bl = detectorIsInRange(BetaLeft)
    local br = detectorIsInRange(BetaRight)
    return al and ar and bl and br
end

local function updateDistanceUI()
    local aOK, aDist, aAllowed = detectorIsInRange(AlphaRight)
    local bOK, bDist, bAllowed = detectorIsInRange(BetaRight)
    UIState.alphaDistance = aDist
    UIState.alphaAllowed = aAllowed
    UIState.betaDistance = bDist
    UIState.betaAllowed = bAllowed
    UIState.inRange = aOK and bOK
    return UIState.inRange
end

-- ==================== Power history and gear detection ====================
local powerHistory = {}
local learnedGear1Rate = nil
local lastPhysicalStep = -math.huge
local currentGear = 0
local mismatchStart = nil
local mismatchExpected = nil
local lastKnownMovingGear = 0

local function resetPowerHistory()
    table.clear(powerHistory)
end

local function pushPowerSample(power)
    local now = os.clock()
    table.insert(powerHistory, { t = now, p = power })
    local keepWindow = math.max(CONFIG.STABLE_WINDOW, CONFIG.RATE_WINDOW) + 0.25
    local cutoff = now - keepWindow
    while #powerHistory > 0 and powerHistory[1].t < cutoff do
        table.remove(powerHistory, 1)
    end
end

local function getWindowStats(windowSeconds, currentPower)
    local now = os.clock()
    local oldest = nil
    local minPower = currentPower
    local maxPower = currentPower
    for _, sample in ipairs(powerHistory) do
        if sample.t >= now - windowSeconds then
            if not oldest then oldest = sample end
            minPower = math.min(minPower, sample.p)
            maxPower = math.max(maxPower, sample.p)
        end
    end
    if not oldest then return 0, 0, 0 end
    local duration = now - oldest.t
    local delta = currentPower - oldest.p
    local range = maxPower - minPower
    local rate = duration > 0.08 and delta / duration or 0
    return rate, range, duration
end

local function directionFromRate(rate)
    if math.abs(rate) < 1 then return 0 end
    local rising = rate > 0
    if CONFIG.INCREMENT_RAISES_POWER then
        return rising and 1 or -1
    else
        return rising and -1 or 1
    end
end

local function classifyDetectedGear(rate, stable)
    if stable then return 0 end
    local direction = directionFromRate(rate)
    if direction == 0 then return 0 end
    local absRate = math.abs(rate)
    local gear2Threshold
    if learnedGear1Rate and learnedGear1Rate >= CONFIG.GEAR1_LEARN_MIN_RATE then
        gear2Threshold = learnedGear1Rate * CONFIG.GEAR2_RATE_RATIO
    else
        gear2Threshold = CONFIG.GEAR2_FALLBACK_RATE
    end
    if absRate >= gear2Threshold then
        return direction * 2
    end
    return direction
end

local function learnGear1Rate(rate, stable)
    if stable then return end
    if math.abs(currentGear) ~= 1 then return end
    if os.clock() - lastPhysicalStep < CONFIG.GEAR_DETECT_GRACE_AFTER_CLICK then return end
    local absRate = math.abs(rate)
    if absRate < CONFIG.GEAR1_LEARN_MIN_RATE then return end
    if not learnedGear1Rate then
        learnedGear1Rate = absRate
        log("已学习一挡速度:", string.format("%.0f kW/s", learnedGear1Rate))
    else
        learnedGear1Rate = learnedGear1Rate * (1 - CONFIG.GEAR1_LEARN_ALPHA) + absRate * CONFIG.GEAR1_LEARN_ALPHA
    end
    UIState.learnedGear1Rate = learnedGear1Rate
end

local function maybeSyncGearFromTelemetry(detectedGear, stable)
    local sinceClick = os.clock() - lastPhysicalStep
    if stable then
        if sinceClick >= CONFIG.GEAR_DETECT_GRACE_AFTER_CLICK then
            if currentGear ~= 0 then
                log("功率已稳定，真实挡位同步为 0")
            end
            currentGear = 0
            if UIState.current ~= nil and UIState.current > CONFIG.ZERO_POWER_THRESHOLD then
                lastKnownMovingGear = 0
            end
            mismatchStart = nil
            mismatchExpected = nil
        end
        return
    end
    if math.abs(currentGear) == 2 and math.abs(detectedGear) == 1 and currentGear * detectedGear > 0 and sinceClick >= CONFIG.GEAR_DETECT_GRACE_AFTER_CLICK then
        if mismatchExpected ~= detectedGear then
            mismatchExpected = detectedGear
            mismatchStart = os.clock()
        elseif mismatchStart and os.clock() - mismatchStart >= CONFIG.GEAR_MISMATCH_CONFIRM then
            warnLog("检测到二挡速度实际只像一挡，推测第二次点击被吞；内部挡位", currentGear, "->", detectedGear)
            currentGear = detectedGear
            mismatchStart = nil
            mismatchExpected = nil
            setAction("检测到二挡丢失，准备补第二挡")
        end
    else
        mismatchStart = nil
        mismatchExpected = nil
    end
end

local function updateTelemetry(currentPower)
    pushPowerSample(currentPower)
    local rate, _, rateDuration = getWindowStats(CONFIG.RATE_WINDOW, currentPower)
    local _, stableRange, stableDuration = getWindowStats(CONFIG.STABLE_WINDOW, currentPower)
    local stable = stableDuration >= CONFIG.STABLE_WINDOW * 0.80 and stableRange <= CONFIG.STABLE_DELTA_MAX
    local detectedGear = 0
    if rateDuration >= CONFIG.RATE_WINDOW * 0.70 then
        detectedGear = classifyDetectedGear(rate, stable)
    end
    learnGear1Rate(rate, stable)
    maybeSyncGearFromTelemetry(detectedGear, stable)
    UIState.powerRate = rate
    UIState.stable = stable
    UIState.stableRange = stableRange
    UIState.detectedGear = detectedGear
    UIState.commandGear = currentGear
    UIState.learnedGear1Rate = learnedGear1Rate
    if currentPower > CONFIG.ZERO_POWER_THRESHOLD and detectedGear ~= 0 then
        lastKnownMovingGear = detectedGear
    end
    return stable, stableRange, rate, detectedGear
end

-- ==================== Durability UI ====================
local durabilityEmergency = false
local lastDurabilityNeutralAttempt = -math.huge

local function updateDurabilityUI()
    local safe, a, b = durabilityIsSafe()
    UIState.alphaDurability = a
    UIState.betaDurability = b
    UIState.durabilitySafe = safe
    if safe then
        UIState.protection = "正常"
    else
        UIState.protection = "耐久保护"
    end
    return safe, a, b
end

-- ==================== Clicking ====================
local lastControl = 0

local function clickOne(alphaDetector, betaDetector, direction, allowLowDurability)
    local inRange, aDist, aAllowed, bDist, bAllowed = pairIsInRange(alphaDetector, betaDetector)
    if not inRange then
        warnLog(string.format("距离不足 | Alpha=%.1f/%.1f | Beta=%.1f/%.1f", aDist or -1, aAllowed or -1, bDist or -1, bAllowed or -1))
        setAction("距离不足，取消点击")
        return false
    end
    local safe, aDur, bDur = durabilityIsSafe()
    if not safe and not allowLowDurability then
        warnLog("耐久保护阻止继续加/减功率 | Alpha=", aDur, "Beta=", bDur)
        setAction("耐久 <=25，禁止继续调功率")
        return false
    end
    local elapsed = os.clock() - lastPhysicalStep
    if elapsed < CONFIG.MIN_STEP_INTERVAL then
        task.wait(CONFIG.MIN_STEP_INTERVAL - elapsed)
    end
    local alphaOK = false
    local betaOK = false
    local alphaDone = false
    local betaDone = false
    task.spawn(function()
        alphaOK = pcall(function() fireclickdetector(alphaDetector) end)
        alphaDone = true
    end)
    task.spawn(function()
        betaOK = pcall(function() fireclickdetector(betaDetector) end)
        betaDone = true
    end)
    local deadline = os.clock() + 0.30
    while (not alphaDone or not betaDone) and os.clock() < deadline do
        task.wait()
    end
    if not alphaDone or not betaDone then
        warnLog("Alpha/Beta 点击超时")
        return false
    end
    if not alphaOK or not betaOK then
        warnLog("Alpha/Beta 点击调用失败")
        return false
    end
    lastPhysicalStep = os.clock()
    local label = direction > 0 and "Alpha/Beta 同步 +1" or "Alpha/Beta 同步 -1"
    setAction(label)
    log(label)
    return true
end

local function increaseOne(allowLowDurability)
    return clickOne(AlphaRight, BetaRight, 1, allowLowDurability)
end

local function decreaseOne(allowLowDurability)
    return clickOne(AlphaLeft, BetaLeft, -1, allowLowDurability)
end

-- ==================== Neutral confirmation ====================
local function measurePowerMotion()
    local first = getCurrentPower()
    if first == nil then return nil, nil, nil end
    task.wait(CONFIG.MOTION_CHECK_DELAY)
    local second = getCurrentPower()
    if second == nil then return nil, nil, nil end
    local delta = second - first
    local rate = delta / CONFIG.MOTION_CHECK_DELAY
    if math.abs(delta) <= CONFIG.STABLE_DELTA_MAX then
        return 0, delta, rate
    end
    return delta > 0 and 1 or -1, delta, rate
end

local function returnToZero(allowLowDurability)
    if currentGear == 0 then return true end
    log("正在把 Alpha/Beta 恢复到 0 挡")
    while currentGear > 0 do
        if not decreaseOne(allowLowDurability) then return false end
        currentGear = currentGear - 1
        UIState.commandGear = currentGear
        refreshStatus()
    end
    while currentGear < 0 do
        if not increaseOne(allowLowDurability) then return false end
        currentGear = currentGear + 1
        UIState.commandGear = currentGear
        refreshStatus()
    end
    return true
end

local function verifyAndCorrectNeutral(allowLowDurability)
    if not allControlsInRange() then
        warnLog("距离不足，无法确认真实 0 挡")
        return false
    end
    for attempt = 0, CONFIG.MAX_NEUTRAL_CORRECTIONS do
        local motion, delta, rate = measurePowerMotion()
        if motion == nil then
            warnLog("中位确认读取功率失败")
            return false
        end
        log(string.format("中位检测 | Δ功率=%+.0f kW | 速度=%+.0f kW/s", delta, rate))
        if motion == 0 then
            currentGear = 0
            lastKnownMovingGear = 0
            UIState.commandGear = 0
            UIState.detectedGear = 0
            UIState.targetGear = 0
            resetPowerHistory()
            setAction("已确认真实稳定 0 挡")
            log("已确认真实稳定状态 = 0挡")
            return true
        end
        if attempt >= CONFIG.MAX_NEUTRAL_CORRECTIONS then break end
        if motion > 0 then
            setAction("功率仍上升，向 - 方向找中位")
            if not decreaseOne(allowLowDurability) then return false end
        else
            setAction("功率仍下降，向 + 方向找中位")
            if not increaseOne(allowLowDurability) then return false end
        end
    end
    warnLog("中位校正达到上限，停止继续盲点")
    return false
end

-- ==================== Set gear ====================
local function setGear(targetGear, force)
    targetGear = math.clamp(math.round(targetGear), -2, 2)
    if currentGear == targetGear then return true end
    if not force and os.clock() - lastControl < CONFIG.CONTROL_COOLDOWN then return false end
    local safe = durabilityIsSafe()
    if not safe then return false end
    if currentGear ~= 0 and targetGear ~= 0 and currentGear * targetGear < 0 then
        if not returnToZero(false) then return false end
    end
    if targetGear == 0 then
        local ok = returnToZero(false)
        lastControl = os.clock()
        return ok
    end
    while currentGear < targetGear do
        if not increaseOne(false) then return false end
        currentGear = currentGear + 1
        UIState.commandGear = currentGear
        refreshStatus()
        if currentGear < targetGear then task.wait(CONFIG.MIN_STEP_INTERVAL) end
    end
    while currentGear > targetGear do
        if not decreaseOne(false) then return false end
        currentGear = currentGear - 1
        UIState.commandGear = currentGear
        refreshStatus()
        if currentGear > targetGear then task.wait(CONFIG.MIN_STEP_INTERVAL) end
    end
    lastControl = os.clock()
    log("当前脚本挡位 =", currentGear)
    return true
end

-- ==================== Target gear calculation ====================
local function calculateTarget(difference)
    local absolute = math.abs(difference)
    if absolute <= CONFIG.TOLERANCE then return 0 end
    if difference > 0 then
        if difference <= CONFIG.FINE_ZONE then return 1 end
        return 2
    end
    if difference < 0 then
        if absolute <= CONFIG.FINE_ZONE then return -1 end
        return -2
    end
    return 0
end

-- ==================== Controller ====================
local env = autoOrderSharedEnv
if env.AutoPowerOrderController and env.AutoPowerOrderController.stop then
    pcall(env.AutoPowerOrderController.stop)
end

local controller = { running = true }
env.AutoPowerOrderController = controller

function controller.stop()
    controller.running = false
    UIState.running = false
    UIState.targetGear = 0
    setAction("正在停止并尝试回 0 挡")
    pcall(function()
        returnToZero(true)
        verifyAndCorrectNeutral(true)
    end)
    UIState.commandGear = currentGear
    setAction("控制器已停止")
    log("控制器停止")
end

StopButton.MouseButton1Click:Connect(function()
    local active = env.AutoPowerOrderController
    if active and active.stop then
        task.spawn(function()
            pcall(active.stop)
            task.wait(0.6)
            if ConsoleGui and ConsoleGui.Parent then
                ConsoleGui:Destroy()
            end
            if env.NexusAutoPowerOrderConsole == ConsoleGui then
                env.NexusAutoPowerOrderConsole = nil
                env.NexusAutoPowerOrderUIState = nil
            end
        end)
    end
end)

-- ==================== Startup Log ====================
log("==========================================")
log("自动完成电力订单 · 挡位检测/耐久保护版")
log("二挡连续脉冲间隔 =", CONFIG.MIN_STEP_INTERVAL, "秒")
log("稳定 =", CONFIG.STABLE_WINDOW, "秒内变化 <=", CONFIG.STABLE_DELTA_MAX, "kW")
log("二挡检测 = 一挡速度 ×", CONFIG.GEAR2_RATE_RATIO)
log("耐久保护阈值 <=", CONFIG.DURABILITY_LIMIT)
log("反应堆正常水位 =", CONFIG.WATER_LEVEL_NORMAL, "%")
log("零功率保护：当前功率 <=", CONFIG.ZERO_POWER_THRESHOLD, "kW -> 强制0挡")
log("距离 = MaxActivationDistance +", CONFIG.DISTANCE_BONUS, "studs")
log("==========================================")

-- ==================== Main Loop ====================
local lastOrder = nil
local lastDistanceWarning = -math.huge

while controller.running do
    local order = getOrder()
    local current = getCurrentPower()
    local waterLevel = getWaterLevel()
    UIState.order = order
    UIState.current = current
    UIState.waterLevel = waterLevel
    local inRange = updateDistanceUI()
    local durabilitySafe, aDur, bDur = updateDurabilityUI()
    if order == nil or current == nil then
        setAction("功率读取失败，等待重试")
        warnLog("无法读取 PowerOrder / ExcessPower | PowerOrder=", tostring(PowerOrder.Text), "| ExcessPower=", tostring(CurrentPower.Text))
        refreshStatus()
        task.wait(0.40)
    else
        local stable, stableRange, rate, detectedGear = updateTelemetry(current)
        local difference = order - current
        UIState.order = order
        UIState.current = current
        UIState.difference = difference
        UIState.waterLevel = waterLevel
        UIState.commandGear = currentGear
        UIState.detectedGear = detectedGear
        UIState.powerRate = rate
        UIState.stable = stable
        UIState.stableRange = stableRange
        UIState.learnedGear1Rate = learnedGear1Rate

        if CONFIG.DEBUG then
            print(string.format("[调试] 距离=%s 耐久安全=%s | A耐久=%s B耐久=%s | A距离=%.1f B距离=%.1f",
                tostring(inRange), tostring(durabilitySafe), fmt0(aDur), fmt0(bDur),
                UIState.alphaDistance or -1, UIState.betaDistance or -1))
        end

        if current <= CONFIG.ZERO_POWER_THRESHOLD then
            UIState.targetGear = 0
            UIState.protection = "零功率保护"
            setAction(string.format("当前功率=%.0f kW，强制涡轮回0 | 水位=%s%%", current, waterLevel ~= nil and fmt1(waterLevel) or "--"))
            if currentGear == 0 and lastKnownMovingGear ~= 0 then
                warnLog("零功率时内部挡位=0，但归零前检测挡位=", lastKnownMovingGear, "；使用最后可信挡位执行回0")
                currentGear = lastKnownMovingGear
                UIState.commandGear = currentGear
            end
            if inRange and allControlsInRange() then
                local zeroOK = returnToZero(true)
                if zeroOK then
                    currentGear = 0
                    lastKnownMovingGear = 0
                    UIState.commandGear = 0
                    UIState.detectedGear = 0
                    setAction(string.format("零功率保护：涡轮已调回0 | 水位=%s%%", waterLevel ~= nil and fmt1(waterLevel) or "--"))
                else
                    warnLog("零功率保护：回0操作未完成")
                end
            else
                UIState.protection = "零功率 + 距离不足"
                setAction(string.format("功率=0，但距离不足无法点击回0 | 水位=%s%%", waterLevel ~= nil and fmt1(waterLevel) or "--"))
            end
        elseif not durabilitySafe then
            UIState.targetGear = 0
            UIState.protection = "耐久保护"
            setAction(string.format("耐久保护：Alpha=%s Beta=%s，立即回0", fmt0(aDur), fmt0(bDur)))
            if not durabilityEmergency then
                durabilityEmergency = true
                warnLog("耐久 <= ", CONFIG.DURABILITY_LIMIT, "，立即停止订单调节并回 0 | Alpha=", aDur, "Beta=", bDur)
            end
            if inRange and os.clock() - lastDurabilityNeutralAttempt >= CONFIG.DURABILITY_RECHECK_NEUTRAL then
                lastDurabilityNeutralAttempt = os.clock()
                pcall(function()
                    returnToZero(true)
                    verifyAndCorrectNeutral(true)
                end)
            elseif not inRange then
                UIState.protection = "耐久低 + 距离不足"
                setAction("耐久 <=25，但距离不足，无法执行回0点击")
            end
        elseif not inRange or not allControlsInRange() then
            if durabilityEmergency then
                durabilityEmergency = false
                log("耐久已恢复 > 25")
            end
            UIState.targetGear = 0
            UIState.protection = "等待靠近"
            setAction("距离不足，暂停自动调挡")
            if os.clock() - lastDistanceWarning >= 1.0 then
                lastDistanceWarning = os.clock()
                warnLog("离涡轮太远 | 允许距离已使用 MaxActivationDistance +", CONFIG.DISTANCE_BONUS)
            end
        else
            if durabilityEmergency then
                durabilityEmergency = false
                log("两台涡轮耐久均已恢复到 > 25，恢复自动订单")
            end
            UIState.protection = "正常"
            if lastOrder == nil or order ~= lastOrder then
                log("================================")
                log("新电力订单:", order, "kW")
                log("当前总发电:", current, "kW")
                log("================================")
                setAction("检测到新订单")
                if stable and os.clock() - lastPhysicalStep >= CONFIG.GEAR_DETECT_GRACE_AFTER_CLICK then
                    currentGear = 0
                    UIState.commandGear = 0
                    UIState.detectedGear = 0
                    log("新订单开始前已确认功率稳定 = 0挡")
                else
                    verifyAndCorrectNeutral(false)
                end
                lastOrder = order
            end
            if math.abs(difference) <= CONFIG.TOLERANCE then
                UIState.targetGear = 0
                if currentGear ~= 0 or not stable then
                    setAction("进入 ±1000，立即回 0")
                    log("达到订单要求 ±1000，恢复稳定 0挡")
                    returnToZero(false)
                    verifyAndCorrectNeutral(false)
                else
                    setAction("订单已满足，稳定保持 0挡")
                end
            else
                local target = calculateTarget(difference)
                UIState.targetGear = target
                if target ~= currentGear then
                    setAction(string.format("调整挡位 %d -> %d", currentGear, target))
                    setGear(target, false)
                else
                    if detectedGear ~= 0 and detectedGear ~= currentGear then
                        setAction(string.format("观察真实挡位：脚本=%d 检测=%d", currentGear, detectedGear))
                    end
                end
            end
        end
        UIState.commandGear = currentGear
        refreshStatus()
        if CONFIG.DEBUG then
            print("[自动完成电力订单]", string.format("订单=%.0f 当前=%.0f 差值=%+.0f | 水位=%s%% | 脚本挡=%d 检测挡=%d | 速度=%+.0f kW/s | A耐久=%s B耐久=%s",
                order, current, difference, waterLevel ~= nil and fmt1(waterLevel) or "--", currentGear, detectedGear, rate, fmt0(aDur), fmt0(bDur)))
        end
        task.wait(CONFIG.SAMPLE_DELAY)
    end
end

pcall(function()
    returnToZero(true)
end)

UIState.running = false
UIState.commandGear = currentGear
UIState.targetGear = 0
setAction("自动完成电力订单已结束")
log("自动完成电力订单结束")
if env.NexusAutoPowerOrderConsole == ConsoleGui then
    env.NexusAutoPowerOrderConsole = ConsoleGui
    env.NexusAutoPowerOrderUIState = UIState
end
end


-- ===================== 破坏设备 / Destroy Devices =====================
-- 这里不使用动态加载，不使用额外 UI 框架；直接复用本脚本自己的状态、组件和 FeatureList。
local BREAK_DEVICE_ATTACK_INTERVAL_MIN = 0.01
local BREAK_DEVICE_ATTACK_INTERVAL_MAX = 2.00
local BREAK_DEVICE_MAX_DISTANCE_MIN = 10
local BREAK_DEVICE_MAX_DISTANCE_MAX = 1000

local function GetBreakDeviceBarrel()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    -- 沿用原游戏脚本的武器结构：Tool -> Barrel / 1Barrel。
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") then
            local barrel = obj:FindFirstChild("Barrel") or obj:FindFirstChild("1Barrel")
            if barrel and barrel:IsA("BasePart") then
                return barrel
            end
        end
    end

    return nil
end

local function GetNearestBreakDevice()
    local facility = workspace:FindFirstChild("FacilitySystems")
    local character = LocalPlayer.Character
    if not facility or not character then
        return nil, nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
    if not root then
        return nil, nil
    end

    local nearestDevice = nil
    local nearestHitbox = nil
    local nearestDistance = math.huge
    local seen = {}

    for _, obj in ipairs(facility:GetDescendants()) do
        if obj.Name == "Hitbox" and obj:IsA("BasePart") then
            local device = obj.Parent
            if device and not seen[device] then
                seen[device] = true

                if device:GetAttribute("Hacked") ~= true then
                    local distance = (root.Position - obj.Position).Magnitude
                    local inRange = BreakDeviceUnlimitedMode
                        or distance <= BreakDeviceMaxDistance

                    if inRange and distance < nearestDistance then
                        nearestDistance = distance
                        nearestDevice = device
                        nearestHitbox = obj
                    end
                end
            end
        end
    end

    return nearestDevice, nearestHitbox
end

local function FireBreakDevice(hitbox, event)
    if not hitbox or not hitbox.Parent then
        return false
    end
    if not event or not event.Parent or not event:IsA("RemoteEvent") then
        return false
    end

    local barrel = GetBreakDeviceBarrel()
    if not barrel or not barrel.Parent then
        return false
    end

    local origin = barrel.Position
    local hitPosition = hitbox.Position
    local delta = hitPosition - origin
    if delta.Magnitude <= 0.001 then
        return false
    end

    local normal = delta.Unit

    local ok = pcall(function()
        -- 原破坏设备功能使用的 39-byte 数据包布局。
        local buf = buffer.create(39)
        buffer.writeu8(buf, 0, 6)
        buffer.writeu8(buf, 1, 14)
        buffer.writef32(buf, 2, origin.X)
        buffer.writef32(buf, 6, origin.Y)
        buffer.writef32(buf, 10, origin.Z)
        buffer.writef32(buf, 14, hitPosition.X)
        buffer.writef32(buf, 18, hitPosition.Y)
        buffer.writef32(buf, 22, hitPosition.Z)
        buffer.writeu8(buf, 26, 1)
        buffer.writef32(buf, 27, normal.X)
        buffer.writef32(buf, 31, normal.Y)
        buffer.writef32(buf, 35, normal.Z)

        event:FireServer(buf, {2}, {barrel}, {hitbox})
    end)

    return ok
end

local function RunBreakDevice()
    if BreakDeviceRunning then
        return
    end

    BreakDeviceRunning = true

    while BreakDeviceEnabled do
        local event = ReplicatedStorage:FindFirstChild("NetRay_RELIABLE")
        local device, hitbox

        if event and event:IsA("RemoteEvent") then
            device, hitbox = GetNearestBreakDevice()
        end

        if device and hitbox and FireBreakDevice(hitbox, event) then
            -- 每次循环都重新读取变量，所以滑块可以在运行中实时生效。
            local interval = math.clamp(
                tonumber(BreakDeviceAttackInterval) or 0.80,
                BREAK_DEVICE_ATTACK_INTERVAL_MIN,
                BREAK_DEVICE_ATTACK_INTERVAL_MAX
            )
            task.wait(interval)
        else
            -- 游戏刚进场、换武器、角色重生、RemoteEvent 延迟出现时继续等待，而不是退出功能。
            task.wait(0.20)
        end
    end

    BreakDeviceRunning = false
end

local function SetBreakDeviceEnabled(enabled)
    BreakDeviceEnabled = enabled == true

    if BreakDeviceEnabled then
        if not BreakDeviceRunning then
            task.spawn(function()
                local ok, err = pcall(RunBreakDevice)
                if not ok then
                    BreakDeviceRunning = false
                    BreakDeviceEnabled = false
                    warn("[SyntaxNext][破坏设备] " .. tostring(err))
                end
            end)
        end
    end
end



-- ================================================================
-- SECTION 11: EXTERNAL UI COMPONENT BINDINGS
-- All migrated controls live inside this nested scope, keeping the
-- stable script top-level local-variable budget unchanged.
-- ================================================================
(function()
    local Window = _G.SyntaxNextWindow
    local NexusFeatureList = _G.NexusFeatureList
    local FeatureDisplayNames = {
        ["RageBot"] = "RageBot",
        ["命中框"] = "Hitbox",
        ["镜头瞄准"] = "Camera Aim",
        ["静默瞄准"] = "Silent Aim",
        ["静默FOV"] = "Silent FOV",
        ["无限弹药"] = "Infinite Ammo",
        ["彩色弹道"] = "RGB Tracers",
        ["命中标记"] = "Hitmarker",
        ["Combat Zoom"] = "Combat Zoom",
        ["镜头FOV"] = "Camera FOV",
        ["移动速度"] = "WalkSpeed",
        ["跳跃高度"] = "JumpPower",
        ["FOV"] = "Field of View",
        ["穿墙"] = "Noclip",
        ["无限跳跃"] = "Infinite Jump",
        ["无限体力"] = "Infinite Stamina",
        ["全亮"] = "Fullbright",
        ["幽灵模式"] = "Ghost Mode",
        ["载具飞行"] = "Vehicle Fly",
        ["SpinBot"] = "SpinBot",
        ["即时交互"] = "Instant Interaction",
        ["人物透视"] = "Player ESP",
        ["载具透视"] = "Vehicle ESP",
        ["通风口透视"] = "Vent ESP",
        ["可破坏物透视"] = "Breakable ESP",
        ["水坑透视"] = "Puddle ESP",
        ["污渍透视"] = "Smudge ESP",
        ["聊天日志"] = "Chat Logs",
        ["自动拖地"] = "Auto Mop",
        ["自动擦玻璃"] = "Auto Clean Glass",
        ["自动修理"] = "Auto Repair",
        ["破坏设备"] = "Destroy Devices",
        ["自动电力订单"] = "Auto Power Order",
    }

    local function getFeatureDisplayName(name)
        return FeatureDisplayNames[name] or tostring(name)
    end

    local function syncFeature(name, enabled, mode)
        pcall(function()
            if _G.NexusFeatureList then
                _G.NexusFeatureList:Set(getFeatureDisplayName(name), enabled == true, mode)
            end
        end)
    end

    local function syncFeatureMode(name, mode)
        pcall(function()
            if _G.NexusFeatureList then
                _G.NexusFeatureList:SetMode(getFeatureDisplayName(name), mode)
            end
        end)
    end

    local function setToggleByCurrent(current, desired, flip)
        desired = desired == true
        if current ~= desired then
            flip()
        end
    end

    local CombatTab = Window:Tab({Title = "战斗", Icon = "crosshair"})
    local PlayerTab = Window:Tab({Title = "玩家", Icon = "user"})
    local VisualTab = Window:Tab({Title = "视觉", Icon = "eye"})
    local MiscTab = Window:Tab({Title = "杂项", Icon = "settings"})
    local ConfigTab = Window:Tab({Title = "配置", Icon = "save"})
    local HideTab = Window:Tab({Title = "隐藏页面", Icon = "eye"})

    _G.NexusCombatTab = CombatTab
    _G.NexusPlayerTab = PlayerTab
    _G.NexusVisualTab = VisualTab
    _G.NexusMiscTab = MiscTab
    _G.NexusConfigTab = ConfigTab
    _G.NexusHideTab = HideTab

    -- ---------------- Combat ----------------
    CombatTab:Section({Title = "战斗功能", TextXAlignment = "Left", TextSize = 17})
    -- 战斗：命中框扩展
    CombatTab:Toggle({Title = "命中框扩展", Default = HitboxEnabled, Keybind = {}, Callback = function(v)
        v = v == true
        if v ~= HitboxEnabled then
            ToggleHitboxState()
        end
        if HitboxEnabled then
            pcall(ApplyHitbox)
        else
            pcall(ResetHitbox)
        end
        syncFeature("命中框", HitboxEnabled, "Both")
    end})

    CombatTab:Slider({
        Title = "命中框大小",
        Value = {Min = 0, Max = 30, Default = HitboxSize},
        Increment = 1,
        Callback = function(v)
            HitboxSize = math.clamp(math.floor(tonumber(v) or HitboxSize), 0, 30)
            if HitboxEnabled then pcall(ApplyHitbox) end
        end,
    })

    CombatTab:Dropdown({
        Title = "命中框部位",
        Values = {"Head", "Body", "Both"},
        Value = HitboxPartSelection,
        Callback = function(v)
            HitboxPartSelection = tostring(v)
            if HitboxEnabled then
                pcall(ResetHitbox)
                pcall(ApplyHitbox)
            end
        end,
    })

    -- 相机自瞄
    CombatTab:Toggle({Title = "镜头瞄准", Default = AimbotEnabled, Keybind = {}, Callback = function(v)
        SetAimbotEnabled(v == true)
        syncFeature("镜头瞄准", AimbotEnabled, "Camera")
    end})

    CombatTab:Toggle({Title = "静默瞄准", Default = NaramoSilentAim.Enabled, Keybind = {}, Callback = function(v)
        NaramoSilentAim:SetEnabled(v == true)
        syncFeature("静默瞄准", NaramoSilentAim.Enabled, "Silent")
    end})

    CombatTab:Toggle({Title = "瞄准队伍检测", Default = AimbotTeamCheck, Callback = function(v)
        AimbotTeamCheck = v == true
        NaramoSilentAim.TeamCheck = AimbotTeamCheck
    end})

    CombatTab:Toggle({Title = "瞄准墙体检测", Default = AimbotWallCheck, Callback = function(v)
        AimbotWallCheck = v == true
        NaramoSilentAim.WallCheck = AimbotWallCheck
    end})

    CombatTab:Slider({
        Title = "瞄准平滑度",
        Value = {Min = 5, Max = 95, Default = math.floor(AimbotSmoothness * 100 + 0.5)},
        Increment = 1,
        Callback = function(v)
            AimbotSmoothness = math.clamp((tonumber(v) or 15) / 100, 0.05, 0.95)
        end,
    })

    CombatTab:Slider({
        Title = "瞄准FOV",
        Value = {Min = 50, Max = 500, Default = AimbotFOV},
        Increment = 5,
        Callback = function(v)
            AimbotFOV = math.clamp(tonumber(v) or AimbotFOV, 50, 500)
        end,
    })

    CombatTab:Slider({
        Title = "静默瞄准FOV",
        Value = {Min = 50, Max = 500, Default = NaramoSilentAim.FOV},
        Increment = 5,
        Callback = function(v)
            pcall(function() NaramoSilentAim:SetFOV(tonumber(v) or NaramoSilentAim.FOV) end)
        end,
    })

    CombatTab:Toggle({Title = "显示静默瞄准FOV", Default = ShowSilentAimFOV, Keybind = {}, Callback = function(v)
        ShowSilentAimFOV = v == true
        pcall(UpdateAimFovCircles)
        syncFeature("静默FOV", ShowSilentAimFOV, "Circle")
    end})

    CombatTab:Dropdown({
        Title = "瞄准部位",
        Values = {"Head", "HumanoidRootPart"},
        Value = AimbotTargetPart,
        Callback = function(v)
            AimbotTargetPart = tostring(v)
            NaramoSilentAim.TargetPart = AimbotTargetPart
        end,
    })

    -- 武器 / 射击视觉
    CombatTab:Toggle({Title = "无限弹药", Default = InfAmmoEnabled, Keybind = {}, Callback = function(v)
        InfAmmoEnabled = v == true
        if InfAmmoEnabled then
            -- 开启瞬间强制处理一次现有 Tool；之后交给事件 + 低频维护。
            pcall(scanAllTools, true)
            pcall(fixGCTables)
        end
        syncFeature("无限弹药", InfAmmoEnabled, "Active")
    end})

    CombatTab:Toggle({Title = "彩色弹道轨迹", Default = TracerEnabled, Keybind = {}, Callback = function(v)
        TracerEnabled = v == true
        syncFeature("彩色弹道", TracerEnabled, "RGB")
    end})

    CombatTab:Dropdown({
        Title = "命中标记",
        Values = {"关闭", "普通", "RGB"},
        Value = HitmarkerMode == 1 and "普通" or (HitmarkerMode == 2 and "RGB" or "关闭"),
        Callback = function(v)
            HitmarkerMode = (v == "普通" and 1) or (v == "RGB" and 2) or 0
            syncFeature("命中标记", HitmarkerMode > 0, HitmarkerMode == 2 and "RGB" or "Normal")
        end,
    })

    CombatTab:Toggle({Title = "战斗缩放状态", Default = ZoomEnabled, Keybind = {}, Callback = function(v)
        ZoomEnabled = v == true
        syncFeature("Combat Zoom", ZoomEnabled, "Active")
    end})

    CombatTab:Toggle({Title = "显示镜头FOV圈", Default = ShowAimbotFOV, Keybind = {}, Callback = function(v)
        ShowAimbotFOV = v == true
        pcall(UpdateAimFovCircles)
        syncFeature("镜头FOV", ShowAimbotFOV, "Circle")
    end})

    -- ---------------- Player ----------------
    PlayerTab:Section({Title = "玩家功能", TextXAlignment = "Left", TextSize = 17})

    PlayerTab:Toggle({Title = "移动速度开关", Default = SpeedEnabled, Keybind = {}, Callback = function(v)
        SpeedEnabled = v == true
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not GhostEnabled then
            pcall(function() hum.WalkSpeed = SpeedEnabled and TargetWalkSpeed or 16 end)
        end
        syncFeature("移动速度", SpeedEnabled, "Speed")
    end})
    PlayerTab:Slider({
        Title = "移动速度",
        Value = {Min = 16, Max = 150, Default = TargetWalkSpeed},
        Increment = 1,
        Callback = function(v)
            TargetWalkSpeed = math.clamp(math.floor(tonumber(v) or TargetWalkSpeed), 16, 150)
            if SpeedEnabled then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and not GhostEnabled then pcall(function() hum.WalkSpeed = TargetWalkSpeed end) end
            end
        end,
    })

    PlayerTab:Toggle({Title = "跳跃高度开关", Default = JumpEnabled, Keybind = {}, Callback = function(v)
        JumpEnabled = v == true
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not GhostEnabled then
            pcall(function() hum.JumpPower = JumpEnabled and TargetJumpPower or 50 end)
        end
        syncFeature("跳跃高度", JumpEnabled, "Jump")
    end})
    PlayerTab:Slider({
        Title = "跳跃高度",
        Value = {Min = 50, Max = 350, Default = TargetJumpPower},
        Increment = 1,
        Callback = function(v)
            TargetJumpPower = math.clamp(math.floor(tonumber(v) or TargetJumpPower), 50, 350)
            if JumpEnabled then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and not GhostEnabled then pcall(function() hum.JumpPower = TargetJumpPower end) end
            end
        end,
    })

    PlayerTab:Toggle({Title = "视野范围开关", Default = FOVEnabled, Keybind = {}, Callback = function(v)
        FOVEnabled = v == true
        Camera = workspace.CurrentCamera or Camera
        if Camera then pcall(function() Camera.FieldOfView = FOVEnabled and TargetFOV or 70 end) end
        syncFeature("FOV", FOVEnabled, "Camera")
    end})
    PlayerTab:Slider({
        Title = "视野范围",
        Value = {Min = 30, Max = 120, Default = TargetFOV},
        Increment = 1,
        Callback = function(v)
            TargetFOV = math.clamp(math.floor(tonumber(v) or TargetFOV), 30, 120)
            if FOVEnabled then
                Camera = workspace.CurrentCamera or Camera
                if Camera then pcall(function() Camera.FieldOfView = TargetFOV end) end
            end
        end,
    })

    local function setNoclipDesired(v)
        setToggleByCurrent(NoclipEnabled, v, ToggleNoclipState)
        syncFeature("穿墙", NoclipEnabled, "Noclip")
    end
    local function setInfJumpDesired(v)
        setToggleByCurrent(InfJumpEnabled, v, ToggleInfJumpState)
        syncFeature("无限跳跃", InfJumpEnabled, "Jump")
    end
    local function setInfStaminaDesired(v)
        setToggleByCurrent(InfStaminaEnabled, v, ToggleInfStaminaState)
        syncFeature("无限体力", InfStaminaEnabled, "Stamina")
    end
    local function setFullbrightDesired(v)
        setToggleByCurrent(FullbrightEnabled, v, ToggleFullbrightState)
        syncFeature("全亮", FullbrightEnabled, "Bright")
    end
    local function setGhostDesired(v)
        setToggleByCurrent(GhostEnabled, v, ToggleGhostMode)
        syncFeature("幽灵模式", GhostEnabled, "Ghost")
    end

    PlayerTab:Toggle({Title = "穿墙模式", Default = NoclipEnabled, Keybind = {}, Callback = setNoclipDesired})
    PlayerTab:Toggle({Title = "无限跳跃", Default = InfJumpEnabled, Keybind = {}, Callback = setInfJumpDesired})
    PlayerTab:Toggle({Title = "无限体力", Default = InfStaminaEnabled, Keybind = {}, Callback = setInfStaminaDesired})
    PlayerTab:Toggle({Title = "全亮模式", Default = FullbrightEnabled, Keybind = {}, Callback = setFullbrightDesired})
    PlayerTab:Toggle({Title = "幽灵模式", Default = GhostEnabled, Keybind = {}, Callback = setGhostDesired})

    PlayerTab:Toggle({Title = "载具飞行", Default = VehicleFlyEnabled, Keybind = {}, Callback = function(v)
        SetVehicleFlyEnabled(v == true)
        syncFeature("载具飞行", VehicleFlyEnabled, "Fly")
    end})
    PlayerTab:Toggle({Title = "旋转模式 SpinBot", Default = SpinBotEnabled, Keybind = {}, Callback = function(v)
        SetSpinBotEnabled(v == true)
        syncFeature("SpinBot", SpinBotEnabled, "Rotate")
    end})
    PlayerTab:Slider({
        Title = "SpinBot 速度",
        Value = {Min = 10, Max = 360, Default = SpinBotSpeed},
        Increment = 5,
        Callback = function(v)
            SpinBotSpeed = math.clamp(math.floor(tonumber(v) or SpinBotSpeed), 10, 360)
        end,
    })
    PlayerTab:Toggle({Title = "即时交互", Default = InstantProximityEnabled, Keybind = {}, Callback = function(v)
        SetInstantProximityEnabled(v == true)
        syncFeature("即时交互", InstantProximityEnabled, "Prompt")
    end})

    -- ---------------- Visual ----------------
    VisualTab:Section({Title = "视觉功能", TextXAlignment = "Left", TextSize = 17})

    local function setChamsDesired(v)
        setToggleByCurrent(ChamsEnabled, v, ToggleChamsState)
        syncFeature("人物透视", ChamsEnabled, "ESP")
    end
    local function setVehicleESPDesired(v)
        setToggleByCurrent(VehicleEspEnabled, v, ToggleVehicleEspState)
        syncFeature("载具透视", VehicleEspEnabled, "ESP")
    end
    local function setVentESPDesired(v)
        setToggleByCurrent(VentEspEnabled, v, ToggleVentEspState)
        syncFeature("通风口透视", VentEspEnabled, "ESP")
    end
    local function setBreakableESPDesired(v)
        setToggleByCurrent(BreakableEspEnabled, v, ToggleBreakableEspState)
        syncFeature("可破坏物透视", BreakableEspEnabled, "ESP")
    end
    local function setPuddleESPDesired(v)
        setToggleByCurrent(PuddleEspEnabled, v, TogglePuddleEspState)
        syncFeature("水坑透视", PuddleEspEnabled, "ESP")
    end
    local function setSmudgeESPDesired(v)
        setToggleByCurrent(SmudgeEspEnabled, v, ToggleSmudgeEspState)
        syncFeature("污渍透视", SmudgeEspEnabled, "ESP")
    end

    VisualTab:Toggle({Title = "人物透视", Default = ChamsEnabled, Keybind = {}, Callback = setChamsDesired})
    VisualTab:Toggle({Title = "载具透视", Default = VehicleEspEnabled, Keybind = {}, Callback = setVehicleESPDesired})
    VisualTab:Toggle({Title = "通风口透视", Default = VentEspEnabled, Keybind = {}, Callback = setVentESPDesired})
    VisualTab:Toggle({Title = "可破坏物透视", Default = BreakableEspEnabled, Keybind = {}, Callback = setBreakableESPDesired})
    VisualTab:Toggle({Title = "水坑透视", Default = PuddleEspEnabled, Keybind = {}, Callback = setPuddleESPDesired})
    VisualTab:Toggle({Title = "污渍透视", Default = SmudgeEspEnabled, Keybind = {}, Callback = setSmudgeESPDesired})
    VisualTab:Toggle({Title = "显示瞄准FOV圈", Default = ShowAimbotFOV, Keybind = {}, Callback = function(v)
        ShowAimbotFOV = v == true
        pcall(UpdateAimFovCircles)
        syncFeature("镜头FOV", ShowAimbotFOV, "Circle")
    end})

    -- ---------------- Misc ----------------
    MiscTab:Section({Title = "杂项与自动化", TextXAlignment = "Left", TextSize = 17})
    MiscTab:Button({Title = "重新加入服务器", Callback = function()
        pcall(RejoinCurrentServer)
    end})
    MiscTab:Toggle({Title = "聊天日志", Default = ChatLogsEnabled, Keybind = {}, Callback = function(v)
        SetChatLogsEnabled(v == true)
        syncFeature("聊天日志", ChatLogsEnabled, "Log")
    end})
    MiscTab:Button({Title = "紧急关闭新增功能", Callback = function()
        PanicDisableAddedFeatures()
        syncFeature("镜头瞄准", false)
        syncFeature("静默瞄准", false)
        syncFeature("载具飞行", false)
        syncFeature("SpinBot", false)
        syncFeature("即时交互", false)
        syncFeature("聊天日志", false)
        syncFeature("破坏设备", false, "Packet")
        Window:Notify({Title = "SyntaxNext", Content = "已执行紧急关闭。", Duration = 2})
    end})
    MiscTab:Button({Title = "自动兑换码", Callback = function()
        pcall(FireGamePromoCodes)
        Window:Notify({Title = "SyntaxNext", Content = "已执行兑换码流程。", Duration = 1.8})
    end})

    MiscTab:Toggle({Title = "自动拖地", Default = AutoMopEnabled, Keybind = {}, Callback = function(v)
        AutoMopEnabled = v == true
        if AutoMopEnabled then task.spawn(function() pcall(RunAutoMop) end) end
        syncFeature("自动拖地", AutoMopEnabled, "Auto")
    end})
    MiscTab:Toggle({Title = "自动擦玻璃", Default = AutoCleanEnabled, Keybind = {}, Callback = function(v)
        AutoCleanEnabled = v == true
        if AutoCleanEnabled then task.spawn(function() pcall(RunAutoClean) end) end
        syncFeature("自动擦玻璃", AutoCleanEnabled, "Auto")
    end})
    MiscTab:Toggle({Title = "自动修理", Default = AutoRepairEnabled, Keybind = {}, Callback = function(v)
        AutoRepairEnabled = v == true
        if AutoRepairEnabled then task.spawn(function() pcall(RunAutoRepair) end) end
        syncFeature("自动修理", AutoRepairEnabled, "Auto")
    end})

    -- ---------------- 破坏设备 ----------------
    -- 与脚本已有功能完全相同的原生组件：Section + Toggle + Slider + Keybind。
    MiscTab:Section({Title = "设备破坏", TextXAlignment = "Left", TextSize = 17})

    MiscTab:Toggle({
        Title = "破坏设备",
        Default = BreakDeviceEnabled,
        Keybind = {},
        Callback = function(v)
            SetBreakDeviceEnabled(v == true)
            syncFeature("破坏设备", BreakDeviceEnabled, "Packet")
        end,
    })

    MiscTab:Slider({
        Title = "破坏设备攻击频率（×0.01秒）",
        Value = {
            Min = 1,
            Max = 200,
            Default = math.clamp(math.floor(BreakDeviceAttackInterval * 100 + 0.5), 1, 200),
        },
        Increment = 1,
        Callback = function(v)
            local step = math.clamp(math.floor((tonumber(v) or 80) + 0.5), 1, 200)
            BreakDeviceAttackInterval = step / 100
        end,
    })

    MiscTab:Slider({
        Title = "破坏设备攻击距离（Stud）",
        Value = {
            Min = BREAK_DEVICE_MAX_DISTANCE_MIN,
            Max = BREAK_DEVICE_MAX_DISTANCE_MAX,
            Default = math.clamp(math.floor(BreakDeviceMaxDistance + 0.5), BREAK_DEVICE_MAX_DISTANCE_MIN, BREAK_DEVICE_MAX_DISTANCE_MAX),
        },
        Increment = 5,
        Callback = function(v)
            BreakDeviceMaxDistance = math.clamp(
                math.floor((tonumber(v) or 100) + 0.5),
                BREAK_DEVICE_MAX_DISTANCE_MIN,
                BREAK_DEVICE_MAX_DISTANCE_MAX
            )
        end,
    })

    MiscTab:Toggle({
        Title = "破坏设备无限制模式",
        Default = BreakDeviceUnlimitedMode,
        Keybind = {},
        Callback = function(v)
            BreakDeviceUnlimitedMode = v == true
            syncFeature("破坏设备", BreakDeviceEnabled, "Packet")
        end,
    })

    MiscTab:Section({Title = "自动完成电力订单", TextXAlignment = "Left", TextSize = 17})

    MiscTab:Button({Title = "启动自动完成订单", Callback = function()
        syncFeature("自动电力订单", true, "Auto")
        task.spawn(function()
            local old = env.NexusAutoPowerOrderConsole
            if old and env.NexusAutoPowerOrderShow then
                pcall(env.NexusAutoPowerOrderShow)
            end
            local ok, err = pcall(StartAutoPowerOrder)
            if not ok then
                syncFeature("自动电力订单", false, "Auto")
                Window:Notify({Title = "自动完成电力订单", Content = tostring(err), Duration = 3})
                return
            end
            syncFeature("自动电力订单", false, "Auto")
        end)
    end})

    MiscTab:Button({Title = "停止自动完成订单并回中位", Callback = function()
        local active = env.AutoPowerOrderController
        syncFeature("自动电力订单", false, "Auto")
        if active and active.stop then
            task.spawn(function()
                pcall(active.stop)
                task.wait(0.6)
                local console = env.NexusAutoPowerOrderConsole
                if console and console.Parent then
                    pcall(function() console:Destroy() end)
                end
                if env.NexusAutoPowerOrderConsole == console then
                    env.NexusAutoPowerOrderConsole = nil
                    env.NexusAutoPowerOrderUIState = nil
                end
            end)
        end
    end})

    MiscTab:Button({Title = "显示自动完成订单状态", Callback = function()
        local show = env.NexusAutoPowerOrderShow
        if show then
            pcall(show)
            Window:Notify({Title = "自动完成电力订单", Content = "状态控制台已显示。", Duration = 1.8})
        else
            Window:Notify({Title = "自动完成电力订单", Content = "状态控制台尚未创建，请先点击启动。", Duration = 2.2})
        end
    end})


    -- ---------------- Config ----------------
    ConfigTab:Section({Title = "配置管理", TextXAlignment = "Left", TextSize = 17})
    ConfigTab:Paragraph({Title = "配置文件", Desc = "Been", Height = 60})

    local CONFIG_FILE = "SyntaxNext_NexusUI_Config.json"
    local function safeFileAvailable(name)
        return type(_G[name]) == "function" or type(getgenv) == "function" and type(getgenv()[name]) == "function"
    end
    local function envFunc(name)
        if type(_G[name]) == "function" then return _G[name] end
        if type(getgenv) == "function" then
            local g = getgenv()
            if type(g[name]) == "function" then return g[name] end
        end
        return nil
    end

    local function makeConfig()
        return {
            HitboxEnabled = HitboxEnabled,
            HitboxSize = HitboxSize,
            HitboxPartSelection = HitboxPartSelection,
            InfAmmoEnabled = InfAmmoEnabled,
            AimbotEnabled = AimbotEnabled,
            AimbotTeamCheck = AimbotTeamCheck,
            AimbotWallCheck = AimbotWallCheck,
            AimbotSmoothness = AimbotSmoothness,
            AimbotTargetPart = AimbotTargetPart,
            AimbotFOV = AimbotFOV,
            SilentAimEnabled = NaramoSilentAim.Enabled,
            SilentAimFOV = NaramoSilentAim.FOV,
            ShowSilentAimFOV = ShowSilentAimFOV,
            TracerEnabled = TracerEnabled,
            HitmarkerMode = HitmarkerMode,
            ZoomEnabled = ZoomEnabled,
            ShowAimbotFOV = ShowAimbotFOV,
            SpeedEnabled = SpeedEnabled,
            TargetWalkSpeed = TargetWalkSpeed,
            JumpEnabled = JumpEnabled,
            TargetJumpPower = TargetJumpPower,
            FOVEnabled = FOVEnabled,
            TargetFOV = TargetFOV,
            NoclipEnabled = NoclipEnabled,
            InfJumpEnabled = InfJumpEnabled,
            InfStaminaEnabled = InfStaminaEnabled,
            FullbrightEnabled = FullbrightEnabled,
            GhostEnabled = GhostEnabled,
            VehicleFlyEnabled = VehicleFlyEnabled,
            SpinBotEnabled = SpinBotEnabled,
            SpinBotSpeed = SpinBotSpeed,
            InstantProximityEnabled = InstantProximityEnabled,
            ChamsEnabled = ChamsEnabled,
            VehicleEspEnabled = VehicleEspEnabled,
            VentEspEnabled = VentEspEnabled,
            BreakableEspEnabled = BreakableEspEnabled,
            PuddleEspEnabled = PuddleEspEnabled,
            SmudgeEspEnabled = SmudgeEspEnabled,
            ChatLogsEnabled = ChatLogsEnabled,
            BreakDeviceEnabled = BreakDeviceEnabled,
            BreakDeviceAttackInterval = BreakDeviceAttackInterval,
            BreakDeviceMaxDistance = BreakDeviceMaxDistance,
            BreakDeviceUnlimitedMode = BreakDeviceUnlimitedMode,
        }
    end

    ConfigTab:Button({Title = "保存配置", Callback = function()
        local writefileFn = envFunc("writefile")
        if not writefileFn then Window:Notify({Title="配置", Content="当前环境没有 writefile", Duration=2.4}); return end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(makeConfig()) end)
        if ok then
            local wok, werr = pcall(writefileFn, CONFIG_FILE, encoded)
            Window:Notify({Title="配置", Content=wok and "配置已保存" or ("保存失败：" .. tostring(werr)), Duration=2})
        else
            Window:Notify({Title="配置", Content="JSON 编码失败：" .. tostring(encoded), Duration=2.4})
        end
    end})

    ConfigTab:Button({Title = "读取配置", Callback = function()
        local isfileFn = envFunc("isfile")
        local readfileFn = envFunc("readfile")
        if not isfileFn or not readfileFn then Window:Notify({Title="配置", Content="当前执行环境没有 isfile/readfile。", Duration=2.4}); return end
        local exists = false
        pcall(function() exists = isfileFn(CONFIG_FILE) end)
        if not exists then Window:Notify({Title="配置", Content="没有找到配置文件。", Duration=2}); return end
        local okRead, raw = pcall(readfileFn, CONFIG_FILE)
        if not okRead then Window:Notify({Title="配置", Content="读取失败："..tostring(raw), Duration=2.4}); return end
        local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not okDecode or type(data) ~= "table" then Window:Notify({Title="配置", Content="配置 JSON 无效。", Duration=2.4}); return end

        local function applyBool(key, current, setter)
            if data[key] ~= nil then pcall(setter, data[key] == true) end
        end
        local function applyNum(key, setter)
            if data[key] ~= nil then pcall(setter, data[key]) end
        end

        if data.HitboxSize ~= nil then HitboxSize = math.clamp(tonumber(data.HitboxSize) or HitboxSize,0,30) end
        if data.HitboxPartSelection then HitboxPartSelection=tostring(data.HitboxPartSelection) end
        if data.AimbotTeamCheck ~= nil then AimbotTeamCheck=data.AimbotTeamCheck==true end
        if data.AimbotWallCheck ~= nil then AimbotWallCheck=data.AimbotWallCheck==true end
        if data.AimbotSmoothness ~= nil then AimbotSmoothness=math.clamp(tonumber(data.AimbotSmoothness) or AimbotSmoothness,0.05,0.95) end
        if data.AimbotTargetPart then AimbotTargetPart=tostring(data.AimbotTargetPart) end
        if data.AimbotFOV ~= nil then AimbotFOV=math.clamp(tonumber(data.AimbotFOV) or AimbotFOV,50,500) end
        if data.SilentAimFOV ~= nil then NaramoSilentAim:SetFOV(math.clamp(tonumber(data.SilentAimFOV) or NaramoSilentAim.FOV,50,500)) end
        if data.TargetWalkSpeed ~= nil then TargetWalkSpeed=math.clamp(tonumber(data.TargetWalkSpeed) or TargetWalkSpeed,16,150) end
        if data.TargetJumpPower ~= nil then TargetJumpPower=math.clamp(tonumber(data.TargetJumpPower) or TargetJumpPower,50,350) end
        if data.TargetFOV ~= nil then TargetFOV=math.clamp(tonumber(data.TargetFOV) or TargetFOV,30,120) end
        if data.SpinBotSpeed ~= nil then SpinBotSpeed=math.clamp(tonumber(data.SpinBotSpeed) or SpinBotSpeed,10,360) end
        if data.BreakDeviceAttackInterval ~= nil then
            BreakDeviceAttackInterval = math.clamp(tonumber(data.BreakDeviceAttackInterval) or BreakDeviceAttackInterval, BREAK_DEVICE_ATTACK_INTERVAL_MIN, BREAK_DEVICE_ATTACK_INTERVAL_MAX)
        end
        if data.BreakDeviceMaxDistance ~= nil then
            BreakDeviceMaxDistance = math.clamp(tonumber(data.BreakDeviceMaxDistance) or BreakDeviceMaxDistance, BREAK_DEVICE_MAX_DISTANCE_MIN, BREAK_DEVICE_MAX_DISTANCE_MAX)
        end

        applyBool("HitboxEnabled", HitboxEnabled, function(v) setToggleByCurrent(HitboxEnabled,v,ToggleHitboxState) end)
        applyBool("InfAmmoEnabled", InfAmmoEnabled, function(v) InfAmmoEnabled=v end)
        applyBool("AimbotEnabled", AimbotEnabled, SetAimbotEnabled)
        applyBool("SilentAimEnabled", NaramoSilentAim.Enabled, NaramoSilentAim.SetEnabled and function(v) NaramoSilentAim:SetEnabled(v) end or function() end)
        applyBool("TracerEnabled", TracerEnabled, function(v) TracerEnabled=v end)
        applyBool("ZoomEnabled", ZoomEnabled, function(v) ZoomEnabled=v end)
        applyBool("ShowAimbotFOV", ShowAimbotFOV, function(v) ShowAimbotFOV=v; pcall(UpdateAimFovCircles) end)
        applyBool("ShowSilentAimFOV", ShowSilentAimFOV, function(v) ShowSilentAimFOV=v; pcall(UpdateAimFovCircles) end)
        applyBool("SpeedEnabled", SpeedEnabled, function(v) SpeedEnabled=v end)
        applyBool("JumpEnabled", JumpEnabled, function(v) JumpEnabled=v end)
        applyBool("FOVEnabled", FOVEnabled, function(v) FOVEnabled=v end)
        applyBool("NoclipEnabled", NoclipEnabled, function(v) setToggleByCurrent(NoclipEnabled,v,ToggleNoclipState) end)
        applyBool("InfJumpEnabled", InfJumpEnabled, function(v) setToggleByCurrent(InfJumpEnabled,v,ToggleInfJumpState) end)
        applyBool("InfStaminaEnabled", InfStaminaEnabled, function(v) setToggleByCurrent(InfStaminaEnabled,v,ToggleInfStaminaState) end)
        applyBool("FullbrightEnabled", FullbrightEnabled, function(v) setToggleByCurrent(FullbrightEnabled,v,ToggleFullbrightState) end)
        applyBool("GhostEnabled", GhostEnabled, function(v) setToggleByCurrent(GhostEnabled,v,ToggleGhostMode) end)
        applyBool("VehicleFlyEnabled", VehicleFlyEnabled, SetVehicleFlyEnabled)
        applyBool("SpinBotEnabled", SpinBotEnabled, SetSpinBotEnabled)
        applyBool("InstantProximityEnabled", InstantProximityEnabled, SetInstantProximityEnabled)
        applyBool("ChamsEnabled", ChamsEnabled, function(v) setToggleByCurrent(ChamsEnabled,v,ToggleChamsState) end)
        applyBool("VehicleEspEnabled", VehicleEspEnabled, function(v) setToggleByCurrent(VehicleEspEnabled,v,ToggleVehicleEspState) end)
        applyBool("VentEspEnabled", VentEspEnabled, function(v) setToggleByCurrent(VentEspEnabled,v,ToggleVentEspState) end)
        applyBool("BreakableEspEnabled", BreakableEspEnabled, function(v) setToggleByCurrent(BreakableEspEnabled,v,ToggleBreakableEspState) end)
        applyBool("PuddleEspEnabled", PuddleEspEnabled, function(v) setToggleByCurrent(PuddleEspEnabled,v,TogglePuddleEspState) end)
        applyBool("SmudgeEspEnabled", SmudgeEspEnabled, function(v) setToggleByCurrent(SmudgeEspEnabled,v,ToggleSmudgeEspState) end)
        applyBool("ChatLogsEnabled", ChatLogsEnabled, SetChatLogsEnabled)
        applyBool("BreakDeviceEnabled", BreakDeviceEnabled, SetBreakDeviceEnabled)
        if data.BreakDeviceUnlimitedMode ~= nil then
            BreakDeviceUnlimitedMode = data.BreakDeviceUnlimitedMode == true
        end
        HitmarkerMode=math.clamp(math.floor(tonumber(data.HitmarkerMode) or HitmarkerMode),0,2)
        if NaramoSilentAim then NaramoSilentAim.TeamCheck=AimbotTeamCheck; NaramoSilentAim.WallCheck=AimbotWallCheck; NaramoSilentAim.TargetPart=AimbotTargetPart end
        Window:Notify({Title="配置", Content="配置已读取；外观保持不变", Duration=2})
    end})

    ConfigTab:Button({Title = "重置主要状态", Callback = function()
        PanicDisableAddedFeatures()
        HitboxEnabled=false; InfAmmoEnabled=false; ZoomEnabled=false; TracerEnabled=false
        SpeedEnabled=false; JumpEnabled=false; FOVEnabled=false
        if HitboxEnabled then ApplyHitbox() else ResetHitbox() end
        syncFeature("命中框",false); syncFeature("无限弹药",false); syncFeature("Combat Zoom",false)
        Window:Notify({Title="配置", Content="主要功能状态已重置。", Duration=2})
    end})

    _G.NexusConfigTab = ConfigTab

    -- 原始功能重接后的统一状态同步接口。
    -- 任何外部代码修改状态后，可以调用这个函数恢复右上角功能列表显示。
    _G.NexusRefreshFeatureState = function()
        local items = {
            {"命中框", HitboxEnabled, "Both"},
            {"镜头瞄准", AimbotEnabled, "Camera"},
            {"静默瞄准", NaramoSilentAim.Enabled, "Silent"},
            {"无限弹药", InfAmmoEnabled, "Active"},
            {"彩色弹道", TracerEnabled, "RGB"},
            {"Combat Zoom", ZoomEnabled, "Active"},
            {"移动速度", SpeedEnabled, "Speed"},
            {"跳跃高度", JumpEnabled, "Jump"},
            {"FOV", FOVEnabled, "Camera"},
            {"穿墙", NoclipEnabled, "Noclip"},
            {"无限跳跃", InfJumpEnabled, "Jump"},
            {"无限体力", InfStaminaEnabled, "Stamina"},
            {"全亮", FullbrightEnabled, "Bright"},
            {"幽灵模式", GhostEnabled, "Ghost"},
            {"载具飞行", VehicleFlyEnabled, "Fly"},
            {"SpinBot", SpinBotEnabled, "Rotate"},
            {"即时交互", InstantProximityEnabled, "Prompt"},
            {"人物透视", ChamsEnabled, "ESP"},
            {"载具透视", VehicleEspEnabled, "ESP"},
            {"通风口透视", VentEspEnabled, "ESP"},
            {"可破坏物透视", BreakableEspEnabled, "ESP"},
            {"水坑透视", PuddleEspEnabled, "ESP"},
            {"污渍透视", SmudgeEspEnabled, "ESP"},
            {"聊天日志", ChatLogsEnabled, "Log"},
            {"自动拖地", AutoMopEnabled, "Auto"},
            {"自动擦玻璃", AutoCleanEnabled, "Auto"},
            {"自动修理", AutoRepairEnabled, "Auto"},
            {"破坏设备", BreakDeviceEnabled, "Packet"},
        }
        for _, item in ipairs(items) do
            pcall(syncFeature, item[1], item[2], item[3])
        end
        -- ArrayList 是 UI 常驻标识，不随功能状态刷新而关闭。
        pcall(function()
            if _G.NexusFeatureList then
                _G.NexusFeatureList:Set("ArrayList", true, "Syntax")
            end
        end)
    end

    pcall(function() _G.NexusRefreshFeatureState() end)

    -- 预留给原脚本附加 RageBot：附加段会继续向这个 CombatTab 注入其自身控件。
    _G.NexusCombatTab = CombatTab
    -- ================================================================
    -- 隐藏页面
    -- ================================================================
    HideTab:Section({Title = "主 UI 隐藏控制", TextXAlignment = "Left", TextSize = 17})
    HideTab:Button({Title = "隐藏主 UI", Callback = function()
        if _G.NexusHideMainUI then
            _G.NexusHideMainUI()
        end
    end})

    HideTab:Button({Title = "立即打开主 UI", Callback = function()
        if _G.NexusShowMainUI then
            _G.NexusShowMainUI()
        end
    end})

    HideTab:Button({Title = "回到第一个页面", Callback = function()
        pcall(function()
            Window.PageController:SelectTab(1)
        end)
    end})

    -- ================================================================
    -- UI 样式 / 字体设置页
    -- ================================================================

    local StyleTab = Window:Tab({Title = "UI样式", Icon = "type"})
    _G.NexusStyleTab = StyleTab

    -- ================================================================
    -- FeatureList / ArrayList visual controls
    -- Keep these controls in Syntax while the actual renderer stays in XHanUI.
    -- ================================================================
    StyleTab:Section({Title = "功能列表样式", TextXAlignment = "Left", TextSize = 17})

    StyleTab:Paragraph({
        Title = "FeatureList / ArrayList",
        Desc = "调整功能列表样式、阴影深度以及辉光流动颜色。",
        Height = 58,
    })

    StyleTab:AnimatedSelector({
        Title = "功能列表样式",
        Values = {"Split", "Bar", "Outline", "None"},
        Value = (_G.NexusFeatureList and _G.NexusFeatureList.Display) or "Split",
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetDisplay then
                    _G.NexusFeatureList:SetDisplay(tostring(value))
                end
            end)
        end,
    })

    StyleTab:Toggle({
        Title = "功能列表背景",
        Desc = "显示或隐藏功能列表背景层",
        Default = (_G.NexusFeatureList and _G.NexusFeatureList.Background) ~= false,
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetBackground then
                    _G.NexusFeatureList:SetBackground(value == true)
                end
            end)
        end,
    })

    StyleTab:Toggle({
        Title = "功能列表辉光",
        Desc = "开启或关闭文字与样式辉光",
        Default = (_G.NexusFeatureList and _G.NexusFeatureList.Glow) ~= false,
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetGlow then
                    _G.NexusFeatureList:SetGlow(value == true)
                end
            end)
        end,
    })

    StyleTab:Slider({
        Title = "功能列表阴影深度",
        Desc = "0 最浅，100 最深",
        Value = {
            Min = 0,
            Max = 100,
            Default = math.floor(
                tonumber(
                    (_G.NexusFeatureList and _G.NexusFeatureList.ShadowStrength)
                    or 78
                ) or 78
            ),
        },
        Increment = 1,
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetShadowStrength then
                    _G.NexusFeatureList:SetShadowStrength(
                        math.clamp(tonumber(value) or 78, 0, 100)
                    )
                end
            end)
        end,
    })

    StyleTab:AnimatedSelector({
        Title = "辉光流动配色",
        Values = {"Starlight", "Aurora", "Rainbow"},
        Value = (_G.NexusFeatureList and _G.NexusFeatureList.Palette) or "Starlight",
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetPalette then
                    _G.NexusFeatureList:SetPalette(tostring(value))
                end
            end)
        end,
    })

    StyleTab:Slider({
        Title = "辉光流动速度",
        Desc = "调整功能列表颜色流动速度",
        Value = {
            Min = 1,
            Max = 100,
            Default = math.floor(
                (
                    tonumber(
                        (_G.NexusFeatureList and _G.NexusFeatureList.FlowSpeed)
                        or 3
                    ) or 3
                ) * 10
            ),
        },
        Increment = 1,
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetFlowSpeed then
                    _G.NexusFeatureList:SetFlowSpeed(
                        math.clamp((tonumber(value) or 30) / 10, 0.1, 10)
                    )
                end
            end)
        end,
    })

    StyleTab:Section({Title = "字体与字体颜色", TextXAlignment = "Left", TextSize = 17})
    StyleTab:Paragraph({
        Title = "UI 样式设置",
        Desc = "在这里调整 UI 字体和字体颜色。",
        Height = 58,
    })

    local UIFontStyles = {
        ["Gotham"] = Enum.Font.Gotham,
        ["Gotham Medium"] = Enum.Font.GothamMedium,
        ["Gotham Bold"] = Enum.Font.GothamBold,
        ["Source Sans"] = Enum.Font.SourceSans,
        ["Source Sans Semibold"] = Enum.Font.SourceSansSemibold,
        ["Code"] = Enum.Font.Code,
        ["Fantasy"] = Enum.Font.Fantasy,
    }

    local UIFontColors = {
        ["纯白"] = Color3.fromRGB(255, 255, 255),
        ["纯黑"] = Color3.fromRGB(0, 0, 0),
        ["冷灰白"] = Color3.fromRGB(232, 234, 240),
        ["冰蓝"] = Color3.fromRGB(212, 238, 255),
        ["薄荷青"] = Color3.fromRGB(213, 255, 239),
        ["樱粉"] = Color3.fromRGB(255, 220, 238),
        ["浅紫"] = Color3.fromRGB(231, 221, 255),
        ["暖金"] = Color3.fromRGB(255, 236, 194),
    }

    local function applyUIFontStyle(font)
        local roots = {}
        if ScreenGui and ScreenGui.Parent then table.insert(roots, ScreenGui) end
        if IslandGui and IslandGui.Parent then table.insert(roots, IslandGui) end
        if FeatureHUD and FeatureHUD.Parent then table.insert(roots, FeatureHUD) end

        for _, root in ipairs(roots) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    obj.Font = font
                end
            end
        end

        pcall(function()
            if _G.NexusFeatureList and _G.NexusFeatureList.RefreshColors then
                _G.NexusFeatureList:RefreshColors()
            end
        end)
    end

    local function applyUIFontColor(color)
        local roots = {}
        if ScreenGui and ScreenGui.Parent then table.insert(roots, ScreenGui) end
        if IslandGui and IslandGui.Parent then table.insert(roots, IslandGui) end

        for _, root in ipairs(roots) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    obj.TextColor3 = color
                end
            end
        end

        pcall(function()
            if _G.NexusFeatureList and _G.NexusFeatureList.RefreshColors then
                _G.NexusFeatureList:RefreshColors()
            end
        end)
    end

    StyleTab:AnimatedSelector({
        Title = "UI字体样式",
        Values = {
            "Gotham",
            "Gotham Medium",
            "Gotham Bold",
            "Source Sans",
            "Source Sans Semibold",
            "Code",
            "Fantasy",
        },
        Value = "Gotham Medium",
        Callback = function(value)
            local font = UIFontStyles[tostring(value)]
            if font then
                applyUIFontStyle(font)
                Window:Notify({Title = "UI样式", Content = "字体已切换为 " .. tostring(value), Duration = 1.8})
            end
        end,
    })

    StyleTab:AnimatedSelector({
        Title = "UI字体颜色",
        Values = {
            "纯白",
            "纯黑",
            "冷灰白",
            "冰蓝",
            "薄荷青",
            "樱粉",
            "浅紫",
            "暖金",
        },
        Value = "纯白",
        Callback = function(value)
            local color = UIFontColors[tostring(value)]
            if color then
                applyUIFontColor(color)
                Window:Notify({Title = "UI样式", Content = "字体颜色已切换为 " .. tostring(value), Duration = 1.8})
            end
        end,
    })


    -- XHanUI is already opened by CreateWindow. No legacy page-controller correction is needed.
    task.defer(function()
        pcall(function() Window.PageController:SelectTab(1) end)
    end)

end)()


-- SECTION 12: ORIGINAL RAGEBOT ADDON
local function InitNexusRageBot()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if env.NexusRageBotAddonLoaded then
        return
    end
    env.NexusRageBotAddonLoaded = true

    local LP = Players.LocalPlayer
    local RageBotEnabled = false
    local RageBotInterval = 0.10
    local RageBotRange = 5000
    local RageBotThread
    local NetRayEvent = ReplicatedStorage:FindFirstChild("NetRay_RELIABLE")

    local function getTarget()
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local closest, closestDistance = nil, RageBotRange
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Team ~= LP.Team and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local part = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and part then
                    local distance = (part.Position - root.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closest = player
                    end
                end
            end
        end
        return closest
    end

    local function getBarrel()
        local char = LP.Character
        if not char then return nil end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then
                local barrel = obj:FindFirstChild("Barrel") or obj:FindFirstChild("1Barrel")
                if barrel and barrel:IsA("BasePart") then return barrel end
            end
        end
        return nil
    end

    local function drawTracer(origin, target)
        if not TracerEnabled then return end
        if typeof(origin) ~= "Vector3" or typeof(target) ~= "Vector3" then return end
        local distance = (target - origin).Magnitude
        if distance <= 0.05 or distance > 1500 then return end
        local tracer = Instance.new("Part")
        tracer.Name = "NexusRageBotTracer"
        tracer.Size = Vector3.new(0.055, 0.055, distance)
        tracer.CFrame = CFrame.lookAt((origin + target)/2, target)
        tracer.Anchored = true
        tracer.CanCollide = false
        tracer.CanTouch = false
        tracer.CanQuery = false
        tracer.CastShadow = false
        tracer.Material = Enum.Material.Neon
        tracer.Transparency = 0.05
        tracer.Color = Color3.fromHSV((os.clock()*0.7)%1,1,1)
        tracer.Parent = workspace
        local born = os.clock()
        task.spawn(function()
            while tracer.Parent and os.clock()-born < 0.65 do
                tracer.Color = Color3.fromHSV((os.clock()*0.7)%1,1,1)
                RunService.RenderStepped:Wait()
            end
        end)
        task.delay(0.65,function() if tracer.Parent then tracer:Destroy() end end)
    end

    local function firePacket(targetPart)
        if not targetPart or not targetPart.Parent then return false end
        local barrel = getBarrel()
        if not barrel then return false end
        if not NetRayEvent or not NetRayEvent.Parent then NetRayEvent = ReplicatedStorage:FindFirstChild("NetRay_RELIABLE") end
        if not NetRayEvent or not NetRayEvent:IsA("RemoteEvent") then return false end
        local origin = barrel.Position
        local hitPos = targetPart.Position
        local delta = hitPos - origin
        if delta.Magnitude <= 0.001 then return false end
        local hitNormal = delta.Unit
        local ok = pcall(function()
            local buf = buffer.create(41)
            buffer.writeu8(buf,0,6)
            buffer.writeu8(buf,1,31)
            buffer.writeu8(buf,2,1)
            buffer.writef32(buf,3,origin.X)
            buffer.writef32(buf,7,origin.Y)
            buffer.writef32(buf,11,origin.Z)
            buffer.writef32(buf,15,hitPos.X)
            buffer.writef32(buf,19,hitPos.Y)
            buffer.writef32(buf,23,hitPos.Z)
            buffer.writeu8(buf,27,1)
            buffer.writef32(buf,28,hitNormal.X)
            buffer.writef32(buf,32,hitNormal.Y)
            buffer.writef32(buf,36,hitNormal.Z)
            buffer.writeu8(buf,40,1)
            NetRayEvent:FireServer(buf,{2},{barrel},{targetPart})
        end)
        if ok and TracerEnabled then drawTracer(origin,hitPos) end
        return ok
    end

    local function stop()
        RageBotEnabled = false
        if RageBotThread then pcall(task.cancel,RageBotThread); RageBotThread=nil end
        if _G.NexusFeatureList then _G.NexusFeatureList:Set("RageBot",false,"Combat") end
    end

    local function start()
        if RageBotThread then pcall(task.cancel,RageBotThread); RageBotThread=nil end
        RageBotThread = task.spawn(function()
            while RageBotEnabled do
                local target = getTarget()
                if target and target.Character then
                    local part = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                    if part then firePacket(part) end
                end
                task.wait(RageBotInterval)
            end
            RageBotThread=nil
        end)
    end

    local combat = _G.NexusCombatTab
    if combat then
        combat:Section({Title = "RageBot"})
        combat:Toggle({Title = "RageBot", Default = false, Callback = function(v)
            RageBotEnabled = v == true
            if RageBotEnabled then start() else stop() end
            if _G.NexusFeatureList then _G.NexusFeatureList:Set("RageBot", RageBotEnabled, "Combat") end
        end})
        combat:Slider({Title = "RageBot 攻击间隔 (×0.01秒)", Value = {Min=5,Max=200,Default=10}, Increment=1, Callback=function(v)
            RageBotInterval = math.clamp(tonumber(v) or 10,5,200)/100
        end})
        combat:Slider({Title = "RageBot 搜索范围", Value = {Min=50,Max=10000,Default=5000}, Increment=50, Callback=function(v)
            RageBotRange = math.clamp(tonumber(v) or 5000,50,10000)
        end})
        combat:Paragraph({Title="RageBot状态",Desc="极度危险。"})
    end

    env.NexusRageBot = {
        Start = function() RageBotEnabled=true; start() end,
        Stop = stop,
        SetEnabled = function(v) if v then RageBotEnabled=true; start() else stop() end end,
        SetInterval = function(seconds) seconds=tonumber(seconds); if seconds then RageBotInterval=math.clamp(seconds,0.05,2) end end,
        SetRange = function(range) range=tonumber(range); if range then RageBotRange=math.clamp(range,50,10000) end end,
        SetTracer = function(v) TracerEnabled = v == true end,
    }
end

pcall(InitNexusRageBot)

-- 记录功能引擎与 XHanUI 外部界面的初始化结果。
_G.NexusUIReady = _G.SyntaxNextWindow ~= nil
_G.NexusBootStatus = function() return true end
