--========================================================
-- DarkyUIGen2
-- Clean single-file Roblox UI library
--========================================================
-- Features:
--   • 550x340 main window
--   • PC + mobile window dragging
--   • Draggable floating minimize/restore button
--   • Square corners
--   • Search bar
--   • Profile + username
--   • Lucide icon names + Roblox asset IDs
--   • Tabs with scrolling
--   • Auto-sized independent sections (NO section Size option)
--   • Automatic page scrolling only when content overflows
--   • Button / Toggle / Slider / Input / Dropdown
--   • Centered searchable dropdown popup
--   • Themes: Red / BlueSky / White / Yellow / Green / Purple / Orange
--   • Theme affects toggle + slider + KeySystem accent only
--   • Notification automatically uses Window.Image
--   • KeySystem can be created BEFORE CreateWindow
--   • Optional saved key
--========================================================

local DarkyUIGen2 = {}

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

--========================================================
-- CONSTANTS
--========================================================

local WINDOW_WIDTH = 550
local WINDOW_HEIGHT = 340

local MAIN_GUI_NAME = "DarkyUIGen2_Main"
local KEY_GUI_NAME = "DarkyUIGen2_KeySystem"
local NOTIFY_GUI_NAME = "DarkyUIGen2_Notifications"

local COLORS = {
    Background = Color3.fromRGB(10, 10, 13),
    Background2 = Color3.fromRGB(14, 14, 18),
    Panel = Color3.fromRGB(19, 19, 24),
    Panel2 = Color3.fromRGB(25, 25, 31),

    Text = Color3.fromRGB(240, 240, 244),
    SubText = Color3.fromRGB(145, 145, 158),
    Muted = Color3.fromRGB(90, 90, 102),

    Border = Color3.fromRGB(38, 38, 46),
    Danger = Color3.fromRGB(225, 60, 72),
    Info = Color3.fromRGB(60, 115, 250),
    Warning = Color3.fromRGB(235, 175, 60),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local THEMES = {
    Red = {
        Accent = Color3.fromRGB(210, 40, 55),
        Accent2 = Color3.fromRGB(240, 70, 85),
    },

    BlueSky = {
        Accent = Color3.fromRGB(45, 105, 245),
        Accent2 = Color3.fromRGB(80, 140, 255),
    },

    White = {
        Accent = Color3.fromRGB(190, 190, 200),
        Accent2 = Color3.fromRGB(235, 235, 242),
    },

    Yellow = {
        Accent = Color3.fromRGB(220, 165, 25),
        Accent2 = Color3.fromRGB(245, 195, 55),
    },

    Green = {
        Accent = Color3.fromRGB(30, 175, 90),
        Accent2 = Color3.fromRGB(65, 210, 120),
    },

    Purple = {
        Accent = Color3.fromRGB(120, 65, 215),
        Accent2 = Color3.fromRGB(155, 95, 250),
    },

    Orange = {
        Accent = Color3.fromRGB(220, 100, 30),
        Accent2 = Color3.fromRGB(245, 135, 55),
    },
}

DarkyUIGen2.Themes = THEMES
DarkyUIGen2.CurrentTheme = "BlueSky"
DarkyUIGen2.CurrentImage = nil
DarkyUIGen2._Window = nil
DarkyUIGen2._KeySystem = nil
DarkyUIGen2._KeyPassed = false
DarkyUIGen2._ThemeObjects = {}

--========================================================
-- FLAG REGISTRY
--========================================================
-- Any element created with a Flag in its config (e.g.
-- Section:CreateToggle({ Flag = "MyToggle", ... })) registers itself
-- here automatically, keyed by that flag string. This is what lets
-- SaveManager save/restore every element's value generically without
-- each element type needing its own bespoke save logic.

DarkyUIGen2._Flags = {}

-- Values loaded from a config before the element they belong to has
-- actually been created yet. SaveManager:SetFolder/LoadAutoloadConfig
-- are meant to be called before CreateWindow (per the intended usage
-- pattern), which means the Flag-tagged elements don't exist yet at
-- that point - DarkyUIGen2._Flags would still be empty, so a naive
-- Load would silently restore nothing. Any value that can't be
-- applied immediately gets cached here instead, and RegisterFlag
-- checks this cache the moment each element registers itself, so the
-- restore still happens correctly regardless of call order.
DarkyUIGen2._PendingFlagValues = {}

local function RegisterFlag(flag, object)
    if typeof(flag) ~= "string"
        or flag == "" then
        return
    end

    DarkyUIGen2._Flags[flag] = object

    local pending = DarkyUIGen2._PendingFlagValues[flag]

    if pending ~= nil
        and typeof(object.SetValue) == "function" then

        pcall(object.SetValue, object, pending, false)
        DarkyUIGen2._PendingFlagValues[flag] = nil
    end
end

--========================================================
-- FILE I/O SAFETY HELPERS
--========================================================
-- writefile/readfile/isfile/listfiles/makefolder/isfolder/delfile are
-- executor-only globals, not guaranteed to exist. Every call is
-- guarded with typeof(...) ~= "function" and wrapped in pcall, same
-- pattern the KeySystem's SaveKey/ReadKey already use above.

local function HasFileAPI()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
        and typeof(makefolder) == "function"
        and typeof(isfolder) == "function"
end

local function EnsureFolder(path)
    if typeof(isfolder) ~= "function"
        or typeof(makefolder) ~= "function" then
        return false
    end

    local ok = pcall(function()
        if not isfolder(path) then
            makefolder(path)
        end
    end)

    return ok
end

local function WriteJSON(path, data)
    if typeof(writefile) ~= "function" then
        return false
    end

    local ok = pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)

    return ok
end

local function ReadJSON(path)
    if typeof(isfile) ~= "function"
        or typeof(readfile) ~= "function" then
        return nil
    end

    local exists = false

    pcall(function()
        exists = isfile(path)
    end)

    if not exists then
        return nil
    end

    local result

    pcall(function()
        local raw = readfile(path)
        result = HttpService:JSONDecode(raw)
    end)

    return result
end

local function DeleteFile(path)
    if typeof(delfile) ~= "function"
        or typeof(isfile) ~= "function" then
        return false
    end

    local ok = pcall(function()
        if isfile(path) then
            delfile(path)
        end
    end)

    return ok
end

local function ListConfigNames(folder)
    local names = {}

    if typeof(listfiles) ~= "function"
        or typeof(isfolder) ~= "function" then
        return names
    end

    local exists = false

    pcall(function()
        exists = isfolder(folder)
    end)

    if not exists then
        return names
    end

    pcall(function()
        for _, filePath in ipairs(listfiles(folder)) do
            local name = filePath:match("([^\\/]+)%.json$")

            if name then
                table.insert(names, name)
            end
        end
    end)

    table.sort(names)

    return names
end

--========================================================
-- SAVE MANAGER
--========================================================
-- Persists the value of every Flag-tagged element (toggles, sliders,
-- inputs, dropdowns) plus the active theme, to a JSON file the user
-- names, and restores them all on load. Must be usable before
-- CreateWindow, since scripts typically set it up first:
--
--   local SaveManager = DarkyUIGen2.SaveManager
--   SaveManager:SetFolder("MyHub")
--   -- ... CreateWindow, tabs, sections, elements with Flags ...
--   SaveManager:BuildConfigSection(Tab)
--   SaveManager:LoadAutoloadConfig()

local SaveManager = {
    Folder = "DarkyUIGen2",
    IgnoreThemeSettings = false,
    IgnoredFlags = {},
}

function SaveManager:SetFolder(folderName)
    if typeof(folderName) == "string"
        and folderName ~= "" then
        self.Folder = folderName
    end

    return self
end

-- Compatibility no-op: some scripts ported from other UI libraries
-- call SaveManager:SetLibrary(Library) to tell it which flag table to
-- read. DarkyUIGen2's flags always live on DarkyUIGen2._Flags, so there's
-- nothing to configure, but the call is accepted harmlessly so those
-- scripts don't error.
function SaveManager:SetLibrary(_library)
    return self
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoreThemeSettings = true
    return self
end

function SaveManager:SetIgnoreIndexes(list)
    if typeof(list) == "table" then
        for _, flag in ipairs(list) do
            self.IgnoredFlags[flag] = true
        end
    end

    return self
end

function SaveManager:ConfigFolderPath()
    return self.Folder .. "/configs"
end

function SaveManager:ConfigFilePath(name)
    return self:ConfigFolderPath() .. "/" .. name .. ".json"
end

function SaveManager:ListConfigs()
    return ListConfigNames(self:ConfigFolderPath())
end

function SaveManager:Save(name)
    if typeof(name) ~= "string"
        or name == "" then
        return false, "Invalid config name"
    end

    if not HasFileAPI() then
        return false, "File API unavailable"
    end

    EnsureFolder(self.Folder)
    EnsureFolder(self:ConfigFolderPath())

    local data = {
        Flags = {},
        Theme = not self.IgnoreThemeSettings
            and DarkyUIGen2.CurrentTheme
            or nil,
    }

    for flag, object in pairs(DarkyUIGen2._Flags) do
        if not self.IgnoredFlags[flag]
            and typeof(object.GetValue) == "function" then

            local ok, value = pcall(object.GetValue, object)

            if ok then
                data.Flags[flag] = value
            end
        end
    end

    local ok = WriteJSON(
        self:ConfigFilePath(name),
        data
    )

    return ok, not ok and "Failed to write file" or nil
end

function SaveManager:Load(name)
    if typeof(name) ~= "string"
        or name == "" then
        return false, "Invalid config name"
    end

    local data = ReadJSON(self:ConfigFilePath(name))

    if not data then
        return false, "Config not found"
    end

    if data.Theme
        and not self.IgnoreThemeSettings
        and typeof(DarkyUIGen2.SetTheme) == "function" then

        pcall(DarkyUIGen2.SetTheme, DarkyUIGen2, data.Theme)
    end

    if typeof(data.Flags) == "table" then
        for flag, value in pairs(data.Flags) do
            if not self.IgnoredFlags[flag] then
                local object = DarkyUIGen2._Flags[flag]

                if object
                    and typeof(object.SetValue) == "function" then

                    pcall(object.SetValue, object, value, false)
                else
                    -- Element doesn't exist yet (Load was called
                    -- before its Tab/Section/element was created) -
                    -- cache it so RegisterFlag can apply it the
                    -- moment that element actually gets created.
                    DarkyUIGen2._PendingFlagValues[flag] = value
                end
            end
        end
    end

    return true
end

function SaveManager:Delete(name)
    return DeleteFile(self:ConfigFilePath(name))
end

function SaveManager:SetAutoloadConfig(name)
    EnsureFolder(self.Folder)

    WriteJSON(
        self.Folder .. "/autoload.json",
        { Config = name }
    )

    return self
end

function SaveManager:LoadAutoloadConfig()
    local data = ReadJSON(self.Folder .. "/autoload.json")

    if data and typeof(data.Config) == "string" then
        return self:Load(data.Config)
    end

    return false, "No autoload config set"
end

DarkyUIGen2.SaveManager = SaveManager

--========================================================
-- INTERFACE MANAGER
--========================================================
-- Persists interface-level preferences (currently: the active theme)
-- separately from SaveManager's per-config saves, since the theme is
-- usually something the user wants to stick permanently rather than
-- bundled inside a specific loadout config.

local InterfaceManager = {
    Folder = "DarkyUIGen2",
}

function InterfaceManager:SetFolder(folderName)
    if typeof(folderName) == "string"
        and folderName ~= "" then
        self.Folder = folderName
    end

    return self
end

function InterfaceManager:SetLibrary(_library)
    return self
end

function InterfaceManager:FilePath()
    return self.Folder .. "/interface.json"
end

function InterfaceManager:SaveSettings()
    EnsureFolder(self.Folder)

    return WriteJSON(
        self:FilePath(),
        { Theme = DarkyUIGen2.CurrentTheme }
    )
end

function InterfaceManager:LoadSettings()
    local data = ReadJSON(self:FilePath())

    if data
        and data.Theme
        and typeof(DarkyUIGen2.SetTheme) == "function" then

        pcall(DarkyUIGen2.SetTheme, DarkyUIGen2, data.Theme)

        return true
    end

    return false
end

DarkyUIGen2.InterfaceManager = InterfaceManager

--========================================================
-- FLOATING BUTTON MANAGER
--========================================================
-- Persists the floating minimize button's last screen position so it
-- reopens in the same spot next session instead of resetting to the
-- default corner every time.

local FloatingButtonManager = {
    Folder = "DarkyUIGen2",
}

function FloatingButtonManager:SetFolder(folderName)
    if typeof(folderName) == "string"
        and folderName ~= "" then
        self.Folder = folderName
    end

    return self
end

function FloatingButtonManager:SetLibrary(_library)
    return self
end

function FloatingButtonManager:FilePath()
    return self.Folder .. "/floating_button.json"
end

function FloatingButtonManager:SavePosition(x, y)
    EnsureFolder(self.Folder)

    return WriteJSON(
        self:FilePath(),
        { X = x, Y = y }
    )
end

function FloatingButtonManager:LoadPosition()
    local data = ReadJSON(self:FilePath())

    if data
        and typeof(data.X) == "number"
        and typeof(data.Y) == "number" then

        return data.X, data.Y
    end

    return nil, nil
end

DarkyUIGen2.FloatingButtonManager = FloatingButtonManager

-- Gen-2: snappier easing for quick interactions (hover, tab
-- switches); MED keeps its original flat ease-out since it's relied
-- on all over the file for size/position tweens where an overshoot
-- could visually clip against ClipsDescendants containers.
local FAST = TweenInfo.new(
    0.12,
    Enum.EasingStyle.Quart,
    Enum.EasingDirection.Out
)

local MED = TweenInfo.new(
    0.22,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

-- Used only for the PageTab swipe settle: an exaggerated springy
-- overshoot, distinct on purpose from the flat MED easing used for
-- the plain top-level tab list and everything else in the library.
local SWING = TweenInfo.new(
    0.42,
    Enum.EasingStyle.Back,
    Enum.EasingDirection.Out,
    0,
    false,
    0
)

-- Gen-2 only: a quick punchy press/pop, used for click feedback on
-- buttons, toggles, tab switches, and anything else that reacts to a
-- tap - shrinks slightly on press, springs back on release.
local POP = TweenInfo.new(
    0.16,
    Enum.EasingStyle.Back,
    Enum.EasingDirection.Out,
    0,
    false,
    0
)

--========================================================
-- HELPERS
--========================================================

local function New(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    return object
end

local function Tween(object, info, properties)
    if not object or not object.Parent then
        return nil
    end

    local tween = TweenService:Create(
        object,
        info,
        properties
    )

    tween:Play()

    return tween
end

-- Gen-2 only: generic click "pop" - briefly scales the target down
-- then springs back up past its normal size before settling. Meant
-- to be fired from MouseButton1Click/MouseButton1Down handlers
-- across every clickable element so every tap in the library feels
-- the same, without hand-adding a tween to each one individually.
local function ClickPop(object)
    if not object or not object.Parent then
        return
    end

    local originalSize = object.Size

    Tween(
        object,
        FAST,
        {
            Size = UDim2.new(
                originalSize.X.Scale,
                originalSize.X.Offset - 3,
                originalSize.Y.Scale,
                originalSize.Y.Offset - 3
            )
        }
    )

    task.delay(FAST.Time, function()
        Tween(
            object,
            POP,
            { Size = originalSize }
        )
    end)
end

-- Roblox never errors on a bad/invalid/moderated rbxassetid:// - the
-- ImageLabel just silently renders blank with no feedback. This checks
-- whether the asset actually loaded and, if not, hands back control via
-- onFailed so the caller can fall back to a placeholder (e.g. initials).
-- Runs off-thread so it never blocks UI creation.
local function VerifyImageLoad(imageLabel, onFailed)
    if not imageLabel then
        return
    end

    task.spawn(function()
        local ok, contentId = pcall(function()
            return imageLabel.Image
        end)

        if not ok or not contentId or contentId == "" then
            return
        end

        local success, result = pcall(function()
            ContentProvider:PreloadAsync({ imageLabel })
            return imageLabel.IsLoaded
        end)

        local loaded = success and (result == nil or result == true)

        if not loaded then
            if imageLabel.Parent and typeof(onFailed) == "function" then
                pcall(onFailed)
            end
        end
    end)
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", {
        Parent = parent,
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
end

local function AssetId(value)
    if typeof(value) == "number" then
        return "rbxassetid://" .. tostring(value)
    end

    if typeof(value) ~= "string" then
        return nil
    end

    if value:match("^rbxassetid://") then
        return value
    end

    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end

    return value
end

local function IsAssetId(value)
    if typeof(value) ~= "string" then
        return false
    end

    return value:match("^rbxassetid://") ~= nil
        or value:match("^%d+$") ~= nil
end

local function AddCorner(parent, radius)
    if not parent then return nil end
    local old = parent:FindFirstChildOfClass("UICorner")
    if old then old:Destroy() end
    return New("UICorner", { Parent = parent, CornerRadius = UDim.new(0, radius or 10) })
end

-- Scale-based full rounding (always exactly half of whatever the
-- object's actual rendered size turns out to be), for anything that
-- must be a true circle regardless of its pixel size - a fixed-pixel
-- CornerRadius only looks circular if it happens to exactly match
-- half the object's size, so knobs/avatars use this instead.
local function AddCircle(parent)
    if not parent then return nil end
    local old = parent:FindFirstChildOfClass("UICorner")
    if old then old:Destroy() end
    return New("UICorner", { Parent = parent, CornerRadius = UDim.new(0.5, 0) })
end

local function CreateAuraFor(gui, target, colorProvider, options)
    options = options or {}
    if not gui or not target then return nil end
    local expand = options.Expand or 18
    local aura = New("Frame", {
        Parent = gui, Name = options.Name or "Aura",
        AnchorPoint = target.AnchorPoint, Position = target.Position,
        Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + expand, target.Size.Y.Scale, target.Size.Y.Offset + expand),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = target.Visible, ZIndex = math.max((target.ZIndex or 1) - 2, 0),
    })
    AddCorner(aura, (options.Radius or 12) + 8)
    local strokes = {}
    local layers = options.Layers or 6
    local thickness = options.Thickness or 5
    local transparency = options.Transparency or 0.78
    for i = 1, layers do
        strokes[i] = New("UIStroke", {
            Parent = aura, Color = colorProvider(),
            Thickness = thickness + ((layers - i) * 3),
            Transparency = math.clamp(transparency + ((i - 1) * 0.035), 0, 1),
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end
    local function sync()
        if not aura.Parent or not target.Parent then return false end
        aura.AnchorPoint = target.AnchorPoint; aura.Position = target.Position
        aura.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + expand, target.Size.Y.Scale, target.Size.Y.Offset + expand)
        aura.Visible = target.Visible; aura.Rotation = target.Rotation
        return true
    end
    local connections = {
        target:GetPropertyChangedSignal("Position"):Connect(sync),
        target:GetPropertyChangedSignal("Size"):Connect(sync),
        target:GetPropertyChangedSignal("Visible"):Connect(sync),
        target:GetPropertyChangedSignal("Rotation"):Connect(sync),
    }
    local object = { Root = aura, Strokes = strokes }
    function object:SetColor(color)
        for _, stroke in ipairs(strokes) do if stroke.Parent then stroke.Color = color end end
    end
    function object:SetVisible(value) aura.Visible = value == true end
    function object:Destroy()
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        if aura then aura:Destroy() end
    end
    sync(); return object
end

--========================================================
-- HTTP / LOADSTRING
--========================================================

local function HttpGet(url)
    local methods = {
        function()
            return game:HttpGet(url)
        end,

        function()
            return request({
                Url = url,
                Method = "GET",
            }).Body
        end,

        function()
            return http_request({
                Url = url,
                Method = "GET",
            }).Body
        end,
    }

    for _, method in ipairs(methods) do
        local success, result = pcall(method)

        if success and result and result ~= "" then
            return result
        end
    end

    return nil
end

local function GetLoadstring()
    if typeof(loadstring) == "function" then
        return loadstring
    end

    if typeof(load) == "function" then
        return load
    end

    return nil
end

--========================================================
-- LUCIDE
--========================================================

local LUCIDE_URL =
    "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

local function LoadLucide()
    local env = {}

    pcall(function()
        if typeof(getgenv) == "function" then
            env = getgenv()
        end
    end)

    -- Supports the user's IsUI / Loadstring / Get environment.
    if env.IsUI and env.Loadstring and env.Get then
        local success, result = pcall(function()
            return env.Loadstring(
                env.Get(LUCIDE_URL)
            )()
        end)

        if success and type(result) == "table" then
            return result
        end
    end

    local source = HttpGet(LUCIDE_URL)
    local loader = GetLoadstring()

    if source and loader then
        local success, result = pcall(function()
            return loader(source)()
        end)

        if success and type(result) == "table" then
            return result
        end
    end

    return {}
end

DarkyUIGen2.Icons = {
    lucide = LoadLucide(),
}

-- Returns asset, isGlyph.
-- isGlyph = true only for resolved lucide icon names (monochrome glyphs,
-- safe to tint). Direct rbxassetid/rbxasset/http(s) images are real
-- pictures and must NOT be tinted, or their colors get washed out/hidden.
local function ResolveIcon(icon)
    if icon == nil then
        return nil, false
    end

    if typeof(icon) == "number" then
        return AssetId(icon), false
    end

    if typeof(icon) ~= "string" then
        return nil, false
    end

    if IsAssetId(icon) then
        return AssetId(icon), false
    end

    if icon:match("^https?://") then
        return icon, false
    end

    if icon:match("^rbxasset") then
        return icon, false
    end

    local direct = DarkyUIGen2.Icons.lucide[icon]

    if direct then
        return AssetId(tostring(direct)), true
    end

    local lower = icon:lower()

    for name, value in pairs(DarkyUIGen2.Icons.lucide) do
        if tostring(name):lower() == lower then
            return AssetId(tostring(value)), true
        end
    end

    return nil, false
end

--========================================================
-- THEME
--========================================================
-- Declared here (ahead of Icon below) since themed icons need to
-- register for live theme-change updates.

local function CurrentTheme()
    return THEMES[DarkyUIGen2.CurrentTheme]
        or THEMES.BlueSky
end

local function RegisterTheme(callback)
    table.insert(
        DarkyUIGen2._ThemeObjects,
        callback
    )

    pcall(function()
        callback(
            DarkyUIGen2.CurrentTheme,
            CurrentTheme()
        )
    end)
end

-- themed: false/nil = static COLORS.Text icon (default, unchanged behavior).
--         true      = tinted with the current theme's Accent color, and
--                      automatically re-tints whenever the theme changes.
--         "Accent2" = same as true, but follows Accent2 instead of Accent.
local function Icon(parent, icon, size, position, zIndex, themed)
    local asset, isGlyph = ResolveIcon(icon)

    if not asset then
        return nil
    end

    local image = New("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Position = position,
        Size = UDim2.fromOffset(size, size),
        Image = asset,
        ImageColor3 = isGlyph and COLORS.Text or COLORS.White,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = zIndex or 10,
    })

    -- Only tint lucide glyphs live with the theme; a real custom image
    -- (rbxassetid/rbxasset/http) is left as-is regardless of `themed`.
    if themed and isGlyph then
        local colorKey = themed == "Accent2" and "Accent2" or "Accent"

        RegisterTheme(function(_, colors)
            if image and image.Parent then
                image.ImageColor3 = colors[colorKey]
            end
        end)
    end

    return image
end

-- IconOrBadge: like Icon(), but never silently disappears. If `icon`
-- resolves to a real glyph/image, that's used as normal. If it's an
-- unrecognized name (e.g. "K" or "Redz" - not a real Lucide icon and
-- not an asset id/url), a small generated logo badge is created
-- instead: a rounded, theme-accent-colored tile with the first 1-2
-- letters of the name. This also covers "deleted" empty icons, since
-- an empty/nil `icon` falls back to `fallbackText` (e.g. the
-- Title) the same way the badge would for any other unknown name.
-- Returns the created object (ImageLabel or Frame) plus a boolean
-- (true if it's a generated badge, false if it's a resolved icon).
local function IconOrBadge(parent, icon, size, position, zIndex, fallbackText)
    local resolved = Icon(parent, icon, size, position, zIndex)

    if resolved then
        return resolved, false
    end

    local letters = tostring(
        (icon ~= nil and icon ~= "" and icon)
            or fallbackText
            or "?"
    )

    -- Keep up to 2 letters for short names/initials, 1 for anything
    -- longer, so it reads like a compact logo rather than a wall of text.
    local badgeText
    if #letters <= 2 then
        badgeText = letters:upper()
    else
        badgeText = letters:sub(1, 1):upper()
    end

    local badge = New("Frame", {
        Parent = parent,
        Position = position,
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = CurrentTheme().Accent,
        BorderSizePixel = 0,
        ZIndex = zIndex or 10,
    })

    AddCorner(badge, math.max(4, math.floor(size / 4)))

    local label = New("TextLabel", {
        Parent = badge,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = badgeText,
        TextColor3 = COLORS.White,
        TextSize = math.max(9, math.floor(size * 0.42)),
        Font = Enum.Font.GothamBold,
        TextScaled = false,
        ZIndex = (zIndex or 10) + 1,
    })

    RegisterTheme(function(_, colors)
        if badge and badge.Parent then
            badge.BackgroundColor3 = colors.Accent
        end
    end)

    badge.Label = label

    return badge, true
end

--========================================================
-- VISUAL DESIGN HELPERS
--========================================================

local function AddTopAccent(parent)
    return New("Frame", {
        Parent = parent,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
        ZIndex = 29,
    })
end

local function AddSectionAccent(parent)
    return New("Frame", {
        Parent = parent,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(2, 20),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
        ZIndex = 15,
    })
end

function DarkyUIGen2:SetTheme(name)
    if type(name) ~= "string" then
        return false
    end

    local selected

    for themeName in pairs(THEMES) do
        if themeName:lower() == name:lower() then
            selected = themeName
            break
        end
    end

    if not selected then
        return false
    end

    DarkyUIGen2.CurrentTheme = selected

    local colors = CurrentTheme()

    for index = #DarkyUIGen2._ThemeObjects, 1, -1 do
        local callback = DarkyUIGen2._ThemeObjects[index]

        if type(callback) == "function" then
            local success = pcall(
                callback,
                selected,
                colors
            )

            if not success then
                table.remove(
                    DarkyUIGen2._ThemeObjects,
                    index
                )
            end
        else
            table.remove(
                DarkyUIGen2._ThemeObjects,
                index
            )
        end
    end

    return true
end

DarkyUIGen2.Theme = DarkyUIGen2.SetTheme

--========================================================
-- NOTIFICATIONS
--========================================================

function DarkyUIGen2:Notify(config)
    config = config or {}

    local title = tostring(
        config.Title or "DarkyUIGen2"
    )

    local content = tostring(
        config.Content or ""
    )

    local duration = tonumber(
        config.Duration
    ) or 3

    if duration < 0 then
        duration = 0
    end

    local gui = CoreGui:FindFirstChild(
        NOTIFY_GUI_NAME
    )

    if not gui then
        gui = New(
            "ScreenGui",
            {
                Name = NOTIFY_GUI_NAME,
                Parent = CoreGui,
                IgnoreGuiInset = true,
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = 2100000,
            }
        )
    end

    local holder = gui:FindFirstChild("Holder")

    if not holder then
        holder = New(
            "Frame",
            {
                Parent = gui,
                Name = "Holder",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 16),
                Size = UDim2.new(0, 330, 1, -32),
                BackgroundTransparency = 1,
                ZIndex = 3000,
            }
        )

        New(
            "UIListLayout",
            {
                Parent = holder,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }
        )
    end

    local notification = New(
        "Frame",
        {
            Parent = holder,
            Size = UDim2.fromOffset(310, 70),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 3001,
        }
    )

    AddCorner(notification, 12)

    Stroke(
        notification,
        COLORS.Border,
        1
    )

    local accent = New(
        "Frame",
        {
            Parent = notification,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(3, 70),
            BackgroundColor3 = CurrentTheme().Accent,
            BorderSizePixel = 0,
            ZIndex = 3002,
        }
    )

    local image = DarkyUIGen2.CurrentImage

    -- The Window image is automatically reused.
    if image ~= nil then
        local imageObject = Icon(
            notification,
            image,
            40,
            UDim2.fromOffset(10, 15),
            3003
        )

        if not imageObject then
            local asset = AssetId(image)

            if asset then
                New(
                    "ImageLabel",
                    {
                        Parent = notification,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(10, 15),
                        Size = UDim2.fromOffset(40, 40),
                        Image = asset,
                        ScaleType = Enum.ScaleType.Crop,
                        ZIndex = 3003,
                    }
                )
            end
        end
    end

    local textLeft = image ~= nil
        and 60
        or 14

    local titleLabel = New(
        "TextLabel",
        {
            Parent = notification,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(textLeft, 8),
            Size = UDim2.new(1, -textLeft - 14, 0, 20),
            Text = title,
            TextColor3 = COLORS.Text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 3004,
        }
    )

    local contentLabel = New(
        "TextLabel",
        {
            Parent = notification,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(textLeft, 29),
            Size = UDim2.new(1, -textLeft - 14, 0, 33),
            Text = content,
            TextColor3 = COLORS.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 3004,
        }
    )

    notification.Position = UDim2.new(
        1,
        320,
        0,
        0
    )

    Tween(
        notification,
        MED,
        {
            Position = UDim2.new(
                1,
                0,
                0,
                0
            )
        }
    )

    task.delay(
        duration,
        function()
            if not notification
                or not notification.Parent then
                return
            end

            local tween = Tween(
                notification,
                MED,
                {
                    Position = UDim2.new(
                        1,
                        320,
                        0,
                        0
                    )
                }
            )

            if tween then
                tween.Completed:Connect(
                    function()
                        if notification then
                            notification:Destroy()
                        end
                    end
                )
            else
                notification:Destroy()
            end
        end
    )

    return notification
end

--========================================================
-- KEY SYSTEM
--========================================================

local function SafeClipboard(text)
    local methods = {
        function()
            setclipboard(text)
        end,

        function()
            toclipboard(text)
        end,

        function()
            if syn and syn.clipboard then
                syn.clipboard = text
            else
                error("clipboard unavailable")
            end
        end,
    }

    for _, method in ipairs(methods) do
        local success = pcall(method)

        if success then
            return true
        end
    end

    return false
end

local function MakeKeySystem(config)
    config = config or {}

    local KeySystem = {
        Destroyed = false,
        Cancelled = false,
    }

    local title = tostring(
        config.Title or "Access Required"
    )

    local note = tostring(
        config.Note or ""
    )

    local keyURL = tostring(
        config.URL or ""
    )

    local saveKey =
        config.SaveKey == true

    -- Thumbnail accepts either the documented table shape
    -- ({ Image = "rbxassetid://...", Title = "..." }) or a bare
    -- image value (rbxassetid string/number, rbxasset://, or
    -- http(s) URL) passed directly as config.Thumbnail, so a plain
    -- id doesn't silently fail to show.
    local thumbnail = config.Thumbnail or {}

    if typeof(thumbnail) == "string"
        or typeof(thumbnail) == "number" then
        thumbnail = { Image = thumbnail }
    end

    -- Border/Blur: connect to the Window's settings.
    -- Explicit config.Border/config.Blur always win. Otherwise, if a
    -- Window already exists (KeySystem created AFTER CreateWindow),
    -- inherit its Border/Blur so both stay visually consistent.
    -- Falls back to false, same default as Window.
    local existingWindow =
        DarkyUIGen2._Window
        and not DarkyUIGen2._Window.Destroyed
        and DarkyUIGen2._Window
        or nil

    local useBorder
    if config.Border ~= nil then
        useBorder = config.Border == true
    elseif existingWindow then
        useBorder = existingWindow.Border == true
    else
        useBorder = false
    end

    local useBlur
    if config.Blur ~= nil then
        useBlur = config.Blur == true
    elseif existingWindow then
        useBlur = existingWindow.Blur == true
    else
        useBlur = false
    end

    KeySystem.Border = useBorder
    KeySystem.Blur = useBlur

    local fileName =
        "DarkyUIGen2_Key.txt"

    -- Create the KeySystem first and keep it independent from the hub GUI.
    local oldGui = CoreGui:FindFirstChild(
        KEY_GUI_NAME
    )

    if oldGui then
        oldGui:Destroy()
    end

    local gui = New(
        "ScreenGui",
        {
            Name = KEY_GUI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 3000000,
        }
    )

    KeySystem.Gui = gui

    local overlay = New(
        "Frame",
        {
            Parent = gui,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = COLORS.Black,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 2000,
        }
    )

    local main = New(
        "Frame",
        {
            Parent = overlay,
            Name = "Main",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(500, 280),
            BackgroundColor3 = COLORS.Background,
            BorderSizePixel = 0,
            ZIndex = 2001,
        }
    )

    AddCorner(main, 12)
    local keyStroke = Stroke(
        main,
        KeySystem.Border and CurrentTheme().Accent or COLORS.Border,
        1
    )
    keyStroke.Transparency = KeySystem.Border and 0 or 1

    local keyAura
    if KeySystem.Blur then
        keyAura = CreateAuraFor(gui, main, function() return CurrentTheme().Accent end, {
            Name = "KeyAura", Expand = 16, Radius = 12, Layers = 5, Thickness = 4, Transparency = 0.80
        })
    end
    KeySystem.Aura = keyAura

    RegisterTheme(function(_, colors)
        if keyStroke and keyStroke.Parent then
            keyStroke.Color = KeySystem.Border and colors.Accent or COLORS.Border
            keyStroke.Transparency = KeySystem.Border and 0 or 1
        end
        if keyAura and keyAura.Root and keyAura.Root.Parent then keyAura:SetColor(colors.Accent) end
    end)

    --====================================================
    -- HEADER
    --====================================================

    local header = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 0, 55),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 2002,
        }
    )

    AddCorner(header, 11)

    New(
        "Frame",
        {
            Parent = header,
            Name = "CornerMask",
            Position = UDim2.new(0, 0, 1, -11),
            Size = UDim2.new(1, 0, 0, 11),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 2002,
        }
    )

    Stroke(header, COLORS.Border, 1)

    New(
        "TextLabel",
        {
            Parent = header,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(15, 7),
            Size = UDim2.new(1, -30, 0, 22),
            Text = title,
            TextColor3 = COLORS.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2003,
        }
    )

    New(
        "TextLabel",
        {
            Parent = header,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(15, 30),
            Size = UDim2.new(1, -30, 0, 17),
            Text = note,
            TextColor3 = COLORS.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2003,
        }
    )

    --====================================================
    -- LEFT THUMBNAIL
    --====================================================

    local left = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(13, 68),
            Size = UDim2.fromOffset(150, 132),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            ZIndex = 2003,
        }
    )

    Stroke(left, COLORS.Border, 1)

    local thumbAsset =
        thumbnail.Image
            and AssetId(thumbnail.Image)

    if thumbAsset then
        local image = New(
            "ImageLabel",
            {
                Parent = left,
                Position = UDim2.fromOffset(7, 7),
                Size = UDim2.new(1, -14, 0, 92),
                BackgroundColor3 = COLORS.Panel2,
                BorderSizePixel = 0,
                Image = thumbAsset,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 2004,
            }
        )

        Stroke(image, COLORS.Border, 1)
    else
        New(
            "TextLabel",
            {
                Parent = left,
                Position = UDim2.fromOffset(7, 7),
                Size = UDim2.new(1, -14, 0, 92),
                BackgroundColor3 = COLORS.Panel2,
                BorderSizePixel = 0,
                Text = "KEY",
                TextColor3 = COLORS.Muted,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                ZIndex = 2004,
            }
        )
    end

    New(
        "TextLabel",
        {
            Parent = left,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 105),
            Size = UDim2.new(1, -14, 0, 20),
            Text = tostring(
                thumbnail.Title
                    or "Premium Member"
            ),
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2005,
        }
    )

    --====================================================
    -- RIGHT INPUT AREA
    --====================================================

    local right = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(174, 68),
            Size = UDim2.new(1, -187, 0, 132),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            ZIndex = 2003,
        }
    )

    Stroke(right, COLORS.Border, 1)

    New(
        "TextLabel",
        {
            Parent = right,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 10),
            Size = UDim2.new(1, -22, 0, 20),
            Text = "Enter your access key",
            TextColor3 = COLORS.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2004,
        }
    )

    New(
        "TextLabel",
        {
            Parent = right,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 31),
            Size = UDim2.new(1, -22, 0, 17),
            Text = "Paste your key below to continue.",
            TextColor3 = COLORS.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2004,
        }
    )

    local inputFrame = New(
        "Frame",
        {
            Parent = right,
            Position = UDim2.fromOffset(10, 58),
            Size = UDim2.new(1, -20, 0, 38),
            BackgroundColor3 = COLORS.Panel2,
            BorderSizePixel = 0,
            ZIndex = 2005,
        }
    )

    Stroke(inputFrame, COLORS.Border, 1)

    local inputIcon = Icon(
        inputFrame,
        "key-round",
        16,
        UDim2.fromOffset(10, 11),
        2006
    )

    if not inputIcon then
        New(
            "TextLabel",
            {
                Parent = inputFrame,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.fromOffset(20, 38),
                Text = "🔑",
                TextSize = 13,
                TextColor3 = CurrentTheme().Accent2,
                Font = Enum.Font.GothamBold,
                ZIndex = 2006,
            }
        )
    end

    local keyInput = New(
        "TextBox",
        {
            Parent = inputFrame,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(34, 0),
            Size = UDim2.new(1, -42, 1, 0),
            PlaceholderText = "Enter key...",
            PlaceholderColor3 = COLORS.Muted,
            Text = "",
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2006,
        }
    )

    local status = New(
        "TextLabel",
        {
            Parent = main,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(13, 240),
            Size = UDim2.new(1, -26, 0, 18),
            Text = "",
            TextColor3 = COLORS.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2007,
        }
    )

    --====================================================
    -- BOTTOM BUTTONS
    --====================================================

    local function KeyButton(x, text, iconName, background)
        local button = New(
            "TextButton",
            {
                Parent = main,
                Position = UDim2.fromOffset(x, 210),
                Size = UDim2.fromOffset(108, 38),
                BackgroundColor3 = background,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 2008,
            }
        )

        Stroke(
            button,
            background == CurrentTheme().Accent
                and CurrentTheme().Accent2
                or COLORS.Border,
            1
        )

        local image = Icon(
            button,
            iconName,
            16,
            UDim2.fromOffset(12, 11),
            2009
        )

        if iconName == "x" and image then
            image.ImageColor3 = COLORS.Danger
        elseif image then
            image.ImageColor3 =
                background == CurrentTheme().Accent
                and COLORS.White
                or COLORS.Text
        end

        New(
            "TextLabel",
            {
                Parent = button,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(36, 0),
                Size = UDim2.new(1, -41, 1, 0),
                Text = text,
                TextColor3 =
                    background == CurrentTheme().Accent
                    and COLORS.White
                    or COLORS.Text,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 2009,
            }
        )

        return button
    end

    local cancelButton = KeyButton(
        13,
        "Cancel",
        "x",
        COLORS.Panel
    )

    local getKeyButton = KeyButton(
        195,
        "Get Key",
        "key",
        COLORS.Panel
    )

    local submitButton = KeyButton(
        379,
        "Submit",
        "arrow-right",
        CurrentTheme().Accent
    )

    -- Only the accent of the KeySystem changes with the theme.
    RegisterTheme(function(_, colors)
        if not main.Parent then
            return
        end

        submitButton.BackgroundColor3 = colors.Accent

        local stroke = submitButton:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = colors.Accent2
        end

        for _, child in ipairs(submitButton:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextColor3 = COLORS.White
            elseif child:IsA("ImageLabel") then
                child.ImageColor3 = COLORS.White
            end
        end

        local keyIcon = inputFrame:FindFirstChildOfClass("ImageLabel")
        if keyIcon then
            keyIcon.ImageColor3 = colors.Accent2
        end

        status.TextColor3 = COLORS.SubText
    end)

    AddCorner(left, 10)
    AddCorner(right, 10)
    AddCorner(inputFrame, 8)
    AddCorner(cancelButton, 9)
    AddCorner(getKeyButton, 9)
    AddCorner(submitButton, 9)

    --====================================================
    -- VALIDATION / SAVE
    --====================================================

    local function Validate(key)
        if typeof(config.KeyValidator) ~= "function" then
            return false
        end

        local success, result = pcall(
            config.KeyValidator,
            key
        )

        return success and result == true
    end

    local function SaveKey(key)
        if not saveKey then
            return
        end

        if typeof(writefile) ~= "function" then
            return
        end

        pcall(function()
            writefile(fileName, key)
        end)
    end

    local function ReadKey()
        if not saveKey then
            return nil
        end

        if typeof(isfile) ~= "function"
            or typeof(readfile) ~= "function" then
            return nil
        end

        local exists = false

        pcall(function()
            exists = isfile(fileName)
        end)

        if not exists then
            return nil
        end

        local key

        pcall(function()
            key = readfile(fileName)
        end)

        if key and key ~= "" then
            return key
        end

        return nil
    end

    local function Finish()
        if KeySystem.Destroyed then
            return
        end

        KeySystem.Destroyed = true
        DarkyUIGen2._KeyPassed = true

        local tween = Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(500, 0)
            }
        )

        if tween then
            tween.Completed:Connect(function()
                if gui then
                    gui:Destroy()
                end

                -- Reveal a hub created immediately after CreateKeySystem.
                if DarkyUIGen2._Window
                    and not DarkyUIGen2._Window.Destroyed
                    and DarkyUIGen2._Window._KeyLocked then

                    DarkyUIGen2._Window._KeyLocked = false
                    DarkyUIGen2._Window.Main.Visible = true

                    DarkyUIGen2._Window.Main.Size =
                        UDim2.fromOffset(550, 0)

                    Tween(
                        DarkyUIGen2._Window.Main,
                        MED,
                        {
                            Size = UDim2.fromOffset(
                                WINDOW_WIDTH,
                                WINDOW_HEIGHT
                            )
                        }
                    )
                end
            end)
        else
            if gui then
                gui:Destroy()
            end
        end
    end

    cancelButton.MouseButton1Click:Connect(function()
        KeySystem.Cancelled = true
        KeySystem.Destroyed = true
        DarkyUIGen2._KeyPassed = false

        if gui then
            gui:Destroy()
        end
    end)

    getKeyButton.MouseButton1Click:Connect(function()
        if keyURL == "" then
            status.Text = "Key URL is not configured."
            status.TextColor3 = COLORS.Danger
            return
        end

        local copied = SafeClipboard(keyURL)

        if copied then
            status.Text = "Key URL copied to clipboard."
            status.TextColor3 = CurrentTheme().Accent2
        else
            -- Still show URL when clipboard APIs are unavailable.
            status.Text = keyURL
            status.TextColor3 = COLORS.SubText
        end
    end)

    local submitting = false

    local function SubmitKey()
        if submitting then
            return
        end

        submitting = true

        local key = keyInput.Text

        if key == "" then
            status.Text = "Please enter a key."
            status.TextColor3 = COLORS.Warning
            submitting = false
            return
        end

        status.Text = "Checking key..."
        status.TextColor3 = COLORS.SubText

        if Validate(key) then
            status.Text = "Key accepted!"
            status.TextColor3 = CurrentTheme().Accent2

            SaveKey(key)

            task.delay(0.25, Finish)
        else
            status.Text = "Invalid key."
            status.TextColor3 = COLORS.Danger
        end

        submitting = false
    end

    submitButton.MouseButton1Click:Connect(
        SubmitKey
    )

    keyInput.FocusLost:Connect(
        function(enterPressed)
            if enterPressed then
                SubmitKey()
            end
        end
    )

    --====================================================
    -- SAVED KEY
    --====================================================

    local saved = ReadKey()

    if saved and Validate(saved) then
        keyInput.Text = saved
        Finish()
    else
        main.Size = UDim2.fromOffset(500, 0)

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(500, 280)
            }
        )
    end

    function KeySystem:GetKey()
        return keyInput.Text
    end

    function KeySystem:SetKey(value)
        keyInput.Text = tostring(value or "")
    end

    function KeySystem:Submit()
        SubmitKey()
    end

    function KeySystem:Destroy()
        if KeySystem.Destroyed then
            return
        end

        KeySystem.Destroyed = true

        if gui then
            gui:Destroy()
        end
    end

    function KeySystem:IsDestroyed()
        return KeySystem.Destroyed == true
    end

    return KeySystem
end

function DarkyUIGen2:CreateAura(target, config)
    config = config or {}
    if not target or not target:IsA("GuiObject") then return nil end
    local gui = target:FindFirstAncestorOfClass("ScreenGui")
    if not gui then return nil end
    local aura = CreateAuraFor(gui, target, function() return CurrentTheme().Accent end, config)
    if aura then
        RegisterTheme(function(_, colors)
            if aura.Root and aura.Root.Parent then aura:SetColor(colors.Accent) end
        end)
    end
    return aura
end

function DarkyUIGen2:CreateKeySystem(config)
    if self._KeySystem
        and not self._KeySystem.Destroyed then
        self._KeySystem:Destroy()
    end

    self._KeyPassed = false

    local keySystem = MakeKeySystem(config)

    self._KeySystem = keySystem

    return keySystem
end

--========================================================
-- PROGRESS BAR
--========================================================
-- DarkyUI:CreateProgressBar({
--     Title = "Download",
--     Desc = "Downloading files...", -- optional
--     Value = { Min = 0, Max = 100, Default = 25 },
--     Icon = "download", -- lucide icon or "rbxassetid://". optional
-- })
-- Top-level (called on the library itself, not a Section) - a
-- floating toast stacked in the corner, independent of any window/
-- tab, the same way CreateAura and CreateKeySystem are. Multiple
-- progress bars stack vertically and each returns an object with
-- SetValue/GetValue/SetTitle/SetDesc/Destroy so callers can drive it
-- as work progresses and dismiss it when done.

DarkyUIGen2._ProgressBars = {}

local PROGRESS_GUI_NAME = "DarkyUIGen2_ProgressBars"

local function GetProgressBarGui()
    local existing = CoreGui:FindFirstChild(PROGRESS_GUI_NAME)

    if existing then
        return existing
    end

    local gui = New(
        "ScreenGui",
        {
            Name = PROGRESS_GUI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 2600000,
        }
    )

    local stack = New(
        "Frame",
        {
            Parent = gui,
            Name = "Stack",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 16),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ZIndex = 2000,
        }
    )

    New(
        "UIListLayout",
        {
            Parent = stack,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        }
    )

    return gui
end

function DarkyUIGen2:CreateProgressBar(config)
    config = config or {}

    local gui = GetProgressBarGui()
    local stack = gui:FindFirstChild("Stack")

    local title = tostring(config.Title or "Progress")
    local desc = tostring(config.Desc or "")

    local range = config.Value or {}

    local minimum = tonumber(range.Min) or 0
    local maximum = tonumber(range.Max) or 100
    local current = tonumber(range.Default) or minimum

    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end

    local hasIcon = config.Icon ~= nil
        and config.Icon ~= ""

    local titleInset =
        hasIcon and 34 or 12

    local root = New(
        "Frame",
        {
            Parent = stack,
            Size = UDim2.new(
                1,
                0,
                0,
                desc ~= "" and 74 or 58
            ),
            BackgroundColor3 = COLORS.Background,
            BorderSizePixel = 0,
            LayoutOrder = #DarkyUIGen2._ProgressBars + 1,
            ZIndex = 2000,
        }
    )

    AddCorner(root, 10)

    Stroke(
        root,
        COLORS.Border,
        1
    )

    if hasIcon then
        Icon(
            root,
            config.Icon,
            16,
            UDim2.fromOffset(12, 10),
            2002,
            true
        )
    end

    New(
        "TextLabel",
        {
            Parent = root,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(titleInset, 8),
            Size = UDim2.new(1, -(titleInset + 55), 0, 18),
            Text = title,
            TextColor3 = COLORS.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2002,
        }
    )

    local percentLabel = New(
        "TextLabel",
        {
            Parent = root,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -55, 0, 8),
            Size = UDim2.fromOffset(43, 18),
            Text = "0%",
            TextColor3 = CurrentTheme().Accent2,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 2002,
        }
    )

    if desc ~= "" then
        New(
            "TextLabel",
            {
                Parent = root,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(titleInset, 26),
                Size = UDim2.new(1, -(titleInset + 12), 0, 14),
                Text = desc,
                TextColor3 = COLORS.SubText,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 2002,
            }
        )
    end

    local trackY = desc ~= "" and 50 or 34
    local trackHeight = 8

    local track = New(
        "Frame",
        {
            Parent = root,
            Position = UDim2.fromOffset(12, trackY),
            Size = UDim2.new(1, -24, 0, trackHeight),
            BackgroundColor3 = CurrentTheme().Accent,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            ZIndex = 2001,
        }
    )

    AddCorner(track, math.floor(trackHeight / 2))

    Stroke(
        track,
        COLORS.Border,
        1
    )

    local fill = New(
        "Frame",
        {
            Parent = track,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = CurrentTheme().Accent,
            BorderSizePixel = 0,
            ZIndex = 2002,
        }
    )

    AddCorner(fill, math.floor(trackHeight / 2))

    root.BackgroundTransparency = 1
    Tween(root, FAST, { BackgroundTransparency = 0 })

    local function updateTheme(_, colors)
        if not root.Parent then
            return
        end

        track.BackgroundColor3 = colors.Accent
        fill.BackgroundColor3 = colors.Accent
        percentLabel.TextColor3 = colors.Accent2
    end

    RegisterTheme(updateTheme)

    local function set(value, animate)
        current = math.clamp(
            tonumber(value) or minimum,
            minimum,
            maximum
        )

        local percent = (current - minimum)
            / math.max(maximum - minimum, 0.00001)

        percentLabel.Text =
            tostring(math.floor(percent * 100 + 0.5)) .. "%"

        if animate == false then
            fill.Size = UDim2.new(percent, 0, 1, 0)
        else
            Tween(
                fill,
                MED,
                { Size = UDim2.new(percent, 0, 1, 0) }
            )
        end
    end

    local progressBar = {
        Root = root,
        Destroyed = false,
    }

    function progressBar:SetValue(value, animate)
        set(value, animate)
    end

    function progressBar:GetValue()
        return current
    end

    function progressBar:SetTitle(newTitle)
        title = tostring(newTitle or title)
    end

    function progressBar:SetDesc(newDesc)
        desc = tostring(newDesc or "")
    end

    function progressBar:Destroy()
        if progressBar.Destroyed then
            return
        end

        progressBar.Destroyed = true

        for index, bar in ipairs(DarkyUIGen2._ProgressBars) do
            if bar == progressBar then
                table.remove(DarkyUIGen2._ProgressBars, index)
                break
            end
        end

        local tween = Tween(
            root,
            FAST,
            { BackgroundTransparency = 1 }
        )

        task.delay(FAST.Time, function()
            if root then
                root:Destroy()
            end
        end)
    end

    set(current, false)

    table.insert(DarkyUIGen2._ProgressBars, progressBar)

    return progressBar
end

--========================================================
-- WINDOW
--========================================================

function DarkyUIGen2:CreateWindow(config)
    config = config or {}

    if DarkyUIGen2._Window
        and not DarkyUIGen2._Window.Destroyed then
        pcall(function()
            DarkyUIGen2._Window:Destroy()
        end)
    end

    if config.Image ~= nil then
        DarkyUIGen2.CurrentImage = config.Image
    end

    local Window = {
        Destroyed = false,
        Minimized = false,
        Tabs = {},
        Elements = {},
        ActiveTab = nil,
    }

    Window.Title = tostring(
        config.Title or "DarkyUIGen2"
    )

    Window.Subtitle = tostring(
        config.Subtitle or ""
    )

    Window.Image = config.Image
    Window.SearchEnabled =
        config.SearchBar == true
    Window.UserConfig =
        config.User or {}

    -- Border/Blur: connect to the KeySystem's settings.
    -- Explicit config.Border/config.Blur always win. Otherwise, if a
    -- KeySystem already exists (CreateKeySystem called first, the
    -- documented common order), inherit its Border/Blur so both stay
    -- visually consistent. Falls back to false.
    local existingKeySystem =
        DarkyUIGen2._KeySystem
        and not DarkyUIGen2._KeySystem.Destroyed
        and DarkyUIGen2._KeySystem
        or nil

    if config.Border ~= nil then
        Window.Border = config.Border == true
    elseif existingKeySystem then
        Window.Border = existingKeySystem.Border == true
    else
        Window.Border = false
    end

    if config.Blur ~= nil then
        Window.Blur = config.Blur == true
    elseif existingKeySystem then
        Window.Blur = existingKeySystem.Blur == true
    else
        Window.Blur = false
    end

    -- If a KeySystem was just created and has not passed yet,
    -- keep the hub hidden until the KeySystem succeeds.
    Window._KeyLocked =
        DarkyUIGen2._KeySystem ~= nil
        and not DarkyUIGen2._KeySystem.Destroyed
        and not DarkyUIGen2._KeyPassed

    --====================================================
    -- GUI
    --====================================================

    local oldGui = CoreGui:FindFirstChild(
        MAIN_GUI_NAME
    )

    if oldGui then
        oldGui:Destroy()
    end

    local gui = New(
        "ScreenGui",
        {
            Name = MAIN_GUI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 1000000,
        }
    )

    Window.Gui = gui

    --====================================================
    -- FLOATING BUTTON
    --====================================================

    local floating = New(
        "TextButton",
        {
            Parent = gui,
            Name = "FloatingButton",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 18, 0.5, 0),
            Size = UDim2.fromOffset(52, 52),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Active = true,
            Text = "",
            Visible = false,
            ZIndex = 500,
        }
    )

    -- Restore the floating button's last saved screen position, if
    -- FloatingButtonManager has one on file for this folder. Falls
    -- back to the default left-center spot above if there's nothing
    -- saved yet (first run, or file API unavailable). Keeps the
    -- original X/Y scale components (0, 0.5) so it stays anchored the
    -- same way on screen resize - only the offsets are restored.
    do
        local savedX, savedY =
            DarkyUIGen2.FloatingButtonManager:LoadPosition()

        if savedX and savedY then
            floating.Position = UDim2.new(
                0,
                savedX,
                0.5,
                savedY
            )
        end
    end

    AddCorner(floating, 11)

    Stroke(
        floating,
        COLORS.Border,
        1
    )

    local floatingIcon = IconOrBadge(
        floating,
        Window.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        501,
        Window.Title
    )

    --====================================================
    -- MAIN
    --====================================================

    local main = New(
        "Frame",
        {
            Parent = gui,
            Name = "Main",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(
                WINDOW_WIDTH,
                WINDOW_HEIGHT
            ),
            BackgroundColor3 = COLORS.Background,
            -- Gen-2: a slight glass/translucent feel on the window's
            -- base panel - subtle, not heavy, so text and content
            -- (which sit on their own fully opaque Panel/Panel2
            -- surfaces) stay perfectly legible.
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = not Window._KeyLocked,
            ZIndex = 10,
        }
    )

    Window.Main = main

    AddCorner(main, 12)
    local mainStroke = Stroke(
        main,
        Window.Border and CurrentTheme().Accent or COLORS.Border,
        1
    )
    mainStroke.Transparency = Window.Border and 0 or 1

    local mainAura
    if Window.Blur then
        mainAura = CreateAuraFor(gui, main, function() return CurrentTheme().Accent end, {
            Name = "MainAura", Expand = 20, Radius = 12, Layers = 6, Thickness = 5, Transparency = 0.76
        })
    end
    Window.Aura = mainAura

    --====================================================
    -- TOP BAR
    --====================================================

    local top = New(
        "Frame",
        {
            Parent = main,
            Name = "TopBar",
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 0, 57),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 20,
        }
    )

    AddCorner(top, 11)

    New(
        "Frame",
        {
            Parent = top,
            Name = "CornerMask",
            Position = UDim2.new(0, 0, 1, -11),
            Size = UDim2.new(1, 0, 0, 11),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 20,
        }
    )

    Stroke(
        top,
        COLORS.Border,
        1
    )

    RegisterTheme(function(_, colors)
        if mainStroke and mainStroke.Parent then
            mainStroke.Color = Window.Border and colors.Accent or COLORS.Border
            mainStroke.Transparency = Window.Border and 0 or 1
        end
        if mainAura and mainAura.Root and mainAura.Root.Parent then
            mainAura:SetColor(colors.Accent)
        end
    end)

    --====================================================
    -- DRAG MAIN WINDOW
    --====================================================

    do
        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        local function update(input)
            if not dragging then
                return
            end

            local delta =
                input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        top.InputBegan:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true
                dragStart = input.Position
                startPosition = main.Position
                dragInput = input

                input.Changed:Connect(function()
                    if input.UserInputState ==
                        Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        top.InputChanged:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput then
                update(input)
            end
        end)
    end

    --====================================================
    -- WINDOW ICON
    --====================================================

    local iconHolder = New(
        "Frame",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 9),
            Size = UDim2.fromOffset(40, 40),
            ZIndex = 21,
        }
    )

    local windowIcon = IconOrBadge(
        iconHolder,
        Window.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        22,
        Window.Title
    )

    --====================================================
    -- TITLE + SUBTITLE
    --====================================================

    local titleLabel = New(
        "TextLabel",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 7),
            Size = UDim2.new(1, -225, 0, 23),
            Text = Window.Title,
            TextColor3 = COLORS.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        }
    )

    local subtitleLabel = New(
        "TextLabel",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 30),
            Size = UDim2.new(1, -225, 0, 17),
            Text = Window.Subtitle,
            TextColor3 = COLORS.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        }
    )

    --====================================================
    -- TAG (small colored badge next to the window title)
    --====================================================
    -- Window:Tag({ Title = "Featured", Icon = "star", Color = ... })
    -- Also callable as Tab:Tag(...) on any tab (see below) since
    -- that's how it reads most naturally when scripting, but it's
    -- really one badge for the whole window, shown once next to the
    -- title - not a per-tab thing.

    local tagHolder = New(
        "Frame",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(1, 18),
            Visible = false,
            ZIndex = 23,
        }
    )

    function Window:Tag(tagConfig)
        tagConfig = tagConfig or {}

        local tagTitle = tostring(tagConfig.Title or "Tag")
        local tagColor = typeof(tagConfig.Color) == "Color3"
            and tagConfig.Color
            or CurrentTheme().Accent

        for _, child in ipairs(tagHolder:GetChildren()) do
            child:Destroy()
        end

        local hasIcon = tagConfig.Icon ~= nil
            and tagConfig.Icon ~= ""

        local textStartX = hasIcon and 22 or 8

        local pill = New(
            "Frame",
            {
                Parent = tagHolder,
                Size = UDim2.fromOffset(1, 18),
                BackgroundColor3 = tagColor,
                BackgroundTransparency = 0.78,
                BorderSizePixel = 0,
                ZIndex = 23,
            }
        )

        AddCorner(pill, 6)

        Stroke(pill, tagColor, 1)

        if hasIcon then
            local iconHolderTag = New(
                "Frame",
                {
                    Parent = pill,
                    Position = UDim2.fromOffset(5, 2),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                    ZIndex = 24,
                }
            )

            local tagIconObject = Icon(
                iconHolderTag,
                tagConfig.Icon,
                12,
                UDim2.fromOffset(1, 1),
                24
            )

            if tagIconObject then
                tagIconObject.ImageColor3 = tagColor
            end
        end

        local tagLabel = New(
            "TextLabel",
            {
                Parent = pill,
                Position = UDim2.fromOffset(textStartX, 0),
                Size = UDim2.fromOffset(200, 18),
                BackgroundTransparency = 1,
                Text = tagTitle,
                TextColor3 = tagColor,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                ZIndex = 24,
            }
        )

        -- Measure the label after AutomaticSize settles so the pill
        -- itself (and its holder) can size to fit exactly.
        task.defer(function()
            if not tagLabel.Parent then
                return
            end

            local fullWidth = textStartX
                + tagLabel.AbsoluteSize.X
                + 8

            pill.Size = UDim2.fromOffset(fullWidth, 18)
            tagHolder.Size = UDim2.fromOffset(fullWidth, 18)
        end)

        tagHolder.Position = UDim2.fromOffset(
            58 + titleLabel.TextBounds.X + 8,
            8
        )

        tagHolder.Visible = true

        return self
    end

    --====================================================
    -- SEARCH BAR
    --====================================================

    local searchBox

    if Window.SearchEnabled then
        local searchFrame = New(
            "Frame",
            {
                Parent = top,
                Position = UDim2.new(1, -205, 0, 11),
                Size = UDim2.fromOffset(125, 36),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                ZIndex = 25,
            }
        )

        Stroke(
            searchFrame,
            COLORS.Border,
            1
        )

        Icon(
            searchFrame,
            "search",
            15,
            UDim2.fromOffset(9, 10),
            26
        )

        searchBox = New(
            "TextBox",
            {
                Parent = searchFrame,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -35, 1, 0),
                PlaceholderText = "Search",
                PlaceholderColor3 = COLORS.Muted,
                Text = "",
                TextColor3 = COLORS.Text,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 26,
            }
        )

        Window.SearchBox = searchBox
    end

    --====================================================
    -- MINIMIZE / CLOSE
    --====================================================

    local minimizeButton = New(
        "TextButton",
        {
            Parent = top,
            Position = UDim2.new(1, -75, 0, 9),
            Size = UDim2.fromOffset(30, 38),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 30,
        }
    )

    Icon(
        minimizeButton,
        "minus",
        17,
        UDim2.new(0.5, -8, 0.5, -8),
        31
    )

    local closeButton = New(
        "TextButton",
        {
            Parent = top,
            Position = UDim2.new(1, -40, 0, 9),
            Size = UDim2.fromOffset(30, 38),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 30,
        }
    )

    local closeIcon = Icon(
        closeButton,
        "x",
        18,
        UDim2.new(0.5, -9, 0.5, -9),
        31
    )

    if closeIcon then
        closeIcon.ImageColor3 = COLORS.Danger
    end

    --====================================================
    -- BODY
    --====================================================

    local body = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(0, 58),
            Size = UDim2.new(1, 0, 1, -58),
            BackgroundTransparency = 1,
            ZIndex = 10,
        }
    )

    --====================================================
    -- TABS
    --====================================================

    local tabs = New(
        "ScrollingFrame",
        {
            Parent = body,
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(145, 266),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = COLORS.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 11,
        }
    )

    AddCorner(tabs, 10)

    Stroke(
        tabs,
        COLORS.Border,
        1
    )

    Padding(
        tabs,
        6,
        6,
        6,
        6
    )

    New(
        "UIListLayout",
        {
            Parent = tabs,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        }
    )

    --====================================================
    -- PROFILE
    --====================================================

    if Window.UserConfig.Profile
        or Window.UserConfig.Username then

        local profile = New(
            "Frame",
            {
                Parent = tabs,
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                LayoutOrder = -100,
                ZIndex = 13,
            }
        )

        AddCorner(profile, 10)

        Stroke(
            profile,
            COLORS.Border,
            1
        )

        if Window.UserConfig.Profile then
            local avatar = New(
                "ImageLabel",
                {
                    Parent = profile,
                    Position = UDim2.fromOffset(7, 7),
                    Size = UDim2.fromOffset(36, 36),
                    BackgroundColor3 = COLORS.Panel2,
                    BorderSizePixel = 0,
                    ZIndex = 14,
                }
            )

            AddCircle(avatar)

            pcall(function()
                local image =
                    Players:GetUserThumbnailAsync(
                        LocalPlayer.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size100x100
                    )

                avatar.Image = image
            end)

            Stroke(
                avatar,
                COLORS.Border,
                1
            )
        end

        if Window.UserConfig.Username then
            local x =
                Window.UserConfig.Profile
                    and 49
                    or 8

            New(
                "TextLabel",
                {
                    Parent = profile,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(x, 7),
                    Size = UDim2.new(1, -x - 5, 0, 19),
                    Text = LocalPlayer.DisplayName,
                    TextColor3 = COLORS.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 14,
                }
            )

            New(
                "TextLabel",
                {
                    Parent = profile,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(x, 26),
                    Size = UDim2.new(1, -x - 5, 0, 16),
                    Text = "@" .. LocalPlayer.Name,
                    TextColor3 = COLORS.SubText,
                    TextSize = 9,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 14,
                }
            )
        end
    end

    --====================================================
    -- CONTENT
    --====================================================

    local content = New(
        "Frame",
        {
            Parent = body,
            Position = UDim2.fromOffset(160, 8),
            Size = UDim2.new(1, -168, 1, -16),
            BackgroundTransparency = 1,
            ZIndex = 11,
        }
    )

    --====================================================
    -- SEARCH LOGIC
    --====================================================

    local function SearchElements(text)
        text = tostring(text or ""):lower()

        for _, element in ipairs(Window.Elements) do
            if element.Root and element.Root.Parent then
                if text == "" then
                    element.Root.Visible = true
                else
                    local elementTitle = tostring(
                        element.Title or ""
                    ):lower()

                    local elementDesc = tostring(
                        element.Desc or ""
                    ):lower()

                    element.Root.Visible =
                        elementTitle:find(text, 1, true) ~= nil
                        or elementDesc:find(text, 1, true) ~= nil
                end
            end
        end
    end

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text")
            :Connect(function()
                SearchElements(searchBox.Text)
            end)
    end

    --====================================================
    -- WINDOW METHODS
    --====================================================

    function Window:Minimize()
        if self.Destroyed
            or self.Minimized
            or self._KeyLocked then
            return
        end

        self.Minimized = true

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(
                    WINDOW_WIDTH,
                    0
                )
            }
        )

        task.delay(0.22, function()
            if self.Destroyed then
                return
            end

            main.Visible = false
            floating.Visible = true
            floating.Size = UDim2.fromOffset(0, 0)

            Tween(
                floating,
                MED,
                {
                    Size = UDim2.fromOffset(52, 52)
                }
            )
        end)
    end

    function Window:Restore()
        if self.Destroyed
            or not self.Minimized then
            return
        end

        self.Minimized = false
        floating.Visible = false
        main.Visible = true
        main.Size = UDim2.fromOffset(WINDOW_WIDTH, 0)

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(
                    WINDOW_WIDTH,
                    WINDOW_HEIGHT
                )
            }
        )
    end

    --====================================================
    -- DELETE CONFIRMATION POPUP
    --====================================================

    local function ShowDeleteConfirm()
        local confirmGui = New(
            "ScreenGui",
            {
                Name = "DarkyUIGen2_ConfirmDelete",
                Parent = CoreGui,
                IgnoreGuiInset = true,
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = 3500000,
            }
        )

        local overlay = New(
            "Frame",
            {
                Parent = confirmGui,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = COLORS.Black,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                ZIndex = 1000,
            }
        )

        local function ClosePopup()
            confirmGui:Destroy()
        end

        local outside = New(
            "TextButton",
            {
                Parent = overlay,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 1000,
            }
        )

        outside.MouseButton1Click:Connect(ClosePopup)

        local popup = New(
            "Frame",
            {
                Parent = overlay,
                Name = "ConfirmPopup",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(300, 170),
                BackgroundColor3 = COLORS.Background,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 1002,
            }
        )

        AddCorner(popup, 12)

        Stroke(
            popup,
            COLORS.Border,
            1
        )

        local warnIcon = Icon(
            popup,
            "trash-2",
            30,
            UDim2.new(0.5, -15, 0, 20),
            1003,
            false
        )

        if warnIcon then
            warnIcon.ImageColor3 = COLORS.Danger
        end

        New(
            "TextLabel",
            {
                Parent = popup,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(15, 60),
                Size = UDim2.new(1, -30, 0, 20),
                Text = "Delete UI library?",
                TextColor3 = COLORS.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1003,
            }
        )

        New(
            "TextLabel",
            {
                Parent = popup,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(15, 82),
                Size = UDim2.new(1, -30, 0, 32),
                Text = "Do you really want to delete UI library? This action cannot be undone.",
                TextColor3 = COLORS.SubText,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 1003,
            }
        )

        local cancelButton = New(
            "TextButton",
            {
                Parent = popup,
                Position = UDim2.new(0, 15, 1, -46),
                Size = UDim2.new(0.5, -20, 0, 32),
                BackgroundColor3 = COLORS.Info,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 1003,
            }
        )

        AddCorner(cancelButton, 8)

        local cancelIcon = Icon(
            cancelButton,
            "x",
            14,
            UDim2.new(0, 12, 0.5, -7),
            1004
        )

        if cancelIcon then
            cancelIcon.ImageColor3 = COLORS.White
        end

        New(
            "TextLabel",
            {
                Parent = cancelButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -38, 1, 0),
                Text = "Cancel",
                TextColor3 = COLORS.White,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1004,
            }
        )

        local deleteButton = New(
            "TextButton",
            {
                Parent = popup,
                Position = UDim2.new(0.5, 5, 1, -46),
                Size = UDim2.new(0.5, -20, 0, 32),
                BackgroundColor3 = COLORS.Danger,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 1003,
            }
        )

        AddCorner(deleteButton, 8)

        local deleteIcon = Icon(
            deleteButton,
            "trash-2",
            14,
            UDim2.new(0, 12, 0.5, -7),
            1004
        )

        if deleteIcon then
            deleteIcon.ImageColor3 = COLORS.White
        end

        New(
            "TextLabel",
            {
                Parent = deleteButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -38, 1, 0),
                Text = "Delete",
                TextColor3 = COLORS.White,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1004,
            }
        )

        cancelButton.MouseEnter:Connect(function()
            Tween(cancelButton, FAST, { BackgroundTransparency = 0.15 })
        end)

        cancelButton.MouseLeave:Connect(function()
            Tween(cancelButton, FAST, { BackgroundTransparency = 0 })
        end)

        deleteButton.MouseEnter:Connect(function()
            Tween(deleteButton, FAST, { BackgroundTransparency = 0.15 })
        end)

        deleteButton.MouseLeave:Connect(function()
            Tween(deleteButton, FAST, { BackgroundTransparency = 0 })
        end)

        cancelButton.MouseButton1Click:Connect(ClosePopup)

        deleteButton.MouseButton1Click:Connect(function()
            ClosePopup()
            Window:Destroy()
        end)

        popup.Size = UDim2.fromOffset(300, 0)

        Tween(
            popup,
            MED,
            {
                Size = UDim2.fromOffset(300, 170)
            }
        )
    end

    function Window:Destroy()
        if self.Destroyed then
            return
        end

        self.Destroyed = true

        if self.Aura then
            pcall(function() self.Aura:Destroy() end)
            self.Aura = nil
        end

        if gui then
            gui:Destroy()
        end
    end

    function Window:CreateAura(config)
        config = config or {}
        if not self.Main or not self.Main.Parent then return nil end
        if self.Aura then self.Aura:Destroy() end
        self.Aura = DarkyUIGen2:CreateAura(self.Main, config)
        return self.Aura
    end

    function Window:SetTitle(value)
        self.Title = tostring(value)
        titleLabel.Text = self.Title
    end

    function Window:SetSubtitle(value)
        self.Subtitle = tostring(value)
        subtitleLabel.Text = self.Subtitle
    end

    function Window:SetIcon(value)
        self.Image = value
        DarkyUIGen2.CurrentImage = value

        -- Deleting the icon (nil/"") reverts cleanly to the default
        -- glyph instead of leaving the previous image stuck on screen.
        -- Rebuilt (not mutated) so it correctly swaps between a real
        -- resolved icon and a generated letter-badge either direction.
        local displayValue = value or "layout-dashboard"

        if windowIcon then
            windowIcon:Destroy()
        end

        windowIcon = IconOrBadge(
            iconHolder,
            displayValue,
            24,
            UDim2.new(0.5, -12, 0.5, -12),
            22,
            self.Title
        )

        if floatingIcon then
            floatingIcon:Destroy()
        end

        floatingIcon = IconOrBadge(
            floating,
            displayValue,
            24,
            UDim2.new(0.5, -12, 0.5, -12),
            501,
            self.Title
        )
    end

    function Window:SetVisible(value)
        value = value == true

        if value then
            if self.Minimized then
                self:Restore()
            else
                main.Visible = true
            end
        else
            main.Visible = false
        end
    end

    function Window:GetActiveTab()
        return self.ActiveTab
    end

    --====================================================
    -- BUTTON EVENTS
    --====================================================

    minimizeButton.MouseButton1Click:Connect(function()
        ClickPop(minimizeButton)
        self = Window
        Window:Minimize()
    end)

    closeButton.MouseButton1Click:Connect(function()
        ClickPop(closeButton)
        ShowDeleteConfirm()
    end)

    --====================================================
    -- FLOATING BUTTON DRAG + TAP
    --====================================================

    do
        local dragging = false
        local dragInput
        local dragStart
        local startPosition
        local moved = false

        local function update(input)
            if not dragging then
                return
            end

            local delta =
                input.Position - dragStart

            if delta.Magnitude > 7 then
                moved = true
            end

            floating.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        floating.InputBegan:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true
                moved = false
                dragInput = input
                dragStart = input.Position
                startPosition = floating.Position

                input.Changed:Connect(function()
                    if input.UserInputState ==
                        Enum.UserInputState.End then

                        dragging = false

                        if not moved then
                            Window:Restore()
                        else
                            -- Persist wherever it was actually
                            -- dropped, so it reopens in the same
                            -- spot next session.
                            DarkyUIGen2.FloatingButtonManager:SavePosition(
                                floating.Position.X.Offset,
                                floating.Position.Y.Offset
                            )
                        end
                    end
                end)
            end
        end)

        floating.InputChanged:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput then
                update(input)
            end
        end)
    end

    --====================================================
    -- TAB SECTION (collapsible group of tabs)
    --====================================================
    -- Window:Section({ Title = "..." }) groups tabs under a
    -- collapsible header in the sidebar - click the header (or the
    -- arrow) to slide the group open/closed. Purely optional: plain
    -- Window:CreateTab(...) still works exactly as before and adds
    -- an ungrouped tab straight into the list.

    function Window:Section(sectionConfig)
        sectionConfig = sectionConfig or {}

        local sectionTitle = tostring(
            sectionConfig.Title or "Section"
        )

        local TabSection = {
            Title = sectionTitle,
            Collapsed = false,
        }

        local header = New(
            "TextButton",
            {
                Parent = tabs,
                Name = "TabSectionHeader",
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = #Window.Tabs + 1,
                ZIndex = 15,
            }
        )

        New(
            "TextLabel",
            {
                Parent = header,
                Position = UDim2.fromOffset(4, 0),
                Size = UDim2.new(1, -26, 1, 0),
                BackgroundTransparency = 1,
                Text = sectionTitle,
                TextColor3 = COLORS.SubText,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 16,
            }
        )

        local arrowIcon = Icon(
            header,
            "chevron-down",
            12,
            UDim2.new(1, -20, 0.5, -6),
            16
        )

        local group = New(
            "Frame",
            {
                Parent = tabs,
                Name = "TabSectionGroup",
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = #Window.Tabs + 2,
                ZIndex = 15,
            }
        )

        local groupLayout = New(
            "UIListLayout",
            {
                Parent = group,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
            }
        )

        Padding(
            group,
            0,
            0,
            0,
            5
        )

        function TabSection:CreateTab(tabConfig)
            return Window:CreateTab(tabConfig, group)
        end

        -- Start expanded, sized to whatever tabs get added to this
        -- group during the user's synchronous setup script. Deferred
        -- since AbsoluteContentSize isn't accurate until after those
        -- tabs have actually been parented and laid out.
        task.defer(function()
            if group.Parent and not TabSection.Collapsed then
                group.Size = UDim2.new(
                    1,
                    0,
                    0,
                    groupLayout.AbsoluteContentSize.Y
                )
            end
        end)

        function TabSection:Toggle()
            self.Collapsed = not self.Collapsed

            if arrowIcon then
                Tween(
                    arrowIcon,
                    FAST,
                    {
                        Rotation = self.Collapsed and -90 or 0
                    }
                )
            end

            if self.Collapsed then
                Tween(
                    group,
                    FAST,
                    { Size = UDim2.new(1, 0, 0, 0) }
                )
            else
                group.Visible = true

                Tween(
                    group,
                    FAST,
                    {
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            groupLayout.AbsoluteContentSize.Y
                        )
                    }
                )
            end
        end

        header.MouseButton1Click:Connect(function()
            ClickPop(header)
            TabSection:Toggle()
        end)

        return TabSection
    end

    --====================================================
    -- CREATE TAB
    --====================================================

    function Window:CreateTab(tabConfig, parentContainer)
        tabConfig = tabConfig or {}
        parentContainer = parentContainer or tabs

        local Tab = {
            Title = tabConfig.Title or "Tab",
            Icon = tabConfig.Icon or "circle",
            Sections = {},
            Selected = false,
        }

        local tabButton = New(
            "TextButton",
            {
                Parent = parentContainer,
                Name = "TabButton",
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = #Window.Tabs + 1,
                ZIndex = 15,
            }
        )

        AddCorner(tabButton, 8)

        Stroke(
            tabButton,
            COLORS.Border,
            1
        )

        local selectedBar = New(
            "Frame",
            {
                Parent = tabButton,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(3, 38),
                BackgroundColor3 = COLORS.Border,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 16,
            }
        )

        AddCorner(selectedBar, 6)

        local tabIconHolder = New(
            "Frame",
            {
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.fromOffset(38, 38),
                ZIndex = 16,
            }
        )

        local tabIcon = IconOrBadge(
            tabIconHolder,
            Tab.Icon,
            17,
            UDim2.new(0.5, -8, 0.5, -8),
            17,
            Tab.Title
        )

        local tabText = New(
            "TextLabel",
            {
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(47, 0),
                Size = UDim2.new(1, -53, 1, 0),
                Text = Tab.Title,
                TextColor3 = COLORS.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 17,
            }
        )

        --================================================
        -- PAGE SCAFFOLD (reusable: default page + Tab:CreatePage)
        --================================================
        -- Builds one scrollable page with the two-column section
        -- layout described above. Returns a page object carrying its
        -- own independent column/section state, so a Tab can have
        -- multiple pages (via Tab:CreatePage) that each lay out their
        -- sections separately without interfering with one another.

        local pageCount = 0

        local function BuildPage(pageTitle, pageIcon)
            pageCount = pageCount + 1

            local pageFrame = New(
                "ScrollingFrame",
                {
                    Parent = content,
                    Name = "Page_"
                        .. tostring(#Window.Tabs + 1)
                        .. "_"
                        .. tostring(pageCount),
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = COLORS.Border,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    Visible = false,
                    ZIndex = 12,
                }
            )

            Padding(
                pageFrame,
                0,
                5,
                0,
                8
            )

            -- Sections are placed into whichever column comes up
            -- next in the left/right alternation, so the page fills
            -- space efficiently (two compact sections share a row)
            -- while each section still auto-sizes to its own content
            -- and new sections keep stacking below. On a narrow page,
            -- both columns still lay out side by side at half width
            -- each; if only one column ever gets content, its sibling
            -- automatically expands to fill the row (see below).

            local columnsRow = New(
                "Frame",
                {
                    Parent = pageFrame,
                    Name = "ColumnsRow",
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                    ZIndex = 12,
                }
            )

            New(
                "UIListLayout",
                {
                    Parent = pageFrame,
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 7),
                }
            )

            local COLUMN_GAP = 7

            local function MakeColumn(order)
                local column = New(
                    "Frame",
                    {
                        Parent = columnsRow,
                        Name = "Column_" .. tostring(order),
                        Position = UDim2.new(
                            (order - 1) * 0.5,
                            (order - 1) * (COLUMN_GAP / 2),
                            0,
                            0
                        ),
                        Size = UDim2.new(
                            0.5,
                            -(COLUMN_GAP / 2),
                            0,
                            0
                        ),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 12,
                    }
                )

                local layout = New(
                    "UIListLayout",
                    {
                        Parent = column,
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 7),
                    }
                )

                return column, layout
            end

            local columnLeft, layoutLeft = MakeColumn(1)
            local columnRight, layoutRight = MakeColumn(2)

            -- If a column ends up with nothing in it (an odd trailing
            -- section, or only one section ever created), let its
            -- sibling expand to fill the whole row instead of sitting
            -- stuck at half-width with empty space next to it.
            local function RebalanceWidths()
                local leftHasContent =
                    #columnLeft:GetChildren() > 1

                local rightHasContent =
                    #columnRight:GetChildren() > 1

                if leftHasContent and not rightHasContent then
                    columnLeft.Size = UDim2.new(1, 0, 0, 0)
                    columnRight.Size = UDim2.new(0, 0, 0, 0)
                elseif rightHasContent and not leftHasContent then
                    columnLeft.Size = UDim2.new(0, 0, 0, 0)
                    columnRight.Size = UDim2.new(1, 0, 0, 0)
                else
                    columnLeft.Size = UDim2.new(
                        0.5,
                        -(COLUMN_GAP / 2),
                        0,
                        0
                    )
                    columnRight.Size = UDim2.new(
                        0.5,
                        -(COLUMN_GAP / 2),
                        0,
                        0
                    )
                end
            end

            columnLeft.ChildAdded:Connect(RebalanceWidths)
            columnLeft.ChildRemoved:Connect(RebalanceWidths)
            columnRight.ChildAdded:Connect(RebalanceWidths)
            columnRight.ChildRemoved:Connect(RebalanceWidths)

            local pageObj = {
                Title = pageTitle or "Page",
                Icon = pageIcon,
                Frame = pageFrame,
                Sections = {},
                _ColumnToggle = false,
                _NextOrder = 1,
                _Columns = { columnLeft, columnRight },
                _RebalanceWidths = RebalanceWidths,
                _ColumnsRow = columnsRow,
            }

            -- Sections pair up left/right in the order they're
            -- created: 1st -> left, 2nd -> right (same row), 3rd ->
            -- left (new row below), 4th -> right, and so on. Each
            -- section still auto-sizes to its own content
            -- independently of its row partner.
            function pageObj._NextColumn()
                pageObj._ColumnToggle = not pageObj._ColumnToggle

                if pageObj._ColumnToggle then
                    return columnLeft, layoutLeft, 1
                end

                return columnRight, layoutRight, 2
            end

            return pageObj
        end

        local defaultPageObj = BuildPage("Main")
        local page = defaultPageObj.Frame

        Tab.Button = tabButton
        Tab.Page = page
        Tab.Pages = {}
        Tab._DefaultPage = defaultPageObj
        Tab._ActivePage = defaultPageObj
        Tab._Bar = selectedBar
        Tab._Text = tabText

        --================================================
        -- PAGE SLIDER (shown only once a 2nd page exists)
        --================================================
        -- Each tab can hold multiple pages (Tab:CreatePage /
        -- Section:CreatePage). Only one page is visible within the
        -- tab at a time. This bar shows the current page's icon and
        -- title ("2 / 3") and is dragged/swiped left or right to
        -- switch pages - no buttons, just a direct swipe gesture,
        -- similar to scrolling the tab list itself.

        local pageSwitcher = New(
            "Frame",
            {
                Parent = content,
                Name = "PageSwitcher_" .. tostring(#Window.Tabs + 1),
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 12,
            }
        )

        AddCorner(pageSwitcher, 8)

        Stroke(pageSwitcher, COLORS.Border, 1)

        local pageIconHolder = New(
            "Frame",
            {
                Parent = pageSwitcher,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.fromOffset(38, 38),
                Visible = false,
                ZIndex = 13,
            }
        )

        local pageLabel = New(
            "TextLabel",
            {
                Parent = pageSwitcher,
                Position = UDim2.fromOffset(47, 0),
                Size = UDim2.new(1, -53, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = COLORS.Text,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 13,
            }
        )

        -- The swipeable hit area covers the whole bar. A plain
        -- TextButton doubles as the InputBegan/Changed/Ended target
        -- for the drag gesture below.
        local swipeArea = New(
            "TextButton",
            {
                Parent = pageSwitcher,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 14,
            }
        )

        -- Once a tab has 3+ pages, swiping one-by-one stops being the
        -- fastest way to get around - the bar turns into a dropdown
        -- button instead (chevron shown on the right) that opens a
        -- popup listing every page, tap one to jump straight to it.
        local dropdownChevron = Icon(
            pageSwitcher,
            "chevron-down",
            14,
            UDim2.new(1, -22, 0.5, -7),
            13
        )

        if dropdownChevron then
            dropdownChevron.Visible = false
        end

        local isDropdownMode = false

        Tab._PageSwitcher = pageSwitcher

        -- Reserve a strip at the top of `content` for the slider bar,
        -- only for tabs that actually end up with multiple pages.
        -- Runs once, the moment the 2nd page is added.
        local function ReserveSwitcherSpace()
            for _, pageObj in ipairs(Tab.Pages) do
                pageObj.Frame.Position = UDim2.fromOffset(0, 44)
                pageObj.Frame.Size = UDim2.new(1, 0, 1, -44)
            end
        end

        local function CurrentPageIndex()
            for index, pageObj in ipairs(Tab.Pages) do
                if pageObj == Tab._ActivePage then
                    return index
                end
            end

            return 1
        end

        local currentPageIcon = nil

        local function RefreshSwitcherBar()
            local index = CurrentPageIndex()
            local total = #Tab.Pages
            local activePage = Tab._ActivePage

            isDropdownMode = total >= 3

            if dropdownChevron then
                dropdownChevron.Visible = isDropdownMode
            end

            pageLabel.Size = isDropdownMode
                and UDim2.new(1, -75, 1, 0)
                or UDim2.new(1, -53, 1, 0)

            pageLabel.Text = activePage.Title
                .. "  ("
                .. tostring(index)
                .. "/"
                .. tostring(total)
                .. ")"

            if currentPageIcon then
                currentPageIcon:Destroy()
                currentPageIcon = nil
            end

            pageIconHolder.Visible = true

            -- Same treatment as the sidebar tab list: a real icon if
            -- one was given, otherwise a generated letter badge, so
            -- the header always has an icon slot instead of a gap.
            currentPageIcon = IconOrBadge(
                pageIconHolder,
                activePage.Icon,
                17,
                UDim2.new(0.5, -8, 0.5, -8),
                13,
                activePage.Title
            )
        end

        -- Single source of truth for whether the slider bar should
        -- currently be shown: only if this tab is the selected one
        -- AND it actually has more than one page. Called from every
        -- place that changes page count or tab selection, instead of
        -- scattered .Visible assignments that can drift out of sync
        -- with each other depending on call order.
        local function SyncSwitcherVisibility()
            pageSwitcher.Visible =
                Tab.Selected and #Tab.Pages > 1
        end

        Tab._SyncSwitcherVisibility = SyncSwitcherVisibility

        -- Animated slide: the current page slides fully off to one
        -- side while the target page slides in from the other side,
        -- so it reads as a swipe rather than an instant cut.
        local sliding = false

        local function SlideToIndex(targetIndex, direction, continuingDrag)
            if sliding then
                return
            end

            local total = #Tab.Pages

            if targetIndex < 1
                or targetIndex > total then
                return
            end

            local fromPage = Tab._ActivePage
            local toPage = Tab.Pages[targetIndex]

            if fromPage == toPage then
                return
            end

            sliding = true

            local width = page.AbsoluteSize.X > 0
                and page.AbsoluteSize.X
                or 380

            -- When continuing an in-progress drag, both frames are
            -- already positioned near where they should be (the user
            -- dragged them there) - just tween on from there instead
            -- of snapping back to a fixed starting offset first.
            if not continuingDrag then
                toPage.Frame.Visible = true
                toPage.Frame.Position = UDim2.fromOffset(
                    direction * width,
                    toPage.Frame.Position.Y.Offset
                )
            end

            Tween(
                fromPage.Frame,
                SWING,
                {
                    Position = UDim2.fromOffset(
                        -direction * width,
                        fromPage.Frame.Position.Y.Offset
                    )
                }
            )

            Tween(
                toPage.Frame,
                SWING,
                {
                    Position = UDim2.fromOffset(
                        0,
                        toPage.Frame.Position.Y.Offset
                    )
                }
            )

            Tab._ActivePage = toPage

            task.delay(SWING.Time, function()
                fromPage.Frame.Visible = false
                fromPage.Frame.Position = UDim2.fromOffset(
                    0,
                    fromPage.Frame.Position.Y.Offset
                )
                sliding = false
                RefreshSwitcherBar()
            end)

            RefreshSwitcherBar()

            if searchBox then
                SearchElements(searchBox.Text)
            end
        end

        -- Swipe/drag gesture: press and drag left or right across the
        -- bar (mouse or touch) to switch pages, mirroring how the
        -- tab list itself scrolls - the current page visibly follows
        -- the drag, then either snaps to the next/previous page or
        -- springs back depending on how far it was dragged.
        local dragging = false
        local dragStartX = 0
        local dragFromPage = nil
        local dragPeekPage = nil
        local dragPeekDirection = 0
        local SWIPE_THRESHOLD = 55

        local function EndDrag(input)
            if not dragging then
                return
            end

            dragging = false

            local dragDeltaX =
                input.Position.X - dragStartX

            if dragDeltaX <= -SWIPE_THRESHOLD and dragPeekPage then
                SlideToIndex(CurrentPageIndex() + 1, 1, true)
            elseif dragDeltaX >= SWIPE_THRESHOLD and dragPeekPage then
                SlideToIndex(CurrentPageIndex() - 1, -1, true)
            else
                -- Not far enough - spring back to where it started.
                if dragPeekPage then
                    dragPeekPage.Frame.Visible = false
                end

                Tween(
                    dragFromPage.Frame,
                    SWING,
                    {
                        Position = UDim2.fromOffset(
                            0,
                            dragFromPage.Frame.Position.Y.Offset
                        )
                    }
                )
            end

            dragFromPage = nil
            dragPeekPage = nil
        end

        swipeArea.InputBegan:Connect(function(input)
            if sliding or isDropdownMode then
                return
            end

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true
                dragStartX = input.Position.X
                dragFromPage = Tab._ActivePage
                dragPeekPage = nil
                dragPeekDirection = 0
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging then
                return
            end

            if input.UserInputType ==
                Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                local dragDeltaX =
                    input.Position.X - dragStartX

                local currentIndex = CurrentPageIndex()
                local direction = dragDeltaX < 0 and 1 or -1
                local peekIndex = currentIndex + direction

                if peekIndex < 1
                    or peekIndex > #Tab.Pages then

                    -- Nothing to swipe to on this side; resist a
                    -- little rather than dragging freely off-screen.
                    dragFromPage.Frame.Position = UDim2.fromOffset(
                        dragDeltaX * 0.3,
                        dragFromPage.Frame.Position.Y.Offset
                    )

                    if dragPeekPage then
                        dragPeekPage.Frame.Visible = false
                        dragPeekPage = nil
                    end

                    return
                end

                if dragPeekPage ~= Tab.Pages[peekIndex] then
                    if dragPeekPage then
                        dragPeekPage.Frame.Visible = false
                    end

                    dragPeekPage = Tab.Pages[peekIndex]
                    dragPeekDirection = direction
                    dragPeekPage.Frame.Visible = true
                end

                local width = page.AbsoluteSize.X > 0
                    and page.AbsoluteSize.X
                    or 380

                dragFromPage.Frame.Position = UDim2.fromOffset(
                    dragDeltaX,
                    dragFromPage.Frame.Position.Y.Offset
                )

                dragPeekPage.Frame.Position = UDim2.fromOffset(
                    dragDeltaX + (dragPeekDirection * width),
                    dragPeekPage.Frame.Position.Y.Offset
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if dragging
                and (
                    input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                    or input.UserInputType ==
                        Enum.UserInputType.Touch
                ) then

                EndDrag(input)
            end
        end)

        --================================================
        -- PAGE DROPDOWN (3+ pages)
        --================================================
        -- Once a tab has 3 or more pages, swiping through them one
        -- at a time stops scaling - the bar becomes a button that
        -- opens a small popup listing every page, tap one to jump
        -- straight to it. Built the same way as the delete
        -- confirmation popup: its own ScreenGui on CoreGui so it
        -- always renders above the window.

        local function ShowPageDropdown()
            local dropdownGui = New(
                "ScreenGui",
                {
                    Name = "DarkyUIGen2_PageDropdown",
                    Parent = CoreGui,
                    IgnoreGuiInset = true,
                    ResetOnSpawn = false,
                    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                    DisplayOrder = 3400000,
                }
            )

            local overlay = New(
                "Frame",
                {
                    Parent = dropdownGui,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = COLORS.Black,
                    BackgroundTransparency = 0.4,
                    BorderSizePixel = 0,
                    ZIndex = 1000,
                }
            )

            local function ClosePopup()
                dropdownGui:Destroy()
            end

            local outside = New(
                "TextButton",
                {
                    Parent = overlay,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 1000,
                }
            )

            outside.MouseButton1Click:Connect(ClosePopup)

            local total = #Tab.Pages
            local popupHeight = math.clamp(
                46 + (total * 42),
                120,
                340
            )

            local popup = New(
                "Frame",
                {
                    Parent = overlay,
                    Name = "PageDropdownPopup",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(260, popupHeight),
                    BackgroundColor3 = COLORS.Background,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 1002,
                }
            )

            AddCorner(popup, 12)

            Stroke(popup, COLORS.Border, 1)

            New(
                "TextLabel",
                {
                    Parent = popup,
                    Position = UDim2.fromOffset(14, 10),
                    Size = UDim2.new(1, -28, 0, 20),
                    BackgroundTransparency = 1,
                    Text = "Select a page",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 1003,
                }
            )

            local list = New(
                "ScrollingFrame",
                {
                    Parent = popup,
                    Position = UDim2.fromOffset(8, 36),
                    Size = UDim2.new(1, -16, 1, -44),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = COLORS.Border,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 1003,
                }
            )

            New(
                "UIListLayout",
                {
                    Parent = list,
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                }
            )

            for pageIndex, pageObj in ipairs(Tab.Pages) do
                local isActive = pageObj == Tab._ActivePage

                local row = New(
                    "TextButton",
                    {
                        Parent = list,
                        Size = UDim2.new(1, 0, 0, 36),
                        BackgroundColor3 = isActive
                            and COLORS.Panel2
                            or COLORS.Panel,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        LayoutOrder = pageIndex,
                        ZIndex = 1003,
                    }
                )

                AddCorner(row, 8)

                Stroke(row, COLORS.Border, 1)

                local rowIconHolder = New(
                    "Frame",
                    {
                        Parent = row,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(6, 6),
                        Size = UDim2.fromOffset(24, 24),
                        ZIndex = 1004,
                    }
                )

                IconOrBadge(
                    rowIconHolder,
                    pageObj.Icon,
                    17,
                    UDim2.new(0.5, -8, 0.5, -8),
                    1005,
                    pageObj.Title
                )

                New(
                    "TextLabel",
                    {
                        Parent = row,
                        Position = UDim2.fromOffset(38, 0),
                        Size = UDim2.new(1, -44, 1, 0),
                        BackgroundTransparency = 1,
                        Text = pageObj.Title,
                        TextColor3 = isActive
                            and COLORS.Text
                            or COLORS.SubText,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 1004,
                    }
                )

                row.MouseButton1Click:Connect(function()
                    ClosePopup()
                    pageObj:Select()
                end)
            end

            popup.Size = UDim2.fromOffset(260, 0)

            Tween(
                popup,
                MED,
                {
                    Size = UDim2.fromOffset(260, popupHeight)
                }
            )
        end

        swipeArea.MouseButton1Click:Connect(function()
            if isDropdownMode then
                ShowPageDropdown()
            end
        end)

        local function RegisterPage(pageObj)
            table.insert(Tab.Pages, pageObj)

            -- Only reveal the slider bar once there's more than one
            -- page to switch between; a tab with a single (default)
            -- page keeps its old, uncluttered look.
            if #Tab.Pages > 1 then
                ReserveSwitcherSpace()
                RefreshSwitcherBar()
            end

            SyncSwitcherVisibility()

            function pageObj:Select()
                local index = 1

                for i, other in ipairs(Tab.Pages) do
                    if other == pageObj then
                        index = i
                    end
                end

                local currentIndex = CurrentPageIndex()

                if currentIndex == index then
                    return
                end

                local direction = index > currentIndex and 1 or -1
                SlideToIndex(index, direction)
            end

            function pageObj:CreateSection(sectionConfig)
                return Tab:CreateSection(sectionConfig, pageObj)
            end
        end

        -- The default/"Main" page is only registered as an actual
        -- page (visible in Tab.Pages, eligible to show in the slide
        -- bar) once it's actually used - either a section lands on
        -- it directly, or CreatePage is called and we need to know
        -- whether Main already holds anything. A tab that only ever
        -- calls Tab:CreatePage never gets a phantom empty "Main" page.
        local defaultPageRegistered = false

        local function EnsureDefaultPageRegistered()
            if defaultPageRegistered then
                return
            end

            defaultPageRegistered = true
            RegisterPage(defaultPageObj)

            -- RegisterPage never sets Frame.Visible itself (it has no
            -- opinion on which page should be showing). If this tab
            -- was already selected before any section ever landed on
            -- the default page (the common case: CreateTab runs its
            -- auto-select long before the user's script gets around
            -- to calling CreateSection), nothing would otherwise ever
            -- flip this page's Frame.Visible on, and it would stay
            -- hidden forever even though it's the tab's active page.
            if Tab.Selected then
                defaultPageObj.Frame.Visible = true
            end
        end

        --================================================
        -- TAG (alias to Window:Tag)
        --================================================
        -- Tab:Tag({ Title = "Featured", Icon = "star", Color = ... })
        -- reads naturally when scripting from a tab, but the badge
        -- itself lives on the window title bar, not per-tab - this
        -- just forwards to Window:Tag so both call styles work.

        function Tab:Tag(tagConfig)
            return Window:Tag(tagConfig)
        end

        --================================================
        -- CREATE PAGE
        --================================================

        function Tab:CreatePage(pageConfig)
            pageConfig = pageConfig or {}

            -- If sections were already created directly on the tab
            -- (landing on the default page), that page has real
            -- content and deserves a slot in the slider too. If not,
            -- it stays hidden/unregistered rather than showing up as
            -- an empty, unwanted "Main" page.
            local defaultWasUnused = not defaultPageRegistered

            if #defaultPageObj.Sections > 0 then
                EnsureDefaultPageRegistered()
                defaultWasUnused = false
            end

            local newPageObj = BuildPage(
                pageConfig.Title or ("Page " .. tostring(#Tab.Pages + 1)),
                pageConfig.Icon
            )

            RegisterPage(newPageObj)

            -- The default page was never actually used (no sections
            -- ever landed on it, so it stayed unregistered/hidden).
            -- Whichever page is created first in that case becomes
            -- the tab's visible page - otherwise Tab._ActivePage
            -- would still point at the unused default page, which
            -- isn't in Tab.Pages, and every page (including this new
            -- one) would end up permanently hidden.
            if defaultWasUnused and #Tab.Pages == 1 then
                Tab._ActivePage = newPageObj

                -- Only actually show it right now if this tab is the
                -- one currently selected; otherwise Tab:Select() will
                -- show the right page whenever this tab is chosen.
                newPageObj.Frame.Visible = Tab.Selected == true
            end

            SyncSwitcherVisibility()

            if Tab.Selected then
                RefreshSwitcherBar()
            end

            return newPageObj
        end

        -- Lets the implicit default/"Main" page (the one sections
        -- land on when created directly via Tab:CreateSection or
        -- Section1:CreateSection with no page involved) be renamed
        -- and given an icon too, since it's built before the user
        -- has a chance to configure it otherwise.
        function Tab:SetDefaultPage(pageConfig)
            pageConfig = pageConfig or {}

            if pageConfig.Title ~= nil then
                defaultPageObj.Title = tostring(pageConfig.Title)
            end

            if pageConfig.Icon ~= nil then
                defaultPageObj.Icon = pageConfig.Icon
            end

            RefreshSwitcherBar()

            return defaultPageObj
        end


        function Tab:Select()
            for _, other in ipairs(Window.Tabs) do
                local active =
                    other == Tab

                other.Selected = active

                -- Show whichever page was last active within that
                -- tab (defaults to the tab's default/"Main" page),
                -- not always the same first page.
                for _, otherPage in ipairs(other.Pages) do
                    otherPage.Frame.Visible =
                        active and otherPage == other._ActivePage
                end

                if other._SyncSwitcherVisibility then
                    other._SyncSwitcherVisibility()
                end

                other._Bar.Visible = active

                other.Button.BackgroundColor3 = active
                    and COLORS.Panel2
                    or COLORS.Panel

                other._Text.TextColor3 = active
                    and COLORS.Text
                    or COLORS.SubText
            end

            Window.ActiveTab = Tab

            if searchBox then
                SearchElements(searchBox.Text)
            end
        end

        tabButton.MouseButton1Click:Connect(function()
            ClickPop(tabButton)
            Tab:Select()
        end)

        tabButton.MouseEnter:Connect(function()
            if not Tab.Selected then
                Tween(
                    tabButton,
                    FAST,
                    {
                        BackgroundColor3 = COLORS.Panel2
                    }
                )
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if not Tab.Selected then
                Tween(
                    tabButton,
                    FAST,
                    {
                        BackgroundColor3 = COLORS.Panel
                    }
                )
            end
        end)

        --================================================
        -- CREATE SECTION
        --================================================

        function Tab:CreateSection(sectionConfig, targetPage)
            sectionConfig = sectionConfig or {}
            targetPage = targetPage or Tab._DefaultPage

            if targetPage == defaultPageObj then
                EnsureDefaultPageRegistered()
            end

            -- Belt-and-suspenders: whatever page this section is
            -- about to land on, make sure its Frame.Visible actually
            -- matches reality right now - it should be showing if
            -- it's this tab's current page AND this tab is selected.
            -- Sections/elements are meant to be visible immediately
            -- with no PageTab required at all; PageTab only exists
            -- for people who explicitly want extra pages within the
            -- same tab, it's never a requirement to see anything.
            if targetPage == Tab._ActivePage then
                targetPage.Frame.Visible = Tab.Selected == true
            end

            local Section = {
                Title = sectionConfig.Title or "Section",
            }

            local targetColumn, _, columnIndex =
                targetPage._NextColumn()

            targetPage._NextOrder = targetPage._NextOrder + 1

            -- No Size property. Fully automatic; width is always the
            -- full width of whichever column it lands in, and height
            -- follows its own content regardless of the other column.
            local sectionFrame = New(
                "Frame",
                {
                    Parent = targetColumn,
                    Name = "Section_" .. Section.Title,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = COLORS.Background2,
                    BorderSizePixel = 0,
                    LayoutOrder = targetPage._NextOrder,
                    ZIndex = 13,
                }
            )

            Section.Column = columnIndex
            Section.Page = targetPage
            Section._Tab = Tab

            -- Gen-2: every new section fades in instead of just
            -- appearing instantly. Transparency-only (no UIScale) so
            -- it can't ever transiently distort AbsolutePosition/
            -- AbsoluteSize for anything inside that depends on those
            -- being stable immediately (e.g. the slider's drag math).
            sectionFrame.BackgroundTransparency = 1

            Tween(
                sectionFrame,
                FAST,
                { BackgroundTransparency = 0 }
            )

            Section.Icon = sectionConfig.Icon

            AddCorner(sectionFrame, 10)

            Stroke(
                sectionFrame,
                COLORS.Border,
                1
            )

            Padding(
                sectionFrame,
                6,
                6,
                5,
                6
            )

            AddSectionAccent(sectionFrame)

            local hasSectionIcon = Section.Icon ~= nil
                and Section.Icon ~= ""

            if hasSectionIcon then
                Section._IconObject = IconOrBadge(
                    sectionFrame,
                    Section.Icon,
                    14,
                    UDim2.fromOffset(6, 3),
                    16,
                    Section.Title
                )
            end

            New(
                "TextLabel",
                {
                    Parent = sectionFrame,
                    Position = hasSectionIcon
                        and UDim2.fromOffset(24, 0)
                        or UDim2.fromOffset(6, 0),
                    Size = hasSectionIcon
                        and UDim2.new(1, -24, 0, 20)
                        or UDim2.new(1, -6, 0, 20),
                    BackgroundTransparency = 1,
                    Text = Section.Title,
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 16,
                }
            )

            local holder = New(
                "Frame",
                {
                    Parent = sectionFrame,
                    Position = UDim2.fromOffset(0, 25),
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 14,
                }
            )

            New(
                "UIListLayout",
                {
                    Parent = holder,
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                }
            )

            Section.Frame = sectionFrame
            Section.Holder = holder
            Section.Elements = {}

            table.insert(
                Tab.Sections,
                Section
            )

            table.insert(
                targetPage.Sections,
                Section
            )

            local function Register(root, title, desc)
                AddCorner(root, 8)
                local record = {
                    Root = root,
                    Title = title,
                    Desc = desc,
                }

                table.insert(
                    Window.Elements,
                    record
                )

                table.insert(
                    Section.Elements,
                    record
                )

                return record
            end

            --============================================
            -- BUTTON
            --============================================

            function Section:CreateButton(buttonConfig)
                buttonConfig = buttonConfig or {}

                local title =
                    buttonConfig.Title or "Button"

                -- Optional description shown below the button title.
                local desc =
                    buttonConfig.Desc or ""

                local locked =
                    buttonConfig.Locked == true

                local height =
                    desc ~= "" and 44 or 34

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(1, 0, 0, height),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                local click = New(
                    "TextButton",
                    {
                        Parent = root,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 17,
                    }
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 0
                        ),
                        Size = UDim2.new(1, -55, 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                if locked then
                    local lock = Icon(
                        root,
                        "lock",
                        14,
                        UDim2.new(1, -25, 0.5, -7),
                        18
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end

                    click.Active = false
                else
                    Icon(
                        root,
                        "chevron-right",
                        15,
                        UDim2.new(1, -28, 0.5, -7),
                        18
                    )

                    click.MouseEnter:Connect(function()
                        Tween(
                            root,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )
                    end)

                    click.MouseLeave:Connect(function()
                        Tween(
                            root,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel
                            }
                        )
                    end)

                    click.MouseButton1Click:Connect(function()
                        ClickPop(root)

                        if typeof(buttonConfig.Callback) ==
                            "function" then

                            task.spawn(
                                buttonConfig.Callback
                            )
                        end
                    end)
                end

                local object = {
                    Root = root,
                }

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- TOGGLE
            --============================================

            function Section:CreateToggle(toggleConfig)
                toggleConfig = toggleConfig or {}

                local title =
                    toggleConfig.Title or "Toggle"

                local desc =
                    toggleConfig.Desc or ""

                local state =
                    toggleConfig.Value == true

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 46 or 36
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 0
                        ),
                        Size = UDim2.new(1, -75, 0, 20),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -80, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                local switch = New(
                    "TextButton",
                    {
                        Parent = root,
                        Position = UDim2.new(1, -58, 0.5, -11),
                        Size = UDim2.fromOffset(44, 22),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 19,
                    }
                )

                AddCorner(switch, 8)

                Stroke(
                    switch,
                    COLORS.Border,
                    1
                )

                local knob = New(
                    "Frame",
                    {
                        Parent = switch,
                        Position = UDim2.fromOffset(3, 3),
                        Size = UDim2.fromOffset(16, 16),
                        BackgroundColor3 = COLORS.SubText,
                        BorderSizePixel = 0,
                        ZIndex = 20,
                    }
                )

                AddCorner(knob, 6)

                local function updateToggle(_, colors)
                    if not root.Parent then
                        return
                    end

                    if state then
                        Tween(
                            switch,
                            FAST,
                            {
                                BackgroundColor3 = colors.Accent
                            }
                        )

                        Tween(
                            knob,
                            FAST,
                            {
                                Position = UDim2.new(1, -19, 0.5, -8),
                                BackgroundColor3 = COLORS.White,
                            }
                        )
                    else
                        Tween(
                            switch,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )

                        Tween(
                            knob,
                            FAST,
                            {
                                Position = UDim2.fromOffset(3, 3),
                                BackgroundColor3 = COLORS.SubText,
                            }
                        )
                    end
                end

                RegisterTheme(updateToggle)

                local object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    state = value == true
                    updateToggle(nil, CurrentTheme())

                    if callCallback ~= false
                        and typeof(toggleConfig.Callback) ==
                            "function" then

                        task.spawn(
                            toggleConfig.Callback,
                            state
                        )
                    end
                end

                function object:GetValue()
                    return state
                end

                RegisterFlag(toggleConfig.Flag, object)

                switch.MouseButton1Click:Connect(function()
                    ClickPop(switch)

                    object:SetValue(
                        not state,
                        true
                    )
                end)

                updateToggle(
                    nil,
                    CurrentTheme()
                )

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- SLIDER
            --============================================

            function Section:CreateSlider(sliderConfig)
                sliderConfig = sliderConfig or {}

                local title =
                    sliderConfig.Title or "Slider"

                local desc =
                    sliderConfig.Desc or ""

                local range =
                    sliderConfig.Value or {}

                local minimum =
                    tonumber(range.Min) or 0

                local maximum =
                    tonumber(range.Max) or 100

                local current =
                    tonumber(range.Default)
                    or minimum

                local step =
                    tonumber(sliderConfig.Step)
                    or 1

                if maximum < minimum then
                    minimum, maximum = maximum, minimum
                end

                -- Gen-2: sized and laid out like CreateButton - a
                -- rounded panel with the title inside near the top,
                -- the track larger and themed instead of a plain
                -- gray bar, and the description (if any) sitting
                -- below the track rather than above it. Kept compact
                -- rather than oversized so it's still easy to fit
                -- several sliders in a section without it feeling
                -- bloated.
                local trackHeight = 10
                local trackY = 30
                local descY = trackY + trackHeight + 8

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and (descY + 20) or (trackY + trackHeight + 12)
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        ZIndex = 15,
                    }
                )

                AddCorner(root, 10)

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 8),
                        Size = UDim2.new(1, -75, 0, 20),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                local valueLabel = New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -60, 0, 8),
                        Size = UDim2.fromOffset(50, 20),
                        Text = tostring(current),
                        TextColor3 = CurrentTheme().Accent2,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 18,
                    }
                )

                local sliderHolder = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(11, trackY),
                        Size = UDim2.new(1, -22, 0, trackHeight),
                        BackgroundTransparency = 1,
                        ZIndex = 18,
                    }
                )

                -- Bigger, theme-colored track "rectangle UI" - a dim
                -- tint of the active theme's accent, not a flat gray,
                -- so switching themes restyles the slider background
                -- too, not just the fill/value text.
                local track = New(
                    "Frame",
                    {
                        Parent = sliderHolder,
                        Position = UDim2.new(0, 0, 0.5, -(trackHeight / 2)),
                        Size = UDim2.new(1, 0, 0, trackHeight),
                        BackgroundColor3 = CurrentTheme().Accent,
                        BackgroundTransparency = 0.85,
                        BorderSizePixel = 0,
                        ZIndex = 18,
                    }
                )

                AddCorner(track, math.floor(trackHeight / 2))

                Stroke(
                    track,
                    COLORS.Border,
                    1
                )

                local fill = New(
                    "Frame",
                    {
                        Parent = track,
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundColor3 = CurrentTheme().Accent,
                        BorderSizePixel = 0,
                        ZIndex = 19,
                    }
                )

                AddCorner(fill, math.floor(trackHeight / 2))

                -- Bigger knob to match the thicker track (was 12x12
                -- on a 6px track; now scaled up with it).
                local knobSize = trackHeight + 6

                local knob = New(
                    "Frame",
                    {
                        Parent = track,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.fromOffset(knobSize, knobSize),
                        BackgroundColor3 = COLORS.White,
                        BorderSizePixel = 0,
                        ZIndex = 20,
                    }
                )

                AddCorner(knob, 4)

                Stroke(
                    knob,
                    COLORS.Border,
                    1
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, descY),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                local drag = New(
                    "TextButton",
                    {
                        Parent = sliderHolder,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 21,
                    }
                )

                local function roundStep(value)
                    value = math.clamp(
                        value,
                        minimum,
                        maximum
                    )

                    local steps = math.floor(
                        ((value - minimum) / step) + 0.5
                    )

                    return math.clamp(
                        minimum + (steps * step),
                        minimum,
                        maximum
                    )
                end

                local function set(value, callCallback)
                    current = roundStep(value)

                    local percent = (
                        current - minimum
                    ) / math.max(
                        maximum - minimum,
                        0.00001
                    )

                    fill.Size = UDim2.new(
                        percent,
                        0,
                        1,
                        0
                    )

                    knob.Position = UDim2.new(
                        percent,
                        0,
                        0.5,
                        0
                    )

                    valueLabel.Text =
                        tostring(current)

                    if callCallback
                        and typeof(sliderConfig.Callback) ==
                            "function" then

                        task.spawn(
                            sliderConfig.Callback,
                            current
                        )
                    end
                end

                local function updateTheme(_, colors)
                    if not root.Parent then
                        return
                    end

                    track.BackgroundColor3 =
                        colors.Accent

                    fill.BackgroundColor3 =
                        colors.Accent

                    valueLabel.TextColor3 =
                        colors.Accent2
                end

                RegisterTheme(updateTheme)

                local moving = false

                local function xToValue(x)
                    local alpha = math.clamp(
                        (
                            x
                            - sliderHolder.AbsolutePosition.X
                        )
                        / math.max(
                            sliderHolder.AbsoluteSize.X,
                            1
                        ),
                        0,
                        1
                    )

                    set(
                        minimum
                            + (
                                maximum
                                - minimum
                            ) * alpha,
                        true
                    )
                end

                drag.InputBegan:Connect(function(input)
                    if input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                        or input.UserInputType ==
                        Enum.UserInputType.Touch then

                        moving = true
                        ClickPop(knob)
                        xToValue(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if moving
                        and (
                            input.UserInputType ==
                                Enum.UserInputType.MouseMovement
                            or input.UserInputType ==
                                Enum.UserInputType.Touch
                        ) then

                        xToValue(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                        or input.UserInputType ==
                        Enum.UserInputType.Touch then

                        moving = false
                    end
                end)

                local object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    set(
                        tonumber(value) or minimum,
                        callCallback ~= false
                    )
                end

                function object:GetValue()
                    return current
                end

                RegisterFlag(sliderConfig.Flag, object)

                function object:SetRange(minimumValue, maximumValue, default)
                    minimum = tonumber(minimumValue)
                        or minimum

                    maximum = tonumber(maximumValue)
                        or maximum

                    if maximum < minimum then
                        minimum, maximum = maximum, minimum
                    end

                    if default ~= nil then
                        current = tonumber(default)
                            or minimum
                    end

                    set(current, false)
                end

                set(current, false)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- INPUT
            --============================================

            function Section:CreateInput(inputConfig)
                inputConfig = inputConfig or {}

                local title =
                    inputConfig.Title or "Input"

                local desc =
                    inputConfig.Desc or ""

                local inputY =
                    desc ~= "" and 40 or 24

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 66 or 52
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                AddCorner(root, 10)

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 7),
                        Size = UDim2.new(1, -20, 0, 19),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 27),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local box = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(10, inputY),
                        Size = UDim2.new(1, -20, 0, 26),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        ZIndex = 18,
                    }
                )

                AddCorner(box, 8)

                Stroke(
                    box,
                    COLORS.Border,
                    1
                )

                local textBox = New(
                    "TextBox",
                    {
                        Parent = box,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -38, 1, 0),
                        Text = inputConfig.Value or "",
                        PlaceholderText = inputConfig.Placeholder or "",
                        PlaceholderColor3 = COLORS.Muted,
                        TextColor3 = COLORS.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 19,
                    }
                )

                -- Pencil icon: tinted with the active theme's Accent color
                -- (BlueSky by default) and re-tints live if the theme changes.
                Icon(
                    box,
                    "pencil",
                    14,
                    UDim2.new(1, -24, 0.5, -7),
                    19,
                    true
                )

                textBox.FocusLost:Connect(function(enterPressed)
                    if typeof(inputConfig.Callback) ==
                        "function" then

                        task.spawn(
                            inputConfig.Callback,
                            textBox.Text,
                            enterPressed
                        )
                    end
                end)

                local object = {
                    Root = root,
                    TextBox = textBox,
                }

                function object:GetValue()
                    return textBox.Text
                end

                function object:SetValue(value)
                    textBox.Text = tostring(value or "")
                end

                RegisterFlag(inputConfig.Flag, object)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- DROPDOWN
            --============================================

            function Section:CreateDropdown(dropdownConfig)
                dropdownConfig = dropdownConfig or {}

                local title =
                    dropdownConfig.Title or "Dropdown"

                -- Optional description shown below the dropdown title.
                local desc =
                    dropdownConfig.Desc or ""

                local values =
                    dropdownConfig.Values or {}

                local multi =
                    dropdownConfig.Multi == true

                local locked =
                    dropdownConfig.Locked == true

                local selected

                if multi then
                    selected = {}

                    if type(dropdownConfig.Value) == "table" then
                        for _, value in ipairs(dropdownConfig.Value) do
                            table.insert(selected, value)
                        end
                    elseif dropdownConfig.Value ~= nil then
                        table.insert(selected, dropdownConfig.Value)
                    end
                else
                    selected = dropdownConfig.Value

                    if selected == nil and #values > 0 then
                        selected = values[1]
                    end
                end

                local function IsSelected(value)
                    if not multi then
                        return tostring(value) == tostring(selected)
                    end

                    for _, item in ipairs(selected) do
                        if tostring(item) == tostring(value) then
                            return true
                        end
                    end

                    return false
                end

                local function GetSelectedText()
                    if not multi then
                        return tostring(selected or "Select...")
                    end

                    if #selected == 0 then
                        return "Select..."
                    end

                    local parts = {}

                    for _, value in ipairs(selected) do
                        table.insert(parts, tostring(value))
                    end

                    return table.concat(parts, ", ")
                end

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 62 or 48
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 6
                        ),
                        Size = UDim2.new(1, -180, 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -22, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local display = New(
                    "TextButton",
                    {
                        Parent = root,
                        Position = UDim2.new(1, -165, 0.5, -14),
                        Size = UDim2.fromOffset(154, 28),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Active = not locked,
                        Text = "",
                        ZIndex = 20,
                    }
                )

                AddCorner(display, 8)

                Stroke(
                    display,
                    COLORS.Border,
                    1
                )

                local selectedLabel = New(
                    "TextLabel",
                    {
                        Parent = display,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(9, 0),
                        Size = UDim2.new(1, -35, 1, 0),
                        Text = GetSelectedText(),
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 21,
                    }
                )

                if locked then
                    local lock = Icon(
                        display,
                        "lock",
                        14,
                        UDim2.new(1, -23, 0.5, -7),
                        21
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                else
                    Icon(
                        display,
                        "chevrons-up-down",
                        15,
                        UDim2.new(1, -22, 0.5, -7),
                        21
                    )
                end

                local popupGui = nil

                local function ClosePopup()
                    if popupGui then
                        popupGui:Destroy()
                        popupGui = nil
                    end
                end

                local function OpenPopup()
                    if popupGui then
                        ClosePopup()
                        return
                    end

                    -- Dropdown overlays the hub and is independently scrollable.
                    popupGui = New(
                        "ScreenGui",
                        {
                            Name = "DarkyUIGen2_Dropdown",
                            Parent = CoreGui,
                            IgnoreGuiInset = true,
                            ResetOnSpawn = false,
                            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                            DisplayOrder = 2500000,
                        }
                    )

                    local overlay = New(
                        "Frame",
                        {
                            Parent = popupGui,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = COLORS.Black,
                            BackgroundTransparency = 0.5,
                            BorderSizePixel = 0,
                            ZIndex = 1000,
                        }
                    )

                    local outside = New(
                        "TextButton",
                        {
                            Parent = overlay,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            Text = "",
                            AutoButtonColor = false,
                            ZIndex = 1000,
                        }
                    )

                    local popup = New(
                        "Frame",
                        {
                            Parent = overlay,
                            Name = "Popup",
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(360, 0),
                            BackgroundColor3 = COLORS.Background,
                            BorderSizePixel = 0,
                            ZIndex = 1002,
                        }
                    )

                    AddCorner(popup, 12)

                    Stroke(
                        popup,
                        COLORS.Border,
                        1
                    )

                    outside.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    local header = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(1, 1),
                            Size = UDim2.new(1, -2, 0, 49),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(header, 9)

                    New(
                        "Frame",
                        {
                            Parent = header,
                            Name = "CornerMask",
                            Position = UDim2.new(0, 0, 1, -9),
                            Size = UDim2.new(1, 0, 0, 9),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    New(
                        "TextLabel",
                        {
                            Parent = header,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(12, 0),
                            Size = UDim2.new(1, -55, 1, 0),
                            Text = title,
                            TextColor3 = COLORS.Text,
                            TextSize = 12,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1004,
                        }
                    )

                    local modalClose = New(
                        "TextButton",
                        {
                            Parent = header,
                            Position = UDim2.new(1, -42, 0, 7),
                            Size = UDim2.fromOffset(32, 36),
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 1005,
                        }
                    )

                    local modalCloseIcon = Icon(
                        modalClose,
                        "x",
                        18,
                        UDim2.new(0.5, -9, 0.5, -9),
                        1006
                    )

                    if modalCloseIcon then
                        modalCloseIcon.ImageColor3 = COLORS.Danger
                    end

                    modalClose.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    local searchFrame = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(10, 58),
                            Size = UDim2.new(1, -20, 0, 34),
                            BackgroundColor3 = COLORS.Panel,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(searchFrame, 8)

                    Stroke(
                        searchFrame,
                        COLORS.Border,
                        1
                    )

                    Icon(
                        searchFrame,
                        "search",
                        15,
                        UDim2.fromOffset(9, 9),
                        1004
                    )

                    local popupSearch = New(
                        "TextBox",
                        {
                            Parent = searchFrame,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(31, 0),
                            Size = UDim2.new(1, -38, 1, 0),
                            PlaceholderText = "Search option...",
                            PlaceholderColor3 = COLORS.Muted,
                            Text = "",
                            TextColor3 = COLORS.Text,
                            TextSize = 10,
                            Font = Enum.Font.Gotham,
                            ClearTextOnFocus = false,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1005,
                        }
                    )

                    local optionList = New(
                        "ScrollingFrame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(10, 100),
                            Size = UDim2.new(1, -20, 0, 160),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            ScrollBarThickness = 4,
                            ScrollBarImageColor3 = COLORS.Border,
                            CanvasSize = UDim2.new(),
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            ScrollingDirection = Enum.ScrollingDirection.Y,
                            ScrollingEnabled = false,
                            ZIndex = 1003,
                        }
                    )

                    Padding(
                        optionList,
                        1,
                        4,
                        1,
                        4
                    )

                    New(
                        "UIListLayout",
                        {
                            Parent = optionList,
                            FillDirection = Enum.FillDirection.Vertical,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 4),
                        }
                    )

                    local countLabel = New(
                        "TextLabel",
                        {
                            Parent = popup,
                            Position = UDim2.new(0, 12, 1, -31),
                            Size = UDim2.new(1, -24, 0, 20),
                            BackgroundTransparency = 1,
                            Text = tostring(#values) .. " options",
                            TextColor3 = COLORS.Muted,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1004,
                        }
                    )

                    local renderOptions

                    local function selectOption(value)
                        if multi then
                            local selectedIndex = nil

                            for index, item in ipairs(selected) do
                                if tostring(item) == tostring(value) then
                                    selectedIndex = index
                                    break
                                end
                            end

                            if selectedIndex then
                                table.remove(selected, selectedIndex)
                            else
                                table.insert(selected, value)
                            end

                            selectedLabel.Text = GetSelectedText()

                            -- Refresh the option list immediately so the
                            -- checkmark/highlight reflects the new selection
                            -- while the popup is still open, instead of only
                            -- updating the next time the popup is reopened.
                            if renderOptions then
                                renderOptions()
                            end

                            if typeof(dropdownConfig.Callback) ==
                                "function" then

                                local result = {}

                                for _, item in ipairs(selected) do
                                    table.insert(result, item)
                                end

                                task.spawn(
                                    dropdownConfig.Callback,
                                    result
                                )
                            end
                        else
                            selected = value
                            selectedLabel.Text = GetSelectedText()

                            ClosePopup()

                            if typeof(dropdownConfig.Callback) ==
                                "function" then

                                task.spawn(
                                    dropdownConfig.Callback,
                                    value
                                )
                            end
                        end
                    end

                    renderOptions = function()
                        for _, child in ipairs(
                            optionList:GetChildren()
                        ) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end

                        local filter =
                            popupSearch.Text:lower()

                        local shown = 0

                        for index, value in ipairs(values) do
                            local text = tostring(value)
                            local matches =
                                filter == ""
                                or text:lower():find(
                                    filter,
                                    1,
                                    true
                                ) ~= nil

                            if matches then
                                shown += 1

                                local option = New(
                                    "TextButton",
                                    {
                                        Parent = optionList,
                                        Size = UDim2.new(1, 0, 0, 35),
                                        BackgroundColor3 = COLORS.Panel,
                                        BorderSizePixel = 0,
                                        AutoButtonColor = false,
                                        Text = "",
                                        LayoutOrder = index,
                                        ZIndex = 1005,
                                    }
                                )

                                AddCorner(option, 7)

                                Stroke(
                                    option,
                                    COLORS.Border,
                                    1
                                )

                                New(
                                    "TextLabel",
                                    {
                                        Parent = option,
                                        BackgroundTransparency = 1,
                                        Position = UDim2.fromOffset(10, 0),
                                        Size = UDim2.new(1, -45, 1, 0),
                                        Text = text,
                                        TextColor3 =
                                            IsSelected(value)
                                            and CurrentTheme().Accent2
                                            or COLORS.Text,
                                        TextSize = 10,
                                        Font = Enum.Font.GothamMedium,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextTruncate = Enum.TextTruncate.AtEnd,
                                        ZIndex = 1006,
                                    }
                                )

                                if IsSelected(value) then
                                    Icon(
                                        option,
                                        "check",
                                        15,
                                        UDim2.new(1, -27, 0.5, -7),
                                        1007
                                    )
                                end

                                option.MouseEnter:Connect(function()
                                    Tween(
                                        option,
                                        FAST,
                                        {
                                            BackgroundColor3 = COLORS.Panel2
                                        }
                                    )
                                end)

                                option.MouseLeave:Connect(function()
                                    Tween(
                                        option,
                                        FAST,
                                        {
                                            BackgroundColor3 = COLORS.Panel
                                        }
                                    )
                                end)

                                option.MouseButton1Click:Connect(function()
                                    ClickPop(option)
                                    selectOption(value)
                                end)
                            end
                        end

                        -- Only enable scrolling when the dropdown has 5+ values.
                        -- With 1-4 values the scrollbar is completely hidden and
                        -- scrolling is disabled.
                        local shouldScroll = #values >= 5

                        optionList.ScrollingEnabled = shouldScroll
                        optionList.ScrollBarThickness = shouldScroll and 4 or 0

                        if not shouldScroll then
                            optionList.CanvasPosition = Vector2.zero
                        end

                        countLabel.Text =
                            tostring(shown)
                            .. " options"
                    end

                    popupSearch:GetPropertyChangedSignal("Text")
                        :Connect(renderOptions)

                    renderOptions()

                    Tween(
                        popup,
                        MED,
                        {
                            Size = UDim2.fromOffset(360, 260)
                        }
                    )
                end

                display.MouseButton1Click:Connect(function()
                    if locked then
                        return
                    end

                    ClickPop(display)
                    OpenPopup()
                end)

                local object = {
                    Root = root,
                    Multi = multi,
                }

                function object:Refresh(newValues)
                    if type(newValues) ~= "table" then
                        return
                    end

                    values = newValues

                    if multi then
                        local filtered = {}

                        for _, selectedValue in ipairs(selected) do
                            for _, value in ipairs(values) do
                                if tostring(value) == tostring(selectedValue) then
                                    table.insert(filtered, selectedValue)
                                    break
                                end
                            end
                        end

                        selected = filtered
                    else
                        local found = false

                        for _, value in ipairs(values) do
                            if tostring(value)
                                == tostring(selected) then
                                found = true
                                break
                            end
                        end

                        if not found then
                            selected = values[1]
                        end
                    end

                    selectedLabel.Text =
                        GetSelectedText()
                end

                function object:SetValue(value, callCallback)
                    if multi then
                        selected = {}

                        if type(value) == "table" then
                            for _, item in ipairs(value) do
                                table.insert(selected, item)
                            end
                        elseif value ~= nil then
                            table.insert(selected, value)
                        end

                        selectedLabel.Text =
                            GetSelectedText()

                        if callCallback ~= false
                            and typeof(dropdownConfig.Callback) ==
                                "function" then

                            local result = {}

                            for _, item in ipairs(selected) do
                                table.insert(result, item)
                            end

                            task.spawn(
                                dropdownConfig.Callback,
                                result
                            )
                        end
                    else
                        selected = value

                        selectedLabel.Text =
                            GetSelectedText()

                        if callCallback ~= false
                            and typeof(dropdownConfig.Callback) ==
                                "function" then

                            task.spawn(
                                dropdownConfig.Callback,
                                value
                            )
                        end
                    end
                end

                function object:GetValue()
                    if multi then
                        local result = {}

                        for _, value in ipairs(selected) do
                            table.insert(result, value)
                        end

                        return result
                    end

                    return selected
                end

                function object:GetValues()
                    return values
                end

                function object:IsMulti()
                    return multi
                end

                function object:SetLocked(value)
                    locked = value == true

                    display.Active = not locked

                    selectedLabel.TextColor3 = locked
                        and COLORS.Muted
                        or COLORS.Text

                    if locked then
                        ClosePopup()
                    end
                end

                RegisterFlag(dropdownConfig.Flag, object)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- ADVANCED DROPDOWN
            --============================================
            -- Section1:CreateAdvencedDropdown({
            --     Title = "Advanced Values",
            --     Desc = "Pick an action", -- optional
            --     Icon = "menu", -- lucide icon or "rbxassetid://". optional
            --     Locked = false, -- disable the dropdown. optional
            --     Values = {
            --         {
            --             Title = "New file",
            --             Desc = "Create a new file",
            --             Icon = "file-plus",
            --             Callback = function() end,
            --         },
            --     },
            -- })
            -- Unlike CreateDropdown (which picks one value from a flat
            -- list and stores it), this is an action menu: each entry
            -- has its own Title/Desc/Icon/Callback and fires
            -- immediately on click. Nothing is "selected" or stored.

            function Section:CreateAdvencedDropdown(dropdownConfig)
                dropdownConfig = dropdownConfig or {}

                local title =
                    dropdownConfig.Title or "Dropdown"

                local desc =
                    dropdownConfig.Desc or ""

                local locked =
                    dropdownConfig.Locked == true

                local items =
                    dropdownConfig.Values or {}

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 62 or 48
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 6
                        ),
                        Size = UDim2.new(1, -85, 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -22, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local display = New(
                    "TextButton",
                    {
                        Parent = root,
                        Position = UDim2.new(1, -75, 0.5, -14),
                        Size = UDim2.fromOffset(64, 28),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Active = not locked,
                        Text = "",
                        ZIndex = 20,
                    }
                )

                AddCorner(display, 8)

                Stroke(
                    display,
                    COLORS.Border,
                    1
                )

                if locked then
                    local lock = Icon(
                        display,
                        "lock",
                        14,
                        UDim2.new(0.5, -7, 0.5, -7),
                        21
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                else
                    Icon(
                        display,
                        "menu",
                        15,
                        UDim2.new(0.5, -7, 0.5, -7),
                        21,
                        true
                    )
                end

                local popupGui = nil

                local function ClosePopup()
                    if popupGui then
                        popupGui:Destroy()
                        popupGui = nil
                    end
                end

                local function OpenPopup()
                    if popupGui then
                        ClosePopup()
                        return
                    end

                    popupGui = New(
                        "ScreenGui",
                        {
                            Name = "DarkyUIGen2_AdvencedDropdown",
                            Parent = CoreGui,
                            IgnoreGuiInset = true,
                            ResetOnSpawn = false,
                            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                            DisplayOrder = 2500000,
                        }
                    )

                    local overlay = New(
                        "Frame",
                        {
                            Parent = popupGui,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = COLORS.Black,
                            BackgroundTransparency = 0.5,
                            BorderSizePixel = 0,
                            ZIndex = 1000,
                        }
                    )

                    local outside = New(
                        "TextButton",
                        {
                            Parent = overlay,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            Text = "",
                            AutoButtonColor = false,
                            ZIndex = 1000,
                        }
                    )

                    outside.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    -- Height grows to fit however many items are
                    -- passed, capped so it scrolls instead of running
                    -- off-screen once there are more than ~6 entries.
                    local rowHeight = 46
                    local listHeight = math.min(
                        #items * (rowHeight + 4),
                        rowHeight * 6
                    )

                    local popup = New(
                        "Frame",
                        {
                            Parent = overlay,
                            Name = "Popup",
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(340, 0),
                            BackgroundColor3 = COLORS.Background,
                            BorderSizePixel = 0,
                            ZIndex = 1002,
                        }
                    )

                    AddCorner(popup, 12)

                    Stroke(
                        popup,
                        COLORS.Border,
                        1
                    )

                    local header = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(1, 1),
                            Size = UDim2.new(1, -2, 0, 49),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(header, 9)

                    New(
                        "Frame",
                        {
                            Parent = header,
                            Name = "CornerMask",
                            Position = UDim2.new(0, 0, 1, -9),
                            Size = UDim2.new(1, 0, 0, 9),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    New(
                        "TextLabel",
                        {
                            Parent = header,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(12, 0),
                            Size = UDim2.new(1, -55, 1, 0),
                            Text = title,
                            TextColor3 = COLORS.Text,
                            TextSize = 12,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1004,
                        }
                    )

                    local modalClose = New(
                        "TextButton",
                        {
                            Parent = header,
                            Position = UDim2.new(1, -42, 0, 7),
                            Size = UDim2.fromOffset(32, 36),
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 1005,
                        }
                    )

                    local modalCloseIcon = Icon(
                        modalClose,
                        "x",
                        18,
                        UDim2.new(0.5, -9, 0.5, -9),
                        1006
                    )

                    if modalCloseIcon then
                        modalCloseIcon.ImageColor3 = COLORS.Danger
                    end

                    modalClose.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    local itemList = New(
                        "ScrollingFrame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(10, 58),
                            Size = UDim2.new(1, -20, 0, listHeight),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            ScrollBarThickness = 4,
                            ScrollBarImageColor3 = COLORS.Border,
                            CanvasSize = UDim2.new(),
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            ScrollingDirection = Enum.ScrollingDirection.Y,
                            ScrollingEnabled = #items * (rowHeight + 4)
                                > listHeight,
                            ZIndex = 1003,
                        }
                    )

                    Padding(
                        itemList,
                        1,
                        4,
                        1,
                        4
                    )

                    New(
                        "UIListLayout",
                        {
                            Parent = itemList,
                            FillDirection = Enum.FillDirection.Vertical,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 4),
                        }
                    )

                    for index, item in ipairs(items) do
                        item = item or {}

                        local itemTitle =
                            tostring(item.Title or "Option")

                        local itemDesc =
                            tostring(item.Desc or "")

                        local row = New(
                            "TextButton",
                            {
                                Parent = itemList,
                                Size = UDim2.new(1, 0, 0, rowHeight),
                                BackgroundColor3 = COLORS.Panel,
                                BorderSizePixel = 0,
                                AutoButtonColor = false,
                                Text = "",
                                LayoutOrder = index,
                                ZIndex = 1005,
                            }
                        )

                        AddCorner(row, 8)

                        Stroke(
                            row,
                            COLORS.Border,
                            1
                        )

                        local hasIcon = item.Icon ~= nil
                            and item.Icon ~= ""

                        if hasIcon then
                            Icon(
                                row,
                                item.Icon,
                                17,
                                UDim2.fromOffset(10, 7.5),
                                1007,
                                true
                            )
                        end

                        New(
                            "TextLabel",
                            {
                                Parent = row,
                                BackgroundTransparency = 1,
                                Position = UDim2.fromOffset(
                                    hasIcon and 37 or 10,
                                    itemDesc ~= "" and 6 or 0
                                ),
                                Size = UDim2.new(
                                    1,
                                    (hasIcon and -47 or -20),
                                    0,
                                    18
                                ),
                                Text = itemTitle,
                                TextColor3 = COLORS.Text,
                                TextSize = 10,
                                Font = Enum.Font.GothamMedium,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                ZIndex = 1006,
                            }
                        )

                        if itemDesc ~= "" then
                            New(
                                "TextLabel",
                                {
                                    Parent = row,
                                    BackgroundTransparency = 1,
                                    Position = UDim2.fromOffset(
                                        hasIcon and 37 or 10,
                                        24
                                    ),
                                    Size = UDim2.new(
                                        1,
                                        (hasIcon and -47 or -20),
                                        0,
                                        16
                                    ),
                                    Text = itemDesc,
                                    TextColor3 = COLORS.SubText,
                                    TextSize = 9,
                                    Font = Enum.Font.Gotham,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextTruncate = Enum.TextTruncate.AtEnd,
                                    ZIndex = 1006,
                                }
                            )
                        end

                        row.MouseEnter:Connect(function()
                            Tween(
                                row,
                                FAST,
                                {
                                    BackgroundColor3 = COLORS.Panel2
                                }
                            )
                        end)

                        row.MouseLeave:Connect(function()
                            Tween(
                                row,
                                FAST,
                                {
                                    BackgroundColor3 = COLORS.Panel
                                }
                            )
                        end)

                        row.MouseButton1Click:Connect(function()
                            ClickPop(row)
                            ClosePopup()

                            if typeof(item.Callback) ==
                                "function" then

                                task.spawn(item.Callback)
                            end
                        end)
                    end

                    Tween(
                        popup,
                        MED,
                        {
                            Size = UDim2.fromOffset(
                                340,
                                58 + listHeight + 10
                            )
                        }
                    )
                end

                display.MouseButton1Click:Connect(function()
                    if locked then
                        return
                    end

                    ClickPop(display)
                    OpenPopup()
                end)

                local object = {
                    Root = root,
                }

                function object:SetLocked(value)
                    locked = value == true

                    display.Active = not locked

                    if locked then
                        ClosePopup()
                    end
                end

                function object:Refresh(newValues)
                    if type(newValues) == "table" then
                        items = newValues
                    end
                end

                RegisterFlag(dropdownConfig.Flag, object)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- COLORPICKER (theme swatches)
            --============================================
            -- Section1:CreateColorpicker({
            --     Title = "Select Color",
            --     Desc = "Pick a color", -- optional
            --     ColorList = { "Red", "BlueSky", "White", ... }, -- optional, defaults to every theme name
            --     Value = "BlueSky", -- default selected theme name. optional
            --     Locked = false, -- disable colorpicker. optional
            --     Flag = "theme_color", -- optional
            --     Callback = function(themeName) end, -- optional
            -- })
            -- Lightweight picker over the library's built-in THEMES
            -- table - each swatch is a named theme's Accent color, and
            -- clicking one calls DarkyUIGen2:SetTheme(name) so the
            -- whole hub re-themes live. For an arbitrary custom
            -- Color3 (not tied to a theme name), use
            -- CreateAdvencedColorpicker instead.

            function Section:CreateColorpicker(colorpickerConfig)
                colorpickerConfig = colorpickerConfig or {}

                local title =
                    colorpickerConfig.Title or "Colorpicker"

                local desc =
                    colorpickerConfig.Desc or ""

                local locked =
                    colorpickerConfig.Locked == true

                local names = {}

                if type(colorpickerConfig.ColorList) == "table"
                    and #colorpickerConfig.ColorList > 0 then

                    for _, name in ipairs(colorpickerConfig.ColorList) do
                        table.insert(names, tostring(name))
                    end
                else
                    for name in pairs(THEMES) do
                        table.insert(names, name)
                    end

                    table.sort(names)
                end

                local function ResolveThemeName(value)
                    if type(value) ~= "string" then
                        return nil
                    end

                    for _, name in ipairs(names) do
                        if name:lower() == value:lower() then
                            return name
                        end
                    end

                    return nil
                end

                local current =
                    ResolveThemeName(colorpickerConfig.Value)
                    or ResolveThemeName(DarkyUIGen2.CurrentTheme)
                    or names[1]

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 68 or 54
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 7),
                        Size = UDim2.new(1, -20, 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 27),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local swatchY =
                    desc ~= "" and 42 or 28

                local swatchRow = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(11, swatchY),
                        Size = UDim2.new(1, -22, 0, 18),
                        BackgroundTransparency = 1,
                        ZIndex = 18,
                    }
                )

                New(
                    "UIListLayout",
                    {
                        Parent = swatchRow,
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 6),
                    }
                )

                local swatches = {}

                local function UpdateSwatches()
                    for name, swatch in pairs(swatches) do
                        local isCurrent =
                            name:lower() == current:lower()

                        swatch.Ring.Visible = isCurrent
                    end
                end

                for index, name in ipairs(names) do
                    local theme = THEMES[name]

                    if theme then
                        local swatch = New(
                            "TextButton",
                            {
                                Parent = swatchRow,
                                Size = UDim2.fromOffset(18, 18),
                                BackgroundColor3 = theme.Accent,
                                BorderSizePixel = 0,
                                AutoButtonColor = false,
                                Active = not locked,
                                Text = "",
                                LayoutOrder = index,
                                ZIndex = 19,
                            }
                        )

                        AddCircle(swatch)

                        local ring = Stroke(
                            swatch,
                            COLORS.White,
                            2
                        )

                        ring.Visible = false

                        Stroke(
                            swatch,
                            COLORS.Border,
                            1
                        )

                        swatch.Ring = ring

                        swatches[name] = swatch

                        if not locked then
                            swatch.MouseButton1Click:Connect(function()
                                ClickPop(swatch)

                                object:SetValue(name, true)
                            end)
                        end
                    end
                end

                if locked then
                    local lock = Icon(
                        root,
                        "lock",
                        13,
                        UDim2.new(1, -22, 0, swatchY + 2),
                        18
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                end

                object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    local resolved =
                        ResolveThemeName(value)

                    if not resolved then
                        return
                    end

                    current = resolved
                    UpdateSwatches()

                    if typeof(DarkyUIGen2.SetTheme) == "function" then
                        DarkyUIGen2:SetTheme(current)
                    end

                    if callCallback ~= false
                        and typeof(colorpickerConfig.Callback) ==
                            "function" then

                        task.spawn(
                            colorpickerConfig.Callback,
                            current
                        )
                    end
                end

                function object:GetValue()
                    return current
                end

                RegisterFlag(colorpickerConfig.Flag, object)

                UpdateSwatches()

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- ADVANCED COLORPICKER (custom RGB/HSV)
            --============================================
            -- Section1:CreateAdvencedColorpicker({
            --     Title = "Select Color",
            --     Desc = "Pick a color", -- optional
            --     Default = Color3.fromRGB(255, 100, 100), -- optional
            --     Locked = false, -- disable colorpicker. optional
            --     Flag = "custom_color", -- optional
            --     Callback = function(color) end, -- optional
            -- })
            -- Unlike CreateColorpicker (which snaps to one of the
            -- library's named THEMES), this opens a full popup with
            -- a saturation/value field, a hue strip, and R/G/B text
            -- inputs, and returns an arbitrary Color3.

            function Section:CreateAdvencedColorpicker(colorpickerConfig)
                colorpickerConfig = colorpickerConfig or {}

                local title =
                    colorpickerConfig.Title or "Colorpicker"

                local desc =
                    colorpickerConfig.Desc or ""

                local locked =
                    colorpickerConfig.Locked == true

                local current =
                    typeof(colorpickerConfig.Default) == "Color3"
                    and colorpickerConfig.Default
                    or Color3.fromRGB(255, 255, 255)

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 62 or 48
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 6
                        ),
                        Size = UDim2.new(1, -75, 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -22, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local display = New(
                    "TextButton",
                    {
                        Parent = root,
                        Position = UDim2.new(1, -58, 0.5, -14),
                        Size = UDim2.fromOffset(47, 28),
                        BackgroundColor3 = current,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Active = not locked,
                        Text = "",
                        ZIndex = 20,
                    }
                )

                AddCorner(display, 8)

                Stroke(
                    display,
                    COLORS.Border,
                    1
                )

                if locked then
                    local lock = Icon(
                        display,
                        "lock",
                        14,
                        UDim2.new(0.5, -7, 0.5, -7),
                        21
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                end

                local popupGui = nil

                local function ClosePopup()
                    if popupGui then
                        popupGui:Destroy()
                        popupGui = nil
                    end
                end

                -- Forward-declared so the RGB text inputs and the
                -- SV/Hue fields can all call back into each other
                -- (e.g. dragging SV updates the RGB boxes, and typing
                -- an RGB box updates the SV/Hue cursors) without
                -- caring which one changed first.
                local syncFromColor

                local function OpenPopup()
                    if popupGui then
                        ClosePopup()
                        return
                    end

                    popupGui = New(
                        "ScreenGui",
                        {
                            Name = "DarkyUIGen2_AdvencedColorpicker",
                            Parent = CoreGui,
                            IgnoreGuiInset = true,
                            ResetOnSpawn = false,
                            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                            DisplayOrder = 2500000,
                        }
                    )

                    local overlay = New(
                        "Frame",
                        {
                            Parent = popupGui,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = COLORS.Black,
                            BackgroundTransparency = 0.5,
                            BorderSizePixel = 0,
                            ZIndex = 1000,
                        }
                    )

                    local outside = New(
                        "TextButton",
                        {
                            Parent = overlay,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            Text = "",
                            AutoButtonColor = false,
                            ZIndex = 1000,
                        }
                    )

                    local popup = New(
                        "Frame",
                        {
                            Parent = overlay,
                            Name = "Popup",
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(300, 0),
                            BackgroundColor3 = COLORS.Background,
                            BorderSizePixel = 0,
                            ZIndex = 1002,
                        }
                    )

                    AddCorner(popup, 12)

                    Stroke(
                        popup,
                        COLORS.Border,
                        1
                    )

                    outside.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    local header = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(1, 1),
                            Size = UDim2.new(1, -2, 0, 49),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(header, 9)

                    New(
                        "Frame",
                        {
                            Parent = header,
                            Name = "CornerMask",
                            Position = UDim2.new(0, 0, 1, -9),
                            Size = UDim2.new(1, 0, 0, 9),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    New(
                        "TextLabel",
                        {
                            Parent = header,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(12, 0),
                            Size = UDim2.new(1, -55, 1, 0),
                            Text = title,
                            TextColor3 = COLORS.Text,
                            TextSize = 12,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1004,
                        }
                    )

                    local modalClose = New(
                        "TextButton",
                        {
                            Parent = header,
                            Position = UDim2.new(1, -42, 0, 7),
                            Size = UDim2.fromOffset(32, 36),
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 1005,
                        }
                    )

                    local modalCloseIcon = Icon(
                        modalClose,
                        "x",
                        18,
                        UDim2.new(0.5, -9, 0.5, -9),
                        1006
                    )

                    if modalCloseIcon then
                        modalCloseIcon.ImageColor3 = COLORS.Danger
                    end

                    modalClose.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    -- Saturation/Value field. Hue is baked into its
                    -- BackgroundColor3 (pure hue at full S/V) and the
                    -- white->transparent + black->transparent
                    -- gradients on top produce the classic square
                    -- picker look.
                    local svField = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(14, 58),
                            Size = UDim2.fromOffset(220, 140),
                            BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(svField, 8)

                    Stroke(
                        svField,
                        COLORS.Border,
                        1
                    )

                    local svWhite = New(
                        "Frame",
                        {
                            Parent = svField,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = COLORS.White,
                            BorderSizePixel = 0,
                            ZIndex = 1004,
                        }
                    )

                    AddCorner(svWhite, 8)

                    New(
                        "UIGradient",
                        {
                            Parent = svWhite,
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(1, 1),
                            }),
                        }
                    )

                    local svBlack = New(
                        "Frame",
                        {
                            Parent = svField,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = COLORS.Black,
                            BorderSizePixel = 0,
                            ZIndex = 1005,
                        }
                    )

                    AddCorner(svBlack, 8)

                    New(
                        "UIGradient",
                        {
                            Parent = svBlack,
                            Rotation = 90,
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(1, 0),
                            }),
                        }
                    )

                    local svCursor = New(
                        "Frame",
                        {
                            Parent = svField,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.fromOffset(12, 12),
                            BackgroundColor3 = COLORS.White,
                            BorderSizePixel = 0,
                            ZIndex = 1006,
                        }
                    )

                    AddCircle(svCursor)

                    Stroke(
                        svCursor,
                        COLORS.Black,
                        2
                    )

                    local svDrag = New(
                        "TextButton",
                        {
                            Parent = svField,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 1007,
                        }
                    )

                    -- Hue strip.
                    local hueField = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(14, 206),
                            Size = UDim2.fromOffset(220, 16),
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(hueField, 8)

                    Stroke(
                        hueField,
                        COLORS.Border,
                        1
                    )

                    local hueSequence = {}

                    for step = 0, 10 do
                        table.insert(
                            hueSequence,
                            ColorSequenceKeypoint.new(
                                step / 10,
                                Color3.fromHSV(step / 10, 1, 1)
                            )
                        )
                    end

                    New(
                        "UIGradient",
                        {
                            Parent = hueField,
                            Color = ColorSequence.new(hueSequence),
                        }
                    )

                    local hueCursor = New(
                        "Frame",
                        {
                            Parent = hueField,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(0, 0, 0.5, 0),
                            Size = UDim2.fromOffset(6, 22),
                            BackgroundColor3 = COLORS.White,
                            BorderSizePixel = 0,
                            ZIndex = 1006,
                        }
                    )

                    AddCorner(hueCursor, 3)

                    Stroke(
                        hueCursor,
                        COLORS.Black,
                        2
                    )

                    local hueDrag = New(
                        "TextButton",
                        {
                            Parent = hueField,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 1007,
                        }
                    )

                    -- Preview swatch + R/G/B text boxes.
                    local preview = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(14, 232),
                            Size = UDim2.fromOffset(44, 44),
                            BackgroundColor3 = current,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(preview, 8)

                    Stroke(
                        preview,
                        COLORS.Border,
                        1
                    )

                    local rgbBoxes = {}
                    local rgbLabels = { "R", "G", "B" }

                    for index, label in ipairs(rgbLabels) do
                        local box = New(
                            "Frame",
                            {
                                Parent = popup,
                                Position = UDim2.fromOffset(
                                    68 + ((index - 1) * 56),
                                    232
                                ),
                                Size = UDim2.fromOffset(50, 44),
                                BackgroundColor3 = COLORS.Panel,
                                BorderSizePixel = 0,
                                ZIndex = 1003,
                            }
                        )

                        AddCorner(box, 8)

                        Stroke(
                            box,
                            COLORS.Border,
                            1
                        )

                        New(
                            "TextLabel",
                            {
                                Parent = box,
                                BackgroundTransparency = 1,
                                Position = UDim2.fromOffset(0, 4),
                                Size = UDim2.new(1, 0, 0, 12),
                                Text = label,
                                TextColor3 = COLORS.SubText,
                                TextSize = 8,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 1004,
                            }
                        )

                        local textBox = New(
                            "TextBox",
                            {
                                Parent = box,
                                BackgroundTransparency = 1,
                                Position = UDim2.fromOffset(0, 18),
                                Size = UDim2.new(1, 0, 0, 20),
                                Text = "255",
                                TextColor3 = COLORS.Text,
                                TextSize = 12,
                                Font = Enum.Font.GothamMedium,
                                ClearTextOnFocus = false,
                                ZIndex = 1004,
                            }
                        )

                        rgbBoxes[label] = textBox
                    end

                    local updatingFromDrag = false

                    local function updateFromHSV(hue, saturation, value, callCallback)
                        current = Color3.fromHSV(
                            hue,
                            saturation,
                            value
                        )

                        display.BackgroundColor3 = current
                        preview.BackgroundColor3 = current

                        svField.BackgroundColor3 =
                            Color3.fromHSV(hue, 1, 1)

                        svCursor.Position = UDim2.new(
                            saturation,
                            0,
                            1 - value,
                            0
                        )

                        hueCursor.Position = UDim2.new(
                            hue,
                            0,
                            0.5,
                            0
                        )

                        updatingFromDrag = true

                        rgbBoxes.R.Text = tostring(
                            math.floor(current.R * 255 + 0.5)
                        )

                        rgbBoxes.G.Text = tostring(
                            math.floor(current.G * 255 + 0.5)
                        )

                        rgbBoxes.B.Text = tostring(
                            math.floor(current.B * 255 + 0.5)
                        )

                        updatingFromDrag = false

                        if callCallback
                            and typeof(colorpickerConfig.Callback) ==
                                "function" then

                            task.spawn(
                                colorpickerConfig.Callback,
                                current
                            )
                        end
                    end

                    local hue, saturation, value =
                        Color3.toHSV(current)

                    local movingSV = false
                    local movingHue = false

                    local function svToValue(x, y)
                        local alphaX = math.clamp(
                            (x - svField.AbsolutePosition.X)
                                / math.max(svField.AbsoluteSize.X, 1),
                            0,
                            1
                        )

                        local alphaY = math.clamp(
                            (y - svField.AbsolutePosition.Y)
                                / math.max(svField.AbsoluteSize.Y, 1),
                            0,
                            1
                        )

                        saturation = alphaX
                        value = 1 - alphaY

                        updateFromHSV(hue, saturation, value, true)
                    end

                    local function hueToValue(x)
                        local alphaX = math.clamp(
                            (x - hueField.AbsolutePosition.X)
                                / math.max(hueField.AbsoluteSize.X, 1),
                            0,
                            1
                        )

                        hue = alphaX

                        updateFromHSV(hue, saturation, value, true)
                    end

                    svDrag.InputBegan:Connect(function(input)
                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            movingSV = true
                            svToValue(input.Position.X, input.Position.Y)
                        end
                    end)

                    hueDrag.InputBegan:Connect(function(input)
                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            movingHue = true
                            hueToValue(input.Position.X)
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType ==
                            Enum.UserInputType.MouseMovement
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            if movingSV then
                                svToValue(
                                    input.Position.X,
                                    input.Position.Y
                                )
                            elseif movingHue then
                                hueToValue(input.Position.X)
                            end
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            movingSV = false
                            movingHue = false
                        end
                    end)

                    local function onRGBChanged()
                        if updatingFromDrag then
                            return
                        end

                        local r = math.clamp(
                            tonumber(rgbBoxes.R.Text) or 0,
                            0,
                            255
                        )

                        local g = math.clamp(
                            tonumber(rgbBoxes.G.Text) or 0,
                            0,
                            255
                        )

                        local b = math.clamp(
                            tonumber(rgbBoxes.B.Text) or 0,
                            0,
                            255
                        )

                        hue, saturation, value = Color3.toHSV(
                            Color3.fromRGB(r, g, b)
                        )

                        updateFromHSV(hue, saturation, value, true)
                    end

                    rgbBoxes.R.FocusLost:Connect(onRGBChanged)
                    rgbBoxes.G.FocusLost:Connect(onRGBChanged)
                    rgbBoxes.B.FocusLost:Connect(onRGBChanged)

                    syncFromColor = function(color)
                        hue, saturation, value = Color3.toHSV(color)
                        updateFromHSV(hue, saturation, value, false)
                    end

                    updateFromHSV(hue, saturation, value, false)

                    Tween(
                        popup,
                        MED,
                        {
                            Size = UDim2.fromOffset(300, 290)
                        }
                    )
                end

                if not locked then
                    display.MouseButton1Click:Connect(function()
                        ClickPop(display)
                        OpenPopup()
                    end)
                end

                object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    if typeof(value) ~= "Color3" then
                        return
                    end

                    current = value
                    display.BackgroundColor3 = current

                    if typeof(syncFromColor) == "function" then
                        syncFromColor(current)
                    end

                    if callCallback ~= false
                        and typeof(colorpickerConfig.Callback) ==
                            "function" then

                        task.spawn(
                            colorpickerConfig.Callback,
                            current
                        )
                    end
                end

                function object:GetValue()
                    return current
                end

                RegisterFlag(colorpickerConfig.Flag, object)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- ADVANCED BUTTON
            --============================================
            -- Section1:CreateAdvencedButton({
            --     Title = "Click Me",
            --     Desc = "Button description", -- optional
            --     Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
            --     IconAlign = "Right", -- "Left" or "Right". optional
            --     IconColor = Color3.fromHex("#30ff6a"), -- optional
            --     Color = Color3.fromRGB(100, 100, 255), -- optional
            --     Locked = false, -- optional
            --     LockedTitle = "Locked", -- optional
            --     Justify = "Between", -- "Between" or "Center". optional
            --     Callback = function() end,
            -- })
            -- Like CreateButton, but with an icon (left or right of
            -- the title), custom panel/icon coloring, a swappable
            -- locked-state title, and a Justify mode that either
            -- spreads title/icon to opposite edges ("Between", the
            -- default look) or centers them together as one unit
            -- ("Center").

            function Section:CreateAdvencedButton(buttonConfig)
                buttonConfig = buttonConfig or {}

                local title =
                    buttonConfig.Title or "Button"

                local desc =
                    buttonConfig.Desc or ""

                local locked =
                    buttonConfig.Locked == true

                local lockedTitle =
                    buttonConfig.LockedTitle or "Locked"

                local iconAlign =
                    buttonConfig.IconAlign == "Left"
                    and "Left"
                    or "Right"

                local justify =
                    buttonConfig.Justify == "Center"
                    and "Center"
                    or "Between"

                local hasIcon = buttonConfig.Icon ~= nil
                    and buttonConfig.Icon ~= ""

                local panelColor =
                    typeof(buttonConfig.Color) == "Color3"
                    and buttonConfig.Color
                    or COLORS.Panel

                local height =
                    desc ~= "" and 44 or 34

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(1, 0, 0, height),
                        BackgroundColor3 = panelColor,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                local click = New(
                    "TextButton",
                    {
                        Parent = root,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Active = not locked,
                        Text = "",
                        ZIndex = 17,
                    }
                )

                -- Reserve space on whichever side the icon sits, plus
                -- the lock icon slot on the far right when locked, so
                -- text never runs under either. In "Center" justify,
                -- icon + label are laid out as one horizontal unit
                -- instead of pinned to opposite edges.
                local sideInset = (hasIcon and not locked) and 30 or 0
                local lockInset = locked and 34 or 12

                local textPosition, textSize, textAlign

                if justify == "Center" then
                    textPosition = UDim2.fromOffset(
                        11,
                        desc ~= "" and 7 or 0
                    )

                    textSize = UDim2.new(1, -22, 0, 20)
                    textAlign = Enum.TextXAlignment.Center
                else
                    local leftInset =
                        (hasIcon and iconAlign == "Left" and not locked)
                        and 34
                        or 11

                    local rightInset =
                        (hasIcon and iconAlign == "Right" and not locked)
                        and math.max(sideInset, lockInset)
                        or lockInset

                    textPosition = UDim2.fromOffset(
                        leftInset,
                        desc ~= "" and 7 or 0
                    )

                    textSize = UDim2.new(
                        1,
                        -(leftInset + rightInset),
                        0,
                        20
                    )

                    textAlign = Enum.TextXAlignment.Left
                end

                local titleLabel = New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = textPosition,
                        Size = textSize,
                        Text = locked and lockedTitle or title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = textAlign,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(
                                justify == "Center" and 11 or textPosition.X.Offset,
                                28
                            ),
                            Size = UDim2.new(
                                1,
                                justify == "Center" and -22 or -(textPosition.X.Offset + lockInset),
                                0,
                                16
                            ),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = textAlign,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                if hasIcon and not locked then
                    local iconPosition

                    if iconAlign == "Left" then
                        iconPosition = UDim2.fromOffset(
                            11,
                            0.5 * height - 7
                        )
                    else
                        iconPosition = UDim2.new(
                            1,
                            -28,
                            0.5,
                            -7
                        )
                    end

                    local icon = Icon(
                        root,
                        buttonConfig.Icon,
                        15,
                        iconPosition,
                        18
                    )

                    if icon
                        and typeof(buttonConfig.IconColor) == "Color3" then

                        icon.ImageColor3 = buttonConfig.IconColor
                    end
                end

                if locked then
                    local lock = Icon(
                        root,
                        "lock",
                        14,
                        UDim2.new(1, -25, 0.5, -7),
                        18
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                else
                    click.MouseEnter:Connect(function()
                        Tween(
                            root,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )
                    end)

                    click.MouseLeave:Connect(function()
                        Tween(
                            root,
                            FAST,
                            {
                                BackgroundColor3 = panelColor
                            }
                        )
                    end)

                    click.MouseButton1Click:Connect(function()
                        ClickPop(root)

                        if typeof(buttonConfig.Callback) ==
                            "function" then

                            task.spawn(
                                buttonConfig.Callback
                            )
                        end
                    end)
                end

                local object = {
                    Root = root,
                }

                function object:SetLocked(value)
                    locked = value == true
                    click.Active = not locked

                    titleLabel.Text =
                        locked and lockedTitle or title

                    titleLabel.TextColor3 = locked
                        and COLORS.Muted
                        or COLORS.Text
                end

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- ADVANCED TOGGLE
            --============================================
            -- Section1:CreateAdvencedToggle({
            --     Title = "Enable Feature",
            --     Desc = "Toggle description", -- optional
            --     Icon = "power", -- lucide icon or "rbxassetid://". optional
            --     Value = false, -- optional
            --     Type = "Toggle", -- "Toggle" or "Checkbox". optional
            --     Locked = false, -- optional
            --     Callback = function(state) end,
            -- })
            -- Like CreateToggle, but with a leading icon next to the
            -- title, and a Type switch between the usual pill-shaped
            -- switch ("Toggle") or a small square checkbox
            -- ("Checkbox") for the same boolean value.

            function Section:CreateAdvencedToggle(toggleConfig)
                toggleConfig = toggleConfig or {}

                local title =
                    toggleConfig.Title or "Toggle"

                local desc =
                    toggleConfig.Desc or ""

                local state =
                    toggleConfig.Value == true

                local locked =
                    toggleConfig.Locked == true

                local isCheckbox =
                    toggleConfig.Type == "Checkbox"

                local hasIcon = toggleConfig.Icon ~= nil
                    and toggleConfig.Icon ~= ""

                local titleInset =
                    hasIcon and 33 or 11

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 46 or 36
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                if hasIcon then
                    Icon(
                        root,
                        toggleConfig.Icon,
                        15,
                        UDim2.fromOffset(
                            11,
                            desc ~= "" and 10 or 0.5 * 36 - 7.5
                        ),
                        18,
                        true
                    )
                end

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            titleInset,
                            desc ~= "" and 7 or 0
                        ),
                        Size = UDim2.new(1, -(titleInset + 64), 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(titleInset, 28),
                            Size = UDim2.new(1, -(titleInset + 69), 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                local switch, knob

                if isCheckbox then
                    switch = New(
                        "TextButton",
                        {
                            Parent = root,
                            Position = UDim2.new(1, -36, 0.5, -11),
                            Size = UDim2.fromOffset(22, 22),
                            BackgroundColor3 = COLORS.Panel2,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Active = not locked,
                            Text = "",
                            ZIndex = 19,
                        }
                    )

                    AddCorner(switch, 6)

                    Stroke(
                        switch,
                        COLORS.Border,
                        1
                    )

                    knob = Icon(
                        switch,
                        "check",
                        14,
                        UDim2.new(0.5, -7, 0.5, -7),
                        20
                    )

                    if knob then
                        knob.Visible = state
                    end
                else
                    switch = New(
                        "TextButton",
                        {
                            Parent = root,
                            Position = UDim2.new(1, -58, 0.5, -11),
                            Size = UDim2.fromOffset(44, 22),
                            BackgroundColor3 = COLORS.Panel2,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Active = not locked,
                            Text = "",
                            ZIndex = 19,
                        }
                    )

                    AddCorner(switch, 8)

                    Stroke(
                        switch,
                        COLORS.Border,
                        1
                    )

                    knob = New(
                        "Frame",
                        {
                            Parent = switch,
                            Position = UDim2.fromOffset(3, 3),
                            Size = UDim2.fromOffset(16, 16),
                            BackgroundColor3 = COLORS.SubText,
                            BorderSizePixel = 0,
                            ZIndex = 20,
                        }
                    )

                    AddCorner(knob, 6)
                end

                if locked then
                    local lock = Icon(
                        root,
                        "lock",
                        13,
                        isCheckbox
                            and UDim2.new(1, -30, 0.5, -6.5)
                            or UDim2.new(1, -52, 0.5, -6.5),
                        21
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                end

                local function updateToggle(_, colors)
                    if not root.Parent then
                        return
                    end

                    if isCheckbox then
                        switch.BackgroundColor3 =
                            state and colors.Accent or COLORS.Panel2

                        if knob then
                            knob.Visible = state
                        end
                    else
                        if state then
                            Tween(
                                switch,
                                FAST,
                                {
                                    BackgroundColor3 = colors.Accent
                                }
                            )

                            Tween(
                                knob,
                                FAST,
                                {
                                    Position = UDim2.new(1, -19, 0.5, -8),
                                    BackgroundColor3 = COLORS.White,
                                }
                            )
                        else
                            Tween(
                                switch,
                                FAST,
                                {
                                    BackgroundColor3 = COLORS.Panel2
                                }
                            )

                            Tween(
                                knob,
                                FAST,
                                {
                                    Position = UDim2.fromOffset(3, 3),
                                    BackgroundColor3 = COLORS.SubText,
                                }
                            )
                        end
                    end
                end

                RegisterTheme(updateToggle)

                local object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    state = value == true
                    updateToggle(nil, CurrentTheme())

                    if callCallback ~= false
                        and typeof(toggleConfig.Callback) ==
                            "function" then

                        task.spawn(
                            toggleConfig.Callback,
                            state
                        )
                    end
                end

                function object:GetValue()
                    return state
                end

                function object:SetLocked(value)
                    locked = value == true
                    switch.Active = not locked
                end

                RegisterFlag(toggleConfig.Flag, object)

                switch.MouseButton1Click:Connect(function()
                    if locked then
                        return
                    end

                    ClickPop(switch)

                    object:SetValue(
                        not state,
                        true
                    )
                end)

                updateToggle(
                    nil,
                    CurrentTheme()
                )

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- ADVANCED SLIDER
            --============================================
            -- Section1:CreateAdvencedSlider({
            --     Title = "Effect Strength",
            --     Desc = "Slider description", -- optional
            --     Icon = "gauge", -- lucide icon or "rbxassetid://". optional
            --     Value = { Min = 0, Max = 100, Default = 50 },
            --     Step = 1, -- optional
            --     Locked = false, -- optional
            --     Callback = function(value) end,
            -- })
            -- Same track/knob/drag behavior as CreateSlider, plus a
            -- leading icon next to the title and a Locked option that
            -- freezes the knob and dims the whole row.

            function Section:CreateAdvencedSlider(sliderConfig)
                sliderConfig = sliderConfig or {}

                local title =
                    sliderConfig.Title or "Slider"

                local desc =
                    sliderConfig.Desc or ""

                local locked =
                    sliderConfig.Locked == true

                local hasIcon = sliderConfig.Icon ~= nil
                    and sliderConfig.Icon ~= ""

                local titleInset =
                    hasIcon and 33 or 11

                local range =
                    sliderConfig.Value or {}

                local minimum =
                    tonumber(range.Min) or 0

                local maximum =
                    tonumber(range.Max) or 100

                local current =
                    tonumber(range.Default)
                    or minimum

                local step =
                    tonumber(sliderConfig.Step)
                    or 1

                if maximum < minimum then
                    minimum, maximum = maximum, minimum
                end

                local trackHeight = 10
                local trackY = 30
                local descY = trackY + trackHeight + 8

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and (descY + 20) or (trackY + trackHeight + 12)
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        ZIndex = 15,
                    }
                )

                AddCorner(root, 10)

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                if hasIcon then
                    Icon(
                        root,
                        sliderConfig.Icon,
                        14,
                        UDim2.fromOffset(11, 9),
                        18,
                        true
                    )
                end

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(titleInset, 8),
                        Size = UDim2.new(1, -(titleInset + 64), 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                local valueLabel = New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -60, 0, 8),
                        Size = UDim2.fromOffset(50, 20),
                        Text = tostring(current),
                        TextColor3 = locked
                            and COLORS.Muted
                            or CurrentTheme().Accent2,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 18,
                    }
                )

                local sliderHolder = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(11, trackY),
                        Size = UDim2.new(1, -22, 0, trackHeight),
                        BackgroundTransparency = 1,
                        ZIndex = 18,
                    }
                )

                local track = New(
                    "Frame",
                    {
                        Parent = sliderHolder,
                        Position = UDim2.new(0, 0, 0.5, -(trackHeight / 2)),
                        Size = UDim2.new(1, 0, 0, trackHeight),
                        BackgroundColor3 = CurrentTheme().Accent,
                        BackgroundTransparency = 0.85,
                        BorderSizePixel = 0,
                        ZIndex = 18,
                    }
                )

                AddCorner(track, math.floor(trackHeight / 2))

                Stroke(
                    track,
                    COLORS.Border,
                    1
                )

                local fill = New(
                    "Frame",
                    {
                        Parent = track,
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundColor3 = locked
                            and COLORS.Muted
                            or CurrentTheme().Accent,
                        BorderSizePixel = 0,
                        ZIndex = 19,
                    }
                )

                AddCorner(fill, math.floor(trackHeight / 2))

                local knobSize = trackHeight + 6

                local knob = New(
                    "Frame",
                    {
                        Parent = track,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.fromOffset(knobSize, knobSize),
                        BackgroundColor3 = COLORS.White,
                        BorderSizePixel = 0,
                        ZIndex = 20,
                    }
                )

                AddCorner(knob, 4)

                Stroke(
                    knob,
                    COLORS.Border,
                    1
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, descY),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                local drag = New(
                    "TextButton",
                    {
                        Parent = sliderHolder,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Active = not locked,
                        Text = "",
                        ZIndex = 21,
                    }
                )

                local function roundStep(value)
                    value = math.clamp(
                        value,
                        minimum,
                        maximum
                    )

                    local steps = math.floor(
                        ((value - minimum) / step) + 0.5
                    )

                    return math.clamp(
                        minimum + (steps * step),
                        minimum,
                        maximum
                    )
                end

                local function set(value, callCallback)
                    current = roundStep(value)

                    local percent = (
                        current - minimum
                    ) / math.max(
                        maximum - minimum,
                        0.00001
                    )

                    fill.Size = UDim2.new(
                        percent,
                        0,
                        1,
                        0
                    )

                    knob.Position = UDim2.new(
                        percent,
                        0,
                        0.5,
                        0
                    )

                    valueLabel.Text =
                        tostring(current)

                    if callCallback
                        and typeof(sliderConfig.Callback) ==
                            "function" then

                        task.spawn(
                            sliderConfig.Callback,
                            current
                        )
                    end
                end

                local function updateTheme(_, colors)
                    if not root.Parent then
                        return
                    end

                    track.BackgroundColor3 =
                        colors.Accent

                    if not locked then
                        fill.BackgroundColor3 =
                            colors.Accent

                        valueLabel.TextColor3 =
                            colors.Accent2
                    end
                end

                RegisterTheme(updateTheme)

                local moving = false

                local function xToValue(x)
                    local alpha = math.clamp(
                        (
                            x
                            - sliderHolder.AbsolutePosition.X
                        )
                        / math.max(
                            sliderHolder.AbsoluteSize.X,
                            1
                        ),
                        0,
                        1
                    )

                    set(
                        minimum
                            + (
                                maximum
                                - minimum
                            ) * alpha,
                        true
                    )
                end

                drag.InputBegan:Connect(function(input)
                    if locked then
                        return
                    end

                    if input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                        or input.UserInputType ==
                        Enum.UserInputType.Touch then

                        moving = true
                        ClickPop(knob)
                        xToValue(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if moving
                        and (
                            input.UserInputType ==
                                Enum.UserInputType.MouseMovement
                            or input.UserInputType ==
                                Enum.UserInputType.Touch
                        ) then

                        xToValue(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                        or input.UserInputType ==
                        Enum.UserInputType.Touch then

                        moving = false
                    end
                end)

                local object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    set(
                        tonumber(value) or minimum,
                        callCallback ~= false
                    )
                end

                function object:GetValue()
                    return current
                end

                function object:SetLocked(value)
                    locked = value == true
                    drag.Active = not locked
                end

                RegisterFlag(sliderConfig.Flag, object)

                function object:SetRange(minimumValue, maximumValue, default)
                    minimum = tonumber(minimumValue)
                        or minimum

                    maximum = tonumber(maximumValue)
                        or maximum

                    if maximum < minimum then
                        minimum, maximum = maximum, minimum
                    end

                    if default ~= nil then
                        current = tonumber(default)
                            or minimum
                    end

                    set(current, false)
                end

                set(current, false)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- ADVANCED INPUT
            --============================================
            -- Section1:CreateAdvencedInput({
            --     Title = "Username",
            --     Desc = "Enter your username", -- optional
            --     Icon = "user", -- lucide icon or "rbxassetid://". optional
            --     Type = "Default", -- "Default" or "Textarea". optional
            --     Placeholder = "Type here...", -- optional
            --     Value = "", -- optional
            --     Locked = false, -- optional
            --     Callback = function(text) end,
            -- })
            -- Like CreateInput, but with a configurable leading icon
            -- (in place of the fixed pencil) and a Type switch: a
            -- single-line "Default" box (the usual layout) or a
            -- taller multi-line "Textarea" box for longer text.

            function Section:CreateAdvencedInput(inputConfig)
                inputConfig = inputConfig or {}

                local title =
                    inputConfig.Title or "Input"

                local desc =
                    inputConfig.Desc or ""

                local locked =
                    inputConfig.Locked == true

                local isTextarea =
                    inputConfig.Type == "Textarea"

                local icon = inputConfig.Icon
                if icon == nil then
                    icon = "pencil"
                end

                local hasIcon = icon ~= ""

                local inputY =
                    desc ~= "" and 40 or 24

                local boxHeight =
                    isTextarea and 64 or 26

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            inputY + boxHeight + 10
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                AddCorner(root, 10)

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 7),
                        Size = UDim2.new(1, -20, 0, 19),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 27),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local box = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(10, inputY),
                        Size = UDim2.new(1, -20, 0, boxHeight),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        ZIndex = 18,
                    }
                )

                AddCorner(box, 8)

                Stroke(
                    box,
                    COLORS.Border,
                    1
                )

                local textBox = New(
                    "TextBox",
                    {
                        Parent = box,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, isTextarea and 6 or 0),
                        Size = UDim2.new(
                            1,
                            hasIcon and -38 or -16,
                            isTextarea and 1 or 1,
                            isTextarea and -12 or 0
                        ),
                        Text = inputConfig.Value or "",
                        PlaceholderText = inputConfig.Placeholder or "",
                        PlaceholderColor3 = COLORS.Muted,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = isTextarea
                            and Enum.TextYAlignment.Top
                            or Enum.TextYAlignment.Center,
                        TextWrapped = isTextarea,
                        MultiLine = isTextarea,
                        TextEditable = not locked,
                        ZIndex = 19,
                    }
                )

                if hasIcon then
                    local iconPosition = isTextarea
                        and UDim2.fromOffset(box.Size.X.Offset - 24, 7)
                        or UDim2.new(1, -24, 0.5, -7)

                    Icon(
                        box,
                        icon,
                        14,
                        iconPosition,
                        19,
                        true
                    )
                end

                if locked then
                    local lock = Icon(
                        root,
                        "lock",
                        13,
                        UDim2.new(1, -22, 0, 8),
                        18
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end
                end

                textBox.FocusLost:Connect(function(enterPressed)
                    if locked then
                        return
                    end

                    if typeof(inputConfig.Callback) ==
                        "function" then

                        task.spawn(
                            inputConfig.Callback,
                            textBox.Text,
                            enterPressed
                        )
                    end
                end)

                local object = {
                    Root = root,
                    TextBox = textBox,
                }

                function object:GetValue()
                    return textBox.Text
                end

                function object:SetValue(value)
                    textBox.Text = tostring(value or "")
                end

                function object:SetLocked(value)
                    locked = value == true
                    textBox.TextEditable = not locked

                    textBox.TextColor3 = locked
                        and COLORS.Muted
                        or COLORS.Text
                end

                RegisterFlag(inputConfig.Flag, object)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- CREATE PAGE (alias)
            --============================================
            -- Section1:CreatePage({ Title = "Movement" }) works the
            -- same as Tab:CreatePage({ Title = "Movement" }) - pages
            -- belong to the Tab, not any one section, but this alias
            -- lets it be called from a Section reference too since
            -- that's how it reads most naturally when scripting.

            function Section:CreatePage(pageConfig)
                return Tab:CreatePage(pageConfig)
            end

            return Section
        end

        table.insert(
            Window.Tabs,
            Tab
        )

        if not Window.ActiveTab then
            Tab:Select()
        end

        return Tab
    end

    --====================================================
    -- STORE WINDOW
    --====================================================

    DarkyUIGen2._Window = Window

    -- This is the icon source for future notifications.
    if config.Image ~= nil then
        DarkyUIGen2.CurrentImage = config.Image
    end

    --====================================================
    -- OPEN MAIN UI
    --====================================================

    if not Window._KeyLocked then
        main.Size = UDim2.fromOffset(
            WINDOW_WIDTH,
            0
        )

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(
                    WINDOW_WIDTH,
                    WINDOW_HEIGHT
                )
            }
        )
    end

    return Window
end

--========================================================
-- SAVE MANAGER / INTERFACE MANAGER UI BUILDERS
--========================================================
-- Added down here (rather than next to the rest of SaveManager /
-- InterfaceManager above) since they need New/AddCorner/Stroke/Icon,
-- which aren't defined yet that early in the file.

function SaveManager:BuildConfigSection(Tab)
    if not Tab or typeof(Tab.CreateSection) ~= "function" then
        return nil
    end

    local Section = Tab:CreateSection({
        Title = "Config",
        Icon = "save",
    })

    local nameValue = ""

    Section:CreateInput({
        Title = "Config name",
        Placeholder = "MyConfig",
        Callback = function(text)
            nameValue = text
        end,
    })

    local configDropdown = Section:CreateDropdown({
        Title = "Saved configs",
        Values = self:ListConfigs(),
        Callback = function() end,
    })

    local function RefreshList()
        if configDropdown
            and typeof(configDropdown.Refresh) == "function" then

            configDropdown:Refresh(self:ListConfigs())
        end
    end

    Section:CreateButton({
        Title = "Save",
        Callback = function()
            if nameValue == "" then
                return
            end

            self:Save(nameValue)
            RefreshList()
        end,
    })

    Section:CreateButton({
        Title = "Load",
        Callback = function()
            local target = nameValue

            if (target == nil or target == "")
                and configDropdown
                and typeof(configDropdown.GetValue) ==
                    "function" then

                target = configDropdown:GetValue()
            end

            if target and target ~= "" then
                self:Load(target)
            end
        end,
    })

    Section:CreateButton({
        Title = "Delete",
        Callback = function()
            local target = nameValue

            if (target == nil or target == "")
                and configDropdown
                and typeof(configDropdown.GetValue) ==
                    "function" then

                target = configDropdown:GetValue()
            end

            if target and target ~= "" then
                self:Delete(target)
                RefreshList()
            end
        end,
    })

    Section:CreateButton({
        Title = "Set as autoload",
        Callback = function()
            local target = nameValue

            if (target == nil or target == "")
                and configDropdown
                and typeof(configDropdown.GetValue) ==
                    "function" then

                target = configDropdown:GetValue()
            end

            if target and target ~= "" then
                self:SetAutoloadConfig(target)
            end
        end,
    })

    return Section
end

function InterfaceManager:BuildInterfaceSection(Tab)
    if not Tab or typeof(Tab.CreateSection) ~= "function" then
        return nil
    end

    local Section = Tab:CreateSection({
        Title = "Interface",
        Icon = "palette",
    })

    local themeNames = {}

    for name in pairs(DarkyUIGen2.Themes) do
        table.insert(themeNames, name)
    end

    table.sort(themeNames)

    local manager = self

    Section:CreateDropdown({
        Title = "Theme",
        Values = themeNames,
        Value = DarkyUIGen2.CurrentTheme,
        Callback = function(value)
            if typeof(DarkyUIGen2.SetTheme) == "function" then
                DarkyUIGen2:SetTheme(value)
            end

            manager:SaveSettings()
        end,
    })

    return Section
end

return DarkyUIGen2
