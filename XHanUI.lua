-- Startup repair: explicit IIFE separators, bounded local scopes, visible diagnostics.
-- This script retains its original executor-specific dependencies.
do
local boot = {Ready = false, Stage = "准备", Error = nil, Version = "V23 startup fix"}
_G.SyntaxBootDiagnostics = boot
_G.NexusUIReady = false
_G.NexusBootStatus = function() return boot.Ready, boot.Stage, boot.Error end

local function traceback(message)
    if debug and type(debug.traceback) == "function" then
        local ok, result = pcall(debug.traceback, tostring(message), 2)
        if ok then return result end
    end
    return tostring(message)
end

local bootOk, bootError = xpcall(function()
    if not game:IsLoaded() then
        boot.Stage = "等待游戏加载"
        game.Loaded:Wait()
    end
    if not game:GetService("RunService"):IsClient() then
        error("请在客户端运行此脚本", 0)
    end
    -- Never treat a window left by an earlier execution as this run's success.
    _G.SyntaxNextWindow = nil
    do
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
        local oldError = playerGui and playerGui:FindFirstChild("SyntaxStartupError")
        if oldError then oldError:Destroy() end
    end

-- Paired with expanded FeatureList matrix glow build
-- ================================================================
-- Syntax / XHanUI external UI bootstrap
-- UI library only; all feature logic below comes from the uploaded SyntaxNext script.
-- ================================================================
(function()
    local URL = "https://raw.githubusercontent.com/MilkShakeLove/XHanUI/refs/heads/main/XHanUI.lua"

    boot.Stage = "下载 XHanUI"
    local okHttp, source = pcall(function()
        -- Cache-bust only: UI appearance is controlled entirely by XHanUI.lua.
        return game:HttpGet(URL .. "?v=" .. tostring(os.time()))
    end)
    if not okHttp then
        error("XHanUI 下载失败: " .. tostring(source), 0)
    end

    if type(source) ~= "string" or source:match("^%s*$") then
        error("XHanUI 下载返回空内容或非文本内容", 0)
    end
    boot.Stage = "编译 XHanUI"
    if type(loadstring) ~= "function" then
        error("当前运行环境不支持 loadstring；此文件依赖执行器接口，不能直接作为 Studio LocalScript 运行", 0)
    end
    local loader, compileError = loadstring(source, "@Syntax/XHanUI")
    if not loader then
        error("XHanUI 编译失败: " .. tostring(compileError), 0)
    end

    boot.Stage = "运行 XHanUI"
    local okLib, XHanUI = pcall(loader)
    if not okLib or type(XHanUI) ~= "table" then
        error("XHanUI 加载失败或未返回库对象: " .. tostring(XHanUI), 0)
    end

    if type(XHanUI.CreateWindow) ~= "function" then
        error("XHanUI 接口不兼容：缺少 CreateWindow", 0)
    end
    boot.Stage = "创建 XHanUI 窗口"
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
                Display = "None",
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
        error("XHanUI 未返回窗口对象", 0)
    end

    boot.Stage = "连接 XHanUI 接口"
    for _, method in ipairs({"GetFeatureList", "CreateDynamicIsland", "RegisterFeature", "Tab"}) do
        if type(NativeWindow[method]) ~= "function" then
            error("XHanUI 窗口接口不兼容：缺少 " .. method, 0)
        end
    end
    local NativeFeatureList = NativeWindow:GetFeatureList()
    if not NativeFeatureList or type(NativeFeatureList.Get) ~= "function" then
        error("XHanUI 未提供有效的 FeatureList:Get 接口", 0)
    end
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
end)();

if not _G.SyntaxNextWindow then
    error("UI 初始化未完成，功能引擎未启动", 0)
end

-- ================================================================
-- AutoPowerOrder++ · on-demand feature loader
-- UI/automation are created only when the Syntax toggle is enabled.
-- ================================================================
_G.AutoPowerOrderPlusPlusLoaded = false
_G.AutoPowerOrderPlusPlusLoadError = nil
_G.__AutoPowerOrderPlusPlusController = nil

local function CleanupAutoPowerOrderPlusPlusUI()
    local function cleanParent(parent)
        if not parent then return end
        local gui = parent:FindFirstChild("PowerControlGUI")
        if gui then
            pcall(function() gui:Destroy() end)
        end
    end

    if type(gethui) == "function" then
        pcall(function()
            cleanParent(gethui())
        end)
    end

    pcall(function()
        cleanParent(game:GetService("CoreGui"))
    end)

    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        cleanParent(player and player:FindFirstChildOfClass("PlayerGui"))
    end)
end

_G.SyntaxStartAutoPowerOrderPlusPlus = function()
    local old = _G.__AutoPowerOrderPlusPlusController
    if old and old.Running then
        return true
    end

    CleanupAutoPowerOrderPlusPlusUI()

    local controller = {
        Running = true,
        Stopped = false,
        Connections = {},
        ScreenGui = nil,
    }

    _G.__AutoPowerOrderPlusPlusController = controller
    _G.AutoPowerOrderPlusPlusLoaded = false
    _G.AutoPowerOrderPlusPlusLoadError = nil

    task.spawn(function()
        local ok, err = xpcall(function()
        local __APOPP = _G.__AutoPowerOrderPlusPlusController
        if not __APOPP or __APOPP.Running ~= true then
            return
        end
        
        local Players          = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local RunService       = game:GetService("RunService")
        
        local LocalPlayer = Players.LocalPlayer
        
        local function resolveUIParent()
            if type(gethui) == "function" then
                local ok, result = pcall(gethui)
                if ok and result then
                    return result
                end
            end
        
            local okCore, coreGui = pcall(function()
                return game:GetService("CoreGui")
            end)
            if okCore and coreGui then
                return coreGui
            end
        
            if LocalPlayer then
                return LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    or LocalPlayer:WaitForChild("PlayerGui", 5)
            end
        
            return nil
        end
        
        local uiParent = resolveUIParent()
        if not uiParent then
            error("[AutoPowerOrder++] 找不到可用的 UI Parent")
        end
        
        for _, n in ipairs({"PowerControlGUI"}) do
            local old = uiParent:FindFirstChild(n)
            if old then pcall(function() old:Destroy() end) end
        end
        
        local function parseNum(s)
            if not s then return nil end
            if type(s) == "number" then return s end
            local n = string.match(tostring(s), "%-?%d+%.?%d*")
            return n and tonumber(n) or nil
        end
        
        local function normalizeStatus(s)
            if not s then return "" end
            return string.upper(string.gsub(tostring(s), "%s+", ""))
        end
        
        local FacilitySystems = workspace:WaitForChild("FacilitySystems")
        local ControlPanels    = FacilitySystems:WaitForChild("ControlPanels")
        local Turbines         = FacilitySystems:WaitForChild("Controls"):WaitForChild("Turbines")
        
        local BigSignThing = ControlPanels:WaitForChild("BigSignThing")
        
        local function getPartLabel(parent, name)
            local holder = parent and parent:FindFirstChild(name)
            local part = holder and holder:FindFirstChild("Part")
            local surface = part and part:FindFirstChild("SurfaceGui")
            local label = surface and surface:FindFirstChild("TextLabel")
            return label
        end
        
        local ExcessPowerLabel    = getPartLabel(BigSignThing, "ExcessPower")
        local PowerOrderLabel     = getPartLabel(BigSignThing, "PowerOrder")
        local MarginForErrorLabel = getPartLabel(BigSignThing, "MarginForError")
        local HoldForLabel        = getPartLabel(BigSignThing, "HoldFor")
        
        local TemperatureLabel          = getPartLabel(BigSignThing, "Temperature")
        local FeedwaterLabel            = getPartLabel(BigSignThing, "Feedwater")
        local PressureLabel             = getPartLabel(BigSignThing, "Pressure")
        local ControlRodPercentageLabel = getPartLabel(BigSignThing, "ControlRodPercentage")
        
        local BetaValveSwitch  = Turbines:WaitForChild("TurbBetaValveSwitch")
        local BetaSwitchPart   = BetaValveSwitch:WaitForChild("Switch")
        local BetaDecCD        = BetaValveSwitch:WaitForChild("Decrement"):WaitForChild("ClickDetector")
        local BetaIncCD        = BetaValveSwitch:WaitForChild("Increment"):WaitForChild("ClickDetector")
        local BetaSyncPrompt   = Turbines:WaitForChild("TurbineBetaSyncSwitch"):WaitForChild("Main"):WaitForChild("ProximityPrompt")
        
        local AlphaValveSwitch = Turbines:WaitForChild("TurbAlphaValveSwitch")
        local AlphaSwitchPart  = AlphaValveSwitch:WaitForChild("Switch")
        local AlphaDecCD       = AlphaValveSwitch:WaitForChild("Decrement"):WaitForChild("ClickDetector")
        local AlphaIncCD       = AlphaValveSwitch:WaitForChild("Increment"):WaitForChild("ClickDetector")
        local AlphaSyncPrompt  = Turbines:WaitForChild("TurbineAlphaSyncSwitch"):WaitForChild("Main"):WaitForChild("ProximityPrompt")
        
        local BetaSynchroscope  = Turbines:WaitForChild("TurbBetaSynchroscope"):WaitForChild("SynchroscopeLights")
        local BetaGreenLight    = BetaSynchroscope:WaitForChild("0")
        local BetaAlarmLight    = BetaSynchroscope:FindFirstChild("29")
        
        local AlphaSynchroscope = Turbines:WaitForChild("TurbAlphaSynchroscope"):WaitForChild("SynchroscopeLights")
        local AlphaGreenLight   = AlphaSynchroscope:WaitForChild("0")
        local AlphaAlarmLight   = AlphaSynchroscope:FindFirstChild("29")
        
        local GridOpsText = ControlPanels:WaitForChild("GridOps"):WaitForChild("Text")
        
        local function findLabelByPos(targetPos)
            local bestChild, bestDist = nil, math.huge
            for _, c in ipairs(GridOpsText:GetChildren()) do
                local sg = c:FindFirstChildOfClass("SurfaceGui")
                local part = sg and sg.Parent
                if part and part:IsA("BasePart") then
                    local d = (part.Position - targetPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestChild = c
                    end
                end
            end
            if not bestChild then return nil, nil end
            local sg = bestChild:FindFirstChildOfClass("SurfaceGui")
            local lbl = sg and sg:FindFirstChildOfClass("TextLabel")
            return lbl, bestDist
        end
        
        local BetaRPM  = findLabelByPos(Vector3.new(-3800.04517, 80.304039,  5723.68213))
        local BetaFlow = findLabelByPos(Vector3.new(-3798.52002, 80.1617813, 5725.20605))
        local BetaVib  = findLabelByPos(Vector3.new(-3800.05469, 79.9411774, 5723.69141))
        local BetaStat = findLabelByPos(Vector3.new(-3800.04492, 80.6800232, 5723.68213))
        
        local AlphaStat = findLabelByPos(Vector3.new(-3803.16919, 80.6739807, 5720.55615))
        local AlphaRPM  = findLabelByPos(Vector3.new(-3803.16748, 80.2984467, 5720.55518))
        local AlphaVib  = findLabelByPos(Vector3.new(-3803.16748, 79.935585,  5720.55518))
        local AlphaFlow = findLabelByPos(Vector3.new(-3801.61133, 80.156189,  5722.11133))
        
        local ORIENT_MAP = {
            { offset = -2, orient = Vector3.new( -8.743000030517578,  31.634000778198242, -24.52899932861328) },
            { offset = -1, orient = Vector3.new(-23.225000381469727,  -2.7070000171661377, -20.72599983215332) },
            { offset =  0, orient = Vector3.new(-39.222999572753906, -37.76300048828125,  -26.558000564575195) },
            { offset =  1, orient = Vector3.new(-83.15299987792969,  -66.6240005493164,   -62.986000061035156) },
            { offset =  2, orient = Vector3.new(-166.14500427246094, -57.30099868774414, -139.13299560546875) },
        }
        
        local DIST_BANDS = {
            { max =   3, offset = -1 },
            { max =  15, offset = -2 },
            { max =  45, offset =  0 },
            { max =  85, offset =  1 },
            { max = 999, offset =  2 },
        }
        
        local function readOffsetFrom(part)
            local ok, cur = pcall(function() return part.Orientation end)
            if not ok or not cur then return 0, nil end
            local bestDist = math.huge
            for _, e in ipairs(ORIENT_MAP) do
                local d = (cur - e.orient).Magnitude
                if d < bestDist then bestDist = d end
            end
            for _, band in ipairs(DIST_BANDS) do
                if bestDist <= band.max then
                    return band.offset, bestDist
                end
            end
            return 0, bestDist
        end
        
        local function readNetOffsetBeta()  return readOffsetFrom(BetaSwitchPart)  end
        local function readNetOffsetAlpha() return readOffsetFrom(AlphaSwitchPart) end
        
        local function readPowerValues()
            return {
                excess = ExcessPowerLabel    and parseNum(ExcessPowerLabel.Text),
                order  = PowerOrderLabel     and parseNum(PowerOrderLabel.Text),
                margin = MarginForErrorLabel and parseNum(MarginForErrorLabel.Text),
                hold   = HoldForLabel        and parseNum(HoldForLabel.Text),
            }
        end
        
        local function readReactorValues()
            return {
                temperature = TemperatureLabel          and parseNum(TemperatureLabel.Text),
                feedwater   = FeedwaterLabel            and tostring(FeedwaterLabel.Text or ""),
                pressure    = PressureLabel             and parseNum(PressureLabel.Text),
                rodPct      = ControlRodPercentageLabel and parseNum(ControlRodPercentageLabel.Text),
            }
        end
        
        local function readBetaValues()
            return {
                flowRate  = BetaFlow  and parseNum(BetaFlow.Text),
                rpm       = BetaRPM   and parseNum(BetaRPM.Text),
                vibration = BetaVib   and parseNum(BetaVib.Text),
                status    = BetaStat  and tostring(BetaStat.Text or "") or "",
            }
        end
        
        local function readAlphaValues()
            return {
                flowRate  = AlphaFlow and parseNum(AlphaFlow.Text),
                rpm       = AlphaRPM  and parseNum(AlphaRPM.Text),
                vibration = AlphaVib  and parseNum(AlphaVib.Text),
                status    = AlphaStat and tostring(AlphaStat.Text or "") or "",
            }
        end
        
        local function readBetaStatus()
            if not BetaStat then return "" end
            return normalizeStatus(BetaStat.Text or "")
        end
        
        local function readAlphaStatus()
            if not AlphaStat then return "" end
            return normalizeStatus(AlphaStat.Text or "")
        end
        
        local LIME_BRICK  = BrickColor.new("Lime green")
        local ALARM_BRICK = BrickColor.new("Crimson")
        
        local function isGreenReady(light)
            if not light then return false end
            local ok, bc = pcall(function() return light.BrickColor end)
            if not ok or not bc then return false end
            return bc == LIME_BRICK
        end
        
        local function isAlarmCrimson(light)
            if not light then return false end
            local ok, bc = pcall(function() return light.BrickColor end)
            if not ok or not bc then return false end
            return bc == ALARM_BRICK
        end
        
        local betaRpmHistory, alphaRpmHistory = {}, {}
        
        local function pushRpm(history, rpm)
            if not rpm then return end
            local now = tick()
            table.insert(history, {t = now, v = rpm})
            while #history > 0 and now - history[1].t > 2.0 do
                table.remove(history, 1)
            end
        end
        
        local function predictRpm(history, futureSec)
            if #history < 2 then return nil end
            local first = history[1]
            local last  = history[#history]
            local dt = last.t - first.t
            if dt < 0.1 then return nil end
            local rate = (last.v - first.v) / dt
            return last.v + rate * futureSec
        end
        
        -- ========== UI ==========
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PowerControlGUI"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 100010
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = uiParent
        
        __APOPP.ScreenGui = screenGui
        __APOPP.Connections = __APOPP.Connections or {}
        
        local function registerConnection(conn)
            if conn then
                table.insert(__APOPP.Connections, conn)
            end
            return conn
        end
        
        __APOPP.Stop = function()
            if __APOPP.Stopped then
                return
            end
        
            __APOPP.Stopped = true
            __APOPP.Running = false
        
            for i = #__APOPP.Connections, 1, -1 do
                local conn = __APOPP.Connections[i]
                __APOPP.Connections[i] = nil
                pcall(function()
                    conn:Disconnect()
                end)
            end
        
            if __APOPP.ScreenGui then
                pcall(function()
                    __APOPP.ScreenGui:Destroy()
                end)
                __APOPP.ScreenGui = nil
            end
        
            _G.AutoPowerOrderPlusPlusLoaded = false
        end
        
        local SCREEN_W = 1200
        local SCREEN_H = 620
        
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(0, SCREEN_W, 0, SCREEN_H)
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.new(0.5, 0, 0.5, 0)
        panel.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
        panel.BackgroundTransparency = 0.05
        panel.BorderSizePixel = 0
        panel.Active = true
        panel.Parent = screenGui
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
        local panelStroke = Instance.new("UIStroke", panel)
        panelStroke.Color = Color3.fromRGB(60, 100, 180)
        panelStroke.Thickness = 2
        
        -- Keep the original UI layout exactly as-is and shrink the whole panel.
        local panelScale = Instance.new("UIScale")
        panelScale.Parent = panel
        
        local function updatePanelScale()
            local camera = workspace.CurrentCamera
            local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
        
            local fitX = math.max(0.1, (vp.X - 18) / SCREEN_W)
            local fitY = math.max(0.1, (vp.Y - 18) / SCREEN_H)
        
            -- Never enlarge the original UI; only shrink it.
            panelScale.Scale = math.clamp(
                math.min(0.78, fitX, fitY),
                0.28,
                0.78
            )
        end
        
        updatePanelScale()
        
        if workspace.CurrentCamera then
            registerConnection(
                workspace.CurrentCamera
                    :GetPropertyChangedSignal("ViewportSize")
                    :Connect(updatePanelScale)
            )
        end
        
        local titleBar = Instance.new("Frame", panel)
        titleBar.Size = UDim2.new(1, 0, 0, 42)
        titleBar.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
        titleBar.BorderSizePixel = 0
        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
        local titleFix = Instance.new("Frame", titleBar)
        titleFix.Size = UDim2.new(1, 0, 0, 14)
        titleFix.Position = UDim2.new(0, 0, 1, -14)
        titleFix.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
        titleFix.BorderSizePixel = 0
        
        local title = Instance.new("TextLabel", titleBar)
        title.Size = UDim2.new(1, -400, 1, 0)
        title.Position = UDim2.new(0, 16, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "⚡ POWER & REACTOR CONTROL  —  DUAL TURBINE PANEL"
        title.TextColor3 = Color3.fromRGB(140, 200, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        
        local closeBtn = Instance.new("TextButton", titleBar)
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -36, 0.5, -15)
        closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 18
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = titleBar
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
        
        local overrideBtn = Instance.new("TextButton")
        overrideBtn.Size = UDim2.new(0, 180, 0, 30)
        overrideBtn.Position = UDim2.new(1, -220, 0.5, -15)
        overrideBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
        overrideBtn.Text = "⚠ MANUAL OVERRIDE"
        overrideBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
        overrideBtn.Font = Enum.Font.GothamBold
        overrideBtn.TextSize = 13
        overrideBtn.AutoButtonColor = false
        overrideBtn.BorderSizePixel = 0
        overrideBtn.Parent = titleBar
        Instance.new("UICorner", overrideBtn).CornerRadius = UDim.new(0, 6)
        local overrideStroke = Instance.new("UIStroke", overrideBtn)
        overrideStroke.Color = Color3.fromRGB(180, 60, 60)
        overrideStroke.Thickness = 1.5
        
        local openBtn = Instance.new("TextButton")
        openBtn.Size = UDim2.new(0, 180, 0, 44)
        openBtn.Position = UDim2.new(0, 20, 0, 200)
        openBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
        openBtn.BackgroundTransparency = 0.1
        openBtn.Text = "⚡ CONTROL"
        openBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
        openBtn.Font = Enum.Font.GothamBold
        openBtn.TextSize = 14
        openBtn.AutoButtonColor = false
        openBtn.Visible = false
        openBtn.Parent = screenGui
        Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)
        local openStroke = Instance.new("UIStroke", openBtn)
        openStroke.Color = Color3.fromRGB(60, 130, 220)
        openStroke.Thickness = 1.5
        
        local contentArea = Instance.new("Frame", panel)
        contentArea.Size = UDim2.new(1, -16, 1, -56)
        contentArea.Position = UDim2.new(0, 8, 0, 48)
        contentArea.BackgroundTransparency = 1
        contentArea.BorderSizePixel = 0
        
        local topRow = Instance.new("Frame", contentArea)
        topRow.Size = UDim2.new(1, 0, 0, 210)
        topRow.BackgroundTransparency = 1
        topRow.BorderSizePixel = 0
        
        local reactorBox = Instance.new("Frame", topRow)
        reactorBox.Size = UDim2.new(0.5, -6, 1, 0)
        reactorBox.Position = UDim2.new(0, 0, 0, 0)
        reactorBox.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
        reactorBox.BorderSizePixel = 0
        Instance.new("UICorner", reactorBox).CornerRadius = UDim.new(0, 10)
        local reactorStroke = Instance.new("UIStroke", reactorBox)
        reactorStroke.Color = Color3.fromRGB(50, 80, 130)
        reactorStroke.Thickness = 1.5
        
        local powerBox = Instance.new("Frame", topRow)
        powerBox.Size = UDim2.new(0.5, -6, 1, 0)
        powerBox.Position = UDim2.new(0.5, 6, 0, 0)
        powerBox.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
        powerBox.BorderSizePixel = 0
        Instance.new("UICorner", powerBox).CornerRadius = UDim.new(0, 10)
        local powerStroke = Instance.new("UIStroke", powerBox)
        powerStroke.Color = Color3.fromRGB(50, 80, 130)
        powerStroke.Thickness = 1.5
        
        local botRow = Instance.new("Frame", contentArea)
        botRow.Size = UDim2.new(1, 0, 1, -222)
        botRow.Position = UDim2.new(0, 0, 0, 222)
        botRow.BackgroundTransparency = 1
        botRow.BorderSizePixel = 0
        
        local alphaBox = Instance.new("Frame", botRow)
        alphaBox.Size = UDim2.new(0.5, -6, 1, 0)
        alphaBox.Position = UDim2.new(0, 0, 0, 0)
        alphaBox.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
        alphaBox.BorderSizePixel = 0
        Instance.new("UICorner", alphaBox).CornerRadius = UDim.new(0, 10)
        local alphaStroke = Instance.new("UIStroke", alphaBox)
        alphaStroke.Color = Color3.fromRGB(60, 130, 90)
        alphaStroke.Thickness = 1.5
        
        local betaBox = Instance.new("Frame", botRow)
        betaBox.Size = UDim2.new(0.5, -6, 1, 0)
        betaBox.Position = UDim2.new(0.5, 6, 0, 0)
        betaBox.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
        betaBox.BorderSizePixel = 0
        Instance.new("UICorner", betaBox).CornerRadius = UDim.new(0, 10)
        local betaStroke = Instance.new("UIStroke", betaBox)
        betaStroke.Color = Color3.fromRGB(60, 130, 90)
        betaStroke.Thickness = 1.5
        
        local function makeRow(parent, label, y, color, h)
            h = h or 28
            local l = Instance.new("TextLabel", parent)
            l.Size = UDim2.new(0.55, -8, 0, h)
            l.Position = UDim2.new(0, 12, 0, y)
            l.BackgroundTransparency = 1
            l.Text = label
            l.TextColor3 = Color3.fromRGB(140, 150, 180)
            l.Font = Enum.Font.Gotham
            l.TextSize = 13
            l.TextXAlignment = Enum.TextXAlignment.Left
        
            local v = Instance.new("TextLabel", parent)
            v.Size = UDim2.new(0.45, -12, 0, h)
            v.Position = UDim2.new(0.55, 0, 0, y)
            v.BackgroundTransparency = 1
            v.Text = "--"
            v.TextColor3 = color or Color3.fromRGB(220, 230, 255)
            v.Font = Enum.Font.GothamBold
            v.TextSize = 14
            v.TextXAlignment = Enum.TextXAlignment.Right
            return v
        end
        
        local function makeSectionTitle(parent, text)
            local h = Instance.new("TextLabel", parent)
            h.Size = UDim2.new(1, -20, 0, 26)
            h.Position = UDim2.new(0, 12, 0, 8)
            h.BackgroundTransparency = 1
            h.Text = text
            h.TextColor3 = Color3.fromRGB(160, 200, 255)
            h.Font = Enum.Font.GothamBold
            h.TextSize = 14
            h.TextXAlignment = Enum.TextXAlignment.Left
            return h
        end
        
        makeSectionTitle(reactorBox, "◆ REACTOR")
        local tempVal  = makeRow(reactorBox, "Temperature",   42, Color3.fromRGB(255, 160, 120))
        local feedVal  = makeRow(reactorBox, "Feedwater",     70, Color3.fromRGB(160, 220, 255))
        local pressVal = makeRow(reactorBox, "Pressure",      98, Color3.fromRGB(255, 200, 100))
        local rodVal   = makeRow(reactorBox, "Control Rod %", 126, Color3.fromRGB(200, 200, 255))
        
        makeSectionTitle(powerBox, "◆ POWER")
        local excessVal = makeRow(powerBox, "Excess Power", 36, Color3.fromRGB(120, 220, 255))
        local orderVal  = makeRow(powerBox, "Power Order",  62, Color3.fromRGB(200, 200, 255))
        local marginVal = makeRow(powerBox, "Margin",       88, Color3.fromRGB(255, 200, 100))
        local holdVal   = makeRow(powerBox, "Hold For",     114, Color3.fromRGB(180, 255, 180))
        
        local statusLabel = Instance.new("TextLabel", powerBox)
        statusLabel.Size = UDim2.new(1, -20, 0, 26)
        statusLabel.Position = UDim2.new(0, 10, 0, 142)
        statusLabel.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
        statusLabel.BorderSizePixel = 0
        statusLabel.Text = "IDLE"
        statusLabel.TextColor3 = Color3.fromRGB(120, 140, 180)
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextSize = 13
        Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)
        
        local autoBtn = Instance.new("TextButton", powerBox)
        autoBtn.Size = UDim2.new(1, -20, 0, 32)
        autoBtn.Position = UDim2.new(0, 10, 0, 172)
        autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        autoBtn.Text = "POWER AUTO: OFF"
        autoBtn.TextColor3 = Color3.fromRGB(160, 170, 200)
        autoBtn.Font = Enum.Font.GothamBold
        autoBtn.TextSize = 13
        autoBtn.AutoButtonColor = false
        autoBtn.BorderSizePixel = 0
        Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)
        local autoStroke = Instance.new("UIStroke", autoBtn)
        autoStroke.Color = Color3.fromRGB(80, 90, 130)
        autoStroke.Thickness = 1.5
        
        local function buildTurbineBlock(parent, titleText)
            makeSectionTitle(parent, titleText)
        
            local rpmBig = Instance.new("TextLabel", parent)
            rpmBig.Size = UDim2.new(0, 130, 0, 40)
            rpmBig.Position = UDim2.new(0, 16, 0, 50)
            rpmBig.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
            rpmBig.BorderSizePixel = 0
            rpmBig.Text = "0"
            rpmBig.TextColor3 = Color3.fromRGB(200, 240, 255)
            rpmBig.Font = Enum.Font.GothamBold
            rpmBig.TextSize = 26
            Instance.new("UICorner", rpmBig).CornerRadius = UDim.new(0, 6)
            local rpmBigStroke = Instance.new("UIStroke", rpmBig)
            rpmBigStroke.Color = Color3.fromRGB(60, 100, 160)
            rpmBigStroke.Thickness = 1.5
        
            local rpmCaption = Instance.new("TextLabel", parent)
            rpmCaption.Size = UDim2.new(0, 130, 0, 16)
            rpmCaption.Position = UDim2.new(0, 16, 0, 94)
            rpmCaption.BackgroundTransparency = 1
            rpmCaption.Text = "RPM"
            rpmCaption.TextColor3 = Color3.fromRGB(140, 150, 180)
            rpmCaption.Font = Enum.Font.Gotham
            rpmCaption.TextSize = 12
            rpmCaption.TextXAlignment = Enum.TextXAlignment.Center
        
            local barBg = Instance.new("Frame", parent)
            barBg.Size = UDim2.new(0, 130, 0, 14)
            barBg.Position = UDim2.new(0, 16, 0, 114)
            barBg.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
            barBg.BorderSizePixel = 0
            Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 7)
        
            local barFill = Instance.new("Frame", barBg)
            barFill.Size = UDim2.new(0, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(120, 220, 255)
            barFill.BorderSizePixel = 0
            Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 7)
        
            local dataX = 165
            local labelW = 110
            local valueW = 150
        
            local function dataRow(label, y, color)
                local l = Instance.new("TextLabel", parent)
                l.Size = UDim2.new(0, labelW, 0, 26)
                l.Position = UDim2.new(0, dataX, 0, y)
                l.BackgroundTransparency = 1
                l.Text = label
                l.TextColor3 = Color3.fromRGB(140, 150, 180)
                l.Font = Enum.Font.Gotham
                l.TextSize = 13
                l.TextXAlignment = Enum.TextXAlignment.Left
        
                local v = Instance.new("TextLabel", parent)
                v.Size = UDim2.new(0, valueW, 0, 26)
                v.Position = UDim2.new(0, dataX + labelW, 0, y)
                v.BackgroundTransparency = 1
                v.Text = "--"
                v.TextColor3 = color
                v.Font = Enum.Font.GothamBold
                v.TextSize = 14
                v.TextXAlignment = Enum.TextXAlignment.Right
                return v
            end
        
            local statusVal = dataRow("Status",    42, Color3.fromRGB(200, 200, 220))
            local rpmVal    = dataRow("RPM",       70, Color3.fromRGB(120, 220, 255))
            local flowVal   = dataRow("Flow Rate", 98, Color3.fromRGB(160, 220, 255))
            local vibVal    = dataRow("Vibration", 126, Color3.fromRGB(255, 200, 100))
        
            local btnColW = 130
        
            local autoSyncBtn = Instance.new("TextButton", parent)
            autoSyncBtn.Size = UDim2.new(0, btnColW, 0, 40)
            autoSyncBtn.Position = UDim2.new(1, -btnColW - 14, 0, 44)
            autoSyncBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            autoSyncBtn.Text = "AUTO SYNC: OFF"
            autoSyncBtn.TextColor3 = Color3.fromRGB(160, 170, 200)
            autoSyncBtn.Font = Enum.Font.GothamBold
            autoSyncBtn.TextSize = 13
            autoSyncBtn.AutoButtonColor = false
            autoSyncBtn.BorderSizePixel = 0
            Instance.new("UICorner", autoSyncBtn).CornerRadius = UDim.new(0, 8)
            local autoSyncStroke = Instance.new("UIStroke", autoSyncBtn)
            autoSyncStroke.Color = Color3.fromRGB(80, 90, 130)
            autoSyncStroke.Thickness = 1.5
        
            local incBtn = Instance.new("TextButton", parent)
            incBtn.Size = UDim2.new(0, (btnColW - 6) / 2, 0, 40)
            incBtn.Position = UDim2.new(1, -btnColW - 14 + (btnColW + 6) / 2, 0, 92)
            incBtn.BackgroundColor3 = Color3.fromRGB(25, 50, 25)
            incBtn.Text = "+"
            incBtn.TextColor3 = Color3.fromRGB(180, 255, 180)
            incBtn.Font = Enum.Font.GothamBold
            incBtn.TextSize = 22
            incBtn.AutoButtonColor = false
            incBtn.BorderSizePixel = 0
            Instance.new("UICorner", incBtn).CornerRadius = UDim.new(0, 8)
        
            local decBtn = Instance.new("TextButton", parent)
            decBtn.Size = UDim2.new(0, (btnColW - 6) / 2, 0, 40)
            decBtn.Position = UDim2.new(1, -btnColW - 14, 0, 92)
            decBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 25)
            decBtn.Text = "−"
            decBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
            decBtn.Font = Enum.Font.GothamBold
            decBtn.TextSize = 22
            decBtn.AutoButtonColor = false
            decBtn.BorderSizePixel = 0
            Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0, 8)
        
            local lightRow = Instance.new("Frame", parent)
            lightRow.Size = UDim2.new(0, btnColW, 0, 28)
            lightRow.Position = UDim2.new(1, -btnColW - 14, 0, 142)
            lightRow.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
            lightRow.BorderSizePixel = 0
            Instance.new("UICorner", lightRow).CornerRadius = UDim.new(0, 6)
        
            local lightDot = Instance.new("Frame", lightRow)
            lightDot.Size = UDim2.new(0, 16, 0, 16)
            lightDot.Position = UDim2.new(0, 8, 0.5, -8)
            lightDot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            lightDot.BorderSizePixel = 0
            Instance.new("UICorner", lightDot).CornerRadius = UDim.new(1, 0)
        
            local lightText = Instance.new("TextLabel", lightRow)
            lightText.Size = UDim2.new(1, -32, 1, 0)
            lightText.Position = UDim2.new(0, 28, 0, 0)
            lightText.BackgroundTransparency = 1
            lightText.Text = "SYNC: --"
            lightText.TextColor3 = Color3.fromRGB(150, 160, 190)
            lightText.Font = Enum.Font.GothamBold
            lightText.TextSize = 11
            lightText.TextXAlignment = Enum.TextXAlignment.Left
        
            local valvePosLabel = Instance.new("TextLabel", parent)
            valvePosLabel.Size = UDim2.new(0, btnColW, 0, 20)
            valvePosLabel.Position = UDim2.new(1, -btnColW - 14, 0, 176)
            valvePosLabel.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
            valvePosLabel.BorderSizePixel = 0
            valvePosLabel.Text = "valvePos: 0"
            valvePosLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
            valvePosLabel.Font = Enum.Font.Code
            valvePosLabel.TextSize = 12
            Instance.new("UICorner", valvePosLabel).CornerRadius = UDim.new(0, 4)
        
            return {
                rpmBig = rpmBig, barFill = barFill, barBg = barBg,
                statusVal = statusVal, rpmVal = rpmVal, flowVal = flowVal, vibVal = vibVal,
                autoSyncBtn = autoSyncBtn, autoSyncStroke = autoSyncStroke,
                incBtn = incBtn, decBtn = decBtn,
                lightDot = lightDot, lightText = lightText,
                valvePosLabel = valvePosLabel,
            }
        end
        
        local alphaUI = buildTurbineBlock(alphaBox, "◆ TURBINE ALPHA (1)")
        local betaUI  = buildTurbineBlock(betaBox,  "◆ TURBINE BETA (2)")
        
        local dragging, dragStart, startPos = false, nil, nil
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = panel.Position
            end
        end)
        registerConnection(UserInputService.InputChanged:Connect(function(input)
            if not __APOPP.Running then return end
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        
        registerConnection(UserInputService.InputEnded:Connect(function(input)
            if not __APOPP.Running then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        
        local powerAutoEnabled     = false
        local autoSyncAlphaEnabled = false
        local autoSyncBetaEnabled  = false
        local lastExcess           = nil
        local lastSyncFireAlpha    = 0
        local lastSyncFireBeta     = 0
        local SYNC_RETRY_INTERVAL  = 1.0
        local PREDICT_AHEAD        = 0.3
        local OVERRIDE_HOLD_TIME   = 3.0
        local VIB_LIMIT            = 300
        
        local function tapBetaDec()  pcall(function() fireclickdetector(BetaDecCD)  end) end
        local function tapBetaInc()  pcall(function() fireclickdetector(BetaIncCD)  end) end
        local function tapAlphaDec() pcall(function() fireclickdetector(AlphaDecCD) end) end
        local function tapAlphaInc() pcall(function() fireclickdetector(AlphaIncCD) end) end
        
        local function fireSyncBeta()  pcall(function() fireproximityprompt(BetaSyncPrompt)  end) end
        local function fireSyncAlpha() pcall(function() fireproximityprompt(AlphaSyncPrompt) end) end
        
        local function updatePowerDisplay()
            local v = readPowerValues()
            excessVal.Text = v.excess and string.format("%.2f", v.excess) or "--"
            orderVal.Text  = v.order  and string.format("%.2f", v.order)  or "--"
            marginVal.Text = v.margin and string.format("%.2f", v.margin) or "--"
            holdVal.Text   = v.hold   and string.format("%.2f", v.hold)   or "--"
        
            if v.excess and v.order and v.margin then
                local diff = v.excess - v.order
                if math.abs(diff) <= v.margin then
                    statusLabel.Text = "IN RANGE"
                    statusLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
                elseif diff > 0 then
                    statusLabel.Text = string.format("OVER  +%.2f", diff)
                    statusLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
                else
                    statusLabel.Text = string.format("UNDER  %.2f", diff)
                    statusLabel.TextColor3 = Color3.fromRGB(255, 130, 130)
                end
            else
                statusLabel.Text = "IDLE"
                statusLabel.TextColor3 = Color3.fromRGB(120, 140, 180)
            end
        end
        
        local function updateReactorDisplay()
            local r = readReactorValues()
            tempVal.Text  = r.temperature and string.format("%.1f", r.temperature) or "--"
            feedVal.Text  = (r.feedwater and r.feedwater ~= "") and r.feedwater or "--"
            pressVal.Text = r.pressure and string.format("%.2f", r.pressure) or "--"
            rodVal.Text   = r.rodPct   and string.format("%.1f%%", r.rodPct) or "--"
        end
        
        local function updateTurbineDisplay(ui, vals, statusStr, isBeta)
            local st = normalizeStatus(statusStr)
            ui.statusVal.Text = (statusStr ~= "") and statusStr or "--"
            if st == "SYNCED" then
                ui.statusVal.TextColor3 = Color3.fromRGB(120, 255, 150)
            elseif st == "DESYNCED" then
                ui.statusVal.TextColor3 = Color3.fromRGB(255, 200, 100)
            elseif st == "BROKEN" then
                ui.statusVal.TextColor3 = Color3.fromRGB(255, 100, 100)
            else
                ui.statusVal.TextColor3 = Color3.fromRGB(200, 200, 220)
            end
        
            local rpm = vals.rpm or 0
            ui.rpmBig.Text  = string.format("%.0f", rpm)
            ui.rpmVal.Text  = string.format("%.0f", rpm)
            ui.flowVal.Text = vals.flowRate  and string.format("%.2f", vals.flowRate)  or "--"
            ui.vibVal.Text  = vals.vibration and string.format("%.1f", vals.vibration) or "--"
        
            local pct = math.clamp(rpm / 3600, 0, 1)
            ui.barFill.Size = UDim2.new(0, 130 * pct, 1, 0)
        
            if rpm > 3300 then
                ui.barFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            elseif rpm > 3100 then
                ui.barFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
            else
                ui.barFill.BackgroundColor3 = Color3.fromRGB(120, 220, 255)
            end
        
            if vals.flowRate and (vals.flowRate >= 3.60 and vals.flowRate <= 3.63) then
                ui.flowVal.TextColor3 = Color3.fromRGB(120, 255, 150)
            else
                ui.flowVal.TextColor3 = Color3.fromRGB(160, 220, 255)
            end
        
            if vals.vibration and vals.vibration > 95 then
                ui.vibVal.TextColor3 = Color3.fromRGB(255, 120, 120)
            elseif vals.vibration and vals.vibration > 60 then
                ui.vibVal.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                ui.vibVal.TextColor3 = Color3.fromRGB(120, 255, 150)
            end
        
            local greenLight = isBeta and BetaGreenLight or AlphaGreenLight
            if isGreenReady(greenLight) then
                ui.lightDot.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
                ui.lightText.Text = "SYNC: GREEN ✓"
                ui.lightText.TextColor3 = Color3.fromRGB(120, 255, 150)
            else
                ui.lightDot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                ui.lightText.Text = "SYNC: --"
                ui.lightText.TextColor3 = Color3.fromRGB(150, 160, 190)
            end
        
            local pos = isBeta and readNetOffsetBeta() or readNetOffsetAlpha()
            ui.valvePosLabel.Text = string.format("valvePos: %+d", pos)
        end
        
        local function updateAutoBtn()
            if powerAutoEnabled then
                autoBtn.Text = "POWER AUTO: ON"
                autoBtn.TextColor3 = Color3.fromRGB(120, 255, 150)
                autoBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
                autoStroke.Color = Color3.fromRGB(0, 200, 100)
            else
                autoBtn.Text = "POWER AUTO: OFF"
                autoBtn.TextColor3 = Color3.fromRGB(160, 170, 200)
                autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
                autoStroke.Color = Color3.fromRGB(80, 90, 130)
            end
        end
        
        local function updateAutoSyncBtn(ui, enabled, status)
            if status == "SYNCED" then
                ui.autoSyncBtn.Text = "AUTO SYNC: LOCKED"
                ui.autoSyncBtn.TextColor3 = Color3.fromRGB(110, 110, 130)
                ui.autoSyncBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                ui.autoSyncStroke.Color = Color3.fromRGB(60, 60, 85)
                return
            end
            if enabled then
                ui.autoSyncBtn.Text = "AUTO SYNC: ON"
                ui.autoSyncBtn.TextColor3 = Color3.fromRGB(120, 255, 150)
                ui.autoSyncBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
                ui.autoSyncStroke.Color = Color3.fromRGB(0, 200, 100)
            else
                ui.autoSyncBtn.Text = "AUTO SYNC: OFF"
                ui.autoSyncBtn.TextColor3 = Color3.fromRGB(160, 170, 200)
                ui.autoSyncBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
                ui.autoSyncStroke.Color = Color3.fromRGB(80, 90, 130)
            end
        end
        
        -- ===== POWER AUTO =====
        local function powerAutoTick()
            local v = readPowerValues()
            if not v.excess or not v.order or not v.margin then return end
        
            local diff = v.excess - v.order
            local inRange = math.abs(diff) <= v.margin
        
            local betaVals  = readBetaValues()
            local alphaVals = readAlphaValues()
            local betaVib   = betaVals.vibration  or 0
            local alphaVib  = alphaVals.vibration or 0
            local vibHigh   = (betaVib > VIB_LIMIT) or (alphaVib > VIB_LIMIT)
        
            local targetPos
            if inRange then
                targetPos = 0
            else
                local allowBig = (math.abs(diff) > 3000) and (not vibHigh)
                if diff > 0 then
                    targetPos = allowBig and -2 or -1
                else
                    targetPos = allowBig and 2 or 1
                end
            end
        
            local betaPos = readNetOffsetBeta()
            if betaPos ~= targetPos then
                if betaPos < targetPos then tapBetaInc()
                elseif betaPos > targetPos then tapBetaDec() end
            end
        
            local alphaPos = readNetOffsetAlpha()
            if alphaPos ~= targetPos then
                if alphaPos < targetPos then tapAlphaInc()
                elseif alphaPos > targetPos then tapAlphaDec() end
            end
        
            lastExcess = v.excess
        end
        
        -- ===== AUTO SYNC (flow 到范围强制归零) =====
        local function autoSyncTick(isBeta)
            local enabled = isBeta and autoSyncBetaEnabled or autoSyncAlphaEnabled
            if not enabled then return end
        
            local statusFn = isBeta and readBetaStatus or readAlphaStatus
            local st = statusFn()
        
            if st == "SYNCED" then
                if isBeta then
                    autoSyncBetaEnabled = false
                    updateAutoSyncBtn(betaUI, false, st)
                else
                    autoSyncAlphaEnabled = false
                    updateAutoSyncBtn(alphaUI, false, st)
                end
                return
            end
        
            if st == "BROKEN" then
                if isBeta then tapBetaDec() else tapAlphaDec() end
                return
            end
        
            local vals  = isBeta and readBetaValues() or readAlphaValues()
            local tapI  = isBeta and tapBetaInc or tapAlphaInc
            local tapD  = isBeta and tapBetaDec or tapAlphaDec
            local posFn = isBeta and readNetOffsetBeta or readNetOffsetAlpha
        
            if not vals.flowRate then return end
        
            local vib     = vals.vibration or 0
            local vibHigh = (vib > VIB_LIMIT)
            local flow    = vals.flowRate
            local pos     = posFn()
        
            -- 核心: flow 到 3.60~3.63 无条件把 ValvePos 归零
            if flow >= 3.60 and flow <= 3.63 then
                if pos > 0 then tapD()
                elseif pos < 0 then tapI() end
                return
            end
        
            -- 其他: 把 flow 拉回区间
            local allowBig = (not vibHigh)
            local targetPos
        
            if flow < 3.00 then
                targetPos = allowBig and  2 or  1
            elseif flow < 3.60 then
                targetPos = 1
            elseif flow > 4.00 then
                targetPos = allowBig and -2 or -1
            else
                targetPos = -1
            end
        
            if pos == targetPos then return end
            if pos < targetPos then tapI()
            elseif pos > targetPos then tapD() end
        end
        
        autoBtn.MouseButton1Click:Connect(function()
            powerAutoEnabled = not powerAutoEnabled
            lastExcess = nil
            updateAutoBtn()
        end)
        
        betaUI.autoSyncBtn.MouseButton1Click:Connect(function()
            if readBetaStatus() == "SYNCED" then return end
            autoSyncBetaEnabled = not autoSyncBetaEnabled
            updateAutoSyncBtn(betaUI, autoSyncBetaEnabled, readBetaStatus())
        end)
        
        alphaUI.autoSyncBtn.MouseButton1Click:Connect(function()
            if readAlphaStatus() == "SYNCED" then return end
            autoSyncAlphaEnabled = not autoSyncAlphaEnabled
            updateAutoSyncBtn(alphaUI, autoSyncAlphaEnabled, readAlphaStatus())
        end)
        
        betaUI.decBtn.MouseButton1Click:Connect(function() tapBetaDec() end)
        betaUI.incBtn.MouseButton1Click:Connect(function() tapBetaInc() end)
        alphaUI.decBtn.MouseButton1Click:Connect(function() tapAlphaDec() end)
        alphaUI.incBtn.MouseButton1Click:Connect(function() tapAlphaInc() end)
        
        local CLOSE_HOLD_TIME = 1.0
        local closeHoldStart, closeHoldHandled = nil, false
        
        closeBtn.MouseButton1Down:Connect(function()
            closeHoldStart = tick()
            closeHoldHandled = false
            task.spawn(function()
                while closeHoldStart and (tick() - closeHoldStart) < CLOSE_HOLD_TIME do
                    task.wait(0.05)
                end
                if closeHoldStart and not closeHoldHandled then
                    closeHoldHandled = true
                    closeHoldStart = nil
                    if __APOPP.Stop then
                        __APOPP.Stop()
                    end
                end
            end)
        end)
        
        closeBtn.MouseButton1Up:Connect(function()
            if closeHoldStart and not closeHoldHandled then
                closeHoldStart = nil
                panel.Visible = false
                openBtn.Position = UDim2.new(0, 20, 0, 200)
                openBtn.Visible = true
            end
            closeHoldStart = nil
        end)
        
        openBtn.MouseButton1Click:Connect(function()
            openBtn.Visible = false
            panel.Visible = true
        end)
        
        local overrideArmed = false
        local overrideArmTime = 0
        
        local function resetOverride()
            overrideArmed = false
            overrideBtn.Text = "⚠ MANUAL OVERRIDE"
            overrideBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
            overrideBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
            overrideStroke.Color = Color3.fromRGB(180, 60, 60)
        end
        
        local function destroyAll()
            powerAutoEnabled = false
            autoSyncAlphaEnabled = false
            autoSyncBetaEnabled = false
        
            if __APOPP.Stop then
                __APOPP.Stop()
            end
        
            print("[PowerControl] MANUAL OVERRIDE: 全部逻辑已卸载")
        end
        
        overrideBtn.MouseButton1Click:Connect(function()
            if not overrideArmed then
                overrideArmed = true
                overrideArmTime = tick()
                overrideBtn.Text = "⚠ 再按一次确认 (3s)"
                overrideBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
                overrideBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
                overrideStroke.Color = Color3.fromRGB(255, 80, 80)
            else
                destroyAll()
            end
        end)
        
        task.spawn(function()
            while __APOPP.Running do
                task.wait(0.1)
                if not __APOPP.Running then break end
                if overrideArmed then
                    local elapsed = tick() - overrideArmTime
                    if elapsed >= OVERRIDE_HOLD_TIME then
                        resetOverride()
                    else
                        local remain = math.max(0, OVERRIDE_HOLD_TIME - elapsed)
                        overrideBtn.Text = string.format("⚠ 再按一次确认 (%.1fs)", remain)
                    end
                end
            end
        end)
        
        registerConnection(RunService.RenderStepped:Connect(function(dt)
            if not __APOPP.Running then return end
        
            updatePowerDisplay()
            updateReactorDisplay()
        
            local bv = readBetaValues()
            local av = readAlphaValues()
            updateTurbineDisplay(betaUI,  bv, bv.status, true)
            updateTurbineDisplay(alphaUI, av, av.status, false)
        
            updateAutoSyncBtn(betaUI,  autoSyncBetaEnabled,  readBetaStatus())
            updateAutoSyncBtn(alphaUI, autoSyncAlphaEnabled, readAlphaStatus())
        
            -- Beta fire
            if autoSyncBetaEnabled and readBetaStatus() == "DESYNCED" then
                local rpm = bv.rpm
                if rpm then pushRpm(betaRpmHistory, rpm) end
        
                local rpmLoose = rpm and (rpm >= 2985 and rpm <= 3020)
                local rpmEdge  = rpm and (
                    (rpm >= 2986 and rpm < 2990) or
                    (rpm > 3010 and rpm <= 3014)
                )
        
                local greenReady = isGreenReady(BetaGreenLight)
                local alarmRed   = isAlarmCrimson(BetaAlarmLight)
        
                local canFire   = greenReady and rpmLoose
                local edgeFire  = alarmRed and greenReady and rpmEdge
                local pred      = predictRpm(betaRpmHistory, PREDICT_AHEAD)
                local predictFire = greenReady and pred and pred >= 2990 and pred <= 3010
        
                if canFire or edgeFire or predictFire then
                    local now = tick()
                    if now - lastSyncFireBeta >= SYNC_RETRY_INTERVAL then
                        lastSyncFireBeta = now
                        fireSyncBeta()
                    end
                end
            end
        
            -- Alpha fire
            if autoSyncAlphaEnabled and readAlphaStatus() == "DESYNCED" then
                local rpm = av.rpm
                if rpm then pushRpm(alphaRpmHistory, rpm) end
        
                local rpmLoose = rpm and (rpm >= 2985 and rpm <= 3020)
                local rpmEdge  = rpm and (
                    (rpm >= 2986 and rpm < 2990) or
                    (rpm > 3010 and rpm <= 3014)
                )
        
                local greenReady = isGreenReady(AlphaGreenLight)
                local alarmRed   = isAlarmCrimson(AlphaAlarmLight)
        
                local canFire   = greenReady and rpmLoose
                local edgeFire  = alarmRed and greenReady and rpmEdge
                local pred      = predictRpm(alphaRpmHistory, PREDICT_AHEAD)
                local predictFire = greenReady and pred and pred >= 2990 and pred <= 3010
        
                if canFire or edgeFire or predictFire then
                    local now = tick()
                    if now - lastSyncFireAlpha >= SYNC_RETRY_INTERVAL then
                        lastSyncFireAlpha = now
                        fireSyncAlpha()
                    end
                end
            end
        end))
        
        task.spawn(function()
            while __APOPP.Running do
                task.wait(1.0)
                if not __APOPP.Running then break end
                if powerAutoEnabled then powerAutoTick() end
            end
        end)
        
        task.spawn(function()
            while __APOPP.Running do
                task.wait(0.5)
                if not __APOPP.Running then break end
                if autoSyncBetaEnabled  then autoSyncTick(true)  end
                if autoSyncAlphaEnabled then autoSyncTick(false) end
            end
        end)
        
        updatePowerDisplay()
        updateReactorDisplay()
        updateAutoBtn()
        print("[PowerControl] DUAL TURBINE PANEL loaded")
        
        if __APOPP.Running then
            _G.AutoPowerOrderPlusPlusLoaded = true
            _G.AutoPowerOrderPlusPlusLoadError = nil
        end
        end, function(message)
            local trace = ""
            pcall(function()
                trace = debug.traceback(tostring(message), 2)
            end)
            return trace ~= "" and trace or tostring(message)
        end)

        if not ok then
            controller.Running = false
            _G.AutoPowerOrderPlusPlusLoaded = false
            _G.AutoPowerOrderPlusPlusLoadError = tostring(err)

            if controller.Stop then
                pcall(controller.Stop)
            else
                CleanupAutoPowerOrderPlusPlusUI()
            end

            warn("[AutoPowerOrder++] LOAD ERROR: " .. tostring(err))

            pcall(function()
                if _G.SyntaxNextWindow then
                    _G.SyntaxNextWindow:Notify({
                        Title = "AutoPowerOrder++ 加载失败",
                        Content = tostring(err),
                        Duration = 8,
                    })
                end
            end)
        end
    end)

    return true
end

_G.SyntaxStopAutoPowerOrderPlusPlus = function()
    local controller = _G.__AutoPowerOrderPlusPlusController

    if controller then
        controller.Running = false
        if controller.Stop then
            pcall(controller.Stop)
        end
    end

    CleanupAutoPowerOrderPlusPlusUI()

    _G.AutoPowerOrderPlusPlusLoaded = false
    _G.__AutoPowerOrderPlusPlusController = nil

    return true
end

boot.Stage = "初始化功能引擎"
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
local BreakDeviceAttackMode = "单体攻击"

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
-- Legacy UI pointers are scoped to their maintenance callback below.

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
local fixGCTables, scanAllTools
do -- Private tool-maintenance helpers.
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

fixGCTables = function()
    if not InfAmmoEnabled or type(getgc) ~= "function" then return end
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" then
                patchAmmoTable(v)
            end
        end
    end)
end

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

scanAllTools = function(forceRecheck)
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

do
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:WaitForChild("Backpack", 15)
    if not backpack then error("等待玩家 Backpack 超时，请角色加载完成后再运行", 0) end
    bindAmmoRoot(backpack)
end
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

end -- Private tool-maintenance helpers.

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
-- SECTION 9: CAMERA AIMBOT + CLICK FX

-- ============================================================================
-- WEAPON SHOT ORIGIN · used only by tracer / hitmarker visuals
-- ============================================================================
local function GetWeaponShotOrigin()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")

    if tool then
        local muzzle = tool:FindFirstChild("Muzzle", true)

        if muzzle then
            if muzzle:IsA("Attachment") then
                return muzzle.WorldPosition
            end

            if muzzle:IsA("BasePart") then
                return muzzle.Position
            end
        end

        local handle = tool:FindFirstChild("Handle", true)

        if handle and handle:IsA("BasePart") then
            return handle.Position
        end
    end

    local root =
        char
        and char:FindFirstChild("HumanoidRootPart")

    return root
        and root.Position
        or Camera.CFrame.Position
end

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

end

RunService.RenderStepped:Connect(UpdateAimFovCircles)

-- Hitmarker / rainbow tracer click pipeline.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        and (TracerEnabled or HitmarkerMode > 0) then

        local char = LocalPlayer.Character
        local origin = GetWeaponShotOrigin()

        if origin then
            local destination = nil
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

            -- 彩色弹道只显示当前真实鼠标射线，不再依赖已删除的旧 SilentAim。
            if TracerEnabled then
                DrawNaramoRGBTracer(origin, destination)
            end

            local shouldHitmarker = false
            if rayResult and rayResult.Instance then
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
local CreateChatLogs, SetChatLogsEnabled
do -- Private chat helpers.
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

CreateChatLogs = function()
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

SetChatLogsEnabled = function(enabled)
    ChatLogsEnabled = enabled == true
    CreateChatLogs()
    if ChatLogsFrame then ChatLogsFrame.Visible = ChatLogsEnabled end
end

end -- Private chat helpers.

local function PanicDisableAddedFeatures()
    SetAimbotEnabled(false)
    SetVehicleFlyEnabled(false)
    SetSpinBotEnabled(false)
    SetInstantProximityEnabled(false)
    InfAmmoEnabled = false
    ShowAimbotFOV = false
        SetChatLogsEnabled(false)
    BreakDeviceEnabled = false

    pcall(function()
        local pack = _G.SyntaxImportedFeaturePack
        if pack and pack.StopAll then
            pack:StopAll()
        end
    end)

    if AimbotFovCircle then AimbotFovCircle.Visible = false end
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
    local frame, label, borderGlow, themeBtn
    local hitBtn, sizeBtn, infAmBtn, noclipBtn, brightBtn, ghostBtn, vehicleEspBtn, ventEspBtn, breakableEspBtn
    local rejoinBtn, chamsBtn, infJumpBtn, infStamBtn, zoomBtn, tracerBtn, hitmarkerBtn
    local speedSlider, speedKnob, speedText
    local jumpSlider, jumpKnob, jumpText
    local zoomSlider, zoomKnob, zoomText
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

local function GetBreakDeviceTargets()
    local facility = workspace:FindFirstChild("FacilitySystems")
    local character = LocalPlayer.Character
    if not facility or not character then
        return {}
    end

    local root = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
    if not root then
        return {}
    end

    local targets = {}
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

                    if inRange then
                        table.insert(targets, {
                            Device = device,
                            Hitbox = obj,
                            Distance = distance,
                        })
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        return a.Distance < b.Distance
    end)

    -- 单体攻击保持原行为：只攻击最近目标。
    if BreakDeviceAttackMode ~= "群体攻击" and #targets > 1 then
        for i = #targets, 2, -1 do
            targets[i] = nil
        end
    end

    return targets
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
        local targets = {}

        if event and event:IsA("RemoteEvent") then
            targets = GetBreakDeviceTargets()
        end

        local attacked = 0

        if event and event:IsA("RemoteEvent") then
            for _, target in ipairs(targets) do
                if not BreakDeviceEnabled then
                    break
                end

                local device = target.Device
                local hitbox = target.Hitbox

                if device
                    and device.Parent
                    and device:GetAttribute("Hacked") ~= true
                    and hitbox
                    and hitbox.Parent
                    and FireBreakDevice(hitbox, event) then

                    attacked = attacked + 1
                end
            end
        end

        if attacked > 0 then
            -- 单体：本轮只会有一个目标。
            -- 群体：本轮攻击范围内全部目标，然后统一等待一次攻击间隔。
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
-- IMPORTED SOURCE FEATURES · SAFE / LAZY
-- Based on user-provided 功能.zip.
-- SilentAim and Adonis are runtime-compiled only when requested.
-- ================================================================
boot.Stage = "注册扩展功能";
(function()
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Pack = {
        GlobalBurstEnabled = false,
        VehicleBombardEnabled = false,
        AdonisLoaded = false,
        GlobalBurstConnection = nil,
        VehicleBombardConnection = nil,
    }

    -- ------------------------------------------------------------
    -- INF REC GUN.lua
    -- ------------------------------------------------------------
    local GlobalBurstBuffer = nil

    local function getGlobalBurstBuffer()
        if GlobalBurstBuffer then
            return GlobalBurstBuffer
        end

        if type(buffer) ~= "table"
            or type(buffer.fromstring) ~= "function" then
            return nil
        end

        GlobalBurstBuffer = buffer.fromstring(
            "\a\006\216\134X\195\\B\020\193F1O\194\168\237\172\194\188\170\178C3\022:\197"
        )

        return GlobalBurstBuffer
    end

    local function fireAllBarrels()
        local netRay =
            ReplicatedStorage:FindFirstChild("NetRay_RELIABLE")
        local buf = getGlobalBurstBuffer()

        if not netRay
            or not netRay:IsA("RemoteEvent")
            or not buf then
            return false
        end

        local found = false

        for _, barrel in ipairs(workspace:GetDescendants()) do
            if barrel.Name == "Barrel"
                and barrel:IsA("BasePart") then

                found = true

                pcall(function()
                    netRay:FireServer(
                        buf,
                        {1},
                        {barrel},
                        {}
                    )
                end)
            end
        end

        return found
    end

    function Pack:SetGlobalBurstEnabled(value)
        value = value == true

        if value == self.GlobalBurstEnabled then
            return true
        end

        self.GlobalBurstEnabled = value

        if self.GlobalBurstConnection then
            self.GlobalBurstConnection:Disconnect()
            self.GlobalBurstConnection = nil
        end

        if self.GlobalBurstEnabled then
            self.GlobalBurstConnection =
                RunService.RenderStepped:Connect(function()
                    if Pack.GlobalBurstEnabled then
                        fireAllBarrels()
                    end
                end)
        end

        return true
    end

    function Pack:FireGlobalBurstOnce()
        return fireAllBarrels()
    end

    -- ------------------------------------------------------------
    -- 载具摧毁.lua
    -- ------------------------------------------------------------
    local originShotPos =
        Vector3.new(
            -188.93150329589844,
            146.36265563964844,
            24.09722137451172
        )

    local shotDir =
        Vector3.new(
            0.3305094540119171,
            0.7066996097564697,
            0.625571072101593
        )

    local baseHitbox =
        Vector3.new(
            12.100074768066406,
            7.865014553070068,
            4.840036869049072
        )

    local dmgMul = 1

    local function getDamageRemote()
        local services =
            ReplicatedStorage:FindFirstChild("TREK_SERVICES")
        local remotes =
            services and services:FindFirstChild("TREK_Remotes")
        local remote =
            remotes and remotes:FindFirstChild("Damage")

        if remote and remote:IsA("RemoteEvent") then
            return remote
        end

        return nil
    end

    local function getPriorityPart(bodyObj)
        local priority = {
            "TurretRing",
            "Weakspot",
            "Weakspots",
            "Back",
            "Sides",
        }

        for _, name in ipairs(priority) do
            local part = bodyObj:FindFirstChild(name)

            if part and part:IsA("BasePart") then
                return part
            end
        end

        local pool = {}

        local function scan(obj)
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BasePart") then
                    table.insert(pool, child)
                end

                scan(child)
            end
        end

        scan(bodyObj)

        if #pool > 0 then
            return pool[math.random(1, #pool)]
        end

        return nil
    end

    local function sendAllVehicleDamage()
        local remote = getDamageRemote()
        local vehicleFolder =
            workspace:FindFirstChild("TVehicles")

        if not remote or not vehicleFolder then
            return false
        end

        local attacked = 0

        for _, vehicleRoot in ipairs(
            vehicleFolder:GetChildren()
        ) do
            local vehicle =
                vehicleRoot:FindFirstChild("TVehicle")
            local body =
                vehicle and vehicle:FindFirstChild("Body")

            if body then
                local target = getPriorityPart(body)

                if target then
                    local args = {
                        target.Position,
                        target,
                        baseHitbox,
                        dmgMul,
                        originShotPos,
                        shotDir,
                    }

                    local ok = pcall(function()
                        remote:FireServer(table.unpack(args))
                    end)

                    if ok then
                        attacked = attacked + 1
                    end
                end
            end
        end

        return attacked > 0
    end

    function Pack:SendVehicleDamageOnce()
        return sendAllVehicleDamage()
    end

    function Pack:SetVehicleBombardEnabled(value)
        value = value == true

        if value == self.VehicleBombardEnabled then
            return true
        end

        self.VehicleBombardEnabled = value

        if self.VehicleBombardConnection then
            self.VehicleBombardConnection:Disconnect()
            self.VehicleBombardConnection = nil
        end

        if self.VehicleBombardEnabled then
            self.VehicleBombardConnection =
                RunService.RenderStepped:Connect(function()
                    if Pack.VehicleBombardEnabled then
                        sendAllVehicleDamage()
                    end
                end)
        end

        return true
    end

    -- ------------------------------------------------------------
    -- Lazy source loaders
    -- ------------------------------------------------------------
    local SilentAimSource = [====[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- 核心配置
local Settings = {
    AIM_ENABLED = false,
    TEAM_CHECK = true,
    WALL_CHECK = true,
    TRACK_ENABLED = false,
    TRACK_CHANCE = 85,
    FOV_ENABLED = false,
    FOV_RADIUS = 160,
    TARGET_PART = "Head",
    AIM_MODE = "TP",
    LIMBS_PARTS = {"Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    TARGET_TYPE = "PLAYER",
    HIGHLIGHT_ENABLED = false,
    RCV_MODE = false,
    VEHICLE_MODE = false,
    TEAM_VEHICLE_MONITOR = false
}

local AmmoTypeMap = {
    ["1"] = "AP/APDS",
    ["96"] = "MG/HEAT"
}

local DestroyStatusList = {
    "[DESTROYED]"
}

local CurrentTarget = nil
local oldNamecall = nil
local ViewportSize = Camera.ViewportSize
local ScreenCenter = Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)
local HighlightCache = {}
local RandomPartCache = setmetatable({}, {__mode = "k"})
local UI_Destroyed = false
local heartbeatConn
local currentVehicleId = nil
local lastVehicleHealth = 0
local vehicleDamageCache = {}

-- Probability miss is cached briefly so multiple Raycast calls generated by
-- the same shot share one decision instead of rolling independently.
local TrackDecisionUntil = 0
local TrackDecisionValue = false

local TeamVehiclePanel = nil
local TeamVehicleLayout = nil
local TeamVehicleScrollFrame = nil
local TeamVehicleFrameCache = {}
local DestroyedVehicleTimeout = {}
local GlobalVehicleNotifyMark = {}
local EnemyVehicleNotifyMark = {}
local VehicleFixedDestroyText = {}

local isDragging = false
local dragStartMouse = Vector2.new(0,0)
local panelStartUDim = UDim2.new(0,0,0,0)

-- ==============================================================================
-- >> [NPC] NPC 缓存（避免每帧扫全图）
-- ==============================================================================

local NPCCache = {}
local NPCList = {}

local function RebuildNPCCache()
    local newCache = {}
    local newList = {}
    for _, ent in ipairs(workspace:GetDescendants()) do
        if ent:IsA("Model") then
            local hum = ent:FindFirstChildOfClass("Humanoid")
            if hum then
                local owner = Players:GetPlayerFromCharacter(ent)
                if not owner and hum.Health > 0 and not ent:FindFirstChild("ForceField") then
                    newCache[ent] = true
                    table.insert(newList, ent)
                end
            end
        end
    end
    NPCCache = newCache
    NPCList = newList
end

RebuildNPCCache()

task.spawn(function()
    while task.wait(1) do
        if UI_Destroyed then break end
        if Settings.TARGET_TYPE == "NPC" or Settings.TARGET_TYPE == "BOTH" then
            RebuildNPCCache()
        end
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if UI_Destroyed then return end
    if not obj:IsA("Model") then return end
    task.defer(function()
        if UI_Destroyed then return end
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum and not Players:GetPlayerFromCharacter(obj) then
            NPCCache[obj] = true
            table.insert(NPCList, obj)
        end
    end)
end)

workspace.DescendantRemoving:Connect(function(obj)
    if not obj:IsA("Model") then return end
    if NPCCache[obj] then
        NPCCache[obj] = nil
    end
end)

-- ==============================================================================

local function ClampPanelPosition(pos, panelSize)
    local screenX = Camera.ViewportSize.X
    local screenY = Camera.ViewportSize.Y
    local newX = math.clamp(pos.X.Offset, 0, screenX - panelSize.X)
    local newY = math.clamp(pos.Y.Offset, 0, screenY - panelSize.Y)
    return UDim2.new(pos.X.Scale, newX, pos.Y.Scale, newY)
end

local function GetFixedDestroyStatus(vehUniqueId)
    if VehicleFixedDestroyText[vehUniqueId] then
        return VehicleFixedDestroyText[vehUniqueId]
    end
    local randomIndex = math.random(1, #DestroyStatusList)
    local fixedText = DestroyStatusList[randomIndex]
    VehicleFixedDestroyText[vehUniqueId] = fixedText
    return fixedText
end

local function GetActiveCamera()
    local current = workspace.CurrentCamera
    if current then
        Camera = current
    end
    return Camera
end

local function RefreshViewportState()
    local cam = GetActiveCamera()
    if not cam then return end
    ViewportSize = cam.ViewportSize
    ScreenCenter = Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)
end

local function GetAimScreenPoint()
    local cam = GetActiveCamera()
    if not cam then
        return ScreenCenter
    end

    -- PC: FOV/target selection follows the actual mouse cursor.
    if UserInputService.MouseEnabled then
        local mouse = UserInputService:GetMouseLocation()
        return Vector2.new(
            math.clamp(mouse.X, 0, cam.ViewportSize.X),
            math.clamp(mouse.Y, 0, cam.ViewportSize.Y)
        )
    end

    -- Touch/gamepad fallback keeps the old center-screen behavior.
    return Vector2.new(
        cam.ViewportSize.X / 2,
        cam.ViewportSize.Y / 2
    )
end

local function GetScreenDistance(position)
    local cam = GetActiveCamera()
    if not cam then
        return math.huge, false, nil
    end

    local screenPos, onScreen = cam:WorldToViewportPoint(position)
    if not onScreen or screenPos.Z <= 0 then
        return math.huge, false, nil
    end

    local pos2D = Vector2.new(screenPos.X, screenPos.Y)
    local aimPoint = GetAimScreenPoint()
    return (pos2D - aimPoint).Magnitude, true, pos2D
end

local function GetVisibilityRoot(hitPart, candidate)
    if not hitPart then
        return candidate
    end

    -- Vehicle mode: accept any part of the same TVehicle as visible.
    local current = hitPart
    while current do
        if current:IsA("Model")
            and current.Name == "TVehicle" then
            return current
        end

        current = current.Parent
    end

    -- Player/NPC: use the humanoid character model.
    current = hitPart
    while current do
        if current:IsA("Model")
            and current:FindFirstChildOfClass("Humanoid") then
            return current
        end

        current = current.Parent
    end

    if candidate and candidate:IsA("Model") then
        return candidate
    end

    return hitPart.Parent
end

local function IsSilentAimTargetVisible(hitPart, candidate)
    if not Settings.WALL_CHECK then
        return true
    end

    if not hitPart
        or not hitPart.Parent then
        return false
    end

    local cam = GetActiveCamera()
    if not cam then
        return false
    end

    local origin = cam.CFrame.Position
    local direction = hitPart.Position - origin

    if direction.Magnitude <= 0.01 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local exclusions = {}
    if LocalPlayer.Character then
        table.insert(exclusions, LocalPlayer.Character)
    end
    params.FilterDescendantsInstances = exclusions

    local result =
        workspace:Raycast(
            origin,
            direction,
            params
        )

    if not result then
        return true
    end

    if result.Instance == hitPart then
        return true
    end

    local visibilityRoot =
        GetVisibilityRoot(
            hitPart,
            candidate
        )

    return visibilityRoot ~= nil
        and result.Instance:IsDescendantOf(
            visibilityRoot
        )
end

local function ShouldTrackSilentAimShot()
    -- Probability tracking is opt-in. When disabled, SilentAim behaves
    -- exactly like the normal 100% tracking mode.
    if not Settings.TRACK_ENABLED then
        return true
    end

    local chance =
        math.clamp(
            tonumber(Settings.TRACK_CHANCE) or 0,
            0,
            100
        )

    if chance <= 0 then
        return false
    end

    if chance >= 100 then
        return true
    end

    local now = os.clock()

    if now >= TrackDecisionUntil then
        -- One cached roll for the short cluster of Raycasts generated by
        -- a single shot. This avoids different pellets/internal checks
        -- randomly switching between tracked and untracked state.
        TrackDecisionUntil = now + 0.075
        TrackDecisionValue =
            math.random(1,10000)
            <= math.floor(chance * 100)
    end

    return TrackDecisionValue
end

RefreshViewportState()

if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if UI_Destroyed then return end
        RefreshViewportState()
    end)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if UI_Destroyed then return end
    RefreshViewportState()
end)

local function GetVehicleTeamName(vehModel)
    if not vehModel then return "" end
    local statsFolder = vehModel:FindFirstChild("Stats")
    if not statsFolder then return "" end
    local teamObj = statsFolder:FindFirstChild("Team")
    if teamObj then
        if teamObj.ClassName == "ObjectValue" and teamObj.Value then
            return teamObj.Value.Name
        end
        if teamObj.ClassName == "StringValue" then
            return teamObj.Value
        end
    end
    return ""
end

local function GetVehicleStats(tVehicle)
    local destroyed = false
    local health = 0
    local teamName = ""
    if not tVehicle then
        return destroyed, health, teamName
    end
    local statsFolder = tVehicle:FindFirstChild("Stats")
    if statsFolder then
        local destroyedVal = statsFolder:FindFirstChild("Destroyed")
        if destroyedVal and destroyedVal.ClassName == "BoolValue" then
            destroyed = destroyedVal.Value
        end
        local healthVal = statsFolder:FindFirstChild("Health")
        if healthVal then
            if healthVal.ClassName == "NumberValue" or healthVal.ClassName == "DoubleConstrainedValue" then
                health = healthVal.Value
            end
        end
        teamName = GetVehicleTeamName(tVehicle)
    end
    return destroyed, health, teamName
end

local function GetVehicleAmmoData(tVehicle)
    local ammoData = {}
    local ammoRoot = tVehicle:FindFirstChild("TAmmo")
    if not ammoRoot then return ammoData end
    for ammoFolderName,ammoDesc in pairs(AmmoTypeMap) do
        local ammoFolder = ammoRoot:FindFirstChild(tostring(ammoFolderName))
        if ammoFolder then
            local ammoValObj = ammoFolder:FindFirstChild("Ammo")
            if ammoValObj and ammoValObj.ClassName == "DoubleConstrainedValue" then
                table.insert(ammoData,{
                    TypeName = ammoDesc,
                    Count = math.floor(ammoValObj.Value)
                })
            end
        end
    end
    return ammoData
end

local function GetEnemyAmmoShowText(ammoList)
    local strTab = {}
    for _,ammo in ipairs(ammoList) do
        table.insert(strTab,string.format("%s:%d发",ammo.TypeName,ammo.Count))
    end
    return #strTab>0 and table.concat(strTab," | ") or "无弹药"
end

local function GlobalCheckTeamVehicleDestroy()
    if UI_Destroyed or not Settings.AIM_ENABLED then return end
    local localTeam = LocalPlayer.Team.Name
    local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then return end
    local vehFolder = workspace:FindFirstChild("TVehicles")
    if not vehFolder then return end
    for _,rootVeh in ipairs(vehFolder:GetChildren()) do
        if not rootVeh:IsA("Model")then continue end
        local tVeh = rootVeh:FindFirstChild("TVehicle")
        if not tVeh then continue end
        local isDestroyed,_,vehTeam = GetVehicleStats(tVeh)
        local vehId = rootVeh:GetDebugId()
        local vehPos = tVeh:GetPivot().Position
        local dist = math.floor((vehPos - playerRoot.Position).Magnitude)

        if vehTeam == localTeam and isDestroyed and not GlobalVehicleNotifyMark[vehId] then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "己方损失",
                Text = string.format("[%s] 已被摧毁，距离：%d", rootVeh.Name, dist),
                Duration = 5
            })
            GlobalVehicleNotifyMark[vehId] = true
        end

        if vehTeam ~= localTeam and isDestroyed and not EnemyVehicleNotifyMark[vehId] then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "确认击毁",
                Text = string.format("[%s]已被击毁，确认无效化，距离：%d", rootVeh.Name, dist),
                Duration = 5
            })
            EnemyVehicleNotifyMark[vehId] = true
        end
    end
end
RunService.RenderStepped:Connect(GlobalCheckTeamVehicleDestroy)

local function FindCharacterPart(char, partName)
    if not char or UI_Destroyed then return nil end
    local part = char:FindFirstChild(partName)
    if not part then
        part = char:FindFirstChild(partName:gsub(" ", ""))
    end
    return part
end

local function IsInFOV(position)
    if UI_Destroyed then return false end
    local screenDistance, onScreen = GetScreenDistance(position)
    return onScreen and screenDistance <= Settings.FOV_RADIUS
end

local function AddAimPart(list, seen, part)
    if part and part:IsA("BasePart") and not seen[part] then
        seen[part] = true
        table.insert(list, part)
    end
end

local function AddCharacterPartNames(char, list, seen, names)
    for _, name in ipairs(names) do
        AddAimPart(list, seen, FindCharacterPart(char, name))
    end
end

local function GetCharacterCandidateParts(char, mode)
    local list = {}
    local seen = {}

    if mode == "Head" then
        AddCharacterPartNames(char, list, seen, {"Head"})

    elseif mode == "HumanoidRootPart" then
        AddCharacterPartNames(char, list, seen, {
            "HumanoidRootPart",
            "UpperTorso",
            "Torso",
            "LowerTorso",
        })

    elseif mode == "SURR" then
        AddCharacterPartNames(char, list, seen, {
            "RightHand",
            "RightLowerArm",
            "RightUpperArm",
            "Right Arm",
        })

    elseif mode == "LIMBS" then
        AddCharacterPartNames(char, list, seen, {
            -- R6
            "Left Arm", "Right Arm", "Left Leg", "Right Leg",
            -- R15 arms
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            -- R15 legs
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot",
        })

    elseif mode == "RANDOM" then
        AddCharacterPartNames(char, list, seen, {
            "Head",
            "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso",
            "Left Arm", "Right Arm", "Left Leg", "Right Leg",
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot",
        })

    else
        AddCharacterPartNames(char, list, seen, {mode})
    end

    return list
end

local function GetClosestPartToAim(parts, requireFOV, visibilityRoot)
    local bestPart = nil
    local bestScreenDistance = math.huge
    local aimRadius = Settings.FOV_RADIUS

    for _, part in ipairs(parts) do
        if part and part.Parent then
            local screenDistance, onScreen = GetScreenDistance(part.Position)

            if onScreen
                and (not requireFOV or screenDistance <= aimRadius)
                and IsSilentAimTargetVisible(part, visibilityRoot)
                and screenDistance < bestScreenDistance then

                bestScreenDistance = screenDistance
                bestPart = part
            end
        end
    end

    return bestPart, bestScreenDistance
end

local function GetTargetPart(char)
    if not char or UI_Destroyed then return nil end

    local mode = Settings.TARGET_PART
    local candidates = GetCharacterCandidateParts(char, mode)

    if #candidates == 0 then
        return nil
    end

    -- RANDOM stays random, but is now stable instead of changing every Heartbeat.
    -- It re-rolls only when the cached part is gone or leaves the current mouse FOV.
    if mode == "RANDOM" then
        local cached = RandomPartCache[char]

        if cached
            and cached.Parent
            and IsInFOV(cached.Position)
            and IsSilentAimTargetVisible(cached, char) then
            return cached
        end

        local inFov = {}
        for _, part in ipairs(candidates) do
            if IsInFOV(part.Position)
                and IsSilentAimTargetVisible(part, char) then

                table.insert(inFov, part)
            end
        end

        if #inFov == 0 and Settings.WALL_CHECK then
            RandomPartCache[char] = nil
            return nil
        end

        local pool =
            #inFov > 0
            and inFov
            or candidates

        local picked =
            pool[math.random(1, #pool)]

        RandomPartCache[char] = picked
        return picked
    end

    -- LIMBS / right-arm / body variants choose the part nearest the mouse.
    -- This keeps target-part selection consistent with the moving PC FOV.
    local closest =
        GetClosestPartToAim(
            candidates,
            false,
            char
        )

    return closest or candidates[1]
end

local function CreateHighlight(obj)
    if not Settings.HIGHLIGHT_ENABLED or not obj or UI_Destroyed then return end
    if HighlightCache[obj] then return HighlightCache[obj] end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.new(1,0,0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1,1,0)
    highlight.OutlineTransparency = 0
    highlight.Parent = obj
    HighlightCache[obj] = highlight
    return highlight
end

local function ClearAllHighlights()
    for obj,hl in pairs(HighlightCache) do
        pcall(function() hl:Destroy() end)
    end
    table.clear(HighlightCache)
end

local function UpdateSingleHighlight(obj)
    if not Settings.HIGHLIGHT_ENABLED or not obj then
        if next(HighlightCache) ~= nil then
            ClearAllHighlights()
        end
        return
    end

    for cachedObj, hl in pairs(HighlightCache) do
        if cachedObj ~= obj then
            pcall(function() hl:Destroy() end)
            HighlightCache[cachedObj] = nil
        end
    end

    if not HighlightCache[obj] then
        CreateHighlight(obj)
    end
end

local function GetRCVArmorModel()
    local vehFolder = workspace:FindFirstChild("TVehicles")
    if not vehFolder then return nil end
    local rcv = vehFolder:FindFirstChild("RCV-1")
    if not rcv then return nil end
    local tVeh = rcv:FindFirstChild("TVehicle")
    if not tVeh then return nil end
    local barrel = tVeh:FindFirstChild("DecorBarrel")
    if not barrel then return nil end
    local armor = barrel:FindFirstChild("Armor")
    if armor and armor:IsA("Model") then
        return armor
    end
    return nil
end

local function GetLocalDrivingVehicle()
    local char = LocalPlayer.Character
    if not char then return nil end
    local human = char:FindFirstChildOfClass("Humanoid")
    if not human or not human.Sit then return nil end
    local seat = human.SeatPart
    if seat.Name ~= "DriverSeat" then return nil end
    local current = seat
    local targetVeh = nil
    while current do
        if current.Name == "TVehicle" and current:IsA("Model") then
            targetVeh = current
            break
        end
        current = current.Parent
    end
    return targetVeh
end

local function GetModelAttributes(mod)
    local resist = mod:GetAttribute("ArmorDamageResist")
    local reqDmg = mod:GetAttribute("RequiredArmourDamage")
    local r = type(resist)=="number" and resist or math.huge
    local d = type(reqDmg)=="number" and reqDmg or math.huge
    return r,d
end

local function IsValidTargetModel(mod)
    local nameLower = mod.Name:lower()
    if nameLower == "front" or nameLower == "armor" then
        return false
    end
    local hasResist = mod:GetAttribute("ArmorDamageResist") ~= nil
    local hasReqDmg = mod:GetAttribute("RequiredArmourDamage") ~= nil
    if not hasResist and not hasReqDmg then
        return false
    end
    local cur = mod
    while cur do
        if cur.Name == "SystemParts" then
            return hasResist or hasReqDmg
        end
        cur = cur.Parent
    end
    return true
end

local function GetPartPriority(mod)
    local name = mod.Name:lower()
    if name == "turretring" or name == "weakspots" or name == "weakspot" then
        return 1
    elseif name == "back" then
        return 2
    end
    return 3
end

local function ScanAllValidModels(root,excludeVeh)
    local list = {}
    local function scan(obj)
        if obj:IsA("Model") then
            if excludeVeh and obj:IsDescendantOf(excludeVeh) then return end
            if IsValidTargetModel(obj) then
                table.insert(list,obj)
            end
            for _,child in ipairs(obj:GetChildren()) do
                scan(child)
            end
        end
    end
    scan(root)
    return list
end

local VehicleModelPartCache = setmetatable({}, {__mode = "k"})
local VEHICLE_MODEL_PART_CACHE_SECONDS = 0.75

local function GetModelPart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end

    local candidates = nil

    if Settings.VEHICLE_MODE then
        local now = os.clock()
        local cached = VehicleModelPartCache[model]

        if cached and now < cached.ExpiresAt then
            candidates = cached.Parts
        else
            candidates = {}

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(candidates, part)
                end
            end

            VehicleModelPartCache[model] = {
                Parts = candidates,
                ExpiresAt = now + VEHICLE_MODEL_PART_CACHE_SECONDS,
            }
        end
    else
        candidates = {}

        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(candidates, part)
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    if Settings.VEHICLE_MODE then
        -- Vehicle models can contain a very large number of BaseParts.
        -- Do not Raycast every part here: FindBestTarget performs one final
        -- visibility check after this fast screen-space selection.
        local closest = nil
        local closestDistance = math.huge

        for _, part in ipairs(candidates) do
            if part and part.Parent then
                local screenDistance, onScreen =
                    GetScreenDistance(part.Position)

                if onScreen
                    and screenDistance < closestDistance then
                    closestDistance = screenDistance
                    closest = part
                end
            end
        end

        if closest then
            return closest
        end
    else
        local closest =
            GetClosestPartToAim(
                candidates,
                false,
                model
            )

        if closest then
            return closest
        end
    end

    if Settings.WALL_CHECK then
        return nil
    end

    for _, part in ipairs(candidates) do
        if part and part.Parent then
            return part
        end
    end

    return nil
end
local function GetRootTVehicle(obj)
    local cur = obj
    while cur do
        if cur.Name == "TVehicle" and cur:IsA("Model") then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

local function GetTopVehicleModel(tVehicle)
    local cur = tVehicle
    while cur do
        if cur.Parent and cur.Parent.Name == "TVehicles" then
            return cur
        end
        cur = cur.Parent
    end
    return cur
end

local VehicleTargetPoolCache = {}
local VehicleTargetPoolCacheUntil = 0
local VehicleTargetPoolCacheTeamCheck = nil
local VehicleTargetPoolCacheTeamName = nil
local NextVehicleTargetRefresh = 0
local VEHICLE_POOL_CACHE_SECONDS = 0.75
local VEHICLE_RESELECT_SECONDS = 0.12

local function InvalidateVehicleTargetCache()
    VehicleTargetPoolCache = {}
    VehicleTargetPoolCacheUntil = 0
    VehicleTargetPoolCacheTeamCheck = nil
    VehicleTargetPoolCacheTeamName = nil
    NextVehicleTargetRefresh = 0
end

local function GetSortedVehicleTargets()
    local now = os.clock()
    local playerTeamName =
        LocalPlayer.Team
        and LocalPlayer.Team.Name
        or ""

    if now < VehicleTargetPoolCacheUntil
        and VehicleTargetPoolCacheTeamCheck == Settings.TEAM_CHECK
        and VehicleTargetPoolCacheTeamName == playerTeamName then

        return VehicleTargetPoolCache
    end

    local driveVeh = GetLocalDrivingVehicle()
    local targetPool = {}
    local vehFolder = workspace:FindFirstChild("TVehicles")

    if not vehFolder then
        VehicleTargetPoolCache = targetPool
        VehicleTargetPoolCacheUntil = now + 0.25
        VehicleTargetPoolCacheTeamCheck = Settings.TEAM_CHECK
        VehicleTargetPoolCacheTeamName = playerTeamName
        return targetPool
    end

    for _, vehRoot in ipairs(vehFolder:GetChildren()) do
        if not vehRoot:IsA("Model") then
            continue
        end

        local tVeh = vehRoot:FindFirstChild("TVehicle")
        if not tVeh or not tVeh:IsA("Model") then
            continue
        end

        local isDestroyed, _, vehTeam = GetVehicleStats(tVeh)
        if isDestroyed then
            continue
        end

        if Settings.TEAM_CHECK
            and playerTeamName ~= ""
            and vehTeam == playerTeamName then
            continue
        end

        if driveVeh and tVeh:IsDescendantOf(driveVeh) then
            continue
        end

        local highPriorityList = {}

        local function findHighPart(obj)
            local n = obj.Name:lower()

            if n == "turretring"
                or n == "weakspots"
                or n == "weakspot" then
                table.insert(highPriorityList, obj)
            end

            for _, child in ipairs(obj:GetChildren()) do
                findHighPart(child)
            end
        end

        findHighPart(tVeh)

        if #highPriorityList > 0 then
            table.sort(highPriorityList, function(a, b)
                local ra, da = GetModelAttributes(a)
                local rb, db = GetModelAttributes(b)
                if ra ~= rb then
                    return ra < rb
                end
                return da < db
            end)

            for _, v in ipairs(highPriorityList) do
                table.insert(targetPool, v)
            end

            continue
        end

        local validParts = ScanAllValidModels(tVeh, driveVeh)
        for _, v in ipairs(validParts) do
            table.insert(targetPool, v)
        end
    end

    table.sort(targetPool, function(a, b)
        local pa = GetPartPriority(a)
        local pb = GetPartPriority(b)

        if pa ~= pb then
            return pa < pb
        end

        local ra, da = GetModelAttributes(a)
        local rb, db = GetModelAttributes(b)

        if ra ~= rb then
            return ra < rb
        end

        return da < db
    end)

    VehicleTargetPoolCache = targetPool
    VehicleTargetPoolCacheUntil = now + VEHICLE_POOL_CACHE_SECONDS
    VehicleTargetPoolCacheTeamCheck = Settings.TEAM_CHECK
    VehicleTargetPoolCacheTeamName = playerTeamName

    return VehicleTargetPoolCache
end

local function FindBestTarget()
    if UI_Destroyed then return nil end

    local char = LocalPlayer.Character
    if not char then return nil end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
    if not rootPart then return nil end

    local myTeam = LocalPlayer.Team
    local targetList = {}

    if Settings.RCV_MODE then
        local armor = GetRCVArmorModel()
        if armor then
            table.insert(targetList, armor)
        end

    elseif Settings.VEHICLE_MODE then
        targetList = GetSortedVehicleTargets()

    else
        if Settings.TARGET_TYPE == "PLAYER"
            or Settings.TARGET_TYPE == "BOTH" then

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local c = plr.Character
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    local shield = c:FindFirstChild("ForceField")

                    if hum and hum.Health > 0 and not shield then
                        table.insert(targetList, c)
                    end
                end
            end
        end

        if Settings.TARGET_TYPE == "NPC"
            or Settings.TARGET_TYPE == "BOTH" then

            for i = 1, #NPCList do
                local ent = NPCList[i]

                if ent.Parent then
                    local hum = ent:FindFirstChildOfClass("Humanoid")

                    if hum
                        and hum.Health > 0
                        and not ent:FindFirstChild("ForceField") then
                        table.insert(targetList, ent)
                    end
                end
            end
        end
    end

    local bestTarget = nil
    local bestPriority = math.huge
    local bestScreenDistance = math.huge
    local bestWorldDistance = math.huge

    for _, target in ipairs(targetList) do
        local hitPart

        if Settings.RCV_MODE or Settings.VEHICLE_MODE then
            hitPart = GetModelPart(target)
        else
            hitPart = GetTargetPart(target)
        end

        if not hitPart or not hitPart.Parent then
            continue
        end

        local owner = Players:GetPlayerFromCharacter(target)

        if Settings.TEAM_CHECK
            and owner
            and myTeam
            and owner.Team == myTeam then
            continue
        end

        local screenDistance, onScreen = GetScreenDistance(hitPart.Position)

        if not onScreen or screenDistance > Settings.FOV_RADIUS then
            continue
        end

        if not IsSilentAimTargetVisible(hitPart, target) then
            continue
        end

        local worldDistance = (hitPart.Position - rootPart.Position).Magnitude
        local priority = 0

        -- Preserve the source's vehicle weak-spot priority, then use mouse
        -- proximity inside that priority. Player/NPC mode is pure cursor-nearest.
        if Settings.VEHICLE_MODE and target:IsA("Model") then
            priority = GetPartPriority(target)
        end

        local better = false

        if priority < bestPriority then
            better = true
        elseif priority == bestPriority then
            if screenDistance < bestScreenDistance - 0.01 then
                better = true
            elseif math.abs(screenDistance - bestScreenDistance) <= 0.01
                and worldDistance < bestWorldDistance then
                better = true
            end
        end

        if better then
            bestPriority = priority
            bestScreenDistance = screenDistance
            bestWorldDistance = worldDistance
            bestTarget = hitPart
        end
    end

    UpdateSingleHighlight(
        bestTarget
        and bestTarget.Parent
        or nil
    )

    return bestTarget
end

local function StartHeartbeat()
    if heartbeatConn then return end

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if UI_Destroyed then
            heartbeatConn:Disconnect()
            heartbeatConn = nil
            return
        end

        if Settings.AIM_ENABLED then
            if Settings.VEHICLE_MODE then
                local now = os.clock()

                -- Vehicle target discovery is expensive: it walks TVehicles,
                -- scans weak spots/models, sorts them, then performs visibility
                -- checks. Re-select at a controlled rate while the shooting hook
                -- continues to use the most recent CurrentTarget every frame.
                if now >= NextVehicleTargetRefresh then
                    NextVehicleTargetRefresh =
                        now + VEHICLE_RESELECT_SECONDS

                    CurrentTarget = FindBestTarget()
                end
            else
                NextVehicleTargetRefresh = 0
                CurrentTarget = FindBestTarget()
            end
        else
            CurrentTarget = nil
            NextVehicleTargetRefresh = 0
            ClearAllHighlights()
        end
    end)
end
StartHeartbeat()

-- V35 PROBABILITY TRACKING
-- The old "probability miss" implementation redirected the weapon's native
-- Raycast. Some weapons use their first Raycast result to advance internal
-- firing/cooldown state, so a redirected first shot could break later shots.
--
-- Probability tracking never modifies an unselected shot. If the roll fails,
-- the original Raycast is executed with the exact original arguments.
local TrackAppliedCount = 0
local TrackSkippedCount = 0

local function SetupHook()
    if oldNamecall or UI_Destroyed then return end

    oldNamecall = hookmetamethod(game,"__namecall",function(self,...)
        local method = getnamecallmethod()
        local args = {...}

        if method ~= "Raycast"
            or checkcaller()
            or UI_Destroyed then

            return oldNamecall(self,...)
        end

        if Settings.AIM_ENABLED
            and CurrentTarget
            and #args >= 2 then

            local origin = args[1]
            local dirVec = args[2]
            local param = args[3]

            if typeof(origin) ~= "Vector3"
                or typeof(dirVec) ~= "Vector3" then

                return oldNamecall(self,...)
            end

            -- Not selected for tracking: do absolutely nothing to the
            -- weapon's ray. This is the safe 0%-100% probability behavior.
            if not ShouldTrackSilentAimShot() then
                TrackSkippedCount += 1
                return oldNamecall(self,...)
            end

            local length = dirVec.Magnitude
            local targetDelta = CurrentTarget.Position - origin

            if length <= 0.001
                or targetDelta.Magnitude <= 0.001 then

                return oldNamecall(self,...)
            end

            TrackAppliedCount += 1

            local aimDir =
                targetDelta.Unit * length

            if Settings.AIM_MODE == "TP" then
                -- Preserve the existing V34 TP behavior only on shots that
                -- were selected by probability tracking.
                return {
                    Instance = CurrentTarget,
                    Position = CurrentTarget.Position,
                    Normal = (origin - CurrentTarget.Position).Unit,
                    Material = Enum.Material.Plastic,
                    Distance = targetDelta.Magnitude
                }
            end

            -- DIRECT mode: only the selected shots are redirected.
            return oldNamecall(
                self,
                origin,
                aimDir,
                param
            )
        end

        return oldNamecall(self,...)
    end)
end
SetupHook()

-- V35 · TARGETHUD ANIMATION + VEHICLE OPT + SAFE PROBABILITY TRACKING
-- UI创建 · V32 hard-parent fix
-- V31 swallowed Parent assignment failures inside pcall(). In that case the
-- ScreenGui object existed, but Parent stayed nil, so every child GUI was invisible.
local ScreenGui

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "AimLockUI"
    gui.ResetOnSpawn = false
    gui.Enabled = true
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder = 1000000

    local candidates = {}
    local seen = {}

    local function addCandidate(parent)
        if parent and not seen[parent] then
            seen[parent] = true
            table.insert(candidates, parent)
        end
    end

    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok then
            addCandidate(hui)
        end
    end

    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then
            pcall(function()
                playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
            end)
        end
        addCandidate(playerGui)
    end

    addCandidate(CoreGui)

    local parented = false

    for _, uiParent in ipairs(candidates) do
        pcall(function()
            local oldGui = uiParent:FindFirstChild("AimLockUI")
            if oldGui and oldGui ~= gui then
                oldGui:Destroy()
            end
        end)

        local ok = pcall(function()
            gui.Parent = uiParent
        end)

        if ok and gui.Parent == uiParent then
            parented = true
            break
        end
    end

    if not parented then
        pcall(function()
            gui:Destroy()
        end)
        error("SilentAim Pro 无法把 AimLockUI 挂到可显示的 GUI 容器")
    end

    ScreenGui = gui
end

local FovCircle = Instance.new("Frame")
FovCircle.BackgroundTransparency = 1
FovCircle.Size = UDim2.fromOffset(Settings.FOV_RADIUS*2,Settings.FOV_RADIUS*2)
do
    local aimPoint = GetAimScreenPoint()
    FovCircle.Position = UDim2.fromOffset(
        aimPoint.X - Settings.FOV_RADIUS,
        aimPoint.Y - Settings.FOV_RADIUS
    )
end
FovCircle.Visible = Settings.FOV_ENABLED
FovCircle.Parent = ScreenGui
local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1,0)
circleCorner.Parent = FovCircle
local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.new(0,1,0)
uiStroke.Thickness = 1
uiStroke.Transparency = 0.3
uiStroke.Parent = FovCircle

local fovFollowConnection = RunService.RenderStepped:Connect(function()
    if UI_Destroyed then return end
    if not FovCircle then return end

    local aimPoint = GetAimScreenPoint()
    FovCircle.Position = UDim2.fromOffset(
        aimPoint.X - Settings.FOV_RADIUS,
        aimPoint.Y - Settings.FOV_RADIUS
    )
    FovCircle.Size = UDim2.fromOffset(
        Settings.FOV_RADIUS * 2,
        Settings.FOV_RADIUS * 2
    )
    FovCircle.Visible =
        Settings.AIM_ENABLED
        and Settings.FOV_ENABLED
end)

-- ==============================================================================
-- >> TARGET HUD · video-inspired compact target status
-- ==============================================================================

local TargetHud = Instance.new("Frame")
TargetHud.Name = "TargetHud"
TargetHud.AnchorPoint = Vector2.new(0.5, 0.5)
TargetHud.Position = UDim2.new(0.5, 0, 0.30, 0)
TargetHud.Size = UDim2.fromOffset(292, 76)
TargetHud.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHud.BackgroundTransparency = 1
TargetHud.BorderSizePixel = 0
TargetHud.ClipsDescendants = false
TargetHud.Visible = false
TargetHud.ZIndex = 50
TargetHud.Parent = ScreenGui

local TargetHudCorner = Instance.new("UICorner")
TargetHudCorner.CornerRadius = UDim.new(0, 18)
TargetHudCorner.Parent = TargetHud

local TargetHudStroke = Instance.new("UIStroke")
TargetHudStroke.Color = Color3.fromRGB(255, 255, 255)
TargetHudStroke.Transparency = 1
TargetHudStroke.Thickness = 1
TargetHudStroke.Parent = TargetHud

local TargetHudGradient = Instance.new("UIGradient")
TargetHudGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 56, 62)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 25, 29)),
})
TargetHudGradient.Rotation = 8
TargetHudGradient.Transparency = NumberSequence.new(1)
TargetHudGradient.Parent = TargetHud

-- Transparent TargetHUD body: only a soft shadow remains behind the content.
local TargetHudShadow = Instance.new("ImageLabel")
TargetHudShadow.Name = "Shadow"
TargetHudShadow.AnchorPoint = Vector2.new(0.5, 0.5)
TargetHudShadow.Position = UDim2.fromScale(0.5, 0.5)
TargetHudShadow.Size = UDim2.new(1, 54, 1, 48)
TargetHudShadow.BackgroundTransparency = 1
TargetHudShadow.Image = "rbxassetid://104482361987216"
TargetHudShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
TargetHudShadow.ImageTransparency = 0.42
TargetHudShadow.ScaleType = Enum.ScaleType.Stretch
TargetHudShadow.ZIndex = 49
TargetHudShadow.Parent = TargetHud

local TargetHudScale = Instance.new("UIScale")
TargetHudScale.Scale = 0.94
TargetHudScale.Parent = TargetHud

local TargetHudDamageFlash = Instance.new("Frame")
TargetHudDamageFlash.Name = "DamageFlash"
TargetHudDamageFlash.Size = UDim2.fromScale(1, 1)
TargetHudDamageFlash.BackgroundColor3 = Color3.fromRGB(255, 70, 85)
TargetHudDamageFlash.BackgroundTransparency = 1
TargetHudDamageFlash.BorderSizePixel = 0
TargetHudDamageFlash.ZIndex = 51
TargetHudDamageFlash.Parent = TargetHud

local TargetHudDamageCorner = Instance.new("UICorner")
TargetHudDamageCorner.CornerRadius = UDim.new(0, 18)
TargetHudDamageCorner.Parent = TargetHudDamageFlash

local TargetAvatarHolder = Instance.new("Frame")
TargetAvatarHolder.Name = "AvatarHolder"
TargetAvatarHolder.Position = UDim2.fromOffset(10, 10)
TargetAvatarHolder.Size = UDim2.fromOffset(56, 56)
TargetAvatarHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetAvatarHolder.BackgroundTransparency = 0.86
TargetAvatarHolder.BorderSizePixel = 0
TargetAvatarHolder.ZIndex = 52
TargetAvatarHolder.ClipsDescendants = true
TargetAvatarHolder.Parent = TargetHud

local TargetAvatarCorner = Instance.new("UICorner")
TargetAvatarCorner.CornerRadius = UDim.new(0, 14)
TargetAvatarCorner.Parent = TargetAvatarHolder

local TargetAvatar = Instance.new("ImageLabel")
TargetAvatar.Name = "Avatar"
TargetAvatar.Size = UDim2.fromScale(1, 1)
TargetAvatar.BackgroundTransparency = 1
TargetAvatar.ScaleType = Enum.ScaleType.Crop
TargetAvatar.Image = ""
TargetAvatar.ZIndex = 53
TargetAvatar.Parent = TargetAvatarHolder

local TargetAvatarInitial = Instance.new("TextLabel")
TargetAvatarInitial.Name = "Initial"
TargetAvatarInitial.Size = UDim2.fromScale(1, 1)
TargetAvatarInitial.BackgroundTransparency = 1
TargetAvatarInitial.Text = "?"
TargetAvatarInitial.TextColor3 = Color3.fromRGB(245, 245, 248)
TargetAvatarInitial.TextSize = 24
TargetAvatarInitial.Font = Enum.Font.GothamBold
TargetAvatarInitial.ZIndex = 52
TargetAvatarInitial.Parent = TargetAvatarHolder

local TargetName = Instance.new("TextLabel")
TargetName.Name = "TargetName"
TargetName.Position = UDim2.fromOffset(76, 11)
TargetName.Size = UDim2.new(1, -88, 0, 24)
TargetName.BackgroundTransparency = 1
TargetName.Text = "Name: --"
TargetName.TextColor3 = Color3.fromRGB(245, 245, 248)
TargetName.TextTransparency = 0.02
TargetName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TargetName.TextStrokeTransparency = 0.48
TargetName.TextSize = 14
TargetName.Font = Enum.Font.GothamMedium
TargetName.TextXAlignment = Enum.TextXAlignment.Left
TargetName.TextTruncate = Enum.TextTruncate.AtEnd
TargetName.ZIndex = 52
TargetName.Parent = TargetHud

-- Colored glow follows the CURRENT health width.
local TargetHealthGlowHolder = Instance.new("Frame")
TargetHealthGlowHolder.Name = "HealthGlowHolder"
TargetHealthGlowHolder.Position = UDim2.fromOffset(76, 43)
TargetHealthGlowHolder.Size = UDim2.new(1, -126, 0, 11)
TargetHealthGlowHolder.BackgroundTransparency = 1
TargetHealthGlowHolder.BorderSizePixel = 0
TargetHealthGlowHolder.ClipsDescendants = false
TargetHealthGlowHolder.ZIndex = 50
TargetHealthGlowHolder.Parent = TargetHud

local TargetHealthGlowOuter = Instance.new("ImageLabel")
TargetHealthGlowOuter.Name = "OuterGlow"
TargetHealthGlowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
TargetHealthGlowOuter.Position = UDim2.fromScale(0.5, 0.5)
TargetHealthGlowOuter.Size = UDim2.new(1, 26, 1, 24)
TargetHealthGlowOuter.BackgroundTransparency = 1
TargetHealthGlowOuter.Image = "rbxassetid://104490578391522"
TargetHealthGlowOuter.ImageColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthGlowOuter.ImageTransparency = 0.34
TargetHealthGlowOuter.ScaleType = Enum.ScaleType.Stretch
TargetHealthGlowOuter.ZIndex = 50
TargetHealthGlowOuter.Parent = TargetHealthGlowHolder

local TargetHealthGlowOuterGradient = Instance.new("UIGradient")
TargetHealthGlowOuterGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 239, 169)),
    ColorSequenceKeypoint.new(0.52, Color3.fromRGB(199, 247, 199)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 229, 255)),
})
TargetHealthGlowOuterGradient.Parent = TargetHealthGlowOuter

local TargetHealthGlowInner = Instance.new("ImageLabel")
TargetHealthGlowInner.Name = "InnerGlow"
TargetHealthGlowInner.AnchorPoint = Vector2.new(0.5, 0.5)
TargetHealthGlowInner.Position = UDim2.fromScale(0.5, 0.5)
TargetHealthGlowInner.Size = UDim2.new(1, 16, 1, 14)
TargetHealthGlowInner.BackgroundTransparency = 1
TargetHealthGlowInner.Image = "rbxassetid://102472648910048"
TargetHealthGlowInner.ImageColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthGlowInner.ImageTransparency = 0.16
TargetHealthGlowInner.ScaleType = Enum.ScaleType.Stretch
TargetHealthGlowInner.ZIndex = 51
TargetHealthGlowInner.Parent = TargetHealthGlowHolder

local TargetHealthGlowInnerGradient = Instance.new("UIGradient")
TargetHealthGlowInnerGradient.Color = TargetHealthGlowOuterGradient.Color
TargetHealthGlowInnerGradient.Parent = TargetHealthGlowInner

local TargetHealthTrack = Instance.new("Frame")
TargetHealthTrack.Name = "HealthTrack"
TargetHealthTrack.Position = UDim2.fromOffset(76, 43)
TargetHealthTrack.Size = UDim2.new(1, -126, 0, 11)
TargetHealthTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthTrack.BackgroundTransparency = 0.90
TargetHealthTrack.BorderSizePixel = 0
TargetHealthTrack.ClipsDescendants = true
TargetHealthTrack.ZIndex = 52
TargetHealthTrack.Parent = TargetHud

local TargetHealthTrackCorner = Instance.new("UICorner")
TargetHealthTrackCorner.CornerRadius = UDim.new(1, 0)
TargetHealthTrackCorner.Parent = TargetHealthTrack

local TargetHealthLag = Instance.new("Frame")
TargetHealthLag.Name = "HealthLag"
TargetHealthLag.Size = UDim2.fromScale(1, 1)
TargetHealthLag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthLag.BackgroundTransparency = 0.35
TargetHealthLag.BorderSizePixel = 0
TargetHealthLag.ZIndex = 53
TargetHealthLag.Parent = TargetHealthTrack

local TargetHealthLagCorner = Instance.new("UICorner")
TargetHealthLagCorner.CornerRadius = UDim.new(1, 0)
TargetHealthLagCorner.Parent = TargetHealthLag

local TargetHealthFill = Instance.new("Frame")
TargetHealthFill.Name = "HealthFill"
TargetHealthFill.Size = UDim2.fromScale(1, 1)
TargetHealthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthFill.BorderSizePixel = 0
TargetHealthFill.ZIndex = 54
TargetHealthFill.Parent = TargetHealthTrack

local TargetHealthFillCorner = Instance.new("UICorner")
TargetHealthFillCorner.CornerRadius = UDim.new(1, 0)
TargetHealthFillCorner.Parent = TargetHealthFill

local TargetHealthGradient = Instance.new("UIGradient")
TargetHealthGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 229, 255)),
})
TargetHealthGradient.Parent = TargetHealthFill

local TargetHealthText = Instance.new("TextLabel")
TargetHealthText.Name = "HealthText"
TargetHealthText.AnchorPoint = Vector2.new(1, 0.5)
TargetHealthText.Position = UDim2.new(1, -10, 0, 48)
TargetHealthText.Size = UDim2.fromOffset(34, 22)
TargetHealthText.BackgroundTransparency = 1
TargetHealthText.Text = "--"
TargetHealthText.TextColor3 = Color3.fromRGB(235, 238, 242)
TargetHealthText.TextTransparency = 0.04
TargetHealthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TargetHealthText.TextStrokeTransparency = 0.50
TargetHealthText.TextSize = 13
TargetHealthText.Font = Enum.Font.GothamMedium
TargetHealthText.TextXAlignment = Enum.TextXAlignment.Right
TargetHealthText.ZIndex = 52
TargetHealthText.Parent = TargetHud

local TargetHudShown = false
local TargetHudKey = nil
local TargetHudLastHealth = nil
local TargetHudLastRatio = 1
local TargetHudPreviewUntil = 0
local TargetHudPreviewKey = "__TARGETHUD_PREVIEW_V32__"
local TargetHudBasePosition = TargetHud.Position
local TargetHudAnimationSerial = 0
local TargetHudScaleTween = nil
local TargetHudFrameTween = nil

local function CancelTargetHudAnimation()
    if TargetHudScaleTween then
        pcall(function()
            TargetHudScaleTween:Cancel()
        end)
        TargetHudScaleTween = nil
    end

    if TargetHudFrameTween then
        pcall(function()
            TargetHudFrameTween:Cancel()
        end)
        TargetHudFrameTween = nil
    end
end

local function TargetHudOffsetPosition(offsetY)
    return UDim2.new(
        TargetHudBasePosition.X.Scale,
        TargetHudBasePosition.X.Offset,
        TargetHudBasePosition.Y.Scale,
        TargetHudBasePosition.Y.Offset + offsetY
    )
end

local function SetTargetHudVisible(state, instant)
    state = state == true

    if not instant then
        if state and TargetHudShown and TargetHud.Visible then
            return
        end

        -- TargetHudShown becomes false as soon as the exit tween starts.
        -- Ignore repeated RenderStepped hide requests until that tween ends.
        if not state and not TargetHudShown then
            return
        end
    end

    TargetHudAnimationSerial += 1
    local serial = TargetHudAnimationSerial

    if instant then
        CancelTargetHudAnimation()
        TargetHudShown = state
        TargetHud.Visible = state
        TargetHud.Position = TargetHudBasePosition
        TargetHud.Rotation = 0
        TargetHudScale.Scale = state and 1 or 0.82
        return
    end

    if state then
        TargetHudShown = true
        CancelTargetHudAnimation()

        TargetHud.Visible = true
        TargetHud.Position = TargetHudOffsetPosition(18)
        TargetHud.Rotation = -1.5
        TargetHudScale.Scale = 0.78

        TargetHudScaleTween = TweenService:Create(
            TargetHudScale,
            TweenInfo.new(
                0.24,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {Scale = 1}
        )

        TargetHudFrameTween = TweenService:Create(
            TargetHud,
            TweenInfo.new(
                0.20,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Position = TargetHudBasePosition,
                Rotation = 0,
            }
        )

        TargetHudScaleTween:Play()
        TargetHudFrameTween:Play()
        return
    end

    TargetHudShown = false
    CancelTargetHudAnimation()

    TargetHudScaleTween = TweenService:Create(
        TargetHudScale,
        TweenInfo.new(
            0.14,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ),
        {Scale = 0.82}
    )

    TargetHudFrameTween = TweenService:Create(
        TargetHud,
        TweenInfo.new(
            0.14,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ),
        {
            Position = TargetHudOffsetPosition(14),
            Rotation = 1.2,
        }
    )

    local hideTween = TargetHudFrameTween
    TargetHudScaleTween:Play()
    hideTween:Play()

    task.spawn(function()
        pcall(function()
            hideTween.Completed:Wait()
        end)

        if serial == TargetHudAnimationSerial
            and not TargetHudShown
            and TargetHud
            and TargetHud.Parent then

            TargetHud.Visible = false
            TargetHud.Position = TargetHudBasePosition
            TargetHud.Rotation = 0
            TargetHudScale.Scale = 0.78
        end
    end)
end
local function GetHumanoidModelFromPart(part)
    local current = part

    while current and current ~= workspace do
        if current:IsA("Model")
            and current:FindFirstChildOfClass("Humanoid") then

            return current
        end

        current = current.Parent
    end

    return nil
end

local function GetVehicleHudHealth(tVehicle)
    local currentHealth = 0
    local maxHealth = 0

    if not tVehicle then
        return currentHealth, maxHealth
    end

    local stats = tVehicle:FindFirstChild("Stats")
    local healthValue =
        stats and stats:FindFirstChild("Health")

    if healthValue then
        pcall(function()
            currentHealth = tonumber(healthValue.Value) or 0
        end)

        pcall(function()
            maxHealth = tonumber(healthValue.MaxValue) or 0
        end)
    end

    if maxHealth <= 0 and stats then
        local maxObj =
            stats:FindFirstChild("MaxHealth")
            or stats:FindFirstChild("HealthMax")

        if maxObj then
            pcall(function()
                maxHealth = tonumber(maxObj.Value) or 0
            end)
        end
    end

    if maxHealth <= 0 then
        maxHealth = math.max(currentHealth, 1)
    end

    return currentHealth, maxHealth
end

local function BuildFallbackTargetHudInfo(target, forcedInitial)
    if not target or not target.Parent then
        return nil
    end

    local model = target:FindFirstAncestorOfClass("Model")
    local name =
        (model and model.Name)
        or (target.Parent and target.Parent.Name)
        or target.Name
        or "Target"

    local initial =
        forcedInitial
        or string.upper(
            string.sub(tostring(name), 1, 1)
        )

    return {
        Key = model or target,
        Name = name,
        Health = nil,
        MaxHealth = nil,
        Avatar = nil,
        Initial = initial ~= "" and initial or "?",
    }
end

local function GetTargetHudInfo()
    local target = CurrentTarget

    if not target or not target.Parent then
        return nil
    end

    if Settings.VEHICLE_MODE then
        local tVehicle = GetRootTVehicle(target)

        if not tVehicle then
            -- Do not hide the HUD merely because a vehicle has a different
            -- hierarchy from the expected TVehicle layout.
            return BuildFallbackTargetHudInfo(target, "V")
        end

        local rootModel = GetTopVehicleModel(tVehicle)
        local currentHealth, maxHealth =
            GetVehicleHudHealth(tVehicle)

        local name =
            rootModel
            and rootModel.Name
            or tVehicle.Name

        return {
            Key = tVehicle,
            Name = name,
            Health = currentHealth,
            MaxHealth = maxHealth,
            Avatar = nil,
            Initial = "V",
        }
    end

    if Settings.RCV_MODE then
        local model = target:FindFirstAncestorOfClass("Model")
        local name =
            model
            and model.Name
            or target.Parent.Name

        return {
            Key = model or target,
            Name = name,
            Health = nil,
            MaxHealth = nil,
            Avatar = nil,
            Initial = "R",
        }
    end

    local model = GetHumanoidModelFromPart(target)

    if not model then
        -- CurrentTarget is valid, so keep TargetHUD visible even when the
        -- target hierarchy does not expose a Humanoid where V31 expected it.
        return BuildFallbackTargetHudInfo(target)
    end

    local humanoid =
        model:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return BuildFallbackTargetHudInfo(target)
    end

    if humanoid.Health <= 0 then
        return nil
    end

    local player =
        Players:GetPlayerFromCharacter(model)

    local displayName

    if player then
        displayName =
            player.DisplayName ~= ""
            and player.DisplayName
            or player.Name
    else
        displayName =
            humanoid.DisplayName ~= ""
            and humanoid.DisplayName
            or model.Name
    end

    local avatar

    if player then
        avatar =
            "rbxthumb://type=AvatarHeadShot&id="
            .. tostring(player.UserId)
            .. "&w=150&h=150"
    end

    return {
        Key = player or model,
        Name = displayName,
        Health = humanoid.Health,
        MaxHealth = math.max(humanoid.MaxHealth, 1),
        Avatar = avatar,
        Initial = string.upper(
            string.sub(displayName or "?", 1, 1)
        ),
    }
end

local function SetHealthGradient(ratio)
    local sequence

    if ratio <= 0.25 then
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(255, 74, 109)
            ),
            ColorSequenceKeypoint.new(
                0.5,
                Color3.fromRGB(255, 113, 155)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(255, 190, 208)
            ),
        })
    elseif ratio <= 0.60 then
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(255, 126, 187)
            ),
            ColorSequenceKeypoint.new(
                0.52,
                Color3.fromRGB(255, 196, 122)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(255, 239, 151)
            ),
        })
    else
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(255, 221, 112)
            ),
            ColorSequenceKeypoint.new(
                0.34,
                Color3.fromRGB(137, 255, 173)
            ),
            ColorSequenceKeypoint.new(
                0.68,
                Color3.fromRGB(105, 226, 255)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(180, 142, 255)
            ),
        })
    end

    TargetHealthGradient.Color = sequence
    TargetHealthGlowOuterGradient.Color = sequence
    TargetHealthGlowInnerGradient.Color = sequence
end
local function ShowTargetHudPreview()
    if TargetHudKey ~= TargetHudPreviewKey then
        TargetHudKey = TargetHudPreviewKey
        TargetHudLastHealth = nil
        TargetHudLastRatio = 1

        TargetName.Text = "TargetHUD READY"
        TargetAvatar.Image = ""
        TargetAvatar.Visible = false
        TargetAvatarInitial.Visible = true
        TargetAvatarInitial.Text = "✓"
        TargetHealthText.Text = "--"
        TargetHealthFill.Size = UDim2.fromScale(1, 1)
        TargetHealthLag.Size = UDim2.fromScale(1, 1)
        TargetHealthGlowHolder.Size = UDim2.new(1, -126, 0, 11)
        SetHealthGradient(1)
    end

    SetTargetHudVisible(true, false)
end

local function UpdateTargetHud()
    if UI_Destroyed
        or not Settings.AIM_ENABLED then

        SetTargetHudVisible(false)
        return
    end

    if not CurrentTarget
        or not CurrentTarget.Parent then

        if os.clock() < TargetHudPreviewUntil then
            ShowTargetHudPreview()
        else
            TargetHudKey = nil
            TargetHudLastHealth = nil
            SetTargetHudVisible(false)
        end
        return
    end

    local info = GetTargetHudInfo()

    if not info then
        -- Last-resort fallback: a valid CurrentTarget must never make the HUD
        -- disappear only because metadata parsing failed.
        info = BuildFallbackTargetHudInfo(CurrentTarget)
    end

    if not info then
        TargetHudKey = nil
        TargetHudLastHealth = nil
        SetTargetHudVisible(false)
        return
    end

    local targetChanged =
        TargetHudKey ~= info.Key

    if targetChanged then
        TargetHudKey = info.Key
        TargetHudLastHealth = nil
        TargetHudLastRatio = 1

        TargetName.Text =
            "Name: " .. tostring(info.Name or "--")

        if info.Avatar then
            TargetAvatar.Image = info.Avatar
            TargetAvatar.Visible = true
            TargetAvatarInitial.Visible = false
        else
            TargetAvatar.Image = ""
            TargetAvatar.Visible = false
            TargetAvatarInitial.Visible = true
            TargetAvatarInitial.Text =
                tostring(info.Initial or "?")
        end

    else
        TargetName.Text =
            "Name: " .. tostring(info.Name or "--")
    end

    local ratio = 1
    local healthText = "--"

    if info.Health ~= nil
        and info.MaxHealth ~= nil then

        ratio = math.clamp(
            info.Health / math.max(info.MaxHealth, 1),
            0,
            1
        )

        healthText =
            tostring(
                math.max(
                    0,
                    math.floor(info.Health + 0.5)
                )
            )
    end

    TargetHealthText.Text = healthText

    local ratioChanged =
        targetChanged
        or math.abs(ratio - TargetHudLastRatio) > 0.001

    -- Do not allocate three new tweens every RenderStepped when health is
    -- unchanged. This matters a lot in vehicle mode where target scanning is
    -- already more expensive than player/NPC mode.
    if ratioChanged then
        SetHealthGradient(ratio)

        local fillGoal =
            UDim2.new(ratio, 0, 1, 0)

        local glowGoal =
            UDim2.new(
                ratio,
                -126 * ratio,
                0,
                11
            )

        TweenService:Create(
            TargetHealthGlowHolder,
            TweenInfo.new(
                0.14,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {Size = glowGoal}
        ):Play()

        TweenService:Create(
            TargetHealthFill,
            TweenInfo.new(
                0.12,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {Size = fillGoal}
        ):Play()

        TweenService:Create(
            TargetHealthLag,
            TweenInfo.new(
                0.32,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {Size = fillGoal}
        ):Play()
    end

    if TargetHudLastHealth ~= nil
        and info.Health ~= nil
        and info.Health < TargetHudLastHealth - 0.01 then

        TargetHudDamageFlash.BackgroundTransparency = 0.82

        TweenService:Create(
            TargetHudDamageFlash,
            TweenInfo.new(
                0.24,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {BackgroundTransparency = 1}
        ):Play()

        TargetHudScale.Scale = 1.025

        TweenService:Create(
            TargetHudScale,
            TweenInfo.new(
                0.18,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {Scale = 1}
        ):Play()
    end

    if info.Health ~= nil then
        TargetHudLastHealth = info.Health
    end

    TargetHudLastRatio = ratio
    SetTargetHudVisible(true, false)
end

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(120,480)
Panel.Position = UDim2.new(0.02,0,0.15,0)
Panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
Panel.Draggable = true
Panel.Active = true
Panel.Parent = ScreenGui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0,8)
panelCorner.Parent = Panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,4)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.Parent = Panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0,4)
panelPadding.PaddingLeft = UDim.new(0,4)
panelPadding.PaddingRight = UDim.new(0,4)
panelPadding.Parent = Panel

local function CreateTeamVehicleMonitorUI()
    TeamVehiclePanel = Instance.new("Frame")
    TeamVehiclePanel.Name = "TeamVehicleMonitor"
    TeamVehiclePanel.Size = UDim2.fromOffset(240,320)
    TeamVehiclePanel.Position = UDim2.new(0.125,10,0.15,0)
    TeamVehiclePanel.BackgroundColor3 = Color3.fromRGB(20,20,20)
    TeamVehiclePanel.Visible = false
    TeamVehiclePanel.Active = true
    TeamVehiclePanel.Parent = ScreenGui
    local monitorCorner = Instance.new("UICorner")
    monitorCorner.CornerRadius = UDim.new(0,8)
    monitorCorner.Parent = TeamVehiclePanel
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1,0,0.1,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "队友载具 | 弹药监控"
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = TeamVehiclePanel
    TeamVehicleScrollFrame = Instance.new("ScrollingFrame")
    TeamVehicleScrollFrame.Name = "VehicleScroll"
    TeamVehicleScrollFrame.Size = UDim2.new(1, -10, 0.9, -5)
    TeamVehicleScrollFrame.Position = UDim2.new(0,5,0.1,0)
    TeamVehicleScrollFrame.BackgroundTransparency = 1
    TeamVehicleScrollFrame.ScrollBarThickness = 6
    TeamVehicleScrollFrame.Parent = TeamVehiclePanel
    TeamVehicleLayout = Instance.new("UIListLayout")
    TeamVehicleLayout.Padding = UDim.new(0,4)
    TeamVehicleLayout.FillDirection = Enum.FillDirection.Vertical
    TeamVehicleLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    TeamVehicleLayout.Parent = TeamVehicleScrollFrame
    TeamVehicleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TeamVehicleScrollFrame.CanvasSize = UDim2.new(0,0,0,TeamVehicleLayout.AbsoluteContentSize.Y + 10)
    end)
    local monitorPadding = Instance.new("UIPadding")
    monitorPadding.PaddingTop = UDim.new(0,5)
    monitorPadding.PaddingLeft = UDim.new(0,5)
    monitorPadding.PaddingRight = UDim.new(0,5)
    monitorPadding.Parent = TeamVehiclePanel
    TeamVehiclePanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStartMouse = input.Position
            panelStartUDim = TeamVehiclePanel.Position
        end
    end)
    TeamVehiclePanel.InputChanged:Connect(function(input)
        if not isDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local mouseDelta = input.Position - dragStartMouse
        local newPos = UDim2.new(panelStartUDim.X.Scale,panelStartUDim.X.Offset + mouseDelta.X,panelStartUDim.Y.Scale,panelStartUDim.Y.Offset + mouseDelta.Y)
        local clampedPos = ClampPanelPosition(newPos, TeamVehiclePanel.AbsoluteSize)
        TeamVehiclePanel.Position = clampedPos
    end)
    TeamVehiclePanel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
end
CreateTeamVehicleMonitorUI()

local function CreateButton(text,color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(110,32)
    btn.BackgroundColor3 = color or Color3.fromRGB(0,200,0)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 12
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0,6)
    btnCorner.Parent = btn
    btn.Parent = Panel
    return btn
end

local BtnAim = CreateButton("AIM: ON")
local BtnTeam = CreateButton("TEAM: ON")
local BtnRCV = CreateButton("RCV MODE: OFF",Color3.fromRGB(200,80,80))
local BtnVehicle = CreateButton("VEHICLE: OFF",Color3.fromRGB(200,80,80))
local BtnFov = CreateButton("FOV: ON")
local BtnPart = CreateButton("PART: HEAD")
local BtnFovAdd = CreateButton("FOV +")
local BtnFovSub = CreateButton("FOV -")
local BtnMode = CreateButton("MODE: TP",Color3.fromRGB(255,127,0))
local BtnTarget = CreateButton("TARGET: PLAYER",Color3.fromRGB(0,120,255))
local BtnHigh = CreateButton("HIGH: ON",Color3.fromRGB(255,0,0))
local BtnMin = CreateButton("MINIMIZE",Color3.fromRGB(255,150,0))
local BtnTeamVehMonitor = CreateButton("队友载具: OFF",Color3.fromRGB(100,100,255))
local BtnDestroy = CreateButton("DESTROY",Color3.fromRGB(180,0,0))

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.fromOffset(160,80)
ConfirmFrame.Position = UDim2.new(0.5,-80,0.5,-40)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(50,0,0)
ConfirmFrame.Visible = false
ConfirmFrame.Parent = ScreenGui
local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0,8)
confirmCorner.Parent = ConfirmFrame

local ConfirmTip = Instance.new("TextLabel")
ConfirmTip.Size = UDim2.new(1,0,0.6,0)
ConfirmTip.BackgroundTransparency = 1
ConfirmTip.Text = "DESTROY?\nY/N"
ConfirmTip.TextColor3 = Color3.new(1,1,1)
ConfirmTip.TextSize = 12
ConfirmTip.Parent = ConfirmFrame

local BtnYes = CreateButton("YES",Color3.fromRGB(200,0,0))
BtnYes.Parent = ConfirmFrame
BtnYes.Size = UDim2.new(0.45,0,0.3,0)
BtnYes.Position = UDim2.new(0.05,0,0.65,0)

local BtnNo = CreateButton("NO",Color3.fromRGB(150,150,0))
BtnNo.Parent = ConfirmFrame
BtnNo.Size = UDim2.new(0.45,0,0.3,0)
BtnNo.Position = UDim2.new(0.5,0,0.65,0)

-- 按钮逻辑
BtnAim.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.AIM_ENABLED = not Settings.AIM_ENABLED
    BtnAim.Text = Settings.AIM_ENABLED and "AIM: ON" or "AIM: OFF"
    BtnAim.BackgroundColor3 = Settings.AIM_ENABLED and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
end)

BtnTeam.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.TEAM_CHECK = not Settings.TEAM_CHECK
    BtnTeam.Text = Settings.TEAM_CHECK and "TEAM: ON" or "TEAM: OFF"
    BtnTeam.BackgroundColor3 = Settings.TEAM_CHECK and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
end)

BtnRCV.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.RCV_MODE = not Settings.RCV_MODE
    if Settings.RCV_MODE then
        Settings.VEHICLE_MODE = false
        BtnVehicle.Text = "VEHICLE: OFF"
        BtnVehicle.BackgroundColor3 = Color3.fromRGB(200,80,80)
    end
    BtnRCV.Text = Settings.RCV_MODE and "RCV MODE: ON" or "RCV MODE: OFF"
    BtnRCV.BackgroundColor3 = Settings.RCV_MODE and Color3.fromRGB(0,180,80) or Color3.fromRGB(200,80,80)
end)

BtnVehicle.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.VEHICLE_MODE = not Settings.VEHICLE_MODE
    if Settings.VEHICLE_MODE then
        Settings.RCV_MODE = false
        BtnRCV.Text = "RCV MODE: OFF"
        BtnRCV.BackgroundColor3 = Color3.fromRGB(200,80,80)
    end
    BtnVehicle.Text = Settings.VEHICLE_MODE and "VEHICLE: ON" or "VEHICLE: OFF"
    BtnVehicle.BackgroundColor3 = Settings.VEHICLE_MODE and Color3.fromRGB(0,180,80) or Color3.fromRGB(200,80,80)
end)

BtnFov.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.FOV_ENABLED = not Settings.FOV_ENABLED
    FovCircle.Visible = Settings.FOV_ENABLED
    BtnFov.Text = Settings.FOV_ENABLED and "FOV: ON" or "FOV: OFF"
    BtnFov.BackgroundColor3 = Settings.FOV_ENABLED and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
end)

BtnPart.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    local partList = {"Head","HumanoidRootPart","RANDOM","LIMBS","SURR"}
    local idx = table.find(partList,Settings.TARGET_PART) or 1
    idx = idx % #partList + 1
    Settings.TARGET_PART = partList[idx]
    local showName = Settings.TARGET_PART=="HumanoidRootPart" and "BODY" or Settings.TARGET_PART
    BtnPart.Text = "PART: "..showName
end)

BtnFovAdd.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.FOV_RADIUS = math.min(Settings.FOV_RADIUS+10,500)
    FovCircle.Size = UDim2.fromOffset(Settings.FOV_RADIUS*2,Settings.FOV_RADIUS*2)
    FovCircle.Position = UDim2.new(0.5,-Settings.FOV_RADIUS,0.5,-Settings.FOV_RADIUS)
end)

BtnFovSub.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.FOV_RADIUS = math.max(Settings.FOV_RADIUS-10,20)
    FovCircle.Size = UDim2.fromOffset(Settings.FOV_RADIUS*2,Settings.FOV_RADIUS*2)
    FovCircle.Position = UDim2.new(0.5,-Settings.FOV_RADIUS,0.5,-Settings.FOV_RADIUS)
end)

BtnMode.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.AIM_MODE = Settings.AIM_MODE=="TP" and "DIRECT" or "TP"
    BtnMode.Text = "MODE: "..Settings.AIM_MODE
end)

BtnTarget.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    local typeList = {"PLAYER","NPC","BOTH"}
    local idx = table.find(typeList,Settings.TARGET_TYPE) or 1
    idx = idx % #typeList + 1
    Settings.TARGET_TYPE = typeList[idx]
    BtnTarget.Text = "TARGET: "..Settings.TARGET_TYPE
end)

BtnHigh.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.HIGHLIGHT_ENABLED = not Settings.HIGHLIGHT_ENABLED
    BtnHigh.Text = "HIGH: "..(Settings.HIGHLIGHT_ENABLED and "ON" or "OFF")
    if not Settings.HIGHLIGHT_ENABLED then ClearAllHighlights() end
end)

BtnTeamVehMonitor.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    Settings.TEAM_VEHICLE_MONITOR = not Settings.TEAM_VEHICLE_MONITOR
    TeamVehiclePanel.Visible = Settings.TEAM_VEHICLE_MONITOR
    if Settings.TEAM_VEHICLE_MONITOR then
        BtnTeamVehMonitor.Text = "队友载具: ON"
        BtnTeamVehMonitor.BackgroundColor3 = Color3.fromRGB(50,150,255)
    else
        BtnTeamVehMonitor.Text = "队友载具: OFF"
        BtnTeamVehMonitor.BackgroundColor3 = Color3.fromRGB(100,100,255)
        for _,frame in pairs(TeamVehicleFrameCache) do pcall(function() frame:Destroy() end) end
        table.clear(TeamVehicleFrameCache)
        table.clear(DestroyedVehicleTimeout)
    end
end)

local isMinimize = false
local function SetButtonVisible(state)
    if UI_Destroyed then return end
    BtnAim.Visible = state
    BtnTeam.Visible = state
    BtnRCV.Visible = state
    BtnVehicle.Visible = state
    BtnFov.Visible = state
    BtnPart.Visible = state
    BtnFovAdd.Visible = state
    BtnFovSub.Visible = state
    BtnMode.Visible = state
    BtnTarget.Visible = state
    BtnHigh.Visible = state
    BtnTeamVehMonitor.Visible = state
    BtnDestroy.Visible = state
end

BtnMin.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    isMinimize = not isMinimize
    SetButtonVisible(not isMinimize)
    BtnMin.Text = isMinimize and "OPEN" or "MINIMIZE"
    Panel.Size = isMinimize and UDim2.fromOffset(120,60) or UDim2.fromOffset(120,480)
end)

BtnDestroy.MouseButton1Click:Connect(function()
    if not UI_Destroyed then
        ConfirmFrame.Visible = true
    end
end)

BtnNo.MouseButton1Click:Connect(function()
    ConfirmFrame.Visible = false
end)

BtnYes.MouseButton1Click:Connect(function()
    if UI_Destroyed then return end
    UI_Destroyed = true
    ConfirmFrame.Visible = false
    if oldNamecall then
        pcall(function() hookmetamethod(game,"__namecall",oldNamecall) end)
        oldNamecall = nil
    end
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    ClearAllHighlights()
    CurrentTarget = nil
    pcall(function() if TeamVehiclePanel then TeamVehiclePanel:Destroy() end end)
    pcall(function() ScreenGui:Destroy() end)
end)

local function RefreshTeamVehicleList()
    if not Settings.TEAM_VEHICLE_MONITOR or UI_Destroyed or not TeamVehiclePanel then return end
    local localTeam = LocalPlayer.Team.Name
    local vehFolder = workspace:FindFirstChild("TVehicles")
    if not vehFolder then
        for _,f in pairs(TeamVehicleFrameCache) do pcall(function()f:Destroy()end) end
        table.clear(TeamVehicleFrameCache)
        return
    end
    local teamVehicleList = {}
    for _,rootVeh in ipairs(vehFolder:GetChildren()) do
        if not rootVeh:IsA("Model") then continue end
        local tVeh = rootVeh:FindFirstChild("TVehicle")
        if not tVeh then continue end
        local isDestroyed,hp,vehTeam = GetVehicleStats(tVeh)
        if vehTeam == localTeam then
            local ammoInfo = GetVehicleAmmoData(tVeh)
            table.insert(teamVehicleList,{
                Root = rootVeh,
                TVehicle = tVeh,
                Destroyed = isDestroyed,
                Health = hp,
                VehId = rootVeh:GetDebugId(),
                Ammo = ammoInfo
            })
        end
    end
    local validIdMap = {}
    for _,v in ipairs(teamVehicleList) do validIdMap[v.VehId] = true end
    for id,frame in pairs(TeamVehicleFrameCache) do
        if not validIdMap[id] then
            pcall(function() frame:Destroy() end)
            TeamVehicleFrameCache[id] = nil
            DestroyedVehicleTimeout[id] = nil
        end
    end
    local function BuildAmmoText(ammoList)
        local strTab = {}
        for _,ammo in ipairs(ammoList) do
            table.insert(strTab,string.format("%s:%d发",ammo.TypeName,ammo.Count))
        end
        return #strTab>0 and table.concat(strTab," | ") or "无弹药"
    end
    for _,vehData in ipairs(teamVehicleList) do
        local vehId = vehData.VehId
        local vehFrame = TeamVehicleFrameCache[vehId]
        if not vehFrame then
            vehFrame = Instance.new("Frame")
            vehFrame.Size = UDim2.new(1,0,0,45)
            vehFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
            vehFrame.Parent = TeamVehicleScrollFrame
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0,4)
            frameCorner.Parent = vehFrame
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Name = "InfoLabel"
            infoLabel.Size = UDim2.new(1,0,1,0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextSize = 10
            infoLabel.TextColor3 = Color3.new(1,1,1)
            infoLabel.Font = Enum.Font.SourceSans
            infoLabel.Parent = vehFrame
            local destroyOverlay = Instance.new("TextLabel")
            destroyOverlay.Name = "DestroyOverlay"
            destroyOverlay.Size = UDim2.new(1,0,1,0)
            destroyOverlay.BackgroundColor3 = Color3.new(1,0,0)
            destroyOverlay.BackgroundTransparency = 0.4
            destroyOverlay.Text = ""
            destroyOverlay.TextColor3 = Color3.new(1,1,1)
            destroyOverlay.TextSize = 12
            destroyOverlay.Font = Enum.Font.SourceSansBold
            destroyOverlay.Visible = false
            destroyOverlay.Parent = vehFrame
            TeamVehicleFrameCache[vehId] = vehFrame
        end
        local infoLabel = vehFrame:FindFirstChild("InfoLabel")
        local destroyOverlay = vehFrame:FindFirstChild("DestroyOverlay")
        local ammoStr = BuildAmmoText(vehData.Ammo)
        if infoLabel then
            infoLabel.Text = string.format("载具:%s | 血量:%.0f\n弹药:%s",vehData.Root.Name,vehData.Health,ammoStr)
        end
        if vehData.Destroyed then
            if destroyOverlay then
                local fixedStatus = GetFixedDestroyStatus(vehId)
                destroyOverlay.Text = fixedStatus
                destroyOverlay.Visible = true
            end
            if not DestroyedVehicleTimeout[vehId] then
                DestroyedVehicleTimeout[vehId] = task.delay(3,function()
                    pcall(function()
                        if TeamVehicleFrameCache[vehId] then
                            TeamVehicleFrameCache[vehId]:Destroy()
                            TeamVehicleFrameCache[vehId] = nil
                        end
                    end)
                end)
            end
        else
            if destroyOverlay then destroyOverlay.Visible = false end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if UI_Destroyed then
        return
    end

    pcall(RefreshTeamVehicleList)
end)

local TargetHudUpdateErrorShown = false

RunService.RenderStepped:Connect(function()
    if UI_Destroyed then
        return
    end

    local ok, err = pcall(UpdateTargetHud)

    if not ok and not TargetHudUpdateErrorShown then
        TargetHudUpdateErrorShown = true
        warn("[SilentAim TargetHud] " .. tostring(err))
    end
end)


-- ================================================================
-- Syntax integration API
-- ================================================================
pcall(function()
    if Panel then
        Panel:Destroy()
    end
end)

pcall(function()
    if ConfirmFrame then
        ConfirmFrame:Destroy()
    end
end)

SetTargetHudVisible(false, true)

if FovCircle then
    FovCircle.Visible = false
end

local SyntaxSilentAimAPI = { Version = "V35_PROB_TRACK_SAFE" }

function SyntaxSilentAimAPI:SetEnabled(value)
    Settings.AIM_ENABLED = value == true

    if Settings.AIM_ENABLED then
        -- Show a short, unmistakable TargetHUD self-test every time SilentAim
        -- is enabled. If no target is acquired yet, the preview stays up briefly.
        TargetHudPreviewUntil = os.clock() + 1.75
        CurrentTarget = FindBestTarget()

        pcall(UpdateTargetHud)
    else
        CurrentTarget = nil
        SetTargetHudVisible(false)
    end

    if FovCircle then
        FovCircle.Visible =
            Settings.AIM_ENABLED
            and Settings.FOV_ENABLED
    end

    if not Settings.AIM_ENABLED then
        ClearAllHighlights()
    end
end

function SyntaxSilentAimAPI:SetTeamCheck(value)
    Settings.TEAM_CHECK = value == true
    InvalidateVehicleTargetCache()
end

function SyntaxSilentAimAPI:SetWallCheck(value)
    Settings.WALL_CHECK = value == true
    NextVehicleTargetRefresh = 0

    -- Force an immediate re-evaluation so a target behind a wall is dropped.
    if Settings.AIM_ENABLED then
        CurrentTarget = FindBestTarget()
    end
end

function SyntaxSilentAimAPI:SetTrackEnabled(value)
    Settings.TRACK_ENABLED = value == true
    TrackDecisionUntil = 0
    TrackDecisionValue = true
end

function SyntaxSilentAimAPI:SetTrackChance(value)
    Settings.TRACK_CHANCE =
        math.clamp(
            tonumber(value) or Settings.TRACK_CHANCE,
            0,
            100
        )

    TrackDecisionUntil = 0
end

function SyntaxSilentAimAPI:SetFOVEnabled(value)
    Settings.FOV_ENABLED = value == true

    if FovCircle then
        FovCircle.Visible =
            Settings.AIM_ENABLED
            and Settings.FOV_ENABLED
    end
end

function SyntaxSilentAimAPI:SetFOVRadius(value)
    Settings.FOV_RADIUS = math.clamp(
        tonumber(value) or Settings.FOV_RADIUS,
        20,
        500
    )

    if FovCircle then
        local aimPoint = GetAimScreenPoint()
        FovCircle.Size = UDim2.fromOffset(
            Settings.FOV_RADIUS * 2,
            Settings.FOV_RADIUS * 2
        )
        FovCircle.Position = UDim2.fromOffset(
            aimPoint.X - Settings.FOV_RADIUS,
            aimPoint.Y - Settings.FOV_RADIUS
        )
    end
end

function SyntaxSilentAimAPI:SetTargetPart(value)
    value = tostring(value)

    local allowed = {
        Head = true,
        HumanoidRootPart = true,
        RANDOM = true,
        LIMBS = true,
        SURR = true,
    }

    if allowed[value] then
        Settings.TARGET_PART = value
    end
end

function SyntaxSilentAimAPI:SetAimMode(value)
    value = tostring(value)
    Settings.AIM_MODE =
        value == "DIRECT"
        and "DIRECT"
        or "TP"
end

function SyntaxSilentAimAPI:SetTargetType(value)
    value = tostring(value)

    if value == "NPC" or value == "BOTH" then
        Settings.TARGET_TYPE = value
        RebuildNPCCache()
    else
        Settings.TARGET_TYPE = "PLAYER"
    end
end

function SyntaxSilentAimAPI:SetHighlight(value)
    Settings.HIGHLIGHT_ENABLED = value == true

    if not Settings.HIGHLIGHT_ENABLED then
        ClearAllHighlights()
    end
end

function SyntaxSilentAimAPI:SetSpecialMode(value)
    value = tostring(value)

    if value == "RCV" then
        Settings.RCV_MODE = true
        Settings.VEHICLE_MODE = false
    elseif value == "VEHICLE" then
        Settings.RCV_MODE = false
        Settings.VEHICLE_MODE = true
    else
        Settings.RCV_MODE = false
        Settings.VEHICLE_MODE = false
    end

    InvalidateVehicleTargetCache()

    if Settings.AIM_ENABLED then
        CurrentTarget = FindBestTarget()
        NextVehicleTargetRefresh =
            os.clock() + VEHICLE_RESELECT_SECONDS
    end
end

function SyntaxSilentAimAPI:SetTeamVehicleMonitor(value)
    Settings.TEAM_VEHICLE_MONITOR = value == true

    if TeamVehiclePanel then
        TeamVehiclePanel.Visible =
            Settings.TEAM_VEHICLE_MONITOR
    end

    if Settings.TEAM_VEHICLE_MONITOR then
        pcall(RefreshTeamVehicleList)
    else
        for _, frame in pairs(TeamVehicleFrameCache) do
            pcall(function()
                frame:Destroy()
            end)
        end

        table.clear(TeamVehicleFrameCache)
        table.clear(DestroyedVehicleTimeout)
    end
end

function SyntaxSilentAimAPI:GetTargetHudState()
    return {
        Visible =
            TargetHud
            and TargetHud.Visible
            or false,
        HasTarget =
            CurrentTarget ~= nil
            and CurrentTarget.Parent ~= nil,
        Target =
            CurrentTarget,
        ScreenGuiParent =
            ScreenGui
            and ScreenGui.Parent
            or nil,
        ScreenGuiEnabled =
            ScreenGui
            and ScreenGui.Enabled
            or false,
        HudParent =
            TargetHud
            and TargetHud.Parent
            or nil,
        HudAbsolutePosition =
            TargetHud
            and TargetHud.AbsolutePosition
            or nil,
        HudAbsoluteSize =
            TargetHud
            and TargetHud.AbsoluteSize
            or nil,
        HudText =
            TargetName
            and TargetName.Text
            or nil,
    }
end

function SyntaxSilentAimAPI:ShowTargetHudTest(seconds)
    if UI_Destroyed then
        return false
    end

    Settings.AIM_ENABLED = true
    TargetHudPreviewUntil =
        os.clock()
        + math.clamp(
            tonumber(seconds) or 3,
            0.5,
            15
        )

    ShowTargetHudPreview()
    return true
end

function SyntaxSilentAimAPI:GetSettings()
    return {
        Enabled = Settings.AIM_ENABLED == true,
        TeamCheck = Settings.TEAM_CHECK == true,
        WallCheck = Settings.WALL_CHECK == true,
        TrackEnabled = Settings.TRACK_ENABLED == true,
        TrackChance = Settings.TRACK_CHANCE,
        FOVEnabled = Settings.FOV_ENABLED == true,
        FOVRadius = Settings.FOV_RADIUS,
        TargetPart = Settings.TARGET_PART,
        AimMode = Settings.AIM_MODE,
        TargetType = Settings.TARGET_TYPE,
        Highlight = Settings.HIGHLIGHT_ENABLED == true,
        RCVMode = Settings.RCV_MODE == true,
        VehicleMode = Settings.VEHICLE_MODE == true,
        TeamVehicleMonitor =
            Settings.TEAM_VEHICLE_MONITOR == true,
        TrackAppliedCount = TrackAppliedCount,
        TrackSkippedCount = TrackSkippedCount,
    }
end

function SyntaxSilentAimAPI:Destroy()
    if UI_Destroyed then
        return
    end

    UI_Destroyed = true
    Settings.AIM_ENABLED = false
    Settings.TEAM_VEHICLE_MONITOR = false

    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end

    if fovFollowConnection then
        fovFollowConnection:Disconnect()
        fovFollowConnection = nil
    end

    CurrentTarget = nil
    ClearAllHighlights()
    SetTargetHudVisible(false, true)

    pcall(function()
        if TeamVehiclePanel then
            TeamVehiclePanel:Destroy()
        end
    end)

    pcall(function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)

    _G.SyntaxImportedSilentAim = nil
end

_G.SyntaxImportedSilentAim = SyntaxSilentAimAPI

]====]
    local AdonisSource = [====[
local getInfo = getinfo or debug.getinfo
local debugMode = false
local hookedFunctions = {}
local detectedFunc, killFunc

setthreadidentity(2)

for _, value in ipairs(getgc(true)) do
    if typeof(value) == "table" then
        local detected = rawget(value, "Detected")
        local kill = rawget(value, "Kill")

        if typeof(detected) == "function" and not detectedFunc then
            detectedFunc = detected
            local originalHook
            originalHook = hookfunction(detectedFunc, function(method, info, ...)
                if method ~= "_" then
                    if debugMode then
                        warn(string.format(
                            "Adonis AntiCheat flagged\nMethod: %s\nInfo: %s",
                            tostring(method),
                            tostring(info)
                        ))
                    end
                end
                return true
            end)
            table.insert(hookedFunctions, detectedFunc)
        end

        if rawget(value, "Variables") and rawget(value, "Process") and typeof(kill) == "function" and not killFunc then
            killFunc = kill
            local originalHook
            originalHook = hookfunction(killFunc, function(info)
                if debugMode then
                    warn(string.format("Adonis AntiCheat tried to kill (fallback): %s", tostring(info)))
                end
            end)
            table.insert(hookedFunctions, killFunc)
        end
    end
end

local originalDebugInfo
originalDebugInfo = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local firstArg, _ = ...
    if detectedFunc and firstArg == detectedFunc then
        if debugMode then
            warn("Adonis bypassed")
        end
        return coroutine.yield(coroutine.running())
    end
    return originalDebugInfo(...)
end))

setthreadidentity(7)
]====]

    local function compileSource(name, source)
        if type(loadstring) ~= "function" then
            return nil, "当前执行器不支持 loadstring"
        end

        local fn, compileErr = loadstring(source)

        if not fn then
            return nil,
                name .. " 编译失败: "
                .. tostring(compileErr)
        end

        local ok, runErr = xpcall(
            fn,
            function(message)
                local result = tostring(message)

                pcall(function()
                    result =
                        debug.traceback(
                            tostring(message),
                            2
                        )
                end)

                return result
            end
        )

        if not ok then
            return nil,
                name .. " 运行失败: "
                .. tostring(runErr)
        end

        return true
    end

    local REQUIRED_SILENT_AIM_VERSION = "V35_PROB_TRACK_SAFE"

    local function discardStaleSilentAim()
        local existing = _G.SyntaxImportedSilentAim
        if not existing then
            return
        end

        if existing.Version == REQUIRED_SILENT_AIM_VERSION then
            return
        end

        pcall(function()
            if type(existing.Destroy) == "function" then
                existing:Destroy()
            elseif type(existing.SetEnabled) == "function" then
                existing:SetEnabled(false)
            end
        end)

        _G.SyntaxImportedSilentAim = nil
    end

    function Pack:GetSilentAim()
        discardStaleSilentAim()
        return _G.SyntaxImportedSilentAim
    end

    function Pack:EnsureSilentAim()
        discardStaleSilentAim()

        if _G.SyntaxImportedSilentAim then
            return _G.SyntaxImportedSilentAim
        end

        local ok, err =
            compileSource(
                "SilentAim Pro",
                SilentAimSource
            )

        if not ok then
            return nil, err
        end

        if not _G.SyntaxImportedSilentAim then
            return nil,
                "SilentAim Pro 已执行，但未创建控制 API"
        end

        return _G.SyntaxImportedSilentAim
    end

    function Pack:EnableAdonisBypass()
        if self.AdonisLoaded then
            return true, "already-loaded"
        end

        local ok, err =
            compileSource(
                "Adonis Bypass",
                AdonisSource
            )

        if not ok then
            return false, err
        end

        self.AdonisLoaded = true
        return true
    end

    function Pack:StopAll()
        self:SetGlobalBurstEnabled(false)
        self:SetVehicleBombardEnabled(false)

        local silent = self:GetSilentAim()

        if silent and silent.SetEnabled then
            pcall(function()
                silent:SetEnabled(false)
                silent:SetTeamVehicleMonitor(false)
            end)
        end
    end

    _G.SyntaxImportedFeaturePack = Pack
    _G.SyntaxImportedFeaturePackReady = true
end)();


-- ================================================================
-- SECTION 11: EXTERNAL UI COMPONENT BINDINGS
-- All migrated controls live inside this nested scope, keeping the
-- stable script top-level local-variable budget unchanged.
-- ================================================================
boot.Stage = "绑定界面控件";
(function()
    local Window = _G.SyntaxNextWindow
    local NexusFeatureList = _G.NexusFeatureList
    local FeatureDisplayNames = {
        ["RageBot"] = "RageBot",
        ["命中框"] = "Hitbox",
        ["镜头瞄准"] = "Camera Aim",
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
        ["全图连发"] = "Global Burst",
        ["载具帧频轰炸"] = "Vehicle Bombard",
        ["增强静默瞄准"] = "SilentAim Pro",
        ["Adonis Bypass"] = "Adonis Bypass",
        ["AutoPowerOrder++"] = "AutoPowerOrder++",
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

    CombatTab:Toggle({
        Title = "全图连发",
        Default = false,
        Keybind = {},
        Callback = function(value)
            local pack = _G.SyntaxImportedFeaturePack

            if pack then
                pack:SetGlobalBurstEnabled(
                    value == true
                )
            end

            syncFeature(
                "全图连发",
                value == true,
                "Render"
            )
        end,
    })

    CombatTab:Button({
        Title = "单次全载具弱点打击",
        Callback = function()
            local pack =
                _G.SyntaxImportedFeaturePack

            local ok =
                pack
                and pack:SendVehicleDamageOnce()

            Window:Notify({
                Title = "载具摧毁",
                Content = ok
                    and "已发送一轮全载具弱点打击。"
                    or "未找到可攻击载具或 Damage Remote。",
                Duration = 2,
            })
        end,
    })

    CombatTab:Toggle({
        Title = "载具帧频轰炸",
        Default = false,
        Keybind = {},
        Callback = function(value)
            local pack =
                _G.SyntaxImportedFeaturePack

            if pack then
                pack:SetVehicleBombardEnabled(
                    value == true
                )
            end

            syncFeature(
                "载具帧频轰炸",
                value == true,
                "Frame"
            )
        end,
    })

    CombatTab:Section({
        Title = "SilentAim Pro",
        TextXAlignment = "Left",
        TextSize = 17,
    })

    local ImportedSilentAimState = {
        Enabled = false,
        TeamCheck = true,
        WallCheck = true,
        TrackEnabled = false,
        TrackChance = 85,
        FOVEnabled = false,
        FOVRadius = 160,
        TargetType = "PLAYER",
        TargetPart = "Head",
        AimMode = "TP",
        Highlight = false,
        SpecialMode = "NORMAL",
        TeamVehicleMonitor = false,
    }

    local function applyImportedSilentAimState(api)
        if not api then
            return
        end

        pcall(function()
            api:SetTeamCheck(
                ImportedSilentAimState.TeamCheck
            )

            api:SetWallCheck(
                ImportedSilentAimState.WallCheck
            )

            api:SetTrackEnabled(
                ImportedSilentAimState.TrackEnabled
            )

            api:SetTrackChance(
                ImportedSilentAimState.TrackChance
            )

            api:SetFOVEnabled(
                ImportedSilentAimState.FOVEnabled
            )

            api:SetFOVRadius(
                ImportedSilentAimState.FOVRadius
            )

            api:SetTargetType(
                ImportedSilentAimState.TargetType
            )

            api:SetTargetPart(
                ImportedSilentAimState.TargetPart
            )

            api:SetAimMode(
                ImportedSilentAimState.AimMode
            )

            api:SetHighlight(
                ImportedSilentAimState.Highlight
            )

            api:SetSpecialMode(
                ImportedSilentAimState.SpecialMode
            )

            api:SetTeamVehicleMonitor(
                ImportedSilentAimState
                    .TeamVehicleMonitor
            )
        end)
    end

    local function existingImportedSilentAim()
        local pack =
            _G.SyntaxImportedFeaturePack

        return pack
            and pack:GetSilentAim()
            or nil
    end

    local function ensureImportedSilentAim()
        local pack =
            _G.SyntaxImportedFeaturePack

        if not pack then
            return nil,
                "导入功能管理器未加载"
        end

        local api, err =
            pack:EnsureSilentAim()

        if not api then
            Window:Notify({
                Title = "SilentAim Pro",
                Content = tostring(err),
                Duration = 5,
            })
        end

        return api, err
    end

    CombatTab:Toggle({
        Title = "增强静默瞄准",
        Default = false,
        Keybind = {},
        Callback = function(value)
            local enabled = value == true
            ImportedSilentAimState.Enabled =
                enabled

            if enabled then
                local api =
                    ensureImportedSilentAim()

                if api then
                    applyImportedSilentAimState(api)

                    pcall(function()
                        api:SetEnabled(true)
                    end)

                    syncFeature(
                        "增强静默瞄准",
                        true,
                        ImportedSilentAimState
                            .AimMode
                    )
                else
                    syncFeature(
                        "增强静默瞄准",
                        false,
                        "Error"
                    )
                end
            else
                local api =
                    existingImportedSilentAim()

                if api then
                    pcall(function()
                        api:SetEnabled(false)
                    end)
                end

                syncFeature(
                    "增强静默瞄准",
                    false,
                    ImportedSilentAimState
                        .AimMode
                )
            end
        end,
    })

    CombatTab:Toggle({
        Title = "SilentAim 队伍检测",
        Default = true,
        Callback = function(value)
            ImportedSilentAimState.TeamCheck =
                value == true

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetTeamCheck(
                        ImportedSilentAimState
                            .TeamCheck
                    )
                end)
            end
        end,
    })

    CombatTab:Toggle({
        Title = "SilentAim 墙体检测",
        Default = true,
        Callback = function(value)
            ImportedSilentAimState.WallCheck =
                value == true

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetWallCheck(
                        ImportedSilentAimState
                            .WallCheck
                    )
                end)
            end
        end,
    })

    CombatTab:Toggle({
        Title = "SilentAim 概率追踪",
        Default = false,
        Callback = function(value)
            ImportedSilentAimState.TrackEnabled =
                value == true

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetTrackEnabled(
                        ImportedSilentAimState
                            .TrackEnabled
                    )
                end)
            end
        end,
    })

    CombatTab:Slider({
        Title = "SilentAim 追踪概率",
        Value = {
            Min = 0,
            Max = 100,
            Default = 85,
        },
        Increment = 1,
        Callback = function(value)
            ImportedSilentAimState.TrackChance =
                math.clamp(
                    tonumber(value) or 85,
                    0,
                    100
                )

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetTrackChance(
                        ImportedSilentAimState
                            .TrackChance
                    )
                end)
            end
        end,
    })

    CombatTab:Toggle({
        Title = "显示 SilentAim FOV",
        Default = false,
        Callback = function(value)
            ImportedSilentAimState.FOVEnabled =
                value == true

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetFOVEnabled(
                        ImportedSilentAimState
                            .FOVEnabled
                    )
                end)
            end
        end,
    })

    CombatTab:Slider({
        Title = "SilentAim FOV 半径",
        Value = {
            Min = 20,
            Max = 500,
            Default = 160,
        },
        Increment = 10,
        Callback = function(value)
            ImportedSilentAimState.FOVRadius =
                math.clamp(
                    tonumber(value) or 160,
                    20,
                    500
                )

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetFOVRadius(
                        ImportedSilentAimState
                            .FOVRadius
                    )
                end)
            end
        end,
    })

    CombatTab:AnimatedSelector({
        Title = "SilentAim 目标类型",
        Values = {
            "玩家",
            "NPC",
            "玩家+NPC",
        },
        Value = "玩家",
        Callback = function(value)
            local map = {
                ["玩家"] = "PLAYER",
                ["NPC"] = "NPC",
                ["玩家+NPC"] = "BOTH",
            }

            ImportedSilentAimState.TargetType =
                map[tostring(value)]
                or "PLAYER"

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetTargetType(
                        ImportedSilentAimState
                            .TargetType
                    )
                end)
            end
        end,
    })

    CombatTab:AnimatedSelector({
        Title = "SilentAim 目标部位",
        Values = {
            "头部",
            "身体",
            "随机",
            "四肢",
            "右臂",
        },
        Value = "头部",
        Callback = function(value)
            local map = {
                ["头部"] = "Head",
                ["身体"] = "HumanoidRootPart",
                ["随机"] = "RANDOM",
                ["四肢"] = "LIMBS",
                ["右臂"] = "SURR",
            }

            ImportedSilentAimState.TargetPart =
                map[tostring(value)]
                or "Head"

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetTargetPart(
                        ImportedSilentAimState
                            .TargetPart
                    )
                end)
            end
        end,
    })

    CombatTab:AnimatedSelector({
        Title = "SilentAim 瞄准模式",
        Values = {
            "TP",
            "DIRECT",
        },
        Value = "TP",
        Callback = function(value)
            ImportedSilentAimState.AimMode =
                tostring(value) == "DIRECT"
                and "DIRECT"
                or "TP"

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetAimMode(
                        ImportedSilentAimState
                            .AimMode
                    )
                end)
            end

            syncFeatureMode(
                "增强静默瞄准",
                ImportedSilentAimState.AimMode
            )
        end,
    })

    CombatTab:AnimatedSelector({
        Title = "SilentAim 特殊模式",
        Values = {
            "普通",
            "RCV",
            "载具",
        },
        Value = "普通",
        Callback = function(value)
            local map = {
                ["普通"] = "NORMAL",
                ["RCV"] = "RCV",
                ["载具"] = "VEHICLE",
            }

            ImportedSilentAimState.SpecialMode =
                map[tostring(value)]
                or "NORMAL"

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetSpecialMode(
                        ImportedSilentAimState
                            .SpecialMode
                    )
                end)
            end
        end,
    })

    CombatTab:Toggle({
        Title = "SilentAim 目标高亮",
        Default = false,
        Callback = function(value)
            ImportedSilentAimState.Highlight =
                value == true

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetHighlight(
                        ImportedSilentAimState
                            .Highlight
                    )
                end)
            end
        end,
    })

    CombatTab:Toggle({
        Title = "队友载具弹药监控",
        Default = false,
        Callback = function(value)
            ImportedSilentAimState
                .TeamVehicleMonitor =
                value == true

            local api =
                existingImportedSilentAim()

            if api then
                pcall(function()
                    api:SetTeamVehicleMonitor(
                        ImportedSilentAimState
                            .TeamVehicleMonitor
                    )
                end)
            end
        end,
    })
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

    CombatTab:Toggle({Title = "瞄准队伍检测", Default = AimbotTeamCheck, Callback = function(v)
        AimbotTeamCheck = v == true
    end})

    CombatTab:Toggle({Title = "瞄准墙体检测", Default = AimbotWallCheck, Callback = function(v)
        AimbotWallCheck = v == true
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

    CombatTab:Dropdown({
        Title = "瞄准部位",
        Values = {"Head", "HumanoidRootPart"},
        Value = AimbotTargetPart,
        Callback = function(v)
            AimbotTargetPart = tostring(v)
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

    MiscTab:Button({
        Title = "启用 Adonis Bypass",
        Callback = function()
            local pack =
                _G.SyntaxImportedFeaturePack

            if not pack then
                Window:Notify({
                    Title = "Adonis Bypass",
                    Content = "导入功能管理器未加载。",
                    Duration = 3,
                })
                return
            end

            local ok, err =
                pack:EnableAdonisBypass()

            if ok then
                syncFeature(
                    "Adonis Bypass",
                    true,
                    "Hook"
                )
            end

            Window:Notify({
                Title = "Adonis Bypass",
                Content = ok
                    and "已启用。"
                    or tostring(err),
                Duration = 4,
            })
        end,
    })

    MiscTab:Section({
        Title = "AutoPowerOrder++",
        TextXAlignment = "Left",
        TextSize = 17,
    })

    MiscTab:Toggle({
        Title = "AutoPowerOrder++",
        Default = false,
        Keybind = {},
        Callback = function(value)
            local enabled = value == true

            if enabled then
                local ok, err = pcall(function()
                    return _G.SyntaxStartAutoPowerOrderPlusPlus()
                end)

                if not ok then
                    Window:Notify({
                        Title = "AutoPowerOrder++",
                        Content = "启动失败：" .. tostring(err),
                        Duration = 4,
                    })
                end
            else
                pcall(function()
                    _G.SyntaxStopAutoPowerOrderPlusPlus()
                end)
            end

            syncFeature("AutoPowerOrder++", enabled, "Auto")
        end,
    })
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
        syncFeature("载具飞行", false)
        syncFeature("SpinBot", false)
        syncFeature("即时交互", false)
        syncFeature("聊天日志", false)
        syncFeature("破坏设备", false, "Packet")
        syncFeature("全图连发", false, "Render")
        syncFeature("载具帧频轰炸", false, "Frame")
        syncFeature("增强静默瞄准", false, "TP")
        pcall(function()
            _G.SyntaxStopAutoPowerOrderPlusPlus()
        end)
        syncFeature("AutoPowerOrder++", false, "Auto")
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
            syncFeature("破坏设备", BreakDeviceEnabled, BreakDeviceAttackMode == "群体攻击" and "Group" or "Single")
        end,
    })

    MiscTab:AnimatedSelector({
        Title = "破坏设备攻击模式",
        Values = {"单体攻击", "群体攻击"},
        Value = BreakDeviceAttackMode,
        Callback = function(value)
            value = tostring(value)

            if value == "群体攻击" then
                BreakDeviceAttackMode = "群体攻击"
            else
                BreakDeviceAttackMode = "单体攻击"
            end

            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetMode then
                    _G.NexusFeatureList:SetMode(
                        "Destroy Devices",
                        BreakDeviceAttackMode == "群体攻击" and "Group" or "Single"
                    )
                end
            end)
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
            syncFeature("破坏设备", BreakDeviceEnabled, BreakDeviceAttackMode == "群体攻击" and "Group" or "Single")
        end,
    })

    
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
            BreakDeviceAttackMode = BreakDeviceAttackMode,
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
        if data.BreakDeviceAttackMode ~= nil then
            local mode = tostring(data.BreakDeviceAttackMode)
            BreakDeviceAttackMode = mode == "群体攻击"
                and "群体攻击"
                or "单体攻击"
        end

        applyBool("HitboxEnabled", HitboxEnabled, function(v) setToggleByCurrent(HitboxEnabled,v,ToggleHitboxState) end)
        applyBool("InfAmmoEnabled", InfAmmoEnabled, function(v) InfAmmoEnabled=v end)
        applyBool("AimbotEnabled", AimbotEnabled, SetAimbotEnabled)
        applyBool("TracerEnabled", TracerEnabled, function(v) TracerEnabled=v end)
        applyBool("ZoomEnabled", ZoomEnabled, function(v) ZoomEnabled=v end)
        applyBool("ShowAimbotFOV", ShowAimbotFOV, function(v) ShowAimbotFOV=v; pcall(UpdateAimFovCircles) end)
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
            {"破坏设备", BreakDeviceEnabled, BreakDeviceAttackMode == "群体攻击" and "Group" or "Single"},
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

    StyleTab:Section({Title = "功能列表样式", TextXAlignment = "Left", TextSize = 17})

    StyleTab:AnimatedSelector({
        Title = "功能列表样式",
        Values = {"None", "Split", "Bar", "Outline", "BloomFlow"},
        Value = "None",
        Callback = function(value)
            pcall(function()
                if _G.NexusFeatureList and _G.NexusFeatureList.SetDisplay then
                    _G.NexusFeatureList:SetDisplay(tostring(value))
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

end)();


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

boot.Stage = "初始化附加组件"
do
    local addonOk, addonError = pcall(InitNexusRageBot)
    if not addonOk then
        boot.AddonError = tostring(addonError)
        warn("[Syntax] 附加组件初始化失败: " .. boot.AddonError)
    end
end

-- 记录功能引擎与 XHanUI 外部界面的初始化结果。
_G.NexusUIReady = _G.SyntaxNextWindow ~= nil
boot.Ready = _G.NexusUIReady
boot.Stage = boot.AddonError and "主界面就绪（附加组件失败）" or "就绪"
print("[Syntax] " .. boot.Stage)


end, traceback)

if not bootOk then
    boot.Ready = false
    boot.Error = tostring(bootError)
    _G.NexusUIReady = false
    warn("[Syntax][" .. boot.Stage .. "] " .. boot.Error)
    -- Error UI uses Roblox objects directly, so a missing UI library cannot hide it.
    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local parent = player and (player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5))
        if not parent then return end
        local gui = Instance.new("ScreenGui")
        gui.Name = "SyntaxStartupError"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1000
        gui.Parent = parent
        local panel = Instance.new("Frame")
        panel.AnchorPoint = Vector2.new(0.5, 0)
        panel.Position = UDim2.new(0.5, 0, 0, 20)
        panel.Size = UDim2.new(0.9, 0, 0, 190)
        panel.BackgroundColor3 = Color3.fromRGB(36, 24, 29)
        panel.BorderSizePixel = 0
        panel.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = panel
        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Position = UDim2.fromOffset(14, 12)
        text.Size = UDim2.new(1, -56, 1, -24)
        text.Font = Enum.Font.Code
        text.TextSize = 14
        text.TextColor3 = Color3.fromRGB(255, 220, 220)
        text.TextWrapped = true
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextYAlignment = Enum.TextYAlignment.Top
        text.TextTruncate = Enum.TextTruncate.AtEnd
        text.Text = "Syntax 启动失败 · " .. boot.Stage .. "\n" .. boot.Error .. "\n完整报错见控制台。"
        text.Parent = panel
        local close = Instance.new("TextButton")
        close.Size = UDim2.fromOffset(30, 30)
        close.Position = UDim2.new(1, -36, 0, 6)
        close.BackgroundTransparency = 1
        close.Text = "×"
        close.TextSize = 24
        close.TextColor3 = Color3.new(1, 1, 1)
        close.Parent = panel
        close.Activated:Connect(function() gui:Destroy() end)
    end)
end
end
