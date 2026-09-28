local DarkyX = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Icons = {}
pcall(function()
	local isUI = function()
		return typeof(gethui) == "function" or pcall(function() return CoreGui end)
	end
	local get = function(url)
		return game:HttpGet(url)
	end
	local ok, result = pcall(function()
		return isUI() and loadstring(get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))() or require("./lucide/dist/Icons")
	end)
	if ok and type(result) == "table" then
		Icons.lucide = result
	end
end)

DarkyX.Icons = Icons

local Themes = {
	cobalt = {
		Background = Color3.fromRGB(10, 14, 23),
		Panel = Color3.fromRGB(14, 20, 32),
		Panel2 = Color3.fromRGB(18, 25, 39),
		Element = Color3.fromRGB(21, 29, 45),
		ElementHover = Color3.fromRGB(27, 37, 57),
		Accent = Color3.fromRGB(46, 126, 255),
		Accent2 = Color3.fromRGB(93, 163, 255),
		Text = Color3.fromRGB(245, 248, 255),
		Muted = Color3.fromRGB(153, 165, 188),
		Border = Color3.fromRGB(37, 48, 70),
		Danger = Color3.fromRGB(255, 83, 97),
		Success = Color3.fromRGB(68, 214, 142),
	},
	red = {
		Background = Color3.fromRGB(16, 9, 11), Panel = Color3.fromRGB(24, 13, 16), Panel2 = Color3.fromRGB(31, 17, 20),
		Element = Color3.fromRGB(37, 20, 24), ElementHover = Color3.fromRGB(50, 26, 31), Accent = Color3.fromRGB(235, 57, 72),
		Accent2 = Color3.fromRGB(255, 103, 116), Text = Color3.fromRGB(255, 245, 246), Muted = Color3.fromRGB(181, 151, 156),
		Border = Color3.fromRGB(69, 34, 40), Danger = Color3.fromRGB(255, 73, 88), Success = Color3.fromRGB(69, 214, 143),
	},
	bluesky = {
		Background = Color3.fromRGB(8, 15, 21), Panel = Color3.fromRGB(12, 22, 30), Panel2 = Color3.fromRGB(16, 29, 39),
		Element = Color3.fromRGB(18, 34, 45), ElementHover = Color3.fromRGB(24, 45, 59), Accent = Color3.fromRGB(46, 178, 255),
		Accent2 = Color3.fromRGB(117, 210, 255), Text = Color3.fromRGB(241, 250, 255), Muted = Color3.fromRGB(147, 174, 190),
		Border = Color3.fromRGB(31, 61, 77), Danger = Color3.fromRGB(255, 78, 95), Success = Color3.fromRGB(68, 216, 148),
	},
	dark = {
		Background = Color3.fromRGB(11, 11, 13), Panel = Color3.fromRGB(15, 15, 18), Panel2 = Color3.fromRGB(19, 19, 23),
		Element = Color3.fromRGB(23, 23, 27), ElementHover = Color3.fromRGB(30, 30, 35), Accent = Color3.fromRGB(115, 115, 255),
		Accent2 = Color3.fromRGB(155, 155, 255), Text = Color3.fromRGB(245, 245, 248), Muted = Color3.fromRGB(156, 156, 166),
		Border = Color3.fromRGB(42, 42, 48), Danger = Color3.fromRGB(255, 77, 90), Success = Color3.fromRGB(67, 216, 142),
	},
	green = {
		Background = Color3.fromRGB(7, 15, 11), Panel = Color3.fromRGB(11, 21, 15), Panel2 = Color3.fromRGB(15, 28, 20),
		Element = Color3.fromRGB(17, 35, 24), ElementHover = Color3.fromRGB(23, 47, 32), Accent = Color3.fromRGB(52, 214, 116),
		Accent2 = Color3.fromRGB(105, 235, 153), Text = Color3.fromRGB(239, 255, 246), Muted = Color3.fromRGB(145, 178, 156),
		Border = Color3.fromRGB(29, 61, 42), Danger = Color3.fromRGB(255, 78, 94), Success = Color3.fromRGB(62, 220, 133),
	},
	purple = {
		Background = Color3.fromRGB(12, 9, 18), Panel = Color3.fromRGB(19, 14, 29), Panel2 = Color3.fromRGB(25, 18, 37),
		Element = Color3.fromRGB(31, 22, 46), ElementHover = Color3.fromRGB(42, 28, 61), Accent = Color3.fromRGB(164, 91, 255),
		Accent2 = Color3.fromRGB(198, 144, 255), Text = Color3.fromRGB(248, 242, 255), Muted = Color3.fromRGB(173, 157, 194),
		Border = Color3.fromRGB(57, 39, 80), Danger = Color3.fromRGB(255, 76, 94), Success = Color3.fromRGB(73, 218, 145),
	},
	orange = {
		Background = Color3.fromRGB(18, 11, 7), Panel = Color3.fromRGB(28, 17, 10), Panel2 = Color3.fromRGB(36, 22, 13),
		Element = Color3.fromRGB(43, 27, 16), ElementHover = Color3.fromRGB(57, 35, 20), Accent = Color3.fromRGB(255, 143, 52),
		Accent2 = Color3.fromRGB(255, 183, 111), Text = Color3.fromRGB(255, 248, 239), Muted = Color3.fromRGB(193, 168, 143),
		Border = Color3.fromRGB(74, 46, 26), Danger = Color3.fromRGB(255, 78, 93), Success = Color3.fromRGB(72, 217, 143),
	},
	yellow = {
		Background = Color3.fromRGB(17, 16, 7), Panel = Color3.fromRGB(26, 24, 10), Panel2 = Color3.fromRGB(35, 32, 13),
		Element = Color3.fromRGB(42, 39, 16), ElementHover = Color3.fromRGB(56, 51, 21), Accent = Color3.fromRGB(243, 203, 54),
		Accent2 = Color3.fromRGB(255, 225, 108), Text = Color3.fromRGB(255, 253, 238), Muted = Color3.fromRGB(186, 180, 145),
		Border = Color3.fromRGB(69, 63, 27), Danger = Color3.fromRGB(255, 76, 91), Success = Color3.fromRGB(68, 216, 142),
	},
	white = {
		Background = Color3.fromRGB(239, 241, 246), Panel = Color3.fromRGB(248, 249, 252), Panel2 = Color3.fromRGB(234, 236, 242),
		Element = Color3.fromRGB(226, 229, 236), ElementHover = Color3.fromRGB(214, 218, 227), Accent = Color3.fromRGB(45, 107, 255),
		Accent2 = Color3.fromRGB(85, 139, 255), Text = Color3.fromRGB(24, 28, 38), Muted = Color3.fromRGB(91, 97, 113),
		Border = Color3.fromRGB(199, 204, 216), Danger = Color3.fromRGB(230, 54, 72), Success = Color3.fromRGB(34, 177, 106),
	},
}

local function getTheme(theme)
	if type(theme) == "table" then
		return theme
	end
	return Themes[string.lower(tostring(theme or "cobalt"))] or Themes.cobalt
end

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

local function tween(object, time, properties, style, direction)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(object, info, properties)
	t:Play()
	return t
end

local function safeAsset(icon)
	if typeof(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	end
	if type(icon) ~= "string" then
		return nil
	end
	if icon:match("^rbxassetid://") then
		return icon
	end
	local key = string.lower(icon)
	if Icons.lucide then
		return Icons.lucide[key] or Icons.lucide[string.gsub(key, "_", "-")]
	end
	return nil
end

local function makeIcon(parent, icon, size, tint)
	local imageId = safeAsset(icon)
	if not imageId then
		return nil
	end
	return new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = imageId,
		ImageColor3 = tint or Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(size or 20, size or 20),
		ScaleType = Enum.ScaleType.Fit,
	}, parent)
end

local function addScale(object)
	return new("UIScale", {Scale = 1}, object)
end

local function animateIcon(icon)
	if not icon then return end
	local scale = icon:FindFirstChildOfClass("UIScale") or addScale(icon)
	scale.Scale = 0.86
	icon.Rotation = -8
	tween(scale, 0.22, {Scale = 1.10}, Enum.EasingStyle.Back)
	tween(icon, 0.25, {Rotation = 0}, Enum.EasingStyle.Quint)
	task.delay(0.22, function()
		if icon.Parent then
			tween(scale, 0.18, {Scale = 1}, Enum.EasingStyle.Quint)
		end
	end)
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart
	local startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function addDescription(parent, title, description, y)
	local titleLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(title or ""),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 16, 0, y),
		Size = UDim2.new(1, -32, 0, description and 18 or 22),
		ZIndex = 3,
	}, parent)
	if description and tostring(description) ~= "" then
		new("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(description),
			TextColor3 = Color3.fromRGB(145, 154, 173),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.new(0, 16, 0, y + 18),
			Size = UDim2.new(1, -32, 0, 26),
			ZIndex = 3,
		}, parent)
	end
end

function DarkyX:CreateWindow(config)
	config = config or {}
	local theme = getTheme(config.theme)
	local sidebar = config.sidebarLayout == true
	local guiName = "DarkyX_" .. tostring(math.random(10000, 99999))

	local existing = CoreGui
	if type(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and typeof(result) == "Instance" then existing = result end
	end
	local screenGui = new("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, existing)

	local window = {
		ScreenGui = screenGui,
		Theme = theme,
		Tabs = {},
		Destroyed = false,
		Visible = true,
		Sidebar = sidebar,
	}

	local loadingOverlay = new("Frame", {
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 100,
	}, screenGui)
		
	local bigText = new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "DarkyX",
		TextColor3 = theme.Text,
		TextTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 76,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(500, 100),
		ZIndex = 101,
	}, loadingOverlay)
	local textScale = addScale(bigText)
	textScale.Scale = 0.5
	local loadingSubtitle = new("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(config.subtitle or "DarkyX UI Library"),
		TextColor3 = theme.Muted,
		TextTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(420, 30),
		ZIndex = 101,
	}, loadingOverlay)
	local loadingLine = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.15,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.61),
		Size = UDim2.fromOffset(0, 2),
		ZIndex = 101,
	}, loadingOverlay)
	corner(loadingLine, UDim.new(1, 0))
	
	tween(bigText, 0.42, {TextTransparency = 0})
	tween(textScale, 0.5, {Scale = 1}, Enum.EasingStyle.Quint)
	tween(loadingSubtitle, 0.4, {TextTransparency = 0}, Enum.EasingStyle.Quint)
	tween(loadingLine, 0.55, {Size = UDim2.fromOffset(180, 2)}, Enum.EasingStyle.Quint)

	local main = new("Frame", {
		Name = "Main",
		BackgroundColor3 = theme.Background,
		Size = UDim2.fromOffset(config.width or 550, config.height or 340),
		Position = UDim2.new(0.5, -(config.width or 550) / 2, 0.5, -(config.height or 340) / 2),
		ZIndex = 2,
	}, screenGui)
	corner(main, UDim.new(0, 16))
	stroke(main, theme.Border, 0.2, 1)
	local mainScale = addScale(main)
	mainScale.Scale = 0.94

	main.ZIndex = 2

	local topBar = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 62),
		ZIndex = 5,
	}, main)
	makeDraggable(topBar, main)

	local title = new("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(config.name or "DarkyX Hub"),
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.fromOffset(270, 24),
		ZIndex = 6,
	}, topBar)
	local subtitle = new("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(config.subtitle or "DarkyX"),
		TextColor3 = theme.Muted,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(19, 34),
		Size = UDim2.fromOffset(270, 18),
		ZIndex = 6,
	}, topBar)

	local controls = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(82, 32),
		ZIndex = 8,
	}, topBar)
	local controlsLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5)}, controls)

	local function controlButton(symbol, icon, accent)
		local button = new("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.Element,
			Text = symbol or "",
			TextColor3 = accent or theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.fromOffset(25, 25),
		}, controls)
		corner(button, UDim.new(1, 0))
		stroke(button, theme.Border, 0.35, 1)
		if icon then
			local image = makeIcon(button, icon, 15, accent or theme.Text)
			if image then
				image.AnchorPoint = Vector2.new(0.5, 0.5)
				image.Position = UDim2.fromScale(0.5, 0.5)
				button.Text = ""
			end
		end
		button.MouseEnter:Connect(function() tween(button, 0.15, {BackgroundColor3 = theme.ElementHover}) end)
		button.MouseLeave:Connect(function() tween(button, 0.15, {BackgroundColor3 = theme.Element}) end)
		return button
	end

	local minBtn = controlButton(nil, "minus")
	local closeBtn = controlButton(nil, "x", theme.Danger)

	local content = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 1, -62),
		ZIndex = 3,
	}, main)

	local tabBar = new("Frame", {
		BackgroundTransparency = 1,
		Position = sidebar and UDim2.fromOffset(10, 0) or UDim2.fromOffset(10, 0),
		Size = sidebar and UDim2.new(0, 140, 1, -8) or UDim2.new(1, -20, 0, 42),
		ZIndex = 4,
	}, content)
	if sidebar then
		local sideStroke = stroke(tabBar, theme.Border, 0.5, 1)
		corner(tabBar, UDim.new(0, 12))
	end
	
	local tabList = new("UIListLayout", {
		FillDirection = sidebar and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabBar)
	
	local pages = new("Frame", {
		BackgroundTransparency = 1,
		Position = sidebar and UDim2.new(0, 158, 0, 0) or UDim2.fromOffset(10, 48),
		Size = sidebar and UDim2.new(1, -168, 1, -8) or UDim2.new(1, -20, 1, -58),
		ZIndex = 3,
	}, content)

	local floating = new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -42, 1, -44),
		Size = UDim2.fromOffset(52, 52),
		Text = "",
		ZIndex = 40,
	}, screenGui)
	corner(floating, UDim.new(1, 0))
	stroke(floating, theme.Accent2, 0.35, 1)
	local floatingIcon = makeIcon(floating, "panel-top", 22, Color3.new(1, 1, 1))
	if floatingIcon then floatingIcon.AnchorPoint = Vector2.new(0.5, 0.5); floatingIcon.Position = UDim2.fromScale(0.5, 0.5); addScale(floatingIcon) end
	makeDraggable(floating, floating)

	local currentTab
	local function setVisible(value)
		window.Visible = value
		if value then
			main.Visible = true
			floating.Visible = false
			tween(mainScale, 0.28, {Scale = 1}, Enum.EasingStyle.Back)
		else
			tween(mainScale, 0.22, {Scale = 0.94}, Enum.EasingStyle.Quint)
			task.delay(0.21, function()
				if not window.Visible and main.Parent then main.Visible = false end
			end)
			floating.Visible = true
		end
	end
	
	minBtn.MouseButton1Click:Connect(function() setVisible(false) end)
	floating.MouseButton1Click:Connect(function() setVisible(true) end)
	floating.MouseEnter:Connect(function() tween(floating, 0.18, {Size = UDim2.fromOffset(56, 56)}) end)
	floating.MouseLeave:Connect(function() tween(floating, 0.18, {Size = UDim2.fromOffset(52, 52)}) end)
	closeBtn.MouseButton1Click:Connect(function() window:Destroy() end)
	
	local function createPage(tab)
		local page = new("ScrollingFrame", {
			Name = tab.Name .. "Page",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.Accent,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			ZIndex = 3,
			Visible = false,
		}, pages)
		local padding = new("UIPadding", {
			PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 7),
		}, page)
		local list = new("UIListLayout", {
			Padding = UDim.new(0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)
		return page, list
	end

	local function selectTab(tab)
		if currentTab == tab then return end
		currentTab = tab
		for _, other in ipairs(window.Tabs) do
			other.Page.Visible = false
			other.TabButton.BackgroundColor3 = theme.Element
			other.TabButton.TextColor3 = theme.Muted
			local glass = other.TabButton:FindFirstChild("DarkyXGlass")
			if glass then glass.BackgroundTransparency = 1 end
			if other.Icon then other.Icon.ImageColor3 = theme.Muted end
		end
		tab.Page.Visible = true
		tab.TabButton.BackgroundColor3 = theme.ElementHover
		tab.TabButton.TextColor3 = theme.Text
		local glass = tab.TabButton:FindFirstChild("DarkyXGlass")
		if glass then glass.BackgroundTransparency = 0.86; tween(glass, 0.2, {BackgroundTransparency = 0.66}) end
		if tab.Icon then
			tab.Icon.ImageColor3 = theme.Accent2
			animateIcon(tab.Icon)
		end
	end

	function window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local tab = {
			Name = tostring(tabConfig.name or ("Tab " .. tostring(#window.Tabs + 1))),
			IconData = tabConfig.icon or "layout-dashboard",
		}
		local button = new("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.Element,
			Text = "",
			Size = sidebar and UDim2.new(1, -12, 0, 40) or UDim2.fromOffset(122, 38),
			ZIndex = 6,
			LayoutOrder = #window.Tabs + 1,
		}, tabBar)
		corner(button, UDim.new(0, 11))
		stroke(button, theme.Border, 0.65, 1)
		local glass = new("Frame", {Name = "DarkyXGlass", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5}, button)
		corner(glass, UDim.new(0, 11))
		local icon = makeIcon(button, tab.IconData, 17, theme.Muted)
		if icon then
			icon.Name = "Icon"
			icon.Position = sidebar and UDim2.fromOffset(11, 11) or UDim2.fromOffset(10, 10)
			icon.ZIndex = 7
			addScale(icon)
		end
		local label = new("TextLabel", {
			BackgroundTransparency = 1,
			Text = tab.Name,
			TextColor3 = theme.Muted,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = sidebar and UDim2.fromOffset(36, 0) or UDim2.fromOffset(34, 0),
			Size = sidebar and UDim2.new(1, -44, 1, 0) or UDim2.new(1, -42, 1, 0),
			ZIndex = 7,
		}, button)
		button.MouseEnter:Connect(function()
			if currentTab ~= tab then tween(button, 0.14, {BackgroundColor3 = theme.ElementHover}) end
		end)
		button.MouseLeave:Connect(function()
			if currentTab ~= tab then tween(button, 0.14, {BackgroundColor3 = theme.Element}) end
		end)
		
		tab.TabButton = button
		tab.Icon = icon
		tab.Page, tab.List = createPage(tab)
		tab.Sections = {}
		tab._order = 0
		window.Tabs[#window.Tabs + 1] = tab
		button.MouseButton1Click:Connect(function() selectTab(tab) end)
		if #window.Tabs == 1 then task.defer(function() selectTab(tab) end) end

		function tab:CreateSection(sectionConfig)
			sectionConfig = sectionConfig or {}
			tab._order += 1
			local holder = new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, sectionConfig.description and 46 or 34),
				LayoutOrder = tab._order,
			}, tab.Page)
			local line = new("Frame", {
				BackgroundColor3 = theme.Border,
				BackgroundTransparency = 0.35,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
			}, holder)
			local iconObj = makeIcon(holder, sectionConfig.icon, 16, theme.Accent2)
			if iconObj then iconObj.Position = UDim2.fromOffset(0, 7) end
			local left = iconObj and 23 or 0
			new("TextLabel", {
				BackgroundTransparency = 1,
				Text = tostring(sectionConfig.name or "Section"),
				TextColor3 = theme.Text,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(left, 3),
				Size = UDim2.new(1, -left, 0, 20),
			}, holder)
			if sectionConfig.description then
				new("TextLabel", {
					BackgroundTransparency = 1,
					Text = tostring(sectionConfig.description),
					TextColor3 = theme.Muted,
					Font = Enum.Font.Gotham,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(left, 20),
					Size = UDim2.new(1, -left, 0, 18),
				}, holder)
			end
			tab.Sections[#tab.Sections + 1] = holder
			return holder
		end

		function tab:CreateButton(element)
			element = element or {}
			tab._order += 1
			local height = element.description and 62 or 46
			local button = new("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = theme.Element,
				Text = "",
				Size = UDim2.new(1, 0, 0, height),
				LayoutOrder = tab._order,
			}, tab.Page)
			corner(button, UDim.new(0, 10)); stroke(button, theme.Border, 0.45, 1)
			addDescription(button, element.name or "Button", element.description, 10)
			button.MouseEnter:Connect(function() tween(button, 0.15, {BackgroundColor3 = theme.ElementHover}) end)
			button.MouseLeave:Connect(function() tween(button, 0.15, {BackgroundColor3 = theme.Element}) end)
			button.MouseButton1Click:Connect(function()
				if typeof(element.callback) == "function" then task.spawn(element.callback) end
			end)
			return button
		end

		function tab:CreateToggle(element)
			element = element or {}
			tab._order += 1
			local state = element.value == true
			local height = element.description and 62 or 52
			local button = new("TextButton", {AutoButtonColor = false, BackgroundColor3 = theme.Element, Text = "", Size = UDim2.new(1, 0, 0, height), LayoutOrder = tab._order}, tab.Page)
			corner(button, UDim.new(0, 10)); stroke(button, theme.Border, 0.45, 1)
			addDescription(button, element.name or "Toggle", element.description, 9)
			local track = new("Frame", {BackgroundColor3 = state and theme.Accent or theme.Panel2, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(40, 22)}, button)
			corner(track, UDim.new(1, 0)); stroke(track, theme.Border, 0.25, 1)
			local knob = new("Frame", {BackgroundColor3 = state and Color3.new(1, 1, 1) or theme.Muted, Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 19, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16)}, track)
			corner(knob, UDim.new(1, 0))
			local function applyToggle(fire)
				track.BackgroundColor3 = state and theme.Accent or theme.Panel2
				knob.BackgroundColor3 = state and Color3.new(1, 1, 1) or theme.Muted
				tween(knob, 0.2, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 19, 0.5, 0)}, Enum.EasingStyle.Back)
				if fire and typeof(element.callback) == "function" then task.spawn(element.callback, state) end
			end
			button.MouseButton1Click:Connect(function() state = not state; applyToggle(true) end)
			local api = {}
			function api:Set(value) state = value == true; applyToggle(false); if typeof(element.callback) == "function" then task.spawn(element.callback, state) end end
			function api:Get() return state end
			return api
		end

		function tab:CreateDropdown(element)
			element = element or {}
			tab._order += 1
			local options = table.clone(element.options or {})
			local selected = {}
			if element.multiSelect then
				for _, value in ipairs(element.value or {}) do selected[tostring(value)] = true end
			else
				if element.value ~= nil then selected[tostring(element.value)] = true end
			end
			local height = element.description and 74 or 58
			local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = tab._order}, tab.Page)
			local button = new("TextButton", {AutoButtonColor = false, BackgroundColor3 = theme.Element, Text = "", Size = UDim2.fromScale(1, 1)}, holder)
			corner(button, UDim.new(0, 10)); stroke(button, theme.Border, 0.45, 1)
			addDescription(button, element.name or "Dropdown", element.description, 8)
			local valueLabel = new("TextLabel", {BackgroundTransparency = 1, TextColor3 = theme.Muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.new(0.46, 0, 0.5, -5), Size = UDim2.new(0.47, -35, 0, 18)}, button)
			local arrow = makeIcon(button, "chevron-down", 16, theme.Muted)
			if arrow then arrow.AnchorPoint = Vector2.new(1, 0.5); arrow.Position = UDim2.new(1, -12, 0.5, 6) end
			
			local popup
			local open = false
			local searchText = ""
			local function getSelectionText()
				local out = {}
				for _, option in ipairs(options) do if selected[tostring(option)] then table.insert(out, tostring(option)) end end
				if #out == 0 then return "Select..." end
				if #out <= 2 then return table.concat(out, ", ") end
				return tostring(#out) .. " selected"
			end
			local function updateValue() valueLabel.Text = getSelectionText() end
			updateValue()
			
			local function closePopup()
				if not popup or not open then return end
				open = false
				if arrow then tween(arrow, 0.18, {Rotation = 0}) end
				local panel = popup.Panel
				tween(panel, 0.18, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quint)
				task.delay(0.18, function() if popup and popup.Parent then popup:Destroy(); popup = nil end end)
			end
			
			local function choose(value)
				local key = tostring(value)
				if element.multiSelect then
					selected[key] = not selected[key]
				else
					table.clear(selected); selected[key] = true; closePopup()
				end
				updateValue()
				local result = {}
				if element.multiSelect then for _, option in ipairs(options) do if selected[tostring(option)] then table.insert(result, option) end end else result = element.valueType == "number" and tonumber(value) or value end
				if typeof(element.callback) == "function" then task.spawn(element.callback, result) end
				if popup and popup.RefreshRows then popup.RefreshRows() end
			end
			
			local function createPopup()
				if popup then closePopup(); return end
				open = true
				if arrow then tween(arrow, 0.18, {Rotation = 180}) end
				popup = new("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), ZIndex = 70}, screenGui)
				local panel = new("Frame", {BackgroundColor3 = theme.Panel, BorderSizePixel = 0, Position = UDim2.fromOffset(button.AbsolutePosition.X, button.AbsolutePosition.Y + button.AbsoluteSize.Y + 6), Size = UDim2.new(0, button.AbsoluteSize.X, 0, 0), ClipsDescendants = true, ZIndex = 71}, popup)
				corner(panel, UDim.new(0, 12)); stroke(panel, theme.Border, 0.25, 1)
				popup.Panel = panel
				local header = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 72}, panel)
				local search = new("TextBox", {BackgroundColor3 = theme.Element, PlaceholderText = "Search...", PlaceholderColor3 = theme.Muted, Text = "", TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, Position = UDim2.fromOffset(8, 7), Size = UDim2.new(1, -48, 0, 30), ZIndex = 73}, header)
				corner(search, UDim.new(0, 9)); stroke(search, theme.Border, 0.35, 1)
				local searchIcon = makeIcon(header, "search", 14, theme.Muted)
				if searchIcon then searchIcon.AnchorPoint = Vector2.new(1, 0.5); searchIcon.Position = UDim2.new(1, -12, 0.5, 0); searchIcon.ZIndex = 74 end
				local close = new("TextButton", {AutoButtonColor = false, BackgroundColor3 = theme.Danger, Text = "", Position = UDim2.new(1, -36, 0, 7), Size = UDim2.fromOffset(29, 30), ZIndex = 74}, header)
				corner(close, UDim.new(0, 9))
				local closeIcon = makeIcon(close, "x", 14, Color3.new(1, 1, 1))
				if closeIcon then closeIcon.AnchorPoint = Vector2.new(0.5, 0.5); closeIcon.Position = UDim2.fromScale(0.5, 0.5) end
				close.MouseButton1Click:Connect(closePopup)
				local list = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 46), Size = UDim2.new(1, -16, 1, -54), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = theme.Accent, ZIndex = 72}, panel)
				local layout = new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
				new("UIPadding", {PaddingBottom = UDim.new(0, 6)}, list)
				local function refreshRows()
					for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
					local count = 0
					for _, option in ipairs(options) do
						local text = tostring(option)
						if searchText == "" or string.find(string.lower(text), string.lower(searchText), 1, true) then
							count += 1
							local row = new("TextButton", {AutoButtonColor = false, BackgroundColor3 = selected[text] and theme.Accent or theme.Element, Text = text, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -2, 0, 34), ZIndex = 73}, list)
							corner(row, UDim.new(0, 8))
							new("UIPadding", {PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, element.multiSelect and 34 or 11)}, row)
							if element.multiSelect then
								local mark = makeIcon(row, "check", 15, Color3.new(1, 1, 1))
								if mark then mark.AnchorPoint = Vector2.new(1, 0.5); mark.Position = UDim2.new(1, -10, 0.5, 0); mark.Visible = selected[text] == true end
							end
							row.MouseButton1Click:Connect(function() choose(option) end)
						end
					end
					if count == 0 then new("TextLabel", {BackgroundTransparency = 1, Text = "No results", TextColor3 = theme.Muted, Font = Enum.Font.Gotham, TextSize = 11, Size = UDim2.new(1, 0, 0, 34), ZIndex = 73}, list) end
				end
				popup.RefreshRows = refreshRows
				search:GetPropertyChangedSignal("Text"):Connect(function() searchText = search.Text; refreshRows() end)
				refreshRows()
				local desired = math.clamp(math.min(260, 50 + math.max(1, math.min(#options, 6)) * 36 + 4), 92, 292)
				tween(panel, 0.22, {Size = UDim2.new(0, button.AbsoluteSize.X, 0, desired)}, Enum.EasingStyle.Quint)
			end
			button.MouseButton1Click:Connect(createPopup)
			button.MouseEnter:Connect(function() tween(button, 0.15, {BackgroundColor3 = theme.ElementHover}) end)
			button.MouseLeave:Connect(function() if not open then tween(button, 0.15, {BackgroundColor3 = theme.Element}) end end)
			
			local api = {}
			function api:Refresh(newOptions)
				options = table.clone(newOptions or {})
				if popup and popup.RefreshRows then popup.RefreshRows() end
			end
			function api:Set(value)
				table.clear(selected)
				if element.multiSelect then
					for _, item in ipairs(value or {}) do selected[tostring(item)] = true end
				else
					selected[tostring(value)] = true
				end
				updateValue()
			end
			function api:Get()
				if element.multiSelect then
					local out = {}; for _, option in ipairs(options) do if selected[tostring(option)] then table.insert(out, option) end end; return out
				end
				for _, option in ipairs(options) do if selected[tostring(option)] then return option end end
				return nil
			end
			return api
		end

		function tab:CreateSlider(element)
			element = element or {}
			tab._order += 1
			local range = element.range or {0, 100}
			local minValue, maxValue = tonumber(range[1]) or 0, tonumber(range[2]) or 100
			local value = math.clamp(tonumber(element.value) or minValue, minValue, maxValue)
			local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, element.description and 76 or 62), LayoutOrder = tab._order}, tab.Page)
			local barHolder = new("Frame", {BackgroundColor3 = theme.Element, Size = UDim2.fromScale(1, 1)}, holder)
			corner(barHolder, UDim.new(0, 10)); stroke(barHolder, theme.Border, 0.45, 1)
			addDescription(barHolder, element.name or "Slider", element.description, 8)
			local valueLabel = new("TextLabel", {BackgroundTransparency = 1, TextColor3 = theme.Accent2, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.65, 0, 0, 11), Size = UDim2.new(0.3, -16, 0, 18)}, barHolder)
			local track = new("Frame", {BackgroundColor3 = theme.Panel2, Position = UDim2.new(0, 16, 1, -20), Size = UDim2.new(1, -32, 0, 5)}, barHolder)
			corner(track, UDim.new(1, 0))
			local fill = new("Frame", {BackgroundColor3 = theme.Accent, Size = UDim2.fromScale(0, 1)}, track)
			corner(fill, UDim.new(1, 0))
			local knob = new("Frame", {BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14,14)}, track)
			corner(knob, UDim.new(1,0))
			local function apply(v, fire)
				local increment = tonumber(element.increment) or 1
				v = minValue + math.floor(((v - minValue) / increment) + 0.5) * increment
				value = math.clamp(v, minValue, maxValue)
				local alpha = (value - minValue) / math.max(maxValue - minValue, 0.0001)
				fill.Size = UDim2.fromScale(alpha, 1)
				knob.Position = UDim2.new(alpha, 0, 0.5, 0)
				valueLabel.Text = tostring(value) .. tostring(element.suffix or "")
				if fire and typeof(element.callback) == "function" then task.spawn(element.callback, value) end
			end
			apply(value, false)
			local draggingSlider = false
			local function setFromInput(input)
				local x = math.clamp(input.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
				local alpha = track.AbsoluteSize.X == 0 and 0 or x / track.AbsoluteSize.X
				apply(minValue + (maxValue - minValue) * alpha, true)
			end
			track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true; setFromInput(input) end end)
			UserInputService.InputChanged:Connect(function(input) if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFromInput(input) end end)
			UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end end)
			local api = {}
			function api:Set(v) apply(tonumber(v) or value, true) end
			function api:Get() return value end
			return api
		end

		function tab:CreateInput(element)
			element = element or {}
			tab._order += 1
			local height = element.description and 80 or 66
			local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = tab._order}, tab.Page)
			local panel = new("Frame", {BackgroundColor3 = theme.Element, Size = UDim2.fromScale(1,1)}, holder)
			corner(panel, UDim.new(0,10)); stroke(panel, theme.Border, 0.45, 1)
			addDescription(panel, element.name or "Input", element.description, 8)
			local box = new("TextBox", {BackgroundColor3 = theme.Panel2, Text = tostring(element.value or ""), PlaceholderText = tostring(element.placeholder or ""), PlaceholderColor3 = theme.Muted, TextColor3 = theme.Text, ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 11, Position = UDim2.fromOffset(14, element.description and 47 or 35), Size = UDim2.new(1, -28, 0, 27)}, panel)
			corner(box, UDim.new(0,8)); stroke(box, theme.Border, 0.3, 1)
			local committed = box.Text
			box.FocusLost:Connect(function()
				local text = box.Text
				if element.numeric and tonumber(text) == nil and text ~= "" then box.Text = committed; return end
				committed = box.Text
				if typeof(element.callback) == "function" then task.spawn(element.callback, box.Text) end
			end)
			local api = {}
			function api:Set(text) box.Text = tostring(text); committed = box.Text end
			function api:Get() return box.Text end
			return api
		end

		return tab
	end
	
	function window:Toggle() setVisible(not window.Visible) end
	function window:SetVisible(value) setVisible(value == true) end
	function window:Destroy()
		if window.Destroyed then return end
		window.Destroyed = true
		if screenGui and screenGui.Parent then
			tween(mainScale, 0.2, {Scale = 0.9}, Enum.EasingStyle.Quint)
			tween(main, 0.2, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
			task.delay(0.2, function() if screenGui and screenGui.Parent then screenGui:Destroy() end end)
		end
	end

	task.delay(0.72, function()
		if loadingOverlay.Parent then
			tween(bigText, 0.25, {TextTransparency = 1})
			tween(loadingSubtitle, 0.2, {TextTransparency = 1})
			tween(loadingLine, 0.22, {Size = UDim2.fromOffset(0, 2)})
			tween(loadingOverlay, 0.3, {BackgroundTransparency = 1})
			tween(mainScale, 0.34, {Scale = 1}, Enum.EasingStyle.Back)
			task.delay(0.31, function() if loadingOverlay.Parent then loadingOverlay:Destroy() end end)
		end
	end)

	return window
end

return DarkyX
