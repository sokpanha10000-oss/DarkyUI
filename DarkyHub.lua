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
    HubDescription  = "Paste your key to continue"
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local fSetClipboard = setclipboard or toclipboard or function() end

local function getHwid()
    if gethwid then
        local ok, result = pcall(gethwid)
        if ok and result then
            return tostring(result)
        end
    end

    local ok, result = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)

    if ok and result then
        return tostring(result)
    end

    return "unknown"
end

local function jsonEncode(data)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if ok then
        return result
    end

    return nil
end

local function jsonDecode(data)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(data)
    end)

    if ok and type(result) == "table" then
        return result
    end

    return nil
end

local function getRequest()
    if request then
        return request
    end

    if http_request then
        return http_request
    end

    if syn and syn.request then
        return syn.request
    end

    if http and http.request then
        return http.request
    end

    return nil
end

local function safeRequest(options)
    local req = getRequest()

    if not req then
        return nil, "HTTP requests are not supported by this executor."
    end

    local ok, response = pcall(function()
        return req(options)
    end)

    if not ok then
        return nil, "Request failed: " .. tostring(response)
    end

    if type(response) ~= "table" then
        return nil, "Invalid HTTP response."
    end

    local status = tonumber(
        response.StatusCode
        or response.Status
        or response.status_code
        or 0
    )

    local body = response.Body
        or response.body
        or ""

    return {
        StatusCode = status,
        Body = tostring(body)
    }
end

local function responseMessage(response)
    if not response then
        return nil
    end

    local decoded = jsonDecode(response.Body)

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

local HOSTS = {
    "https://api.platoboost.com",
    "https://api.platoboost.net"
}

local host = nil

local function connectivityCheck(base)
    local response, err = safeRequest({
        Url = base .. "/public/connectivity",
        Method = "GET",
        Headers = {
            ["Accept"] = "application/json",
            ["User-Agent"] = "DarkyHub/1.0"
        }
    })

    if not response then
        return false, err
    end

    if response.StatusCode == 429 then
        return false, "Rate limited by " .. base
    end

    if response.StatusCode ~= 200 then
        return false, "Connectivity HTTP " .. tostring(response.StatusCode)
    end

    local decoded = jsonDecode(response.Body)

    if not decoded then
        return false, "Connectivity returned invalid JSON."
    end

    if decoded.success == false then
        return false, tostring(decoded.message or "Connectivity check failed.")
    end

    return true
end

local function ensureHost()
    if host then
        local ok = connectivityCheck(host)
        if ok then
            return true
        end
    end

    for _, base in ipairs(HOSTS) do
        local ok = connectivityCheck(base)

        if ok then
            host = base
            return true
        end
    end

    host = nil
    return false
end

local function requestJson(method, path, body)
    local attempted = {}

    if host then
        table.insert(attempted, host)
    end

    for _, base in ipairs(HOSTS) do
        if base ~= host then
            table.insert(attempted, base)
        end
    end

    local lastError = "No connection."

    for _, base in ipairs(attempted) do
        local encodedBody

        if body ~= nil then
            encodedBody = jsonEncode(body)

            if not encodedBody then
                return nil, "Failed to encode request."
            end
        end

        local response, err = safeRequest({
            Url = base .. path,
            Method = method,
            Body = encodedBody,
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["User-Agent"] = "DarkyHub/1.0"
            }
        })

        if response then
            if response.StatusCode == 200 then
                host = base
                return response
            end

            if response.StatusCode == 400
                or response.StatusCode == 401
                or response.StatusCode == 403 then
                host = base
                return response
            end

            if response.StatusCode == 404 then
                lastError = "HTTP 404 from " .. base
            elseif response.StatusCode == 429 then
                lastError = "HTTP 429 - Too many requests."
            elseif response.StatusCode >= 500 then
                lastError = "PlatoBoost server HTTP " .. tostring(response.StatusCode)
            else
                lastError = "HTTP " .. tostring(response.StatusCode)
            end
        else
            lastError = tostring(err or "Request failed.")
        end
    end

    return nil, lastError
end

local function generateNonce()
    if HttpService.GenerateGUID then
        local ok, guid = pcall(function()
            return HttpService:GenerateGUID(false)
        end)

        if ok and guid then
            return guid:gsub("-", ""):sub(1, 32)
        end
    end

    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local result = {}

    math.randomseed(
        os.time()
        + math.floor(os.clock() * 1000000)
    )

    for i = 1, 32 do
        local index = math.random(1, #chars)
        result[i] = chars:sub(index, index)
    end

    return table.concat(result)
end

local useNonce = true

local cachedLink = nil
local cachedTime = 0

local function cacheLink()
    if cachedLink and os.time() - cachedTime < 300 then
        return true, cachedLink
    end

    if not ensureHost() then
        return false, "PlatoBoost is unreachable."
    end

    local response, err = requestJson(
        "POST",
        "/public/start",
        {
            service = Config.ServiceId,
            identifier = lDigest(getHwid())
        }
    )

    if not response then
        return false, tostring(err)
    end

    if response.StatusCode == 429 then
        return false, "Too many requests. Wait a few seconds and try again."
    end

    if response.StatusCode ~= 200 then
        local msg = responseMessage(response)

        return false,
            "PlatoBoost HTTP " ..
            tostring(response.StatusCode) ..
            (msg and (" - " .. msg) or "")
    end

    local decoded = jsonDecode(response.Body)

    if not decoded then
        return false, "PlatoBoost returned invalid JSON."
    end

    if not decoded.success then
        return false, tostring(decoded.message or "Failed to create key link.")
    end

    if type(decoded.data) ~= "table" or not decoded.data.url then
        return false, "PlatoBoost response did not contain a key URL."
    end

    cachedLink = tostring(decoded.data.url)
    cachedTime = os.time()

    return true, cachedLink
end

local function redeemKey(key)
    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        return false, "Enter a key first."
    end

    if not ensureHost() then
        return false, "PlatoBoost is unreachable. Check your network."
    end

    local nonce = generateNonce()

    local body = {
        identifier = lDigest(getHwid()),
        key = key
    }

    if useNonce then
        body.nonce = nonce
    end

    local response, err = requestJson(
        "POST",
        "/public/redeem/" .. tostring(Config.ServiceId),
        body
    )

    if not response then
        return false, tostring(err or "Request failed.")
    end

    local status = response.StatusCode
    local decoded = jsonDecode(response.Body)

    if status == 429 then
        return false, "Rate limited. Wait 10-20 seconds and try again."
    end

    if status == 401 then
        return false, "PlatoBoost rejected the request (HTTP 401)."
    end

    if status == 403 then
        return false, "PlatoBoost rejected the service (HTTP 403)."
    end

    if status == 404 then
        return false,
            "Service/API endpoint not found (HTTP 404). Check ServiceId " ..
            tostring(Config.ServiceId) ..
            " in PlatoBoost."
    end

    if status >= 500 then
        return false,
            "PlatoBoost server error (HTTP " ..
            tostring(status) ..
            "). Try again later."
    end

    if status ~= 200 then
        local msg = responseMessage(response)

        return false,
            "PlatoBoost HTTP " ..
            tostring(status) ..
            (msg and (" - " .. msg) or "")
    end

    if not decoded then
        return false, "PlatoBoost returned invalid JSON."
    end

    if not decoded.success then
        return false,
            tostring(
                decoded.message
                or (
                    type(decoded.data) == "table"
                    and decoded.data.message
                )
                or "Invalid key."
            )
    end

    if type(decoded.data) ~= "table" then
        return false, "Invalid verification response."
    end

    if decoded.data.valid ~= true then
        return false, tostring(decoded.message or "Invalid or expired key.")
    end

    if useNonce then
        local serverHash = decoded.data.hash

        if not serverHash then
            return false, "Missing integrity hash from PlatoBoost."
        end

        local expectedHash = lDigest(
            "true-" .. nonce .. "-" .. Config.PlatoSecret
        )

        if tostring(serverHash):lower() ~= tostring(expectedHash):lower() then
            return false, "Integrity check failed. Regenerate PlatoSecret."
        end
    end

    if writefile then
        pcall(function()
            writefile(Config.KeyFileName, key)
        end)
    end

    return true, "Key verified successfully."
end

local function destroyExistingGui(name)
    for _, parent in ipairs({CoreGui, PlayerGui}) do
        local gui = parent:FindFirstChild(name)

        if gui then
            pcall(function()
                gui:Destroy()
            end)
        end
    end
end

local function findMainGui()
    for _, parent in ipairs({CoreGui, PlayerGui}) do
        if parent:FindFirstChild(Config.MainGuiName) then
            return true
        end
    end

    return false
end

local function StartMainScript()
    destroyExistingGui(Config.OldGuiName)

    _G[Config.Secret] = true

    local ok, err = pcall(function()
        local source = game:HttpGet(Config.MainScriptURL)

        if not source or source == "" then
            error("Main script returned empty content.")
        end

        local loader = loadstring(source)

        if not loader then
            error("Main script could not be compiled.")
        end

        loader()
    end)

    if not ok then
        warn("[DarkyHub] Main script failed: " .. tostring(err))
    end
end

local function create(className, parent, properties)
    local object = Instance.new(className)
    object.Parent = parent

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    return object
end

local function round(object, radius)
    create("UICorner", object, {
        CornerRadius = UDim.new(0, radius)
    })
end

local function stroke(object, color, thickness, transparency)
    return create("UIStroke", object, {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    })
end

local function tween(object, time, properties)
    local ok, result = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                time,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ),
            properties
        )
    end)

    if ok and result then
        result:Play()
    end
end

local function makeDraggable(handle, target)
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

local function addHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, 0.16, {
            BackgroundColor3 = hoverColor
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.16, {
            BackgroundColor3 = normalColor
        })
    end)
end

local function CreateGUI()
    destroyExistingGui("DarkyHub_KeySystem")

    local targetParent = CoreGui

    local screenGui = create("ScreenGui", targetParent, {
        Name = "DarkyHub_KeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999999
    })

    local glow = create("Frame", screenGui, {
        Size = UDim2.fromOffset(470, 380),
        Position = UDim2.new(0.5, -235, 0.5, -190),
        BackgroundColor3 = Color3.fromRGB(80, 170, 255),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 0
    })

    round(glow, 28)

    local softGlow = create("Frame", screenGui, {
        Size = UDim2.fromOffset(450, 360),
        Position = UDim2.new(0.5, -225, 0.5, -180),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
        ZIndex = 0
    })

    round(softGlow, 26)

    local main = create("Frame", screenGui, {
        Size = UDim2.fromOffset(440, 350),
        Position = UDim2.new(0.5, -220, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(14, 17, 23),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 2
    })

    round(main, 20)

    local mainStroke = stroke(
        main,
        Color3.fromRGB(255, 255, 255),
        1,
        0.78
    )

    local header = create("Frame", main, {
        Size = UDim2.new(1, 0, 0, 82),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3
    })

    local iconBox = create("Frame", header, {
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.fromOffset(20, 18),
        BackgroundColor3 = Color3.fromRGB(27, 34, 45),
        BorderSizePixel = 0,
        ZIndex = 4
    })

    round(iconBox, 14)
    stroke(iconBox, Color3.fromRGB(255, 255, 255), 1, 0.84)

    create("TextLabel", iconBox, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "D",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 23,
        ZIndex = 5
    })

    create("TextLabel", header, {
        Size = UDim2.new(1, -150, 0, 30),
        Position = UDim2.fromOffset(78, 16),
        BackgroundTransparency = 1,
        Text = Config.HubName,
        TextColor3 = Color3.fromRGB(245, 248, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    })

    create("TextLabel", header, {
        Size = UDim2.new(1, -150, 0, 24),
        Position = UDim2.fromOffset(79, 44),
        BackgroundTransparency = 1,
        Text = Config.HubDescription,
        TextColor3 = Color3.fromRGB(150, 159, 174),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    })

    local close = create("TextButton", header, {
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -52, 0, 22),
        BackgroundColor3 = Color3.fromRGB(28, 32, 40),
        Text = "X",
        TextColor3 = Color3.fromRGB(190, 198, 210),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        ZIndex = 6
    })

    round(close, 12)
    stroke(close, Color3.fromRGB(255, 255, 255), 1, 0.86)

    close.MouseEnter:Connect(function()
        tween(close, 0.15, {
            BackgroundColor3 = Color3.fromRGB(100, 35, 45),
            TextColor3 = Color3.fromRGB(255, 110, 120)
        })
    end)

    close.MouseLeave:Connect(function()
        tween(close, 0.15, {
            BackgroundColor3 = Color3.fromRGB(28, 32, 40),
            TextColor3 = Color3.fromRGB(190, 198, 210)
        })
    end)

    close.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    makeDraggable(header, main)

    local accent = create("Frame", main, {
        Size = UDim2.new(1, -40, 0, 2),
        Position = UDim2.fromOffset(20, 80),
        BackgroundColor3 = Color3.fromRGB(80, 170, 255),
        BorderSizePixel = 0,
        ZIndex = 4
    })

    local accentGradient = create("UIGradient", accent, {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 170, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 90, 255))
        })
    })

    task.spawn(function()
        while screenGui.Parent do
            accentGradient.Offset = Vector2.new(-1, 0)
            tween(accentGradient, 1.4, {
                Offset = Vector2.new(1, 0)
            })
            task.wait(1.5)
        end
    end)

    local body = create("Frame", main, {
        Size = UDim2.new(1, -40, 1, -110),
        Position = UDim2.fromOffset(20, 98),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3
    })

    local socials = create("Frame", body, {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3
    })

    local socialLayout = create("UIListLayout", socials, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8)
    })

    socialLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local socialCount = 0

    local function addSocial(text, url, color)
        socialCount += 1

        local button = create("TextButton", socials, {
            Size = UDim2.fromOffset(118, 36),
            BackgroundColor3 = Color3.fromRGB(28, 33, 42),
            Text = text,
            TextColor3 = Color3.fromRGB(235, 239, 247),
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            AutoButtonColor = false,
            LayoutOrder = socialCount,
            ZIndex = 4
        })

        round(button, 11)
        stroke(
            button,
            Color3.fromRGB(255, 255, 255),
            1,
            0.88
        )

        button.MouseButton1Click:Connect(function()
            fSetClipboard(url)

            statusText.Text = text .. " link copied"
            statusText.TextColor3 = color
            statusDot.BackgroundColor3 = color
        end)

        addHover(
            button,
            Color3.fromRGB(28, 33, 42),
            Color3.fromRGB(37, 45, 58)
        )
    end

    if Config.ShowDiscord then
        addSocial(
            "DISCORD",
            Config.DiscordURL,
            Color3.fromRGB(110, 125, 255)
        )
    end

    if Config.ShowInstagram then
        addSocial(
            "INSTAGRAM",
            Config.InstagramURL,
            Color3.fromRGB(235, 75, 135)
        )
    end

    if Config.ShowYoutube then
        addSocial(
            "YOUTUBE",
            Config.YoutubeURL,
            Color3.fromRGB(255, 80, 80)
        )
    end

    if socialCount == 0 then
        socials.Size = UDim2.new(1, 0, 0, 10)
    end

    local keyCard = create("Frame", body, {
        Size = UDim2.new(1, 0, 0, 72),
        Position = UDim2.fromOffset(0, socialCount > 0 and 52 or 12),
        BackgroundColor3 = Color3.fromRGB(21, 26, 34),
        BorderSizePixel = 0,
        ZIndex = 4
    })

    round(keyCard, 14)
    stroke(
        keyCard,
        Color3.fromRGB(255, 255, 255),
        1,
        0.9
    )

    local keyBadge = create("Frame", keyCard, {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(12, 17),
        BackgroundColor3 = Color3.fromRGB(35, 43, 55),
        BorderSizePixel = 0,
        ZIndex = 5
    })

    round(keyBadge, 11)

    create("TextLabel", keyBadge, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = ">",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        ZIndex = 6
    })

    local keyInput = create("TextBox", keyCard, {
        Size = UDim2.new(1, -136, 0, 44),
        Position = UDim2.fromOffset(60, 14),
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Enter your key...",
        PlaceholderColor3 = Color3.fromRGB(112, 120, 134),
        Text = "",
        TextColor3 = Color3.fromRGB(242, 245, 250),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    })

    local paste = create("TextButton", keyCard, {
        Size = UDim2.fromOffset(54, 36),
        Position = UDim2.new(1, -66, 0.5, -18),
        BackgroundColor3 = Color3.fromRGB(34, 41, 52),
        Text = "PASTE",
        TextColor3 = Color3.fromRGB(200, 208, 220),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        AutoButtonColor = false,
        ZIndex = 7
    })

    round(paste, 10)

    paste.MouseButton1Click:Connect(function()
        if getclipboard then
            local ok, clipboard = pcall(getclipboard)

            if ok and clipboard then
                keyInput.Text = tostring(clipboard)
            end
        end
    end)

    local statusCard = create("Frame", body, {
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.new(
            0,
            0,
            0,
            (socialCount > 0 and 52 or 12) + 82
        ),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4
    })

    local statusDot = create("Frame", statusCard, {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(4, 17),
        BackgroundColor3 = Color3.fromRGB(150, 159, 174),
        BorderSizePixel = 0,
        ZIndex = 5
    })

    round(statusDot, 8)

    local statusText = create("TextLabel", statusCard, {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.fromOffset(18, 0),
        BackgroundTransparency = 1,
        Text = "Waiting for key...",
        TextColor3 = Color3.fromRGB(150, 159, 174),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })

    local buttonRow = create("Frame", body, {
        Size = UDim2.new(1, 0, 0, 46),
        Position = UDim2.new(
            0,
            0,
            0,
            (socialCount > 0 and 52 or 12) + 132
        ),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4
    })

    local verifyButton = create("TextButton", buttonRow, {
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundColor3 = Color3.fromRGB(56, 132, 255),
        Text = "VERIFY KEY",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 5
    })

    round(verifyButton, 13)
    stroke(
        verifyButton,
        Color3.fromRGB(255, 255, 255),
        1,
        0.72
    )

    local getKeyButton = create("TextButton", buttonRow, {
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0.5, 10, 0, 0),
        BackgroundColor3 = Color3.fromRGB(28, 34, 43),
        Text = "GET KEY",
        TextColor3 = Color3.fromRGB(235, 239, 247),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 5
    })

    round(getKeyButton, 13)
    stroke(
        getKeyButton,
        Color3.fromRGB(255, 255, 255),
        1,
        0.83
    )

    addHover(
        verifyButton,
        Color3.fromRGB(56, 132, 255),
        Color3.fromRGB(75, 150, 255)
    )

    addHover(
        getKeyButton,
        Color3.fromRGB(28, 34, 43),
        Color3.fromRGB(38, 46, 58)
    )

    local footer = create("TextLabel", main, {
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 20, 1, -25),
        BackgroundTransparency = 1,
        Text = "SECURE VERIFICATION GATEWAY",
        TextColor3 = Color3.fromRGB(87, 96, 110),
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 4
    })

    local busy = false

    local function setStatus(text, color)
        statusText.Text = text
        statusText.TextColor3 = color
        statusDot.BackgroundColor3 = color
    end

    verifyButton.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        local key = keyInput.Text

        if key == nil or key:gsub("%s+", "") == "" then
            setStatus(
                "Enter your key first.",
                Color3.fromRGB(255, 170, 80)
            )
            return
        end

        busy = true

        verifyButton.Text = "VERIFYING..."
        verifyButton.Active = false

        setStatus(
            "Contacting PlatoBoost...",
            Color3.fromRGB(90, 180, 255)
        )

        task.spawn(function()
            local success, message = redeemKey(key)

            busy = false
            verifyButton.Active = true
            verifyButton.Text = "VERIFY KEY"

            if success then
                setStatus(
                    "Verified. Loading Darky Hub...",
                    Color3.fromRGB(80, 255, 145)
                )

                tween(main, 0.25, {
                    BackgroundTransparency = 0.15
                })

                task.wait(0.55)

                if screenGui.Parent then
                    screenGui:Destroy()
                end

                StartMainScript()
            else
                setStatus(
                    tostring(message),
                    Color3.fromRGB(255, 90, 105)
                )
            end
        end)
    end)

    getKeyButton.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        busy = true
        getKeyButton.Text = "LOADING..."

        setStatus(
            "Creating your key link...",
            Color3.fromRGB(90, 180, 255)
        )

        task.spawn(function()
            local success, result = cacheLink()

            busy = false
            getKeyButton.Text = "GET KEY"

            if success then
                fSetClipboard(result)

                setStatus(
                    "Key link copied to clipboard.",
                    Color3.fromRGB(80, 255, 145)
                )
            else
                setStatus(
                    tostring(result),
                    Color3.fromRGB(255, 90, 105)
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
            local savedKey

            pcall(function()
                savedKey = readfile(Config.KeyFileName)
            end)

            savedKey = tostring(savedKey or "")

            if savedKey ~= "" then
                keyInput.Text = savedKey

                setStatus(
                    "Saved key found. Verifying...",
                    Color3.fromRGB(90, 180, 255)
                )

                task.spawn(function()
                    local success, message = redeemKey(savedKey)

                    if success then
                        setStatus(
                            "Auto-login successful.",
                            Color3.fromRGB(80, 255, 145)
                        )

                        task.wait(0.5)

                        if screenGui.Parent then
                            screenGui:Destroy()
                        end

                        StartMainScript()
                    else
                        setStatus(
                            "Saved key invalid: " .. tostring(message),
                            Color3.fromRGB(255, 170, 80)
                        )
                    end
                end)
            end
        end
    end

    task.spawn(function()
        while screenGui.Parent do
            mainStroke.Transparency = 0.72

            tween(mainStroke, 1.2, {
                Transparency = 0.58
            })

            task.wait(1.2)

            if not screenGui.Parent then
                break
            end

            tween(mainStroke, 1.2, {
                Transparency = 0.78
            })

            task.wait(1.2)
        end
    end)
end

if findMainGui() then
    StartMainScript()
    return
end

CreateGUI()
