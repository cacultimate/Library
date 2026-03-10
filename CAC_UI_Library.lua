--[[
    CAC ULTIMATE - PREMIUM UI FRAMEWORK v2.0
    Arquitetura Pesada, Janela Flutuante, Loading Inteligente e Animações Fluidas.
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local CAC_UI = {}

-- Tema Escuro Premium (Cores exatas do seu plugin)
local Theme = {
    Bg = Color3.fromRGB(15, 15, 18),
    Sidebar = Color3.fromRGB(20, 20, 25),
    Panel = Color3.fromRGB(25, 25, 30),
    PanelHover = Color3.fromRGB(35, 35, 45),
    Border = Color3.fromRGB(40, 40, 50),
    TextMain = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160),
    Accent = Color3.fromRGB(80, 100, 255),
    Success = Color3.fromRGB(80, 255, 100),
    Error = Color3.fromRGB(255, 80, 80)
}

local TI = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

local function ApplyCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function ApplyStroke(parent, color)
    return Create("UIStroke", { Color = color, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end

-- Sistema de Arrastar Janela Suave (Smooth Drag)
local function MakeDraggable(topbarObject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        local Tween = TweenService:Create(object, TweenInfo.new(0.15), {Position = pos})
        Tween:Play()
    end

    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)

    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then DragInput = input end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then Update(input) end
    end)
end

-- ==============================================================================
-- MOTOR DE CRIAÇÃO DA JANELA
-- ==============================================================================
function CAC_UI:CreateWindow(Config)
    local Window = { Tabs = {}, CurrentTab = nil, IsLoaded = false }
    
    if CoreGui:FindFirstChild(Config.Name) then CoreGui:FindFirstChild(Config.Name):Destroy() end

    local ScreenGui = Create("ScreenGui", { Name = Config.Name, Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

    -- JANELA PRINCIPAL (Flutuante)
    local MainFrame = Create("Frame", {
        Parent = ScreenGui, Size = UDim2.new(0, 750, 0, 450), Position = UDim2.new(0.5, -375, 0.5, -225),
        BackgroundColor3 = Theme.Bg, ClipsDescendants = true
    })
    ApplyCorner(MainFrame, 10)
    ApplyStroke(MainFrame, Theme.Border)

    -- Topbar Invisível para Arrastar
    local DragTopbar = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 100
    })
    MakeDraggable(DragTopbar, MainFrame)

    -- ==============================================================================
    -- OVERLAY DE LOADING (Fica dentro da janela flutuante)
    -- ==============================================================================
    local LoadingOverlay = Create("Frame", {
        Parent = MainFrame, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, ZIndex = 2000
    })
    
    local LoadTitle = Create("TextLabel", {
        Parent = LoadingOverlay, Text = Config.LoadingTitle or "Authenticating...", Font = Enum.Font.GothamBold,
        TextSize = 24, TextColor3 = Theme.TextMain, Size = UDim2.fromScale(1, 1), Position = UDim2.new(0, 0, -0.05, 0), BackgroundTransparency = 1
    })
    
    local LoadSub = Create("TextLabel", {
        Parent = LoadingOverlay, Text = "Carregando módulos de alta performance...\nIsto pode levar alguns segundos.",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.fromScale(1, 1), Position = UDim2.new(0, 0, 0.05, 0), BackgroundTransparency = 1
    })

    local Spinner = Create("ImageLabel", {
        Parent = LoadingOverlay, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0.5, -20, 0.65, 0),
        BackgroundTransparency = 1, Image = "rbxassetid://358245233", ImageColor3 = Theme.Accent
    })
    local spinnerConn = RunService.RenderStepped:Connect(function() Spinner.Rotation = Spinner.Rotation + 4 end)

    -- FAILSAFE INTELIGENTE: Remove o loading à força após 20 segundos
    task.delay(20, function()
        if not Window.IsLoaded then Window:FinishLoading() end
    end)

    -- ==============================================================================
    -- CONTEÚDO DA UI (SIDEBAR E ABAS)
    -- ==============================================================================
    local Sidebar = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(0, 180, 1, 0), BackgroundColor3 = Theme.Sidebar
    })
    ApplyStroke(Sidebar, Theme.Border)
    
    Create("TextLabel", {
        Parent = Sidebar, Text = "CAC ULTIMATE", Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = Theme.TextMain, Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1
    })

    local TabContainer = Create("ScrollingFrame", {
        Parent = Sidebar, Size = UDim2.new(1, 0, 1, -80), Position = UDim2.new(0, 0, 0, 60),
        BackgroundTransparency = 1, ScrollBarThickness = 0
    })
    Create("UIListLayout", { Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center })

    local ContentContainer = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(1, -180, 1, 0), Position = UDim2.new(0, 180, 0, 0), BackgroundTransparency = 1
    })

    -- ==============================================================================
    -- GERENCIADOR DE ABAS
    -- ==============================================================================
    function Window:CreateTab(TabName)
        local Tab = {}
        
        local TabBtn = Create("TextButton", {
            Parent = TabContainer, Size = UDim2.new(0.9, 0, 0, 35), BackgroundColor3 = Theme.Sidebar,
            Text = "  " .. TabName, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left
        })
        ApplyCorner(TabBtn, 6)

        local TabPage = Create("ScrollingFrame", {
            Parent = ContentContainer, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border
        })
        Create("UIListLayout", { Parent = TabPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Btn, TI, {TextColor3 = Theme.TextDim, BackgroundColor3 = Theme.Sidebar}):Play()
            end
            TabPage.Visible = true
            TweenService:Create(TabBtn, TI, {TextColor3 = Theme.TextMain, BackgroundColor3 = Theme.Panel}):Play()
        end)

        if not Window.CurrentTab then
            Window.CurrentTab = Tab
            TabPage.Visible = true
            TabBtn.TextColor3 = Theme.TextMain
            TabBtn.BackgroundColor3 = Theme.Panel
        end

        Tab.Btn = TabBtn
        Tab.Page = TabPage
        table.insert(Window.Tabs, Tab)

        -- ==============================================================================
        -- ELEMENTOS DA ABA (Buttons, Inputs, Labels)
        -- ==============================================================================
        
        function Tab:CreateLabel(Text)
            local Label = Create("TextLabel", {
                Parent = TabPage, Size = UDim2.new(1, -10, 0, 20), BackgroundTransparency = 1,
                Text = Text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left
            })
            return Label
        end

        function Tab:CreateButton(Text, Callback)
            local Btn = Create("TextButton", {
                Parent = TabPage, Size = UDim2.new(1, -10, 0, 40), BackgroundColor3 = Theme.Panel,
                Text = Text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.TextMain
            })
            ApplyCorner(Btn, 6)
            ApplyStroke(Btn, Theme.Border)

            Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TI, {BackgroundColor3 = Theme.PanelHover}):Play() end)
            Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TI, {BackgroundColor3 = Theme.Panel}):Play() end)
            
            Btn.MouseButton1Click:Connect(function()
                -- Efeito de clique (Ripple simulado)
                TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(0.98, -10, 0, 38)}):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -10, 0, 40)}):Play()
                Callback()
            end)
        end

        function Tab:CreateInput(Placeholder, Callback)
            local InputBg = Create("Frame", {
                Parent = TabPage, Size = UDim2.new(1, -10, 0, 40), BackgroundColor3 = Theme.Bg
            })
            ApplyCorner(InputBg, 6)
            local Stroke = ApplyStroke(InputBg, Theme.Border)

            local Box = Create("TextBox", {
                Parent = InputBg, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1, Text = "", PlaceholderText = Placeholder,
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.TextMain,
                TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
            })

            Box.Focused:Connect(function() TweenService:Create(Stroke, TI, {Color = Theme.Accent}):Play() end)
            Box.FocusLost:Connect(function() 
                TweenService:Create(Stroke, TI, {Color = Theme.Border}):Play()
                Callback(Box.Text) 
            end)
        end

        function Tab:CreateDashboard(DashConfig)
            local DashFrame = Create("Frame", {
                Parent = TabPage, Size = UDim2.new(1, -10, 0, 120), BackgroundColor3 = Theme.Panel
            })
            ApplyCorner(DashFrame, 8)
            ApplyStroke(DashFrame, Theme.Border)

            local Avatar = Create("ImageLabel", {
                Parent = DashFrame, Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Theme.Bg
            })
            ApplyCorner(Avatar, 100)
            
            task.spawn(function()
                local thumb, ready = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                if ready then Avatar.Image = thumb end
            end)

            Create("TextLabel", {
                Parent = DashFrame, Text = "Hello, " .. LocalPlayer.Name, Font = Enum.Font.GothamBold,
                TextSize = 18, TextColor3 = Theme.TextMain, Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 95, 0, 25), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
            })

            Create("TextLabel", {
                Parent = DashFrame, Text = "UID: " .. LocalPlayer.UserId .. " | Status: " .. (DashConfig.LicenseType or "Active"), Font = Enum.Font.Gotham,
                TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 95, 0, 50), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
            })
        end

        return Tab
    end

    -- ==============================================================================
    -- FUNÇÃO DE FINALIZAR LOADING
    -- ==============================================================================
    function Window:FinishLoading()
        if Window.IsLoaded then return end
        Window.IsLoaded = true
        spinnerConn:Disconnect()
        
        TweenService:Create(Spinner, TI, {ImageTransparency = 1}):Play()
        TweenService:Create(LoadTitle, TI, {TextTransparency = 1}):Play()
        TweenService:Create(LoadSub, TI, {TextTransparency = 1}):Play()
        task.wait(0.3)
        TweenService:Create(LoadingOverlay, TI, {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        LoadingOverlay:Destroy()
    end

    return Window
end

return CAC_UI
