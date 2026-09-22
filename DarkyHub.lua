local Config = {
    ServiceId       = 30662,
    PlatoSecret     = "ae477d26-f663-484f-aa2b-aad70f6874bd",

    Secret          = "1234",

    MainScriptURL   = "https://raw.githubusercontent.com/sokpanha10000-oss/DarkyUI/refs/heads/main/DarkyHUB.lua",

    ShowDiscord     = false,
    DiscordURL      = "https://discord.gg/kT55J724BK",

    ShowInstagram   = false,
    InstagramURL    = "https://www.instagram.com/oyb0i/",

    ShowYoutube     = false,
    YoutubeURL      = "https://www.youtube.com/channel/UCAlXXV1Hbvf7WbfXARuVtiQ",

    KeyFileName     = "Mykey.txt",

    OldGuiName      = "anything",
    MainGuiName     = "anything",

    HubName         = "Darky Hub",
    HubDescription  = "Get key and paste"
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local fSetClipboard = setclipboard or toclipboard or function() end
local fGetHwid = gethwid or function()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end

local lEncode, lDecode, lDigest = a3, aw, Z

local useNonce = true

local cachedLink = ""
local cachedTime = 0

local HOSTS = {
    "https://api.platoboost.com",
    "https://api.platoboost.net"
}

local host = HOSTS[1]

local function safeRequest(options)
    local req =
        request
        or http_request
        or syn_request
        or (http and http.request)

    if not req then
        return nil, "HTTP requests are not supported"
    end

    local ok, response = pcall(function()
        return req(options)
    end)

    if not ok then
        return nil, "Connection Error: " .. tostring(response)
    end

    if type(response) ~= "table" then
        return nil, "Invalid HTTP response"
    end

    return response
end

local function decodeResponse(response)
    if not response then
        return nil
    end

    if not response.Body then
        return nil
    end

    local ok, result = pcall(function()
        return lDecode(response.Body)
    end)

    if ok and type(result) == "table" then
        return result
    end

    return nil
end

local function getResponseMessage(response)
    local decoded = decodeResponse(response)

    if not decoded then
        return nil
    end

    if decoded.message then
        return tostring(decoded.message)
    end

    if decoded.error then
        return tostring(decoded.error)
    end

    if type(decoded.data) == "table" then
        if decoded.data.message then
            return tostring(decoded.data.message)
        end

        if decoded.data.error then
            return tostring(decoded.data.error)
        end
    end

    return nil
end

local function checkConnectivity(base)
    local response = safeRequest({
        Url = base .. "/public/connectivity",
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if not response then
        return false
    end

    local status = tonumber(response.StatusCode or 0)

    if status == 200 or status == 429 then
        return true
    end

    return false
end

local function checkConnectivityAll()
    if checkConnectivity(host) then
        return true
    end

    for _, base in ipairs(HOSTS) do
        if base ~= host and checkConnectivity(base) then
            host = base
            return true
        end
    end

    return false
end

local function generateNonce()
    local result = ""

    for _ = 1, 16 do
        result = result .. string.char(
            math.floor(math.random() * 26) + 97
        )
    end

    return result
end

local function cacheLink()
    if cachedTime + 600 > os.time()
        and cachedLink ~= "" then

        return true, cachedLink
    end

    if not checkConnectivityAll() then
        return false, "Delta/Network Error! Use VPN or change Executor."
    end

    local hwid = tostring(fGetHwid())

    local response, err = safeRequest({
        Url = host .. "/public/start",
        Method = "POST",
        Body = lEncode({
            service = Config.ServiceId,
            identifier = lDigest(hwid)
        }),
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if not response then
        return false, err or "Connection Error"
    end

    local status = tonumber(response.StatusCode or 0)

    if status == 429 then
        return false, "Rate limited. Please try again shortly."
    end

    if status ~= 200 then
        local msg = getResponseMessage(response)

        return false,
            "HTTP " .. tostring(status) ..
            (msg and (" - " .. msg) or "")
    end

    local decoded = decodeResponse(response)

    if not decoded then
        return false, "Invalid server response."
    end

    if not decoded.success then
        return false, tostring(decoded.message or "Unable to create key link.")
    end

    if type(decoded.data) ~= "table"
        or not decoded.data.url then

        return false, "Server did not return a key link."
    end

    cachedLink = tostring(decoded.data.url)
    cachedTime = os.time()

    return true, cachedLink
end

local function redeemKey(key)
    key = tostring(key or "")
    key = key:gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        return false, "Enter a key."
    end

    if not checkConnectivityAll() then
        return false, "PlatoBoost connection failed."
    end

    local nonce = generateNonce()

    local body = {
        identifier = lDigest(tostring(fGetHwid())),
        key = key
    }

    if useNonce then
        body.nonce = nonce
    end

    local response, err = safeRequest({
        Url = host .. "/public/redeem/" .. tostring(Config.ServiceId),
        Method = "POST",
        Body = lEncode(body),
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if not response then
        return false, err or "Connection Error"
    end

    local status = tonumber(response.StatusCode or 0)

    if status == 429 then
        return false, "Too many requests. Try again shortly."
    end

    if status == 401 then
        return false, "Unauthorized request (HTTP 401)."
    end

    if status == 403 then
        return false, "Access denied by PlatoBoost (HTTP 403)."
    end

    if status == 404 then
        return false,
            "Service/API not found (HTTP 404). Check ServiceId."
    end

    if status >= 500 then
        return false,
            "PlatoBoost server error (HTTP " ..
            tostring(status) .. ")."
    end

    if status ~= 200 then
        local msg = getResponseMessage(response)

        return false,
            "HTTP " .. tostring(status) ..
            (msg and (" - " .. msg) or "")
    end

    local decoded = decodeResponse(response)

    if not decoded then
        return false, "Invalid server response."
    end

    if not decoded.success then
        return false,
            tostring(decoded.message or "Invalid key.")
    end

    if type(decoded.data) ~= "table" then
        return false, "Invalid verification data."
    end

    if decoded.data.valid ~= true then
        return false,
            tostring(decoded.message or "Invalid or expired key.")
    end

    if useNonce then
        if not decoded.data.hash then
            return false, "Missing integrity hash."
        end

        local expectedHash = lDigest(
            "true-" ..
            nonce ..
            "-" ..
            Config.PlatoSecret
        )

        if tostring(decoded.data.hash):lower()
            ~= tostring(expectedHash):lower() then

            return false, "Integrity Check Failed"
        end
    end

    if writefile then
        pcall(function()
            writefile(Config.KeyFileName, key)
        end)
    end

    return true, "Success"
end

local function destroyGui(name)
    for _, parent in ipairs({
        CoreGui,
        PlayerGui
    }) do
        local gui = parent:FindFirstChild(name)

        if gui then
            pcall(function()
                gui:Destroy()
            end)
        end
    end
end

local function StartMainScript()
    destroyGui(Config.OldGuiName)

    _G[Config.Secret] = true

    local ok, result = pcall(function()
        local source = game:HttpGet(Config.MainScriptURL)

        if not source or source == "" then
            error("Main script returned empty source")
        end

        local loader = loadstring(source)

        if not loader then
            error("Failed to compile main script")
        end

        loader()
    end)

    if not ok then
        warn("[Darky Hub] Main Script Error: " .. tostring(result))
    end
end

local function Create(className, parent, properties)
    local object = Instance.new(className)
    object.Parent = parent

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    return object
end

local function Corner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = object

    return corner
end

local function Stroke(object, color, thickness, transparency)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Thickness = thickness or 1
    uiStroke.Transparency = transparency or 0
    uiStroke.Parent = object

    return uiStroke
end

local function Tween(object, duration, properties)
    local ok, result = pcall(function()
        local t = TweenService:Create(
            object,
            TweenInfo.new(
                duration,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ),
            properties
        )

        t:Play()

        return t
    end)

    return ok and result
end

local function MakeDraggable(handle, target)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function CreateGUI()
    destroyGui("DarkyHub_KeySystem")

    local ScreenGui = Create("ScreenGui", CoreGui, {
        Name = "DarkyHub_KeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })

    local Glow = Create("Frame", ScreenGui, {
        Size = UDim2.fromOffset(470, 380),
        Position = UDim2.new(0.5, -235, 0.5, -190),
        BackgroundColor3 = Color3.fromRGB(70, 150, 255),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 0
    })

    Corner(Glow, 30)

    local MainFrame = Create("Frame", ScreenGui, {
        Size = UDim2.fromOffset(440, 350),
        Position = UDim2.new(0.5, -220, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(14, 17, 23),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 2
    })

    Corner(MainFrame, 20)

    local MainStroke = Stroke(
        MainFrame,
        Color3.fromRGB(255, 255, 255),
        1,
        0.78
    )

    local Header = Create("Frame", MainFrame, {
        Size = UDim2.new(1, 0, 0, 82),
        BackgroundTransparency = 1,
        ZIndex = 3
    })

    MakeDraggable(Header, MainFrame)

    local IconBox = Create("Frame", Header, {
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.fromOffset(20, 18),
        BackgroundColor3 = Color3.fromRGB(27, 34, 45),
        BorderSizePixel = 0,
        ZIndex = 4
    })

    Corner(IconBox, 14)

    Stroke(
        IconBox,
        Color3.fromRGB(255, 255, 255),
        1,
        0.84
    )

    Create("TextLabel", IconBox, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "D",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 23,
        ZIndex = 5
    })

    Create("TextLabel", Header, {
        Size = UDim2.new(1, -150, 0, 30),
        Position = UDim2.fromOffset(78, 14),
        BackgroundTransparency = 1,
        Text = Config.HubName,
        TextColor3 = Color3.fromRGB(245, 248, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    })

    Create("TextLabel", Header, {
        Size = UDim2.new(1, -150, 0, 22),
        Position = UDim2.fromOffset(79, 44),
        BackgroundTransparency = 1,
        Text = Config.HubDescription,
        TextColor3 = Color3.fromRGB(150, 159, 174),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    })

    local CloseBtn = Create("TextButton", Header, {
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -52, 0, 22),
        BackgroundColor3 = Color3.fromRGB(28, 32, 40),
        BackgroundTransparency = 0,
        Text = "X",
        TextColor3 = Color3.fromRGB(200, 205, 214),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        ZIndex = 7
    })

    Corner(CloseBtn, 12)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local Accent = Create("Frame", MainFrame, {
        Size = UDim2.new(1, -40, 0, 2),
        Position = UDim2.fromOffset(20, 80),
        BackgroundColor3 = Color3.fromRGB(80, 170, 255),
        BorderSizePixel = 0,
        ZIndex = 4
    })

    local AccentGradient = Create("UIGradient", Accent, {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(80, 170, 255)
            ),
            ColorSequenceKeypoint.new(
                0.5,
                Color3.fromRGB(255, 255, 255)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(135, 90, 255)
            )
        })
    })

    task.spawn(function()
        while ScreenGui.Parent do
            AccentGradient.Offset = Vector2.new(-1, 0)

            Tween(
                AccentGradient,
                1.2,
                {
                    Offset = Vector2.new(1, 0)
                }
            )

            task.wait(1.3)
        end
    end)

    local Body = Create("Frame", MainFrame, {
        Size = UDim2.new(1, -40, 1, -105),
        Position = UDim2.fromOffset(20, 94),
        BackgroundTransparency = 1,
        ZIndex = 3
    })

    local CurrentY = 0

    local SocialFrame = Create("Frame", Body, {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 3
    })

    local SocialLayout = Create("UIListLayout", SocialFrame, {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local function AddSocial(
        text,
        url,
        color
    )
        local button = Create("TextButton", SocialFrame, {
            Size = UDim2.fromOffset(120, 34),
            BackgroundColor3 = Color3.fromRGB(29, 35, 44),
            Text = text,
            TextColor3 = Color3.fromRGB(235, 239, 247),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 4
        })

        Corner(button, 11)

        Stroke(
            button,
            Color3.fromRGB(255, 255, 255),
            1,
            0.87
        )

        button.MouseButton1Click:Connect(function()
            fSetClipboard(url)

            Status.Text = text .. " link copied!"
            Status.TextColor3 = color
            StatusDot.BackgroundColor3 = color

            if text == "DISCORD"
                and syn
                and syn.request then

                local inviteCode = string.match(
                    url,
                    "discord%.gg/([%w-]+)"
                )

                if inviteCode then
                    pcall(function()
                        syn.request({
                            Url =
                                "http://localhost:1111/discord?invite="
                                .. inviteCode,
                            Method = "GET"
                        })
                    end)
                end
            end
        end)
    end

    if Config.ShowDiscord then
        AddSocial(
            "DISCORD",
            Config.DiscordURL,
            Color3.fromRGB(88, 101, 242)
        )
    end

    if Config.ShowInstagram then
        AddSocial(
            "INSTAGRAM",
            Config.InstagramURL,
            Color3.fromRGB(225, 48, 108)
        )
    end

    if Config.ShowYoutube then
        AddSocial(
            "YOUTUBE",
            Config.YoutubeURL,
            Color3.fromRGB(255, 60, 60)
        )
    end

    local hasSocial =
        Config.ShowDiscord
        or Config.ShowInstagram
        or Config.ShowYoutube

    if hasSocial then
        CurrentY = 48
    else
        SocialFrame.Visible = false
    end

    local KeyCard = Create("Frame", Body, {
        Size = UDim2.new(1, 0, 0, 68),
        Position = UDim2.fromOffset(0, CurrentY),
        BackgroundColor3 = Color3.fromRGB(21, 26, 34),
        BorderSizePixel = 0,
        ZIndex = 4
    })

    Corner(KeyCard, 14)

    Stroke(
        KeyCard,
        Color3.fromRGB(255, 255, 255),
        1,
        0.9
    )

    local KeyInput = Create("TextBox", KeyCard, {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.fromOffset(15, 0),
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Enter Key...",
        PlaceholderColor3 = Color3.fromRGB(110, 118, 132),
        Text = "",
        TextColor3 = Color3.fromRGB(245, 247, 251),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })

    local PasteBtn = Create("TextButton", KeyCard, {
        Size = UDim2.fromOffset(65, 34),
        Position = UDim2.new(1, -75, 0.5, -17),
        BackgroundColor3 = Color3.fromRGB(35, 42, 53),
        Text = "PASTE",
        TextColor3 = Color3.fromRGB(205, 211, 221),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        AutoButtonColor = false,
        ZIndex = 6
    })

    Corner(PasteBtn, 10)

    PasteBtn.MouseButton1Click:Connect(function()
        if getclipboard then
            local ok, value = pcall(getclipboard)

            if ok and value then
                KeyInput.Text = tostring(value)
            end
        end
    end)

    CurrentY = CurrentY + 82

    local StatusCard = Create("Frame", Body, {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, CurrentY),
        BackgroundTransparency = 1,
        ZIndex = 4
    })

    StatusDot = Create("Frame", StatusCard, {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(4, 11),
        BackgroundColor3 = Color3.fromRGB(150, 159, 174),
        BorderSizePixel = 0,
        ZIndex = 5
    })

    Corner(StatusDot, 8)

    Status = Create("TextLabel", StatusCard, {
        Name = "StatusLabel",
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.fromOffset(19, 0),
        BackgroundTransparency = 1,
        Text = "Waiting for input...",
        TextColor3 = Color3.fromRGB(150, 159, 174),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })

    CurrentY = CurrentY + 36

    local VerifyBtn = Create("TextButton", Body, {
        Size = UDim2.new(0.5, -5, 0, 44),
        Position = UDim2.fromOffset(0, CurrentY),
        BackgroundColor3 = Color3.fromRGB(50, 130, 255),
        Text = "VERIFY KEY",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 5
    })

    Corner(VerifyBtn, 13)

    Stroke(
        VerifyBtn,
        Color3.fromRGB(255, 255, 255),
        1,
        0.72
    )

    local GetKeyBtn = Create("TextButton", Body, {
        Size = UDim2.new(0.5, -5, 0, 44),
        Position = UDim2.new(0.5, 10, 0, CurrentY),
        BackgroundColor3 = Color3.fromRGB(29, 35, 44),
        Text = "GET KEY",
        TextColor3 = Color3.fromRGB(235, 239, 247),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 5
    })

    Corner(GetKeyBtn, 13)

    Stroke(
        GetKeyBtn,
        Color3.fromRGB(255, 255, 255),
        1,
        0.84
    )

    local Footer = Create("TextLabel", MainFrame, {
        Size = UDim2.new(1, -40, 0, 16),
        Position = UDim2.new(0, 20, 1, -22),
        BackgroundTransparency = 1,
        Text = "POWERED BY DARKY HUB",
        TextColor3 = Color3.fromRGB(75, 84, 99),
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        ZIndex = 4
    })

    local busy = false

    local function setStatus(text, color)
        Status.Text = tostring(text)
        Status.TextColor3 = color
        StatusDot.BackgroundColor3 = color
    end

    VerifyBtn.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        local key = KeyInput.Text

        if not key or key:gsub("%s+", "") == "" then
            setStatus(
                "Enter a key first.",
                Color3.fromRGB(255, 170, 80)
            )
            return
        end

        busy = true

        VerifyBtn.Text = "VERIFYING..."

        setStatus(
            "Verifying with PlatoBoost...",
            Color3.fromRGB(80, 175, 255)
        )

        task.spawn(function()
            local success, msg = redeemKey(key)

            if success then
                setStatus(
                    "Success! Loading...",
                    Color3.fromRGB(80, 255, 145)
                )

                task.wait(0.5)

                if ScreenGui.Parent then
                    ScreenGui:Destroy()
                end

                StartMainScript()
                return
            end

            busy = false
            VerifyBtn.Text = "VERIFY KEY"

            setStatus(
                tostring(msg),
                Color3.fromRGB(255, 80, 100)
            )
        end)
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        busy = true
        GetKeyBtn.Text = "LOADING..."

        setStatus(
            "Getting key link...",
            Color3.fromRGB(80, 175, 255)
        )

        task.spawn(function()
            local success, result = cacheLink()

            busy = false
            GetKeyBtn.Text = "GET KEY"

            if success then
                fSetClipboard(result)

                setStatus(
                    "Link copied to clipboard!",
                    Color3.fromRGB(80, 255, 145)
                )
            else
                setStatus(
                    tostring(result),
                    Color3.fromRGB(255, 80, 100)
                )
            end
        end)
    end)

    if isfile and readfile then
        local exists = false

        pcall(function()
            exists = isfile(Config.KeyFileName)
        end)

        if exists then
            local savedKey = ""

            pcall(function()
                savedKey = readfile(Config.KeyFileName)
            end)

            savedKey = tostring(savedKey or "")

            if savedKey ~= "" then
                KeyInput.Text = savedKey

                setStatus(
                    "Saved key found, verifying...",
                    Color3.fromRGB(80, 175, 255)
                )

                task.spawn(function()
                    local success, msg =
                        redeemKey(savedKey)

                    if success then
                        setStatus(
                            "Auto-login success!",
                            Color3.fromRGB(80, 255, 145)
                        )

                        task.wait(0.5)

                        if ScreenGui.Parent then
                            ScreenGui:Destroy()
                        end

                        StartMainScript()
                    else
                        setStatus(
                            "Saved key invalid: "
                            .. tostring(msg),
                            Color3.fromRGB(255, 170, 80)
                        )
                    end
                end)
            end
        end
    end

    task.spawn(function()
        while ScreenGui.Parent do
            Tween(MainStroke, 1.1, {
                Transparency = 0.58
            })

            task.wait(1.1)

            if not ScreenGui.Parent then
                break
            end

            Tween(MainStroke, 1.1, {
                Transparency = 0.78
            })

            task.wait(1.1)
        end
    end)
end

if PlayerGui:FindFirstChild(Config.MainGuiName)
    or CoreGui:FindFirstChild(Config.MainGuiName) then

    StartMainScript()
    return
end

CreateGUI()
