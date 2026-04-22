--[[
    CAC ULTIMATE FRAMEWORK
    Version: 3.0 (Architect Edition)
    Description: Premium, modular, pure-black UI framework for elite scripting.
    Language: English Only
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [ ENVIRONMENT SAFEGUARDS ]
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end
local isfile = isfile or function() return false end
local readfile = readfile or function() return "{}" end
local writefile = writefile or function() end
local delfile = delfile or function() end
local listfiles = listfiles or function() return {} end

-- ==============================================================================
-- 1. UTILITY & THEME MANAGER
-- ==============================================================================

local Utility = {}
local ThemeManager = {
    Themes = {
        Default = {
            Background = Color3.fromRGB(5, 5, 5),        -- Purest Dark
            Panel = Color3.fromRGB(12, 12, 12),          -- Slightly elevated
            PanelHover = Color3.fromRGB(18, 18, 18),
            Border = Color3.fromRGB(24, 24, 24),
            BorderHighlight = Color3.fromRGB(40, 40, 40),
            Text = Color3.fromRGB(255, 255, 255),
            TextDark = Color3.fromRGB(140, 140, 140),
            TextMuted = Color3.fromRGB(80, 80, 80),
            Accent = Color3.fromRGB(255, 255, 255),      -- White Accent
            Success = Color3.fromRGB(120, 255, 120),
            Error = Color3.fromRGB(255, 80, 80),
            Warning = Color3.fromRGB(255, 200, 80),
            Shadow = Color3.fromRGB(0, 0, 0)
        }
    },
    Current = "Default",
    Registry = {} -- Stores instances for dynamic theme updates
}

function ThemeManager:Get(key)
    return self.Themes[self.Current][key]
end

function ThemeManager:Register(instance, property, colorKey)
    if not self.Registry[instance] then self.Registry[instance] = {} end
    self.Registry[instance][property] = colorKey
    instance[property] = self:Get(colorKey)
end

function ThemeManager:SetAccent(color)
    self.Themes[self.Current].Accent = color
    self:UpdateAll()
end

function ThemeManager:UpdateAll()
    for instance, properties in pairs(self.Registry) do
        if instance and instance.Parent then
            for prop, key in pairs(properties) do
                TweenService:Create(instance, TweenInfo.new(0.3), {[prop] = self:Get(key)}):Play()
            end
        else
            self.Registry[instance] = nil
        end
    end
end

-- Tween Helper
function Utility:Tween(obj, props, time, style, dir)
    time = time or 0.2
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local tween = TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
    tween:Play()
    return tween
end

-- Instance Creator
function Utility:Create(className, properties, children)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        if k == "Theme" then
            for prop, key in pairs(v) do ThemeManager:Register(inst, prop, key) end
        else
            inst[k] = v
        end
    end
    for _, child in pairs(children or {}) do child.Parent = inst end
    return inst
end

function Utility:ApplyCorner(parent, radius)
    return self:Create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = parent})
end

function Utility:ApplyStroke(parent, colorKey, thickness, mode)
    return self:Create("UIStroke", {
        Thickness = thickness or 1,
        ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
        Theme = {Color = colorKey or "Border"},
        Parent = parent
    })
end

function Utility:AddShadow(parent, intensity)
    return self:Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = ThemeManager:Get("Shadow"),
        ImageTransparency = intensity or 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = parent.ZIndex - 1,
        Parent = parent
    })
end

-- Smooth Dragging Logic
function Utility:MakeDraggable(dragArea, target)
    local dragging, dragInput, dragStart, startPos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Utility:Tween(target, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.15)
        end
    end)
end

function Utility:GetTextBounds(text, font, size, vector)
    return TextService:GetTextSize(text, size, font, vector or Vector2.new(10000, 10000))
end

-- ==============================================================================
-- 2. SAVE MANAGER (CONFIG & FLAGS)
-- ==============================================================================

local SaveManager = {
    Folder = "CAC_Ultimate",
    Flags = {},
    Options = {},
    Ignore = {}
}

function SaveManager:Init(folderName)
    self.Folder = folderName or self.Folder
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    if not isfolder(self.Folder .. "/configs") then makefolder(self.Folder .. "/configs") end
end

function SaveManager:Save(name)
    local path = self.Folder .. "/configs/" .. name .. ".json"
    local data = {}
    for flag, option in pairs(self.Options) do
        if not self.Ignore[flag] then data[flag] = self.Flags[flag] end
    end
    writefile(path, HttpService:JSONEncode(data))
end

function SaveManager:Load(name)
    local path = self.Folder .. "/configs/" .. name .. ".json"
    if isfile(path) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success and data then
            for flag, val in pairs(data) do
                if self.Options[flag] then
                    self.Options[flag]:SetValue(val)
                end
            end
        end
    end
end

-- ==============================================================================
-- 3. CORE FRAMEWORK (WINDOW & TABS)
-- ==============================================================================

local Library = {
    Windows = {},
    ActiveWindow = nil,
    Keybind = Enum.KeyCode.RightControl
}

function Library:CreateWindow(Settings)
    Settings = Settings or {}
    local Name = Settings.Name or "CAC Ultimate"
    local LoadingTitle = Settings.LoadingTitle or "INITIALIZING FRAMEWORK..."
    
    SaveManager:Init(Settings.Folder)

    local Window = {
        Tabs = {},
        Sections = {},
        Notifications = {},
        Elements = {},
        IsLoaded = false,
        IsToggled = true
    }
    
    local GUI = Utility:Create("ScreenGui", {
        Name = "CAC_Ultimate_Core",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    ProtectGui(GUI)
    GUI.Parent = CoreGui

    -- Main Container
    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 800, 0, 500),
        Position = UDim2.new(0.5, -400, 0.5, -250),
        ClipsDescendants = false,
        Theme = {BackgroundColor3 = "Background"},
        Parent = GUI
    })
    Utility:ApplyCorner(MainFrame, 8)
    Utility:ApplyStroke(MainFrame, "Border", 1)
    Utility:AddShadow(MainFrame, 0.5)

    -- Loading Screen Overlay
    local LoadingFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 2000,
        Theme = {BackgroundColor3 = "Background"},
        Parent = MainFrame
    })
    Utility:ApplyCorner(LoadingFrame, 8)

    local Spinner = Utility:Create("ImageLabel", {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0.4, -20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://13778704232", -- Premium segmented circle
        Theme = {ImageColor3 = "Accent"},
        Parent = LoadingFrame
    })
    
    local LoadTitleObj = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0.5, 10),
        BackgroundTransparency = 1,
        Text = LoadingTitle,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Theme = {TextColor3 = "Text"},
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = LoadingFrame
    })
    
    local loadAnim = RunService.RenderStepped:Connect(function() Spinner.Rotation = Spinner.Rotation + 4 end)

    function Window:FinishLoading()
        if self.IsLoaded then return end
        self.IsLoaded = true
        loadAnim:Disconnect()
        Utility:Tween(Spinner, {ImageTransparency = 1}, 0.3)
        Utility:Tween(LoadTitleObj, {TextTransparency = 1}, 0.3)
        task.wait(0.2)
        Utility:Tween(LoadingFrame, {BackgroundTransparency = 1}, 0.5)
        task.wait(0.5)
        LoadingFrame:Destroy()
    end

    -- Safety timeout
    task.delay(10, function() Window:FinishLoading() end)

    -- Layout Structure
    local DragBar = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = MainFrame
    })
    Utility:MakeDraggable(DragBar, MainFrame)

    local Sidebar = Utility:Create("Frame", {
        Size = UDim2.new(0, 200, 1, 0),
        Theme = {BackgroundColor3 = "Panel"},
        Parent = MainFrame
    })
    Utility:ApplyCorner(Sidebar, 8)
    
    -- Fix right corner bleeding from sidebar
    Utility:Create("Frame", {
        Size = UDim2.new(0, 10, 1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        BorderSizePixel = 0,
        Theme = {BackgroundColor3 = "Panel"},
        Parent = Sidebar
    })
    Utility:ApplyStroke(Sidebar, "Border", 1)

    local TitleArea = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        Parent = Sidebar
    })

    Utility:Create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.new(0, 20, 0, 25),
        BackgroundTransparency = 1,
        Text = Name:upper(),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = {TextColor3 = "Text"},
        Parent = TitleArea
    })

    local TabContainer = Utility:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -120),
        Position = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Parent = Sidebar
    })
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = TabContainer
    })

    -- Profile Mini-Card at bottom of sidebar
    local ProfileCard = Utility:Create("Frame", {
        Size = UDim2.new(1, -20, 0, 45),
        Position = UDim2.new(0, 10, 1, -55),
        Theme = {BackgroundColor3 = "Background"},
        Parent = Sidebar
    })
    Utility:ApplyCorner(ProfileCard, 6)
    Utility:ApplyStroke(ProfileCard, "Border")

    local AvatarImg = Utility:Create("ImageLabel", {
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 10, 0.5, -12.5),
        Theme = {BackgroundColor3 = "Border"},
        Parent = ProfileCard
    })
    Utility:ApplyCorner(AvatarImg, 100)
    task.spawn(function()
        local t, r = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        if r then AvatarImg.Image = t end
    end)

    Utility:Create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 15),
        Position = UDim2.new(0, 45, 0, 8),
        BackgroundTransparency = 1,
        Text = LocalPlayer.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = {TextColor3 = "Text"},
        Parent = ProfileCard
    })
    Utility:Create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 15),
        Position = UDim2.new(0, 45, 0, 22),
        BackgroundTransparency = 1,
        Text = "UID: " .. LocalPlayer.UserId,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = {TextColor3 = "TextMuted"},
        Parent = ProfileCard
    })

    local ContentArea = Utility:Create("Frame", {
        Size = UDim2.new(1, -200, 1, 0),
        Position = UDim2.new(0, 200, 0, 0),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    -- Watermark & Version
    Utility:Create("TextLabel", {
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(1, -210, 1, -25),
        BackgroundTransparency = 1,
        Text = "CAC Ultimate | v4.4",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        Theme = {TextColor3 = "TextMuted"},
        Parent = ContentArea
    })

    -- Notification Area
    local NotifContainer = Utility:Create("Frame", {
        Size = UDim2.new(0, 250, 1, -20),
        Position = UDim2.new(1, -260, 0, 10),
        BackgroundTransparency = 1,
        ZIndex = 500,
        Parent = GUI
    })
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = NotifContainer
    })

    -- Toggle Window Bind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.Keybind then
            Window.IsToggled = not Window.IsToggled
            MainFrame.Visible = Window.IsToggled
        end
    end)

    -- Notification System
    function Window:Notify(config)
        local title = config.Title or "Notification"
        local content = config.Content or "..."
        local duration = config.Duration or 5

        local notif = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Parent = NotifContainer
        })
        
        local card = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(1, 20, 0, 0),
            Theme = {BackgroundColor3 = "Panel"},
            Parent = notif
        })
        Utility:ApplyCorner(card, 6)
        Utility:ApplyStroke(card, "Border")
        Utility:AddShadow(card, 0.4)

        local line = Utility:Create("Frame", {
            Size = UDim2.new(0, 3, 1, -16),
            Position = UDim2.new(0, 8, 0, 8),
            Theme = {BackgroundColor3 = "Accent"},
            Parent = card
        })
        Utility:ApplyCorner(line, 2)

        local lblTitle = Utility:Create("TextLabel", {
            Size = UDim2.new(1, -30, 0, 15),
            Position = UDim2.new(0, 20, 0, 8),
            BackgroundTransparency = 1,
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Theme = {TextColor3 = "Text"},
            Parent = card
        })

        local lblDesc = Utility:Create("TextLabel", {
            Size = UDim2.new(1, -30, 0, 0),
            Position = UDim2.new(0, 20, 0, 25),
            BackgroundTransparency = 1,
            Text = content,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Theme = {TextColor3 = "TextDark"},
            Parent = card
        })

        local bounds = Utility:GetTextBounds(content, Enum.Font.GothamMedium, 11, Vector2.new(220, 1000))
        local targetHeight = bounds.Y + 35
        
        Utility:Tween(notif, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3)
        Utility:Tween(lblDesc, {Size = UDim2.new(1, -30, 0, bounds.Y)}, 0.3)
        task.wait(0.1)
        Utility:Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back)

        task.delay(duration, function()
            Utility:Tween(card, {Position = UDim2.new(1, 20, 0, 0)}, 0.3)
            task.wait(0.3)
            Utility:Tween(notif, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            notif:Destroy()
        end)
    end

    -- ==============================================================================
    -- TAB SYSTEM
    -- ==============================================================================
    
    function Window:CreateTab(name, iconId)
        local Tab = { Elements = {} }
        
        local Btn = Utility:Create("TextButton", {
            Size = UDim2.new(1, -20, 0, 35),
            BackgroundTransparency = 1,
            Text = "",
            Parent = TabContainer
        })
        local BtnBg = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Theme = {BackgroundColor3 = "Background"},
            BackgroundTransparency = 1,
            Parent = Btn
        })
        Utility:ApplyCorner(BtnBg, 6)

        local Icon = Utility:Create("ImageLabel", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 15, 0.5, -8),
            BackgroundTransparency = 1,
            Image = iconId or "rbxassetid://10888331510",
            Theme = {ImageColor3 = "TextDark"},
            Parent = BtnBg
        })
        
        local Label = Utility:Create("TextLabel", {
            Size = UDim2.new(1, -45, 1, 0),
            Position = UDim2.new(0, 40, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Theme = {TextColor3 = "TextDark"},
            Parent = BtnBg
        })

        local Indicator = Utility:Create("Frame", {
            Size = UDim2.new(0, 3, 0, 0),
            Position = UDim2.new(0, 5, 0.5, 0),
            Theme = {BackgroundColor3 = "Accent"},
            AnchorPoint = Vector2.new(0, 0.5),
            Parent = BtnBg
        })
        Utility:ApplyCorner(Indicator, 2)

        local Page = Utility:Create("ScrollingFrame", {
            Size = UDim2.new(1, -40, 1, -50),
            Position = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            Theme = {ScrollBarImageColor3 = "BorderHighlight"},
            Visible = false,
            Parent = ContentArea
        })
        local PageLayout = Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Page
        })
        
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        Btn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Utility:Tween(BtnBg, {BackgroundTransparency = 0}, 0.2)
                Utility:Tween(Label, {TextColor3 = ThemeManager:Get("Text")}, 0.2)
            end
        end)
        Btn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Utility:Tween(BtnBg, {BackgroundTransparency = 1}, 0.2)
                Utility:Tween(Label, {TextColor3 = ThemeManager:Get("TextDark")}, 0.2)
            end
        end)

        function Tab:Show()
            if Window.CurrentTab then
                local old = Window.CurrentTab
                old.Page.Visible = false
                Utility:Tween(old.BtnBg, {BackgroundTransparency = 1}, 0.2)
                Utility:Tween(old.Label, {TextColor3 = ThemeManager:Get("TextDark")}, 0.2)
                Utility:Tween(old.Icon, {ImageColor3 = ThemeManager:Get("TextDark")}, 0.2)
                Utility:Tween(old.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
            end
            Window.CurrentTab = self
            Page.Visible = true
            Utility:Tween(BtnBg, {BackgroundTransparency = 0}, 0.2)
            Utility:Tween(Label, {TextColor3 = ThemeManager:Get("Text")}, 0.2)
            Utility:Tween(Icon, {ImageColor3 = ThemeManager:Get("Accent")}, 0.2)
            Utility:Tween(Indicator, {Size = UDim2.new(0, 3, 0, 16)}, 0.3, Enum.EasingStyle.Back)
        end

        Btn.MouseButton1Click:Connect(function() Tab:Show() end)

        if not Window.CurrentTab then Tab:Show() end
        table.insert(Window.Tabs, Tab)

        Tab.BtnBg = BtnBg
        Tab.Label = Label
        Tab.Icon = Icon
        Tab.Indicator = Indicator
        Tab.Page = Page

        -- ==============================================================================
        -- UI ELEMENTS FACTORY (Methods inside Tab)
        -- ==============================================================================

        function Tab:CreateSection(title)
            local Section = {}
            
            local SecFrame = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Parent = Page
            })
            
            Utility:Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = title:upper(),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = {TextColor3 = "Accent"},
                Parent = SecFrame
            })
            
            Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Theme = {BackgroundColor3 = "Border"},
                BorderSizePixel = 0,
                Parent = SecFrame
            })

            return Section
        end

        function Tab:CreateButton(cfg)
            local btnFrame = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 45),
                Theme = {BackgroundColor3 = "Panel"},
                Parent = Page
            })
            Utility:ApplyCorner(btnFrame, 6)
            local stroke = Utility:ApplyStroke(btnFrame, "Border")

            local btn = Utility:Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = btnFrame
            })

            Utility:Create("TextLabel", {
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                Text = cfg.Name,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = {TextColor3 = "Text"},
                Parent = btnFrame
            })

            local icon = Utility:Create("ImageLabel", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(1, -30, 0.5, -8),
                BackgroundTransparency = 1,
                Image = "rbxassetid://10888331510", -- Arrow right
                Theme = {ImageColor3 = "TextDark"},
                Parent = btnFrame
            })

            btn.MouseEnter:Connect(function()
                Utility:Tween(btnFrame, {BackgroundColor3 = ThemeManager:Get("PanelHover")}, 0.2)
                Utility:Tween(stroke, {Color = ThemeManager:Get("Accent")}, 0.2)
                Utility:Tween(icon, {Position = UDim2.new(1, -25, 0.5, -8), ImageColor3 = ThemeManager:Get("Accent")}, 0.2)
            end)

            btn.MouseLeave:Connect(function()
                Utility:Tween(btnFrame, {BackgroundColor3 = ThemeManager:Get("Panel")}, 0.2)
                Utility:Tween(stroke, {Color = ThemeManager:Get("Border")}, 0.2)
                Utility:Tween(icon, {Position = UDim2.new(1, -30, 0.5, -8), ImageColor3 = ThemeManager:Get("TextDark")}, 0.2)
            end)

            btn.MouseButton1Click:Connect(function()
                Utility:Tween(btnFrame, {Size = UDim2.new(0.98, 0, 0, 43)}, 0.1)
                task.wait(0.1)
                Utility:Tween(btnFrame, {Size = UDim2.new(1, 0, 0, 45)}, 0.1)
                if cfg.Callback then cfg.Callback() end
            end)
        end

        function Tab:CreateToggle(cfg)
            local flag = cfg.Flag or cfg.Name
            local default = cfg.Default or false
            SaveManager.Flags[flag] = default

            local tglFrame = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 45),
                Theme = {BackgroundColor3 = "Panel"},
                Parent = Page
            })
            Utility:ApplyCorner(tglFrame, 6)
            Utility:ApplyStroke(tglFrame, "Border")

            Utility:Create("TextLabel", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                Text = cfg.Name,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = {TextColor3 = "Text"},
                Parent = tglFrame
            })

            local pill = Utility:Create("Frame", {
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -55, 0.5, -10),
                Theme = {BackgroundColor3 = default and "Accent" or "Background"},
                Parent = tglFrame
            })
            Utility:ApplyCorner(pill, 100)
            local pillStroke = Utility:ApplyStroke(pill, default and "Accent" or "Border")

            local circle = Utility:Create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, default and 23 or 3, 0.5, -7),
                Theme = {BackgroundColor3 = default and "Background" or "TextDark"},
                Parent = pill
            })
            Utility:ApplyCorner(circle, 100)

            local btn = Utility:Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = tglFrame
            })

            local ToggleObj = { Value = default }

            function ToggleObj:SetValue(val)
                self.Value = val
                SaveManager.Flags[flag] = val
                Utility:Tween(pill, {BackgroundColor3 = ThemeManager:Get(val and "Accent" or "Background")}, 0.2)
                Utility:Tween(pillStroke, {Color = ThemeManager:Get(val and "Accent" or "Border")}, 0.2)
                Utility:Tween(circle, {
                    Position = UDim2.new(0, val and 23 or 3, 0.5, -7),
                    BackgroundColor3 = ThemeManager:Get(val and "Background" or "TextDark")
                }, 0.3, Enum.EasingStyle.Back)
                
                if cfg.Callback then cfg.Callback(val) end
            end

            btn.MouseButton1Click:Connect(function() ToggleObj:SetValue(not ToggleObj.Value) end)
            SaveManager.Options[flag] = ToggleObj
            if default then ToggleObj:SetValue(true) end

            return ToggleObj
        end

        function Tab:CreateSlider(cfg)
            local flag = cfg.Flag or cfg.Name
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local default = cfg.Default or min
            local decimals = cfg.Decimals or 0
            SaveManager.Flags[flag] = default

            local sFrame = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 60),
                Theme = {BackgroundColor3 = "Panel"},
                Parent = Page
            })
            Utility:ApplyCorner(sFrame, 6)
            Utility:ApplyStroke(sFrame, "Border")

            Utility:Create("TextLabel", {
                Size = UDim2.new(1, -30, 0, 30),
                Position = UDim2.new(0, 15, 0, 5),
                BackgroundTransparency = 1,
                Text = cfg.Name,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = {TextColor3 = "Text"},
                Parent = sFrame
            })

            local valBoxBg = Utility:Create("Frame", {
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -55, 0, 10),
                Theme = {BackgroundColor3 = "Background"},
                Parent = sFrame
            })
            Utility:ApplyCorner(valBoxBg, 4)
            Utility:ApplyStroke(valBoxBg, "Border")

            local valBox = Utility:Create("TextBox", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(default),
                Font = Enum.Font.Code,
                TextSize = 10,
                Theme = {TextColor3 = "Accent"},
                Parent = valBoxBg
            })

            local trackBtn = Utility:Create("TextButton", {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 15, 0, 35),
                BackgroundTransparency = 1,
                Text = "",
                Parent = sFrame
            })

            local track = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 4),
                Position = UDim2.new(0, 0, 0.5, -2),
                Theme = {BackgroundColor3 = "Background"},
                Parent = trackBtn
            })
            Utility:ApplyCorner(track, 2)
            Utility:ApplyStroke(track, "Border")

            local fill = Utility:Create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                Theme = {BackgroundColor3 = "Accent"},
                Parent = track
            })
            Utility:ApplyCorner(fill, 2)

            local node = Utility:Create("Frame", {
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(1, -6, 0.5, -6),
                Theme = {BackgroundColor3 = "Text"},
                Parent = fill
            })
            Utility:ApplyCorner(node, 100)
            Utility:AddShadow(node, 0.3)

            local SliderObj = { Value = default }

            local function formatVal(v)
                return string.format("%."..decimals.."f", v)
            end

            function SliderObj:SetValue(val)
                val = math.clamp(val, min, max)
                self.Value = val
                SaveManager.Flags[flag] = val
                valBox.Text = formatVal(val)
                local pct = (val - min) / (max - min)
                Utility:Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1)
                if cfg.Callback then cfg.Callback(val) end
            end

            local dragging = false
            local function updateDrag(input)
                local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local val = min + ((max - min) * pct)
                if decimals == 0 then val = math.floor(val) end
                SliderObj:SetValue(val)
            end

            trackBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateDrag(input)
                    Utility:Tween(node, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0.5, -8)}, 0.2)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                    dragging = false
                    Utility:Tween(node, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)}, 0.2)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateDrag(input)
                end
            end)

            valBox.FocusLost:Connect(function()
                local n = tonumber(valBox.Text)
                if n then SliderObj:SetValue(n) else valBox.Text = formatVal(SliderObj.Value) end
            end)

            SaveManager.Options[flag] = SliderObj
            SliderObj:SetValue(default)

            return SliderObj
        end

        function Tab:CreateInput(cfg)
            local flag = cfg.Flag or cfg.Name
            local default = cfg.Default or ""
            SaveManager.Flags[flag] = default

            local iFrame = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                Theme = {BackgroundColor3 = "Panel"},
                Parent = Page
            })
            Utility:ApplyCorner(iFrame, 6)
            Utility:ApplyStroke(iFrame, "Border")

            Utility:Create("TextLabel", {
                Size = UDim2.new(0, 150, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                Text = cfg.Name,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = {TextColor3 = "Text"},
                Parent = iFrame
            })

            local boxBg = Utility:Create("Frame", {
                Size = UDim2.new(1, -180, 0, 30),
                Position = UDim2.new(0, 165, 0.5, -15),
                Theme = {BackgroundColor3 = "Background"},
                Parent = iFrame
            })
            Utility:ApplyCorner(boxBg, 4)
            local boxStroke = Utility:ApplyStroke(boxBg, "Border")

            local box = Utility:Create("TextBox", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = default,
                PlaceholderText = cfg.Placeholder or "Type here...",
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Theme = {TextColor3 = "Text"},
                Parent = boxBg
            })

            local InputObj = { Value = default }

            box.Focused:Connect(function() Utility:Tween(boxStroke, {Color = ThemeManager:Get("Accent")}, 0.2) end)
            box.FocusLost:Connect(function()
                Utility:Tween(boxStroke, {Color = ThemeManager:Get("Border")}, 0.2)
                InputObj.Value = box.Text
                SaveManager.Flags[flag] = box.Text
                if cfg.Callback then cfg.Callback(box.Text) end
            end)

            function InputObj:SetValue(val)
                box.Text = val
                self.Value = val
                SaveManager.Flags[flag] = val
                if cfg.Callback then cfg.Callback(val) end
            end

            SaveManager.Options[flag] = InputObj
            return InputObj
        end

        function Tab:CreateLabel(text)
            local lblFrame = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Parent = Page
            })
            Utility:Create("TextLabel", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = {TextColor3 = "TextDark"},
                Parent = lblFrame
            })
        end

        -- Dashboard Stats Element
        function Tab:CreateDashboardStats(stats)
            local grid = Utility:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 70),
                BackgroundTransparency = 1,
                Parent = Page
            })
            local layout = Utility:Create("UIGridLayout", {
                CellPadding = UDim2.new(0, 10, 0, 10),
                CellSize = UDim2.new(0.5, -5, 1, 0),
                Parent = grid
            })

            for _, stat in pairs(stats) do
                local card = Utility:Create("Frame", {
                    Theme = {BackgroundColor3 = "Panel"},
                    Parent = grid
                })
                Utility:ApplyCorner(card, 8)
                Utility:ApplyStroke(card, "Border")

                Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 20),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    Text = stat.Title:upper(),
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Theme = {TextColor3 = "TextDark"},
                    Parent = card
                })

                local valLbl = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 30),
                    Position = UDim2.new(0, 10, 0, 30),
                    BackgroundTransparency = 1,
                    Text = stat.Value,
                    Font = Enum.Font.GothamBold,
                    TextSize = 18,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Theme = {TextColor3 = "Text"},
                    Parent = card
                })

                if stat.UpdateHook then
                    task.spawn(function()
                        while true do
                            valLbl.Text = stat.UpdateHook()
                            task.wait(1)
                        end
                    end)
                end
            end
        end

        return Tab
    end

    return Window
end

-- Return API
return Library
