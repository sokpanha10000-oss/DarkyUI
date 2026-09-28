local DarkyX = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Themes = {
    cobalt = {
        Background = Color3.fromRGB(5, 7, 12),
        Background2 = Color3.fromRGB(7, 10, 17),
        Panel = Color3.fromRGB(9, 13, 21),
        Panel2 = Color3.fromRGB(12, 17, 27),
        Element = Color3.fromRGB(15, 21, 33),
        ElementHover = Color3.fromRGB(21, 29, 45),
        ElementPressed = Color3.fromRGB(25, 35, 55),
        Accent = Color3.fromRGB(66, 132, 255),
        Accent2 = Color3.fromRGB(118, 171, 255),
        AccentDark = Color3.fromRGB(32, 67, 135),
        Text = Color3.fromRGB(247, 250, 255),
        Muted = Color3.fromRGB(143, 154, 175),
        Faint = Color3.fromRGB(91, 103, 126),
        Border = Color3.fromRGB(28, 38, 58),
        Border2 = Color3.fromRGB(39, 53, 79),
        Danger = Color3.fromRGB(255, 75, 92),
        Success = Color3.fromRGB(67, 221, 147),
        White = Color3.fromRGB(255, 255, 255),
    },
    red = {
        Background = Color3.fromRGB(8, 5, 7), Background2 = Color3.fromRGB(12, 7, 9), Panel = Color3.fromRGB(16, 9, 12), Panel2 = Color3.fromRGB(21, 12, 15),
        Element = Color3.fromRGB(27, 14, 18), ElementHover = Color3.fromRGB(38, 19, 25), ElementPressed = Color3.fromRGB(49, 24, 31), Accent = Color3.fromRGB(237, 61, 79), Accent2 = Color3.fromRGB(255, 116, 130), AccentDark = Color3.fromRGB(118, 29, 41),
        Text = Color3.fromRGB(255, 246, 247), Muted = Color3.fromRGB(182, 149, 155), Faint = Color3.fromRGB(111, 83, 89), Border = Color3.fromRGB(57, 29, 35), Border2 = Color3.fromRGB(76, 38, 46), Danger = Color3.fromRGB(255, 74, 92), Success = Color3.fromRGB(69, 215, 143), White = Color3.new(1, 1, 1),
    },
    bluesky = {
        Background = Color3.fromRGB(4, 8, 12), Background2 = Color3.fromRGB(6, 12, 17), Panel = Color3.fromRGB(8, 15, 21), Panel2 = Color3.fromRGB(11, 21, 29),
        Element = Color3.fromRGB(13, 26, 35), ElementHover = Color3.fromRGB(18, 37, 49), ElementPressed = Color3.fromRGB(22, 48, 62), Accent = Color3.fromRGB(45, 176, 255), Accent2 = Color3.fromRGB(126, 219, 255), AccentDark = Color3.fromRGB(21, 94, 138),
        Text = Color3.fromRGB(242, 251, 255), Muted = Color3.fromRGB(141, 172, 190), Faint = Color3.fromRGB(83, 113, 130), Border = Color3.fromRGB(23, 48, 61), Border2 = Color3.fromRGB(31, 67, 85), Danger = Color3.fromRGB(255, 78, 95), Success = Color3.fromRGB(68, 218, 149), White = Color3.new(1, 1, 1),
    },
    dark = {
        Background = Color3.fromRGB(5, 5, 7), Background2 = Color3.fromRGB(8, 8, 10), Panel = Color3.fromRGB(10, 10, 12), Panel2 = Color3.fromRGB(14, 14, 17),
        Element = Color3.fromRGB(18, 18, 22), ElementHover = Color3.fromRGB(26, 26, 31), ElementPressed = Color3.fromRGB(32, 32, 39), Accent = Color3.fromRGB(116, 125, 255), Accent2 = Color3.fromRGB(168, 174, 255), AccentDark = Color3.fromRGB(55, 59, 125),
        Text = Color3.fromRGB(246, 246, 250), Muted = Color3.fromRGB(150, 150, 162), Faint = Color3.fromRGB(92, 92, 103), Border = Color3.fromRGB(31, 31, 36), Border2 = Color3.fromRGB(47, 47, 54), Danger = Color3.fromRGB(255, 77, 90), Success = Color3.fromRGB(67, 215, 141), White = Color3.new(1, 1, 1),
    },
    green = {
        Background = Color3.fromRGB(4, 8, 6), Background2 = Color3.fromRGB(6, 12, 8), Panel = Color3.fromRGB(7, 15, 10), Panel2 = Color3.fromRGB(10, 21, 14),
        Element = Color3.fromRGB(13, 28, 18), ElementHover = Color3.fromRGB(18, 41, 26), ElementPressed = Color3.fromRGB(23, 51, 32), Accent = Color3.fromRGB(50, 214, 113), Accent2 = Color3.fromRGB(111, 241, 161), AccentDark = Color3.fromRGB(24, 107, 58),
        Text = Color3.fromRGB(241, 255, 247), Muted = Color3.fromRGB(142, 175, 154), Faint = Color3.fromRGB(78, 108, 89), Border = Color3.fromRGB(22, 49, 31), Border2 = Color3.fromRGB(31, 68, 42), Danger = Color3.fromRGB(255, 79, 94), Success = Color3.fromRGB(69, 220, 139), White = Color3.new(1, 1, 1),
    },
    purple = {
        Background = Color3.fromRGB(6, 4, 9), Background2 = Color3.fromRGB(10, 7, 14), Panel = Color3.fromRGB(13, 9, 19), Panel2 = Color3.fromRGB(18, 12, 26),
        Element = Color3.fromRGB(23, 15, 34), ElementHover = Color3.fromRGB(33, 21, 49), ElementPressed = Color3.fromRGB(43, 27, 64), Accent = Color3.fromRGB(163, 91, 255), Accent2 = Color3.fromRGB(204, 151, 255), AccentDark = Color3.fromRGB(80, 45, 128),
        Text = Color3.fromRGB(250, 246, 255), Muted = Color3.fromRGB(171, 154, 195), Faint = Color3.fromRGB(101, 83, 122), Border = Color3.fromRGB(53, 35, 73), Border2 = Color3.fromRGB(73, 47, 99), Danger = Color3.fromRGB(255, 78, 94), Success = Color3.fromRGB(72, 217, 145), White = Color3.new(1, 1, 1),
    },
    orange = {
        Background = Color3.fromRGB(8, 5, 3), Background2 = Color3.fromRGB(13, 8, 5), Panel = Color3.fromRGB(17, 10, 6), Panel2 = Color3.fromRGB(23, 14, 8),
        Element = Color3.fromRGB(30, 18, 10), ElementHover = Color3.fromRGB(44, 26, 14), ElementPressed = Color3.fromRGB(56, 33, 18), Accent = Color3.fromRGB(255, 142, 48), Accent2 = Color3.fromRGB(255, 187, 112), AccentDark = Color3.fromRGB(131, 73, 23),
        Text = Color3.fromRGB(255, 249, 240), Muted = Color3.fromRGB(194, 166, 139), Faint = Color3.fromRGB(115, 88, 62), Border = Color3.fromRGB(61, 38, 21), Border2 = Color3.fromRGB(81, 49, 27), Danger = Color3.fromRGB(255, 78, 92), Success = Color3.fromRGB(71, 217, 143), White = Color3.new(1, 1, 1),
    },
    yellow = {
        Background = Color3.fromRGB(8, 8, 3), Background2 = Color3.fromRGB(13, 12, 5), Panel = Color3.fromRGB(17, 16, 7), Panel2 = Color3.fromRGB(23, 21, 9),
        Element = Color3.fromRGB(31, 29, 11), ElementHover = Color3.fromRGB(44, 41, 16), ElementPressed = Color3.fromRGB(56, 52, 20), Accent = Color3.fromRGB(243, 202, 50), Accent2 = Color3.fromRGB(255, 228, 112), AccentDark = Color3.fromRGB(126, 106, 25),
        Text = Color3.fromRGB(255, 253, 239), Muted = Color3.fromRGB(186, 180, 143), Faint = Color3.fromRGB(111, 105, 73), Border = Color3.fromRGB(67, 62, 25), Border2 = Color3.fromRGB(88, 80, 30), Danger = Color3.fromRGB(255, 77, 90), Success = Color3.fromRGB(68, 215, 141), White = Color3.new(1, 1, 1),
    },
    white = {
        Background = Color3.fromRGB(232, 235, 241), Background2 = Color3.fromRGB(242, 244, 248), Panel = Color3.fromRGB(247, 248, 251), Panel2 = Color3.fromRGB(235, 237, 243),
        Element = Color3.fromRGB(225, 228, 235), ElementHover = Color3.fromRGB(214, 218, 227), ElementPressed = Color3.fromRGB(205, 210, 221), Accent = Color3.fromRGB(45, 109, 255), Accent2 = Color3.fromRGB(83, 140, 255), AccentDark = Color3.fromRGB(31, 76, 177),
        Text = Color3.fromRGB(24, 28, 38), Muted = Color3.fromRGB(91, 97, 113), Faint = Color3.fromRGB(132, 138, 151), Border = Color3.fromRGB(199, 204, 216), Border2 = Color3.fromRGB(181, 187, 202), Danger = Color3.fromRGB(230, 54, 72), Success = Color3.fromRGB(37, 177, 105), White = Color3.new(1, 1, 1),
    },
}

Themes.default = {
    Background = Color3.fromRGB(2, 3, 5),
    Background2 = Color3.fromRGB(4, 5, 8),
    Panel = Color3.fromRGB(5, 6, 9),
    Panel2 = Color3.fromRGB(7, 8, 12),
    Element = Color3.fromRGB(10, 11, 16),
    ElementHover = Color3.fromRGB(16, 17, 24),
    ElementPressed = Color3.fromRGB(21, 23, 32),
    Accent = Color3.fromRGB(92, 145, 255),
    Accent2 = Color3.fromRGB(142, 183, 255),
    AccentDark = Color3.fromRGB(31, 60, 120),
    Text = Color3.fromRGB(246, 248, 252),
    Muted = Color3.fromRGB(134, 141, 155),
    Faint = Color3.fromRGB(77, 83, 96),
    Border = Color3.fromRGB(18, 20, 27),
    Border2 = Color3.fromRGB(28, 31, 41),
    Danger = Color3.fromRGB(255, 72, 91),
    Success = Color3.fromRGB(67, 221, 147),
    White = Color3.new(1, 1, 1),
}

local Icons = {lucide = {}}
pcall(function()
    local source = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(source))()
    end)
    if ok and type(result) == "table" then
        Icons.lucide = result
    end
end)

DarkyX.Icons = Icons
DarkyX.Themes = Themes

local function new(className, props, parent)
    local object = Instance.new(className)
    for property, value in pairs(props or {}) do
        object[property] = value
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local function corner(parent, radius)
    return new("UICorner", {CornerRadius = radius or UDim.new(0, 10)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function gradient(parent, colors, rotation, transparency)
    local g = new("UIGradient", {
        Rotation = rotation or 0,
        Color = ColorSequence.new(colors),
    }, parent)
    if transparency then
        if typeof(transparency) == "NumberSequence" then
            g.Transparency = transparency
        else
            g.Transparency = NumberSequence.new(transparency)
        end
    end
    return g
end

local function tween(object, duration, properties, style, direction)
    if not object then return end
    local animation = TweenService:Create(object, TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local function getTheme(theme)
    if type(theme) == "table" then
        return theme
    end
    return Themes[string.lower(tostring(theme or "default"))] or Themes.default
end

local function resolveIcon(icon)
    if typeof(icon) == "number" then
        return "rbxassetid://" .. tostring(icon)
    end
    if type(icon) ~= "string" then
        return nil
    end
    if icon:match("^rbxassetid://") then
        return icon
    end
    local name = string.lower(icon)
    local tableRef = Icons.lucide
    if tableRef then
        if tableRef[name] then return tableRef[name] end
        local compact = name:gsub("[^%w]", "")
        for key, value in pairs(tableRef) do
            if string.lower(tostring(key)):gsub("[^%w]", "") == compact then
                return value
            end
        end
    end
    return nil
end

local function makeIcon(parent, icon, size, color, zIndex)
    local asset = resolveIcon(icon)
    if not asset then return nil end
    return new("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = asset,
        ImageColor3 = color or Color3.new(1, 1, 1),
        Size = UDim2.fromOffset(size or 18, size or 18),
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = zIndex or 1,
    }, parent)
end

local function addScale(parent, scale)
    return new("UIScale", {Scale = scale or 1}, parent)
end

local function iconPop(icon)
    if not icon or not icon.Parent then return end
    local scale = icon:FindFirstChildOfClass("UIScale") or addScale(icon, 1)
    scale.Scale = 0.82
    icon.Rotation = -10
    tween(scale, 0.22, {Scale = 1.08}, Enum.EasingStyle.Back)
    tween(icon, 0.22, {Rotation = 0}, Enum.EasingStyle.Quint)
    task.delay(0.18, function()
        if scale.Parent then tween(scale, 0.15, {Scale = 1}, Enum.EasingStyle.Quint) end
    end)
end

local function makeDrag(handle, target, onClick)
    local dragging = false
    local moved = false
    local dragStart
    local startPosition
    local inputConnection

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        moved = false
        dragStart = input.Position
        startPosition = target.Position
        if inputConnection then inputConnection:Disconnect() end
        inputConnection = UserInputService.InputChanged:Connect(function(changed)
            if not dragging then return end
            if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = changed.Position - dragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
            target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end)
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local wasMoved = moved
        dragging = false
        if inputConnection then inputConnection:Disconnect(); inputConnection = nil end
        if not wasMoved and onClick then onClick() end
    end)
end

local function autoCanvas(scrollingFrame, layout)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local size = layout.AbsoluteContentSize
        scrollingFrame.CanvasSize = UDim2.fromOffset(0, size.Y + 12)
    end)
end

local function addGlow(parent, color, transparency, thickness)
    local glow = new("Frame", {
        Name = "Glow",
        BackgroundColor3 = color,
        BackgroundTransparency = transparency or 0.92,
        Position = UDim2.fromOffset(-8, -8),
        Size = UDim2.new(1, 16, 1, 16),
        ZIndex = (parent.ZIndex or 1) - 1,
    }, parent.Parent)
    corner(glow, UDim.new(0, thickness or 18))
    return glow
end

local function setTextPair(holder, name, description, theme, y, widthOffset, z)
    local title = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(name or "Element"),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = UDim2.fromOffset(15, y),
        Size = UDim2.new(1, widthOffset or -30, 0, description and 18 or 26),
        ZIndex = z or 2,
    }, holder)
    if description and tostring(description) ~= "" then
        new("TextLabel", {
            BackgroundTransparency = 1,
            Text = tostring(description),
            TextColor3 = theme.Muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Position = UDim2.fromOffset(15, y + 19),
            Size = UDim2.new(1, widthOffset or -30, 0, 22),
            ZIndex = z or 2,
        }, holder)
    end
    return title
end

function DarkyX:CreateWindow(config)
    config = config or {}
    local theme = getTheme(config.theme or "Default")
    local sidebarLayout = config.sidebarLayout == true
    local windowWidth = tonumber(config.width) or 550
    local windowHeight = tonumber(config.height) or 340
    local isDefaultTheme = type(config.theme) ~= "table" and string.lower(tostring(config.theme or "default")) == "default"
    local elementBox = Color3.fromRGB(42, 43, 48)
    local elementBoxHover = Color3.fromRGB(52, 53, 59)
    local elementBorder = isDefaultTheme and Color3.fromRGB(20, 21, 27) or theme.Border
    local elementBorderTransparency = isDefaultTheme and 0.03 or 0.35
    local elementStrokeThickness = isDefaultTheme and 1.2 or 1

    local function styleElementBox(object, radius)
        corner(object, UDim.new(0, radius or 11))
        stroke(object, elementBorder, elementBorderTransparency, elementStrokeThickness)
        if isDefaultTheme then
            new("UIGradient", {
                Name = "DefaultElementLight",
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(69, 70, 76)),
                    ColorSequenceKeypoint.new(0.36, Color3.fromRGB(64, 65, 71)),
                    ColorSequenceKeypoint.new(0.49, Color3.fromRGB(58, 59, 65)),
                    ColorSequenceKeypoint.new(0.54, Color3.fromRGB(48, 49, 55)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 43, 48)),
                }),
            }, object)
        end
    end

    local guiName = "DarkyX_" .. tostring(math.random(10000, 99999))

    local guiParent = CoreGui
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then guiParent = result end
    end

    local screenGui = new("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    }, guiParent)

    local window = {
        ScreenGui = screenGui,
        Theme = theme,
        Tabs = {},
        Sidebar = sidebarLayout,
        Destroyed = false,
        Visible = true,
        _StateEntries = {},
        _SearchItems = {},
        _Keybind = config.keybind or Enum.KeyCode.RightControl,
    }

    local loaderTitle = new("TextLabel", {
        Name = "LoadingTitle",
        BackgroundTransparency = 1,
        Text = "DarkyX",
        TextColor3 = theme.Text,
        TextTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 74,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(520, 90),
        ZIndex = 200,
    }, screenGui)
    local loaderScale = addScale(loaderTitle, 0.76)
    tween(loaderTitle, 0.38, {TextTransparency = 0})
    tween(loaderScale, 0.48, {Scale = 1}, Enum.EasingStyle.Back)

    local main = new("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Background,
        Size = UDim2.fromOffset(windowWidth, windowHeight),
        Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2),
        ZIndex = 5,
        Visible = false,
    }, screenGui)
    corner(main, UDim.new(0, 17))
    addScale(main, 0.95)

    local topBar = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        ZIndex = 10,
    }, main)
    makeDrag(topBar, main)

    local titleWrap = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.fromOffset(305, 42),
        ZIndex = 11,
    }, topBar)
    -- Window image is intentionally not shown here.
    -- config.Image is reserved for the FloatingButton logo.
    local titleLeft = 0
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(config.name or "DarkyX Hub"),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(titleLeft, 0),
        Size = UDim2.new(1, -titleLeft, 0, 24),
        ZIndex = 11,
    }, titleWrap)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(config.subtitle or "DarkyX"),
        TextColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(titleLeft, 22),
        Size = UDim2.new(1, -titleLeft, 0, 17),
        ZIndex = 11,
    }, titleWrap)

    local controls = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -11, 0, 10),
        Size = UDim2.fromOffset(142, 30),
        ZIndex = 15,
    }, topBar)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 5),
    }, controls)

    local function makeControl(icon, tint, tooltip)
        local b = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.Element,
            BackgroundTransparency = 0.1,
            Text = "",
            Size = UDim2.fromOffset(29, 29),
            ZIndex = 16,
        }, controls)
        corner(b, UDim.new(0, 9))
        stroke(b, theme.Border2, 0.45, 1)
        local i = makeIcon(b, icon, 15, tint or theme.Muted, 18)
        if i then i.AnchorPoint = Vector2.new(0.5, 0.5); i.Position = UDim2.fromScale(0.5, 0.5) end
        b.MouseEnter:Connect(function()
            tween(b, 0.14, {BackgroundColor3 = theme.ElementHover, BackgroundTransparency = 0})
            if i then tween(i, 0.14, {ImageColor3 = tint or theme.Text}) end
        end)
        b.MouseLeave:Connect(function()
            tween(b, 0.14, {BackgroundColor3 = theme.Element, BackgroundTransparency = 0.1})
            if i then tween(i, 0.14, {ImageColor3 = tint or theme.Muted}) end
        end)
        return b, i
    end

    local searchButton, searchButtonIcon = makeControl("search", theme.Muted)
    local settingsButton, settingsButtonIcon = makeControl("settings", theme.Muted)
    local minimize, minimizeIcon = makeControl("minus", theme.Muted)
    local close, closeIcon = makeControl("x", theme.Danger)

    local searchPanel = new("Frame", {
        BackgroundColor3 = theme.Panel2,
        BackgroundTransparency = 0.02,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 47),
        Size = UDim2.fromOffset(300, 38),
        Visible = false,
        ZIndex = 40,
    }, main)
    corner(searchPanel, UDim.new(0, 11))
    stroke(searchPanel, theme.Border2, 0.2, 1)
    local searchPanelIcon = makeIcon(searchPanel, "search", 15, theme.Muted, 42)
    if searchPanelIcon then searchPanelIcon.Position = UDim2.fromOffset(11, 11) end
    local searchBox = new("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Search current tab...",
        PlaceholderColor3 = theme.Muted,
        Text = "",
        TextColor3 = theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(33, 0),
        Size = UDim2.new(1, -44, 1, 0),
        ZIndex = 42,
    }, searchPanel)

    local currentTab
    local closeSearchPanel
    local tabShell, tabBar, tabList, pages

    local settingsPanel = new("Frame", {
        BackgroundColor3 = theme.Background2,
        BackgroundTransparency = 0,
        Position = UDim2.new(1, 0, 0, 58),
        Size = UDim2.new(1, 0, 1, -58),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 50,
    }, main)
    corner(settingsPanel, UDim.new(0, 14))
    local settingsTop = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        ZIndex = 52,
    }, settingsPanel)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Settings",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -70, 0, 24),
        ZIndex = 53,
    }, settingsTop)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Keybind and Save Manager",
        TextColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 32),
        Size = UDim2.new(1, -70, 0, 16),
        ZIndex = 53,
    }, settingsTop)
    local settingsBack, settingsBackIcon = makeControl("arrow-left", theme.Muted, "Back")
    settingsBack.Parent = settingsTop
    settingsBack.AnchorPoint = Vector2.new(1, 0)
    settingsBack.Position = UDim2.new(1, -12, 0, 11)
    settingsBack.Visible = true
    settingsBack.ZIndex = 55
    if settingsBackIcon then
        settingsBackIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        settingsBackIcon.Position = UDim2.fromScale(0.5, 0.5)
        settingsBackIcon.ZIndex = 57
    end

    local settingsScroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 64),
        Size = UDim2.new(1, -24, 1, -76),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 51,
    }, settingsPanel)
    local settingsList = new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, settingsScroll)
    new("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
    }, settingsScroll)

    local keybindSection = new("Frame", {
        BackgroundColor3 = theme.Element,
        Size = UDim2.new(1, -4, 0, 112),
        LayoutOrder = 1,
        ZIndex = 52,
    }, settingsScroll)
    corner(keybindSection, UDim.new(0, 12))
    stroke(keybindSection, Color3.fromRGB(56, 59, 66), 0.45, 1)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Keybind",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(13, 10),
        Size = UDim2.new(1, -26, 0, 18),
        ZIndex = 54,
    }, keybindSection)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Click the key button, then press a keyboard key.",
        TextColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(13, 31),
        Size = UDim2.new(1, -26, 0, 18),
        ZIndex = 54,
    }, keybindSection)
    local keybindButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Panel2,
        Text = tostring(window._Keybind.Name),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Size = UDim2.new(1, -26, 0, 32),
        Position = UDim2.fromOffset(13, 58),
        ZIndex = 54,
    }, keybindSection)
    corner(keybindButton, UDim.new(0, 9))
    stroke(keybindButton, Color3.fromRGB(65, 68, 75), 0.35, 1)

    local saveSection = new("Frame", {
        BackgroundColor3 = theme.Element,
        Size = UDim2.new(1, -4, 0, 112),
        LayoutOrder = 2,
        ZIndex = 52,
    }, settingsScroll)
    corner(saveSection, UDim.new(0, 12))
    stroke(saveSection, Color3.fromRGB(56, 59, 66), 0.45, 1)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Save Manager",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(13, 10),
        Size = UDim2.new(1, -26, 0, 18),
        ZIndex = 54,
    }, saveSection)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Save or load the current flagged UI values.",
        TextColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(13, 31),
        Size = UDim2.new(1, -26, 0, 18),
        ZIndex = 54,
    }, saveSection)
    local saveRow = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 58),
        Size = UDim2.new(1, -26, 0, 32),
        ZIndex = 54,
    }, saveSection)
    local saveButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Panel2,
        Text = "Save",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Size = UDim2.new(0.5, -4, 1, 0),
        ZIndex = 55,
    }, saveRow)
    corner(saveButton, UDim.new(0, 9))
    stroke(saveButton, Color3.fromRGB(65, 68, 75), 0.35, 1)
    local loadButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Panel2,
        Text = "Load",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Position = UDim2.new(0.5, 4, 0, 0),
        Size = UDim2.new(0.5, -4, 1, 0),
        ZIndex = 55,
    }, saveRow)
    corner(loadButton, UDim.new(0, 9))
    stroke(loadButton, Color3.fromRGB(65, 68, 75), 0.35, 1)
    local settingsStatus = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = theme.Success,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(13, 94),
        Size = UDim2.new(1, -26, 0, 14),
        ZIndex = 55,
    }, saveSection)

    local settingsPageOpen = false
    local function openSettingsPage()
        if settingsPageOpen then return end
        settingsPageOpen = true
        closeSearchPanel()
        tabShell.Visible = false
        pages.Visible = false
        settingsPanel.Visible = true
        settingsPanel.Position = UDim2.new(1, 0, 0, 58)
        tween(settingsPanel, 0.34, {Position = UDim2.new(0, 0, 0, 58)}, Enum.EasingStyle.Quint)
        if settingsButtonIcon then tween(settingsButtonIcon, 0.18, {ImageColor3 = theme.Accent2}) end
    end
    local function closeSettingsPage()
        if not settingsPageOpen then return end
        settingsPageOpen = false
        tween(settingsPanel, 0.3, {Position = UDim2.new(1, 0, 0, 58)}, Enum.EasingStyle.Quint)
        if settingsButtonIcon then tween(settingsButtonIcon, 0.18, {ImageColor3 = theme.Muted}) end
        task.delay(0.31, function()
            if settingsPanel.Parent and not settingsPageOpen then
                settingsPanel.Visible = false
                tabShell.Visible = true
                pages.Visible = true
            end
        end)
    end
    settingsBack.MouseButton1Click:Connect(closeSettingsPage)

    closeSearchPanel = function()
        searchBox.Text = ""
        searchPanel.Visible = false
        if searchButtonIcon then tween(searchButtonIcon, 0.18, {ImageColor3 = theme.Muted}) end
        for _, entry in ipairs(window._SearchItems) do
            entry.Holder.Visible = entry.Tab == currentTab
        end
    end

    searchButton.MouseButton1Click:Connect(function()
        if settingsPageOpen then
            closeSettingsPage()
        end
        if searchPanel.Visible then
            closeSearchPanel()
            return
        end
        searchPanel.Visible = true
        tween(searchButtonIcon, 0.18, {ImageColor3 = theme.Accent2})
        task.defer(function()
            if searchBox.Parent then searchBox:CaptureFocus() end
        end)
    end)
    settingsButton.MouseButton1Click:Connect(function()
        if settingsPageOpen then
            closeSettingsPage()
        else
            openSettingsPage()
        end
    end)

    local content = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 58),
        Size = UDim2.new(1, -20, 1, -68),
        ZIndex = 7,
    }, main)

    if sidebarLayout then
        tabShell = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(0, 144, 1, 0),
            ZIndex = 8,
        }, content)
        tabBar = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(6, 6),
            Size = UDim2.new(1, -12, 1, -12),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 9,
        }, tabShell)
        tabList = new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)
        new("UIPadding", {PaddingBottom = UDim.new(0, 5)}, tabBar)
        pages = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(154, 0),
            Size = UDim2.new(1, -154, 1, 0),
            ZIndex = 7,
        }, content)
    else
        tabShell = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 42),
            ZIndex = 8,
        }, content)
        tabBar = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(7, 5),
            Size = UDim2.new(1, -14, 1, -8),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            ScrollingDirection = Enum.ScrollingDirection.X,
            ScrollBarThickness = 0,
            ZIndex = 9,
        }, tabShell)
        tabList = new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center}, tabBar)
        new("UIPadding", {PaddingRight = UDim.new(0, 5)}, tabBar)
        pages = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 50),
            Size = UDim2.new(1, 0, 1, -50),
            ZIndex = 7,
        }, content)
    end

    local floatingWidth = tonumber(config.floatingWidth) or 156
    local floatingHeight = tonumber(config.floatingHeight) or 42
    local floating = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.03,
        Text = "",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(floatingWidth, floatingHeight),
        ZIndex = 120,
        Visible = false,
    }, screenGui)
    corner(floating, UDim.new(1, 0))
    stroke(floating, theme.Border2, 0.08, 1)
    gradient(floating, {
        ColorSequenceKeypoint.new(0, theme.Panel2),
        ColorSequenceKeypoint.new(0.5, theme.Panel),
        ColorSequenceKeypoint.new(1, theme.Element),
    }, 0)
    local floatingIcon = makeIcon(floating, config.floatingIcon or config.Image or "panel-top", 18, theme.Accent2, 123)
    if floatingIcon then floatingIcon.Position = UDim2.fromOffset(17, 12); addScale(floatingIcon, 1) end
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(config.floatingTitle or config.name or "DarkyX Hub"),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(44, 7),
        Size = UDim2.new(1, -56, 0, 15),
        ZIndex = 123,
    }, floating)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(config.floatingSubtitle or "Show UI"),
        TextColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(44, 22),
        Size = UDim2.new(1, -56, 0, 13),
        ZIndex = 123,
    }, floating)
    local function placeFloatingAbove()
        local mainPos = main.AbsolutePosition
        local mainSize = main.AbsoluteSize
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local x = mainPos.X + (mainSize.X - floatingWidth) * 0.5
        local y = mainPos.Y - floatingHeight - 10
        x = math.clamp(x, 8, math.max(8, viewport.X - floatingWidth - 8))
        y = math.max(8, y)
        floating.Position = UDim2.fromOffset(x, y)
    end

    local dragBarWidth = tonumber(config.dragBarWidth or config.meterWidth) or 220
    local dragBarHeight = tonumber(config.dragBarHeight or config.meterHeight) or 8
    local meterValue = math.clamp(tonumber(config.meterValue) or 0.72, 0, 1)

    -- DragBar lives directly under ScreenGui, never inside Main.
    local dragBar = new("Frame", {
        Name = "DragBar",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(dragBarWidth, dragBarHeight),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 130,
        Visible = false,
        Active = true,
    }, screenGui)
    corner(dragBar, UDim.new(1, 0))
    stroke(dragBar, Color3.new(1, 1, 1), 0.55, 1)

    local dragFill = new("Frame", {
        Name = "Fill",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Size = UDim2.new(meterValue, 0, 1, 0),
        ZIndex = 131,
    }, dragBar)
    corner(dragFill, UDim.new(1, 0))

    local dragKnob = new("Frame", {
        Name = "Handle",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(meterValue, 0, 0.5, 0),
        Size = UDim2.fromOffset(math.max(10, dragBarHeight + 4), math.max(10, dragBarHeight + 4)),
        ZIndex = 132,
    }, dragBar)
    corner(dragKnob, UDim.new(1, 0))

    local function placeDragBarBelow()
        local mainPos = main.AbsolutePosition
        local mainSize = main.AbsoluteSize
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local x = mainPos.X + (mainSize.X - dragBarWidth) * 0.5
        local y = mainPos.Y + mainSize.Y + 9
        x = math.clamp(x, 8, math.max(8, viewport.X - dragBarWidth - 8))
        y = math.max(4, y)
        if y + dragBarHeight > viewport.Y - 4 then
            y = viewport.Y - dragBarHeight - 4
        end
        dragBar.Position = UDim2.fromOffset(x, y)
        dragBar.ZIndex = 130
    end

    local draggingBar = false
    local dragBarInputChangedConnection
    local dragBarInputEndedConnection
    local function setMeterFromInputX(screenX)
        local left = dragBar.AbsolutePosition.X
        local width = math.max(1, dragBar.AbsoluteSize.X)
        meterValue = math.clamp((screenX - left) / width, 0, 1)
        dragFill.Size = UDim2.new(meterValue, 0, 1, 0)
        dragKnob.Position = UDim2.new(meterValue, 0, 0.5, 0)
    end

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true
            setMeterFromInputX(input.Position.X)
        end
    end)
    dragBarInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
        if not draggingBar then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            setMeterFromInputX(input.Position.X)
        end
    end)
    dragBarInputEndedConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = false
        end
    end)

    makeDrag(floating, floating, function()
        if window.Visible then return end
        window:SetVisible(true)
    end)
    floating.MouseEnter:Connect(function()
        tween(floating, 0.18, {BackgroundColor3 = theme.ElementHover, Size = UDim2.fromOffset(floatingWidth + 5, floatingHeight + 2)})
        if floatingIcon then tween(floatingIcon, 0.18, {ImageColor3 = theme.Text}) end
    end)
    floating.MouseLeave:Connect(function()
        tween(floating, 0.18, {BackgroundColor3 = theme.Panel, Size = UDim2.fromOffset(floatingWidth, floatingHeight)})
        if floatingIcon then tween(floatingIcon, 0.18, {ImageColor3 = theme.Accent2}) end
    end)

    local mainScale = main:FindFirstChildOfClass("UIScale")
    local dragBarPositionConnection
    dragBarPositionConnection = RunService.RenderStepped:Connect(function()
        if window.Destroyed then
            if dragBarPositionConnection then dragBarPositionConnection:Disconnect(); dragBarPositionConnection = nil end
            if dragBarInputChangedConnection then dragBarInputChangedConnection:Disconnect(); dragBarInputChangedConnection = nil end
            if dragBarInputEndedConnection then dragBarInputEndedConnection:Disconnect(); dragBarInputEndedConnection = nil end
            return
        end
        if main.Visible and dragBar.Visible then
            placeDragBarBelow()
        end
    end)
    local function setVisible(visible)
        window.Visible = visible
        if visible then
            main.Visible = true
            floating.Visible = false
            dragBar.Visible = true
            placeDragBarBelow()
            mainScale.Scale = 0.96
            tween(mainScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
        else
            dragBar.Visible = false
            tween(mainScale, 0.2, {Scale = 0.95}, Enum.EasingStyle.Quint)
            task.delay(0.19, function()
                if not window.Visible and main.Parent then main.Visible = false end
            end)
            floating.Visible = true
            placeFloatingAbove()
            floating.Size = UDim2.fromOffset(floatingWidth - 6, floatingHeight - 2)
            tween(floating, 0.28, {Size = UDim2.fromOffset(floatingWidth, floatingHeight)}, Enum.EasingStyle.Back)
        end
    end

    minimize.MouseButton1Click:Connect(function()
        iconPop(minimizeIcon)
        setVisible(false)
    end)
    close.MouseButton1Click:Connect(function()
        iconPop(closeIcon)
        window:Destroy()
    end)

    local dropdowns = {}

    local function buildPage(tab)
        local page = new("ScrollingFrame", {
            Name = tab.Name .. "Page",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 8,
        }, pages)
        new("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 5),
        }, page)
        local list = new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        autoCanvas(page, list)
        return page, list
    end

    local function selectTab(tab)
        if currentTab == tab then return end
        currentTab = tab
        for _, other in ipairs(window.Tabs) do
            other.Page.Visible = false
            if other.SelectionBox then
                if other.SelectionBox.Visible then
                    tween(other.SelectionBox, 0.16, {BackgroundTransparency = 1})
                    if other.SelectionStroke then tween(other.SelectionStroke, 0.16, {Transparency = 1}) end
                    if other.SelectionLight then tween(other.SelectionLight, 0.16, {BackgroundTransparency = 1}) end
                    task.delay(0.17, function()
                        if currentTab ~= other and other.SelectionBox.Parent then other.SelectionBox.Visible = false end
                    end)
                end
            end
            other.TabText.TextColor3 = theme.Muted
            if other.Icon then other.Icon.ImageColor3 = theme.Muted end
        end
        tab.Page.Visible = true
        if tab.SelectionBox then
            tab.SelectionBox.Visible = true
            tab.SelectionBox.BackgroundTransparency = 1
            if tab.SelectionStroke then tab.SelectionStroke.Transparency = 1 end
            if tab.SelectionLight then tab.SelectionLight.BackgroundTransparency = 1 end
            tween(tab.SelectionBox, 0.22, {BackgroundTransparency = 0.08}, Enum.EasingStyle.Quint)
            if tab.SelectionStroke then tween(tab.SelectionStroke, 0.22, {Transparency = 0.2}, Enum.EasingStyle.Quint) end
            if tab.SelectionLight then tween(tab.SelectionLight, 0.24, {BackgroundTransparency = 0.38}, Enum.EasingStyle.Quint) end
        end
        tab.TabText.TextColor3 = theme.Text
        if tab.Icon then tab.Icon.ImageColor3 = theme.White; iconPop(tab.Icon) end
        if searchPanel.Visible then
            filterCurrentTabSearch(searchBox.Text)
        else
            for _, entry in ipairs(window._SearchItems) do
                if entry.Tab == tab then entry.Holder.Visible = true end
            end
        end
    end

    local function registerSearchItem(tab, holder, name, description)
        table.insert(window._SearchItems, {
            Tab = tab,
            Holder = holder,
            Text = string.lower(tostring(name or "") .. " " .. tostring(description or "")),
        })
    end

    local function filterCurrentTabSearch(query)
        query = string.lower(query or "")
        for _, entry in ipairs(window._SearchItems) do
            if entry.Tab == currentTab then
                entry.Holder.Visible = query == "" or string.find(entry.Text, query, 1, true) ~= nil
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if searchPanel.Visible then filterCurrentTabSearch(searchBox.Text) end
    end)

    function window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tab = {
            Name = tostring(tabConfig.name or ("Tab " .. (#window.Tabs + 1))),
            IconData = tabConfig.icon or "layout-dashboard",
            Sections = {},
            Order = 0,
        }

        local tabButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.Element,
            BackgroundTransparency = 1,
            Text = "",
            Size = sidebarLayout and UDim2.new(1, 0, 0, 40) or UDim2.fromOffset(math.clamp(74 + #tab.Name * 6, 96, 150), 34),
            LayoutOrder = #window.Tabs + 1,
            ZIndex = 10,
        }, tabBar)
        local selectedBox = new("Frame", {
            BackgroundColor3 = theme.Element,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.fromOffset(1, 1),
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 11,
        }, tabButton)
        corner(selectedBox, UDim.new(0, 10))
        local selectedStroke = stroke(selectedBox, Color3.fromRGB(98, 101, 109), 1, 1)
        local softLight = new("Frame", {
            BackgroundColor3 = theme.White,
            BackgroundTransparency = 0.4,
            Size = UDim2.new(1, 0, 0.56, 0),
            Position = UDim2.fromOffset(0, 0),
            ZIndex = 12,
        }, selectedBox)
        corner(softLight, UDim.new(0, 9))
        gradient(softLight, {
            ColorSequenceKeypoint.new(0, theme.White),
            ColorSequenceKeypoint.new(1, theme.White),
        }, 90, NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.72, 0.62),
            NumberSequenceKeypoint.new(1, 1),
        }))
        local icon = makeIcon(tabButton, tab.IconData, 16, theme.Muted, 13)
        if icon then
            icon.Position = sidebarLayout and UDim2.fromOffset(12, 12) or UDim2.fromOffset(10, 9)
            addScale(icon, 1)
        end
        local tabText = new("TextLabel", {
            BackgroundTransparency = 1,
            Text = tab.Name,
            TextColor3 = theme.Muted,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = sidebarLayout and UDim2.fromOffset(36, 0) or UDim2.fromOffset(33, 0),
            Size = sidebarLayout and UDim2.new(1, -46, 1, 0) or UDim2.new(1, -42, 1, 0),
            ZIndex = 14,
        }, tabButton)
        tab.TabButton = tabButton
        tab.SelectionBox = selectedBox
        tab.SelectionStroke = selectedStroke
        tab.SelectionLight = softLight

        tab.TabButton = tabButton
        tab.TabText = tabText
        tab.Icon = icon
        tab.Page, tab.List = buildPage(tab)

        table.insert(window.Tabs, tab)

        tabButton.MouseEnter:Connect(function()
            if currentTab ~= tab then
                tween(tabText, 0.15, {TextColor3 = theme.Text})
                if icon then tween(icon, 0.15, {ImageColor3 = theme.Text}) end
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if currentTab ~= tab then
                tween(tabText, 0.15, {TextColor3 = theme.Muted})
                if icon then tween(icon, 0.15, {ImageColor3 = theme.Muted}) end
            end
        end)
        tabButton.MouseButton1Click:Connect(function() selectTab(tab) end)
        if #window.Tabs == 1 then task.defer(function() selectTab(tab) end) end

        function tab:CreateSection(sectionConfig)
            sectionConfig = sectionConfig or {}
            tab.Order += 1
            local hasDescription = sectionConfig.description and tostring(sectionConfig.description) ~= ""
            local holder = new("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, hasDescription and 52 or 34),
                LayoutOrder = tab.Order,
                ZIndex = 9,
            }, tab.Page)
            local sectionIcon = makeIcon(holder, sectionConfig.icon, 15, theme.Accent2, 11)
            local left = 11
            if sectionIcon then sectionIcon.Position = UDim2.fromOffset(11, 5); left = 32 end
            new("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(sectionConfig.name or "Section"),
                TextColor3 = theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(left, 2),
                Size = UDim2.new(1, -left, 0, 20),
                ZIndex = 10,
            }, holder)
            if hasDescription then
                new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = tostring(sectionConfig.description),
                    TextColor3 = theme.Muted,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Position = UDim2.fromOffset(left, 22),
                    Size = UDim2.new(1, -left, 0, 18),
                    ZIndex = 10,
                }, holder)
            end
            return holder
        end

        function tab:CreateButton(element)
            element = element or {}
            tab.Order += 1
            local hasDescription = element.description and tostring(element.description) ~= ""
            local height = hasDescription and 64 or 48
            local button = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = elementBox,
                Text = "",
                Size = UDim2.new(1, 0, 0, height),
                LayoutOrder = tab.Order,
                ZIndex = 9,
            }, tab.Page)
            styleElementBox(button, 11)
            setTextPair(button, element.name or "Button", element.description, theme, 9, -62, 10)
            local actionIcon = makeIcon(button, element.icon or "chevron-right", 16, theme.Muted, 12)
            if actionIcon then actionIcon.AnchorPoint = Vector2.new(1, 0.5); actionIcon.Position = UDim2.new(1, -14, 0.5, 0) end
            button.MouseEnter:Connect(function()
                tween(button, 0.15, {BackgroundColor3 = elementBoxHover})
                if actionIcon then tween(actionIcon, 0.15, {ImageColor3 = theme.Accent2, Position = UDim2.new(1, -11, 0.5, 0)}) end
            end)
            button.MouseLeave:Connect(function()
                tween(button, 0.15, {BackgroundColor3 = elementBox})
                if actionIcon then tween(actionIcon, 0.15, {ImageColor3 = theme.Muted, Position = UDim2.new(1, -14, 0.5, 0)}) end
            end)
            button.MouseButton1Click:Connect(function()
                if actionIcon then iconPop(actionIcon) end
                if typeof(element.callback) == "function" then task.spawn(element.callback) end
            end)
            registerSearchItem(tab, button, element.name or "Button", element.description)
            return button
        end

        function tab:CreateToggle(element)
            element = element or {}
            tab.Order += 1
            local state = element.value == true
            local hasDescription = element.description and tostring(element.description) ~= ""
            local height = hasDescription and 64 or 52
            local button = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = elementBox,
                Text = "",
                Size = UDim2.new(1, 0, 0, height),
                LayoutOrder = tab.Order,
                ZIndex = 9,
            }, tab.Page)
            styleElementBox(button, 11)
            setTextPair(button, element.name or "Toggle", element.description, theme, 8, -84, 10)

            local track = new("Frame", {
                BackgroundColor3 = theme.Panel2,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(47, 25),
                ZIndex = 11,
            }, button)
            corner(track, UDim.new(1, 0))
            stroke(track, theme.Border2, 0.2, 1)
            local trackGlow = new("Frame", {
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(1, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 10,
            }, track)
            corner(trackGlow, UDim.new(1, 0))
            local knob = new("Frame", {
                BackgroundColor3 = theme.Muted,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 4, 0.5, 0),
                Size = UDim2.fromOffset(17, 17),
                ZIndex = 12,
            }, track)
            corner(knob, UDim.new(1, 0))
            stroke(knob, Color3.new(1, 1, 1), 0.88, 1)

            local function apply(stateValue, fire)
                state = stateValue == true
                local x = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
                tween(track, 0.19, {BackgroundColor3 = state and theme.AccentDark or theme.Panel2})
                tween(trackGlow, 0.2, {BackgroundTransparency = state and 0.1 or 1})
                tween(knob, 0.22, {Position = x, BackgroundColor3 = state and theme.White or theme.Muted}, Enum.EasingStyle.Back)
                if fire and typeof(element.callback) == "function" then task.spawn(element.callback, state) end
            end
            apply(state, false)
            button.MouseEnter:Connect(function() tween(button, 0.15, {BackgroundColor3 = elementBoxHover}) end)
            button.MouseLeave:Connect(function() tween(button, 0.15, {BackgroundColor3 = elementBox}) end)
            button.MouseButton1Click:Connect(function() apply(not state, true) end)

            local api = {}
            function api:Set(value, fire)
                apply(value == true, fire ~= false)
            end
            function api:Get()
                return state
            end
            if element.flag then window._StateEntries[tostring(element.flag)] = api end
            registerSearchItem(tab, button, element.name or "Toggle", element.description)
            return api
        end

        function tab:CreateDropdown(element)
            element = element or {}
            tab.Order += 1
            local options = table.clone(element.options or {})
            local selected = {}
            if element.multiSelect then
                for _, item in ipairs(element.value or {}) do selected[tostring(item)] = true end
            elseif element.value ~= nil then
                selected[tostring(element.value)] = true
            end

            local hasDescription = element.description and tostring(element.description) ~= ""
            local closedHeight = hasDescription and 72 or 58
            local holder = new("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, closedHeight),
                LayoutOrder = tab.Order,
                ClipsDescendants = true,
                ZIndex = 12,
            }, tab.Page)
            local button = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = elementBox,
                Text = "",
                Size = UDim2.new(1, 0, 0, closedHeight),
                ZIndex = 13,
            }, holder)
            styleElementBox(button, 11)
            setTextPair(button, element.name or "Dropdown", element.description, theme, 7, -140, 14)

            local valueLabel = new("TextLabel", {
                BackgroundTransparency = 1,
                Text = "Select...",
                TextColor3 = theme.Muted,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0.42, 0, hasDescription and 0 or 0.5, hasDescription and 42 or -8),
                Size = UDim2.new(0.52, -30, 0, 18),
                ZIndex = 15,
            }, button)
            local arrow = makeIcon(button, "chevron-down", 16, theme.Muted, 16)
            if arrow then arrow.AnchorPoint = Vector2.new(0.5, 0.5); arrow.Position = UDim2.new(1, -16, 0.5, 0) end

            local open = false
            local searchQuery = ""
            local expandedHeight = closedHeight
            local api = {}

            local searchShell = new("Frame", {
                BackgroundColor3 = theme.Panel2,
                BackgroundTransparency = 0.02,
                Position = UDim2.fromOffset(8, closedHeight - 10),
                Size = UDim2.new(1, -16, 0, 34),
                Visible = false,
                ZIndex = 16,
            }, holder)
            corner(searchShell, UDim.new(0, 9))
            stroke(searchShell, theme.Border2, 0.25, 1)
            local searchIcon = makeIcon(searchShell, "search", 14, theme.Muted, 18)
            if searchIcon then searchIcon.Position = UDim2.fromOffset(10, 10) end
            local search = new("TextBox", {
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                PlaceholderText = "Search options...",
                PlaceholderColor3 = theme.Muted,
                Text = "",
                TextColor3 = theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(31, 0),
                Size = UDim2.new(1, -43, 1, 0),
                ZIndex = 18,
            }, searchShell)

            local list = new("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(8, closedHeight + 31),
                Size = UDim2.new(1, -16, 0, 0),
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = theme.Accent,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 17,
                Visible = false,
            }, holder)
            new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)

            local function getSelectedText()
                local chosen = {}
                for _, item in ipairs(options) do
                    if selected[tostring(item)] then table.insert(chosen, tostring(item)) end
                end
                if #chosen == 0 then return "Select..." end
                if #chosen <= 2 then return table.concat(chosen, ", ") end
                return tostring(#chosen) .. " selected"
            end

            local function updateValue()
                valueLabel.Text = getSelectedText()
            end
            updateValue()

            local function visibleOptions(query)
                local result = {}
                for _, option in ipairs(options) do
                    local text = tostring(option)
                    if query == "" or string.find(string.lower(text), string.lower(query), 1, true) then
                        table.insert(result, option)
                    end
                end
                return result
            end

            local function refreshRows(query)
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("GuiButton") or child:IsA("TextLabel") then child:Destroy() end
                end
                local matches = visibleOptions(query or "")
                if #matches == 0 then
                    new("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = "No matching options",
                        TextColor3 = theme.Muted,
                        Font = Enum.Font.Gotham,
                        TextSize = 10,
                        Size = UDim2.new(1, 0, 0, 34),
                        ZIndex = 18,
                    }, list)
                else
                    for index, option in ipairs(matches) do
                        local text = tostring(option)
                        local row = new("TextButton", {
                            AutoButtonColor = false,
                            BackgroundColor3 = selected[text] and theme.AccentDark or elementBox,
                            BackgroundTransparency = 0.03,
                            Text = "",
                            Size = UDim2.new(1, -2, 0, 34),
                            LayoutOrder = index,
                            ZIndex = 18,
                        }, list)
                        corner(row, UDim.new(0, 8))
                        if isDefaultTheme then
                            stroke(row, elementBorder, 0.05, 1)
                            new("UIGradient", {
                                Name = "DefaultDropdownRowLight",
                                Rotation = 90,
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 63, 68)),
                                    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(56, 57, 62)),
                                    ColorSequenceKeypoint.new(0.53, Color3.fromRGB(46, 47, 52)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 41, 46)),
                                }),
                            }, row)
                        end
                        local rowIcon = makeIcon(row, selected[text] and "check" or (element.optionIcon or "circle"), 14, selected[text] and theme.Accent2 or theme.Faint, 20)
                        if rowIcon then rowIcon.AnchorPoint = Vector2.new(0, 0.5); rowIcon.Position = UDim2.new(0, 10, 0.5, 0) end
                        new("TextLabel", {
                            BackgroundTransparency = 1,
                            Text = text,
                            TextColor3 = selected[text] and theme.Text or theme.Muted,
                            Font = Enum.Font.GothamMedium,
                            TextSize = 10,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Position = UDim2.fromOffset(32, 0),
                            Size = UDim2.new(1, -42, 1, 0),
                            ZIndex = 20,
                        }, row)
                        row.MouseEnter:Connect(function() tween(row, 0.12, {BackgroundColor3 = selected[text] and theme.AccentDark or elementBoxHover}) end)
                        row.MouseLeave:Connect(function() tween(row, 0.12, {BackgroundColor3 = selected[text] and theme.AccentDark or elementBox}) end)
                        row.MouseButton1Click:Connect(function()
                            if element.multiSelect then
                                selected[text] = not selected[text]
                            else
                                table.clear(selected)
                                selected[text] = true
                            end
                            updateValue()
                            if typeof(element.callback) == "function" then
                                if element.multiSelect then
                                    local values = {}
                                    for _, item in ipairs(options) do if selected[tostring(item)] then table.insert(values, item) end end
                                    task.spawn(element.callback, values)
                                else
                                    task.spawn(element.callback, option)
                                end
                            end
                            refreshRows(search.Text)
                            if not element.multiSelect then
                                api:Close()
                            end
                        end)
                    end
                end
            end

            local function recomputeHeight()
                local count = #visibleOptions(searchQuery)
                local listHeight = math.clamp(math.max(1, math.min(count, 6)) * 38, 38, 228)
                expandedHeight = closedHeight + 48 + listHeight + 8
                if open then
                    tween(holder, 0.28, {Size = UDim2.new(1, 0, 0, expandedHeight)}, Enum.EasingStyle.Quint)
                    tween(list, 0.28, {Size = UDim2.new(1, -16, 0, listHeight)}, Enum.EasingStyle.Quint)
                else
                    list.Size = UDim2.new(1, -16, 0, listHeight)
                end
            end

            local function openDropdown()
                if open then
                    api:Close()
                    return
                end
                if window._ActiveDropdown and window._ActiveDropdown ~= api then
                    window._ActiveDropdown:Close()
                end
                window._ActiveDropdown = api
                open = true
                searchQuery = search.Text
                refreshRows(searchQuery)
                recomputeHeight()
                holder.Size = UDim2.new(1, 0, 0, closedHeight)
                searchShell.Visible = true
                list.Visible = true
                searchShell.Position = UDim2.fromOffset(8, closedHeight - 10)
                list.Position = UDim2.fromOffset(8, closedHeight + 28)
                tween(holder, 0.3, {Size = UDim2.new(1, 0, 0, expandedHeight)}, Enum.EasingStyle.Quint)
                tween(searchShell, 0.3, {Position = UDim2.fromOffset(8, closedHeight + 8)}, Enum.EasingStyle.Back)
                tween(list, 0.3, {Position = UDim2.fromOffset(8, closedHeight + 50)}, Enum.EasingStyle.Quint)
                if arrow then tween(arrow, 0.2, {Rotation = 180, ImageColor3 = theme.Accent2}) end
            end

            function api:Close()
                if not open then return end
                open = false
                if window._ActiveDropdown == api then window._ActiveDropdown = nil end
                if arrow then tween(arrow, 0.2, {Rotation = 0, ImageColor3 = theme.Muted}) end
                tween(searchShell, 0.18, {Position = UDim2.fromOffset(8, closedHeight - 10)}, Enum.EasingStyle.Quint)
                tween(list, 0.18, {Position = UDim2.fromOffset(8, closedHeight + 28)}, Enum.EasingStyle.Quint)
                tween(holder, 0.24, {Size = UDim2.new(1, 0, 0, closedHeight)}, Enum.EasingStyle.Quint)
                task.delay(0.23, function()
                    if not open and searchShell.Parent then
                        searchShell.Visible = false
                        list.Visible = false
                    end
                end)
            end

            search:GetPropertyChangedSignal("Text"):Connect(function()
                if not open then return end
                searchQuery = search.Text
                refreshRows(searchQuery)
                recomputeHeight()
            end)
            button.MouseEnter:Connect(function() tween(button, 0.15, {BackgroundColor3 = elementBoxHover}) end)
            button.MouseLeave:Connect(function() if not open then tween(button, 0.15, {BackgroundColor3 = elementBox}) end end)
            button.MouseButton1Click:Connect(openDropdown)

            function api:Refresh(newOptions)
                options = table.clone(newOptions or {})
                for key in pairs(selected) do
                    local found = false
                    for _, option in ipairs(options) do
                        if tostring(option) == key then found = true break end
                    end
                    if not found then selected[key] = nil end
                end
                updateValue()
                if open then refreshRows(search.Text); recomputeHeight() end
            end
            function api:Set(value, fire)
                table.clear(selected)
                if element.multiSelect then
                    for _, item in ipairs(value or {}) do selected[tostring(item)] = true end
                elseif value ~= nil then
                    selected[tostring(value)] = true
                end
                updateValue()
                if fire ~= false and typeof(element.callback) == "function" then
                    if element.multiSelect then
                        local values = {}
                        for _, item in ipairs(options) do if selected[tostring(item)] then table.insert(values, item) end end
                        task.spawn(element.callback, values)
                    else
                        local valueOut
                        for _, item in ipairs(options) do if selected[tostring(item)] then valueOut = item; break end end
                        task.spawn(element.callback, valueOut)
                    end
                end
                if open then refreshRows(search.Text); recomputeHeight() end
            end
            function api:Get()
                if element.multiSelect then
                    local values = {}
                    for _, item in ipairs(options) do if selected[tostring(item)] then table.insert(values, item) end end
                    return values
                end
                for _, item in ipairs(options) do if selected[tostring(item)] then return item end end
                return nil
            end
            if element.flag then window._StateEntries[tostring(element.flag)] = api end
            registerSearchItem(tab, holder, element.name or "Dropdown", element.description)
            table.insert(dropdowns, api)
            return api
        end

        function tab:CreateSlider(element)
            element = element or {}
            tab.Order += 1
            local range = element.range or {0, 100}
            local minValue, maxValue = tonumber(range[1]) or 0, tonumber(range[2]) or 100
            if minValue > maxValue then minValue, maxValue = maxValue, minValue end
            local value = math.clamp(tonumber(element.value) or minValue, minValue, maxValue)
            local holder = new("Frame", {
                BackgroundColor3 = elementBox,
                Size = UDim2.new(1, 0, 0, element.description and 78 or 62),
                LayoutOrder = tab.Order,
                ZIndex = 9,
            }, tab.Page)
            styleElementBox(holder, 11)
            setTextPair(holder, element.name or "Slider", element.description, theme, 8, -30, 10)
            local valueLabel = new("TextLabel", {
                BackgroundTransparency = 1,
                TextColor3 = theme.Accent2,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0.67, 0, 0, 9),
                Size = UDim2.new(0.29, -12, 0, 20),
                ZIndex = 11,
            }, holder)
            local track = new("Frame", {
                BackgroundColor3 = theme.Panel2,
                Position = UDim2.new(0, 15, 1, -20),
                Size = UDim2.new(1, -30, 0, 6),
                ZIndex = 11,
            }, holder)
            corner(track, UDim.new(1, 0))
            local fill = new("Frame", {BackgroundColor3 = theme.Accent, Size = UDim2.fromScale(0, 1), ZIndex = 12}, track)
            corner(fill, UDim.new(1, 0))
            local knob = new("Frame", {BackgroundColor3 = theme.White, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(15, 15), ZIndex = 13}, track)
            corner(knob, UDim.new(1, 0))
            local draggingSlider = false
            local function apply(valueValue, fire)
                local increment = tonumber(element.increment) or 1
                local snapped = minValue + math.floor(((valueValue - minValue) / increment) + 0.5) * increment
                value = math.clamp(snapped, minValue, maxValue)
                local alpha = (value - minValue) / math.max(maxValue - minValue, 0.0001)
                fill.Size = UDim2.fromScale(alpha, 1)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                valueLabel.Text = tostring(value) .. tostring(element.suffix or "")
                if fire and typeof(element.callback) == "function" then task.spawn(element.callback, value) end
            end
            apply(value, false)
            local function inputValue(input)
                local length = math.max(track.AbsoluteSize.X, 1)
                local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / length, 0, 1)
                apply(minValue + (maxValue - minValue) * alpha, true)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true; inputValue(input) end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then inputValue(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
            end)
            local api = {}
            function api:Set(valueValue, fire) apply(tonumber(valueValue) or value, fire ~= false) end
            function api:Get() return value end
            if element.flag then window._StateEntries[tostring(element.flag)] = api end
            registerSearchItem(tab, holder, element.name or "Slider", element.description)
            return api
        end

        function tab:CreateInput(element)
            element = element or {}
            tab.Order += 1
            local hasDescription = element.description and tostring(element.description) ~= ""
            local holder = new("Frame", {
                BackgroundColor3 = elementBox,
                Size = UDim2.new(1, 0, 0, hasDescription and 83 or 69),
                LayoutOrder = tab.Order,
                ZIndex = 9,
            }, tab.Page)
            styleElementBox(holder, 11)
            setTextPair(holder, element.name or "Input", element.description, theme, 8, -30, 10)
            local box = new("TextBox", {
                BackgroundColor3 = theme.Panel2,
                TextColor3 = theme.Text,
                PlaceholderColor3 = theme.Muted,
                PlaceholderText = tostring(element.placeholder or "Enter text"),
                Text = tostring(element.value or ""),
                ClearTextOnFocus = false,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(13, hasDescription and 47 or 34),
                Size = UDim2.new(1, -26, 0, 27),
                ZIndex = 11,
            }, holder)
            corner(box, UDim.new(0, 8))
            stroke(box, theme.Border, 0.22, 1)
            new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, box)
            local committed = box.Text
            box.Focused:Connect(function() tween(box, 0.15, {BackgroundColor3 = theme.ElementHover}) end)
            box.FocusLost:Connect(function()
                tween(box, 0.15, {BackgroundColor3 = theme.Panel2})
                if element.numeric and box.Text ~= "" and tonumber(box.Text) == nil then
                    box.Text = committed
                    return
                end
                committed = box.Text
                if typeof(element.callback) == "function" then task.spawn(element.callback, box.Text) end
            end)
            local api = {}
            function api:Set(value, fire)
                box.Text = tostring(value)
                committed = box.Text
                if fire and typeof(element.callback) == "function" then task.spawn(element.callback, box.Text) end
            end
            function api:Get() return box.Text end
            if element.flag then window._StateEntries[tostring(element.flag)] = api end
            registerSearchItem(tab, holder, element.name or "Input", element.description)
            return api
        end

        return tab
    end

    local keybindCapturing = false
    keybindButton.MouseButton1Click:Connect(function()
        keybindCapturing = true
        keybindButton.Text = "Press a key..."
        keybindButton.TextColor3 = theme.Accent2
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if keybindCapturing then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                window._Keybind = input.KeyCode
                keybindButton.Text = input.KeyCode.Name
                keybindButton.TextColor3 = theme.Text
                keybindCapturing = false
            end
            return
        end
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == window._Keybind then
            window:Toggle()
        end
    end)

    local saveFile = "DarkyX_Save.json"
    local function setSettingsStatus(text, color)
        settingsStatus.Text = text
        settingsStatus.TextColor3 = color or theme.Success
        task.delay(2, function()
            if settingsStatus.Parent then settingsStatus.Text = "" end
        end)
    end

    saveButton.MouseButton1Click:Connect(function()
        if type(writefile) ~= "function" then
            setSettingsStatus("writefile unavailable", theme.Danger)
            return
        end
        local HttpService = game:GetService("HttpService")
        local data = {}
        for flag, apiEntry in pairs(window._StateEntries) do
            local ok, value = pcall(function() return apiEntry:Get() end)
            if ok then data[flag] = value end
        end
        local ok = pcall(function() writefile(saveFile, HttpService:JSONEncode(data)) end)
        setSettingsStatus(ok and "Saved" or "Save failed", ok and theme.Success or theme.Danger)
    end)

    loadButton.MouseButton1Click:Connect(function()
        if type(readfile) ~= "function" then
            setSettingsStatus("readfile unavailable", theme.Danger)
            return
        end
        local HttpService = game:GetService("HttpService")
        local okRead, raw = pcall(function() return readfile(saveFile) end)
        if not okRead then
            setSettingsStatus("No save found", theme.Danger)
            return
        end
        local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not okDecode or type(data) ~= "table" then
            setSettingsStatus("Invalid save", theme.Danger)
            return
        end
        for flag, value in pairs(data) do
            local apiEntry = window._StateEntries[tostring(flag)]
            if apiEntry then pcall(function() apiEntry:Set(value, true) end) end
        end
        setSettingsStatus("Loaded")
    end)

    function window:SetMeter(value)
        meterValue = math.clamp(tonumber(value) or 0, 0, 1)
        tween(dragFill, 0.24, {Size = UDim2.new(meterValue, 0, 1, 0)}, Enum.EasingStyle.Quint)
        tween(dragKnob, 0.24, {Position = UDim2.new(meterValue, 0, 0.5, 0)}, Enum.EasingStyle.Quint)
    end

    function window:GetMeter()
        return meterValue
    end

    function window:Toggle()
        setVisible(not window.Visible)
    end

    function window:SetVisible(value)
        setVisible(value == true)
    end

    function window:Destroy()
        if window.Destroyed then return end
        window.Destroyed = true
        if loaderTitle and loaderTitle.Parent then loaderTitle:Destroy() end
        if screenGui and screenGui.Parent then
            tween(mainScale, 0.22, {Scale = 0.92}, Enum.EasingStyle.Quint)
            task.delay(0.22, function()
                if screenGui and screenGui.Parent then screenGui:Destroy() end
            end)
        end
    end

    task.delay(0.72, function()
        if window.Destroyed or not loaderTitle.Parent then return end
        main.Visible = true
        dragBar.Visible = true
        placeDragBarBelow()
        mainScale.Scale = 0.94
        tween(loaderScale, 0.24, {Scale = 1.12}, Enum.EasingStyle.Quint)
        tween(loaderTitle, 0.22, {TextTransparency = 1})
        tween(mainScale, 0.38, {Scale = 1}, Enum.EasingStyle.Back)
        task.delay(0.25, function()
            if loaderTitle and loaderTitle.Parent then loaderTitle:Destroy() end
        end)
    end)

    return window
end

return DarkyX
