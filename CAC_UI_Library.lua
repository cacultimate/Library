-- ==============================================================================
-- CAC ULTIMATE - PREMIUM UI FRAMEWORK
-- Criado para projetos de alto nível.
-- ==============================================================================

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local CAC_UI = {}

-- Tema extraído do seu Plugin
local Theme = {
    Bg = Color3.fromRGB(12, 12, 12),
    Panel = Color3.fromRGB(20, 20, 20),
    PanelHover = Color3.fromRGB(28, 28, 28),
    Border = Color3.fromRGB(45, 45, 45),
    TextMain = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(140, 140, 140),
    Accent = Color3.fromRGB(255, 255, 255)
}

local TI = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Utilitários
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

-- ==============================================================================
-- FUNÇÃO PRINCIPAL: CRIAR JANELA
-- ==============================================================================
function CAC_UI:CreateWindow(Config)
    local Window = { Tabs = {}, CurrentTab = nil }
    
    -- Proteção contra duplicatas
    if CoreGui:FindFirstChild(Config.Name) then
        CoreGui:FindFirstChild(Config.Name):Destroy()
    end

    local ScreenGui = Create("ScreenGui", { Name = Config.Name, Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    
    -- TELA DE LOADING PREMIUM
    local LoadingFrame = Create("Frame", {
        Parent = ScreenGui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, ZIndex = 1000
    })
    
    local LoadingTitle = Create("TextLabel", {
        Parent = LoadingFrame, Text = Config.LoadingTitle or "CAC ULTIMATE", Font = Enum.Font.GothamBold,
        TextSize = 28, TextColor3 = Theme.TextMain, Size = UDim2.fromScale(1, 1),
        Position = UDim2.new(0, 0, -0.05, 0), BackgroundTransparency = 1
    })
    
    local LoadingSub = Create("TextLabel", {
        Parent = LoadingFrame, Text = "Carregando módulos pesados...\nPode haver travamentos temporários em PCs Low-End.",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.TextDim,
        Size = UDim2.fromScale(1, 1), Position = UDim2.new(0, 0, 0.05, 0), BackgroundTransparency = 1
    })

    local Spinner = Create("ImageLabel", {
        Parent = LoadingFrame, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0.5, -20, 0.6, 0),
        BackgroundTransparency = 1, Image = "rbxassetid://358245233", ImageColor3 = Theme.Accent
    })
    
    -- Animação de Loading (Girando)
    local spinnerConn = RunService.RenderStepped:Connect(function()
        Spinner.Rotation = Spinner.Rotation + 3
    end)

    -- FRAME PRINCIPAL (Oculto no início)
    local MainFrame = Create("Frame", {
        Parent = ScreenGui, Size = UDim2.new(0, 750, 0, 480), Position = UDim2.new(0.5, -375, 0.5, -240),
        BackgroundColor3 = Theme.Bg, ClipsDescendants = true, Visible = false
    })
    ApplyCorner(MainFrame, 10)
    ApplyStroke(MainFrame, Theme.Border)

    -- Sidebar (Esquerda)
    local Sidebar = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(0, 180, 1, 0), BackgroundColor3 = Theme.Panel
    })
    ApplyStroke(Sidebar, Theme.Border)
    
    local Title = Create("TextLabel", {
        Parent = Sidebar, Text = Config.Name, Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = Theme.TextMain, Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1
    })

    local TabContainer = Create("ScrollingFrame", {
        Parent = Sidebar, Size = UDim2.new(1, 0, 1, -60), Position = UDim2.new(0, 0, 0, 60),
        BackgroundTransparency = 1, ScrollBarThickness = 0
    })
    local TabList = Create("UIListLayout", { Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })

    -- Área de Conteúdo (Direita)
    local ContentContainer = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(1, -180, 1, 0), Position = UDim2.new(0, 180, 0, 0), BackgroundTransparency = 1
    })

    -- ==============================================================================
    -- GERENCIAMENTO DE ABAS
    -- ==============================================================================
    function Window:CreateTab(TabName)
        local Tab = { Elements = {} }
        
        local TabBtn = Create("TextButton", {
            Parent = TabContainer, Size = UDim2.new(1, -20, 0, 35), Position = UDim2.new(0, 10, 0, 0),
            BackgroundColor3 = Theme.Panel, Text = "  " .. TabName, Font = Enum.Font.GothamMedium,
            TextSize = 13, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left
        })
        ApplyCorner(TabBtn, 6)

        local TabPage = Create("ScrollingFrame", {
            Parent = ContentContainer, Size = UDim2.new(1, -40, 1, -40), Position = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border
        })
        local PageList = Create("UIListLayout", { Parent = TabPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Btn, TI, {TextColor3 = Theme.TextDim, BackgroundColor3 = Theme.Panel}):Play()
            end
            TabPage.Visible = true
            TweenService:Create(TabBtn, TI, {TextColor3 = Theme.TextMain, BackgroundColor3 = Theme.PanelHover}):Play()
        end)

        if not Window.CurrentTab then
            Window.CurrentTab = Tab
            TabPage.Visible = true
            TabBtn.TextColor3 = Theme.TextMain
            TabBtn.BackgroundColor3 = Theme.PanelHover
        end

        Tab.Btn = TabBtn
        Tab.Page = TabPage
        table.insert(Window.Tabs, Tab)

        -- ==============================================================================
        -- ELEMENTOS DA ABA (DASHBOARD, BOTÕES, ETC)
        -- ==============================================================================
        
        -- Criar o Dashboard Premium
        function Tab:CreateDashboard(DashConfig)
            local DashFrame = Create("Frame", {
                Parent = TabPage, Size = UDim2.new(1, 0, 0, 160), BackgroundColor3 = Theme.Panel
            })
            ApplyCorner(DashFrame, 8)
            ApplyStroke(DashFrame, Theme.Border)

            -- Foto de Perfil e Nome
            local Avatar = Create("ImageLabel", {
                Parent = DashFrame, Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Theme.Bg
            })
            ApplyCorner(Avatar, 100)
            
            -- Carregar a foto real do jogador
            task.spawn(function()
                local thumb, ready = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                if ready then Avatar.Image = thumb end
            end)

            local Welcome = Create("TextLabel", {
                Parent = DashFrame, Text = "Bem-vindo(a), " .. LocalPlayer.Name, Font = Enum.Font.GothamBold,
                TextSize = 18, TextColor3 = Theme.TextMain, Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 95, 0, 25), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
            })

            local UserIDText = Create("TextLabel", {
                Parent = DashFrame, Text = "UID: " .. LocalPlayer.UserId, Font = Enum.Font.Gotham,
                TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 95, 0, 50), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
            })

            -- Caixa de Informações da Key
            local KeyBox = Create("Frame", {
                Parent = DashFrame, Size = UDim2.new(1, -40, 0, 50), Position = UDim2.new(0, 20, 0, 95), BackgroundColor3 = Theme.Bg
            })
            ApplyCorner(KeyBox, 6)
            
            Create("TextLabel", {
                Parent = KeyBox, Text = " LICENÇA: " .. (DashConfig.LicenseType or "Padrão"), Font = Enum.Font.GothamBold,
                TextSize = 12, TextColor3 = Theme.Accent, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
            })
            Create("TextLabel", {
                Parent = KeyBox, Text = "EXPIRA EM: " .. (DashConfig.Expiration or "Nunca") .. " ", Font = Enum.Font.GothamMedium,
                TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right
            })
        end

        -- Criar Changelog
        function Tab:CreateChangelog(Version, UpdatesText)
            local ChangeFrame = Create("Frame", {
                Parent = TabPage, Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = Theme.Panel
            })
            ApplyCorner(ChangeFrame, 8)
            ApplyStroke(ChangeFrame, Theme.Border)

            Create("TextLabel", {
                Parent = ChangeFrame, Text = "Atualização " .. Version, Font = Enum.Font.GothamBold,
                TextSize = 14, TextColor3 = Theme.TextMain, Size = UDim2.new(1, -30, 0, 30), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
            })

            Create("TextLabel", {
                Parent = ChangeFrame, Text = UpdatesText, Font = Enum.Font.Gotham,
                TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(1, -30, 1, -50), Position = UDim2.new(0, 15, 0, 40), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
            })
        end

        -- Botão Padrão
        function Tab:CreateButton(Text, Callback)
            local Btn = Create("TextButton", {
                Parent = TabPage, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Panel,
                Text = Text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.TextMain
            })
            ApplyCorner(Btn, 6)
            ApplyStroke(Btn, Theme.Border)

            Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TI, {BackgroundColor3 = Theme.PanelHover}):Play() end)
            Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TI, {BackgroundColor3 = Theme.Panel}):Play() end)
            Btn.MouseButton1Click:Connect(Callback)
        end

        return Tab
    end

    -- Função para encerrar o loading e mostrar a UI
    function Window:FinishLoading()
        spinnerConn:Disconnect()
        TweenService:Create(Spinner, TI, {ImageTransparency = 1}):Play()
        TweenService:Create(LoadingTitle, TI, {TextTransparency = 1}):Play()
        TweenService:Create(LoadingSub, TI, {TextTransparency = 1}):Play()
        task.wait(0.5)
        TweenService:Create(LoadingFrame, TI, {BackgroundTransparency = 1}):Play()
        
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 700, 0, 440)
        MainFrame.Position = UDim2.new(0.5, -350, 0.5, -220)
        MainFrame.GroupTransparency = 1
        
        TweenService:Create(MainFrame, TI, {
            Size = UDim2.new(0, 750, 0, 480),
            Position = UDim2.new(0.5, -375, 0.5, -240),
            GroupTransparency = 0
        }):Play()
        
        task.wait(0.3)
        LoadingFrame:Destroy()
    end

    return Window
end

return CAC_UI