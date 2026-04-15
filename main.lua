--// TWISTED ULTIMATE: HUB EDITION (DISTANCE FIX)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// СОСТОЯНИЯ
local states = {
    tornado = false, 
    fb = false, 
    pFly = false, 
    cFly = false,
    pESP = false,
    pFlySpeed = 60,
    cFlySpeed = 60
}
local TORNADO_NAMES = {"⚠️ АНОМАЛИЯ", "🌪️ ТОРНАДО", "⚡ ОПАСНОСТЬ", "💀 СМЕРТЬ"}
local carGyro, carVel = nil, nil

--// ОСНОВНОЙ GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 450, 0, 350)
Main.Position = UDim2.new(0.5, -225, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

--// ПЕРЕКЛЮЧЕНИЕ НА LEFT CONTROL
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftControl then 
        Main.Visible = not Main.Visible 
    end
end)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 120, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 5)

local PageContainer = Instance.new("Frame", Main)
PageContainer.Size = UDim2.new(1, -130, 1, -20)
PageContainer.Position = UDim2.new(0, 125, 0, 10)
PageContainer.BackgroundTransparency = 1

local pages = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame", PageContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 1.5, 0)
    page.ScrollBarThickness = 2
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
    
    local tabBtn = Instance.new("TextButton", Sidebar)
    tabBtn.Size = UDim2.new(1, -10, 0, 35)
    tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", tabBtn)
    
    tabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        page.Visible = true
    end)
    pages[name] = page
    return page
end

local function createToggle(parent, text, key)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        states[key] = not states[key]
        btn.Text = text .. (states[key] and ": ON" or ": OFF")
        btn.BackgroundColor3 = states[key] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(45, 45, 45)
    end)
end

local function createSlider(parent, text, min, max, key)
    local sliderFrame = Instance.new("Frame", parent)
    sliderFrame.Size = UDim2.new(1, -10, 0, 45)
    sliderFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", sliderFrame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text .. ": " .. states[key]
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1

    local tray = Instance.new("Frame", sliderFrame)
    tray.Size = UDim2.new(1, -20, 0, 4)
    tray.Position = UDim2.new(0, 10, 0, 30)
    tray.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local handle = Instance.new("TextButton", tray)
    handle.Size = UDim2.new(0, 12, 0, 12)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.Position = UDim2.new((states[key] - min) / (max - min), 0, 0.5, 0)
    handle.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    handle.Text = ""
    Instance.new("UICorner", handle)

    local dragging = false
    handle.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UIS:GetMouseLocation().X
            local relPos = math.clamp((mousePos - tray.AbsolutePosition.X) / tray.AbsoluteSize.X, 0, 1)
            handle.Position = UDim2.new(relPos, 0, 0.5, 0)
            local val = math.floor(min + (relPos * (max - min)))
            states[key] = val
            label.Text = text .. ": " .. val
        end
    end)
end

-- Вкладки
local tPage = createPage("Tornados")
local pPage = createPage("Players")
local vPage = createPage("Vehicle")
local sPage = createPage("Settings")

createToggle(tPage, "Tornado Scan ESP", "tornado")
createToggle(pPage, "Player ESP", "pESP")
createToggle(vPage, "Stable Car Fly", "cFly")
createToggle(sPage, "Fly Player", "pFly")
createToggle(sPage, "Full Bright", "fb")

createSlider(sPage, "Player Speed", 10, 300, "pFlySpeed")
createSlider(sPage, "Vehicle Speed", 10, 500, "cFlySpeed")

pages["Tornados"].Visible = true

--// ЛОГИКА ESP (ОТОБРАЖЕНИЕ МЕТРОВ)
local function CreateESP(obj)
    if obj:FindFirstChild("TornadoESP") then return end
    local bgu = Instance.new("BillboardGui", obj)
    bgu.Name = "TornadoESP"; bgu.AlwaysOnTop = true; bgu.Size = UDim2.new(0, 200, 0, 100); bgu.MaxDistance = 60000
    
    local txt = Instance.new("TextLabel", bgu)
    txt.Size = UDim2.new(1, 0, 0, 30); txt.BackgroundTransparency = 1
    txt.Text = TORNADO_NAMES[math.random(#TORNADO_NAMES)]; txt.TextColor3 = Color3.new(1, 1, 1); txt.Font = Enum.Font.SourceSansBold; txt.TextSize = 22
    
    local dst = Instance.new("TextLabel", bgu)
    dst.Size = UDim2.new(1, 0, 0, 20); dst.Position = UDim2.new(0, 0, 0, 30); dst.BackgroundTransparency = 1
    dst.TextColor3 = Color3.fromRGB(0, 255, 255); dst.Font = Enum.Font.SourceSansBold; dst.TextSize = 18

    task.spawn(function()
        while obj.Parent and states.tornado do
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local d = (LP.Character.HumanoidRootPart.Position - obj.Position).Magnitude
                dst.Text = math.floor(d/3) .. " meters"
            end
            task.wait(0.2)
        end
        bgu:Destroy()
    end)
end

-- Циклы управления
RunService.RenderStepped:Connect(function()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if states.pFly and root and not hum.SeatPart then
        root.Velocity = Camera.CFrame.LookVector * states.pFlySpeed
    end

    if states.cFly and hum and hum.SeatPart then
        local seat = hum.SeatPart
        if not carGyro or carGyro.Parent ~= seat then
            carGyro = Instance.new("BodyGyro", seat); carGyro.P = 9e4; carGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            carVel = Instance.new("BodyVelocity", seat); carVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        carGyro.CFrame = Camera.CFrame
        local dir = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = Camera.CFrame.LookVector
        elseif UIS:IsKeyDown(Enum.KeyCode.S) then dir = -Camera.CFrame.LookVector end
        carVel.Velocity = dir * states.cFlySpeed
    else
        if carGyro then carGyro:Destroy() carGyro = nil end
        if carVel then carVel:Destroy() carVel = nil end
    end

    if states.fb then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000 end
end)

-- Твоя оригинальная логика поиска
task.spawn(function()
    while true do
        if states.tornado then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Sound") and (v.Name:lower():find("roar") or v.Name:lower():find("wind")) then
                    if v.RollOffMaxDistance > 400 then CreateESP(v.Parent) end
                end
            end
        else
            for _, v in pairs(game:GetService("CoreGui"):GetDescendants()) do
                if v.Name == "TornadoESP" then v:Destroy() end
            end
        end
        task.wait(4)
    end
end)

print("Twisted Hub Loaded! Toggle: Left Control")
