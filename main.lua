--// TWISTED ULTIMATE: PRESIDENT EDITION (FIXED & COMPLETE)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local states = {
    tornadoESP = true,
    fb = false, pFly = false, cFly = false,
    pFlySpeed = 60, cFlySpeed = 60, 
    downforce = 0,
    menuKey = Enum.KeyCode.LeftControl
}

local lastFoundTornado = nil

local function getTornadoRank(rollOff)
    if rollOff >= 7500 then return "💀 СМЕРТЬ (EF5?)", Color3.fromRGB(255, 30, 30)
    elseif rollOff >= 4000 then return "🌪️ МОЩНОЕ ТОРНАДО", Color3.fromRGB(255, 120, 0)
    elseif rollOff >= 1500 then return "🌀 СЛАБОЕ ТОРНАДО", Color3.fromRGB(0, 255, 100)
    else return "⚡ ШТОРМ/ВЕТЕР", Color3.fromRGB(200, 200, 0) end
end

--// GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 450, 0, 380); Main.Position = UDim2.new(0.5, -225, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(245, 245, 245); Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(200, 200, 200)

local dragStart, startPos, dragging
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

UIS.InputBegan:Connect(function(i, g) if not g and i.KeyCode == states.menuKey then Main.Visible = not Main.Visible end end)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 120, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(230, 230, 230); Instance.new("UICorner", Sidebar)
Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 5)

local PageContainer = Instance.new("Frame", Main)
PageContainer.Size = UDim2.new(1, -135, 1, -20); PageContainer.Position = UDim2.new(0, 125, 0, 10); PageContainer.BackgroundTransparency = 1

local pages = {}
local function createPage(name)
    local page = Instance.new("ScrollingFrame", PageContainer)
    page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 2, 0); page.ScrollBarThickness = 2
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
    local tab = Instance.new("TextButton", Sidebar)
    tab.Size = UDim2.new(1, -10, 0, 30); tab.BackgroundColor3 = Color3.fromRGB(210, 210, 210); tab.Text = name; Instance.new("UICorner", tab)
    tab.MouseButton1Click:Connect(function() for _, p in pairs(pages) do p.Visible = false end; page.Visible = true end)
    pages[name] = page; return page
end

local function createToggle(parent, text, key)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -5, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(220, 220, 220); btn.Text = text .. ": OFF"; Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function()
        states[key] = not states[key]
        btn.Text = text .. (states[key] and ": ON" or ": OFF")
        btn.BackgroundColor3 = states[key] and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(220, 220, 220)
    end)
end

local function createSlider(parent, text, min, max, key)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -5, 0, 45); frame.BackgroundTransparency = 1
    local lab = Instance.new("TextLabel", frame); lab.Size = UDim2.new(1, 0, 0, 20); lab.Text = text .. ": " .. states[key]; lab.BackgroundTransparency = 1
    local tray = Instance.new("Frame", frame); tray.Size = UDim2.new(1, -20, 0, 4); tray.Position = UDim2.new(0, 10, 0, 30); tray.BackgroundColor3 = Color3.new(0.8,0.8,0.8)
    local btn = Instance.new("TextButton", tray); btn.Size = UDim2.new(0, 12, 0, 12); btn.AnchorPoint = Vector2.new(0.5,0.5); btn.Text = ""
    btn.Position = UDim2.new((states[key]-min)/(max-min), 0, 0.5, 0); Instance.new("UICorner", btn)
    local active = false
    btn.MouseButton1Down:Connect(function() active = true end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then active = false end end)
    RunService.RenderStepped:Connect(function()
        if active then
            local rel = math.clamp((UIS:GetMouseLocation().X - tray.AbsolutePosition.X) / tray.AbsoluteSize.X, 0, 1)
            btn.Position = UDim2.new(rel, 0, 0.5, 0)
            states[key] = math.floor(min + (rel * (max - min)))
            lab.Text = text .. ": " .. states[key]
        end
    end)
end

local tPage = createPage("Tornados")
local pPage = createPage("Players")
local vPage = createPage("Vehicle")
local sPage = createPage("Settings")

createToggle(tPage, "Auto ESP", "tornadoESP")
local tpBtn = Instance.new("TextButton", tPage); tpBtn.Size = UDim2.new(1, -5, 0, 35); tpBtn.BackgroundColor3 = Color3.fromRGB(200, 220, 255); tpBtn.Text = "📍 TP to Last Found"; Instance.new("UICorner", tpBtn)
tpBtn.MouseButton1Click:Connect(function() if lastFoundTornado and LP.Character then LP.Character:MoveTo(lastFoundTornado.Position + Vector3.new(0, 400, 400)) end end)

createToggle(pPage, "Player Fly", "pFly"); createSlider(pPage, "P-Speed", 10, 300, "pFlySpeed")
createToggle(pPage, "Car Fly", "cFly"); createSlider(pPage, "C-Speed", 10, 500, "cFlySpeed")
createSlider(vPage, "Downforce", 0, 5000, "downforce")
createToggle(sPage, "Full Bright", "fb")

pages["Tornados"].Visible = true

--// ESP SYSTEM
local function CreateESP(obj, rollOff)
    if obj:FindFirstChild("TornadoESP") then return end
    lastFoundTornado = obj
    local bgu = Instance.new("BillboardGui", obj); bgu.Name = "TornadoESP"; bgu.AlwaysOnTop = true; bgu.Size = UDim2.new(0, 200, 0, 100); bgu.MaxDistance = 1e6
    local rank, col = getTornadoRank(rollOff)
    local txt = Instance.new("TextLabel", bgu); txt.Size = UDim2.new(1, 0, 0, 30); txt.BackgroundTransparency = 1; txt.Text = rank; txt.TextColor3 = col; txt.Font = 3; txt.TextSize = 20
    local dst = Instance.new("TextLabel", bgu); dst.Position = UDim2.new(0, 0, 0, 25); dst.Size = UDim2.new(1, 0, 0, 20); dst.BackgroundTransparency = 1; dst.TextColor3 = Color3.new(1,1,1); dst.TextSize = 14
    task.spawn(function()
        while obj and obj.Parent and states.tornadoESP do
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                dst.Text = math.floor((LP.Character.HumanoidRootPart.Position - obj.Position).Magnitude / 3) .. "m"
            end; task.wait(0.5)
        end; if bgu then bgu:Destroy() end
    end)
end

--// CYCLES
RunService.RenderStepped:Connect(function()
    local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hum and hum.SeatPart and states.downforce > 0 then
        local body = hum.SeatPart.Parent:FindFirstChild("Body") or hum.SeatPart
        if body:IsA("BasePart") then body.Velocity = body.Velocity + Vector3.new(0, -states.downforce / 100, 0) end
    end

    if states.pFly and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * states.pFlySpeed end
    if hum and hum.SeatPart then
        local seat = hum.SeatPart
        if states.cFly then
            local bg = seat:FindFirstChild("CarGyro") or Instance.new("BodyGyro", seat); bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = Camera.CFrame; bg.Name = "CarGyro"
            local bv = seat:FindFirstChild("CarVel") or Instance.new("BodyVelocity", seat); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Name = "CarVel"
            bv.Velocity = (UIS:IsKeyDown(Enum.KeyCode.W) and Camera.CFrame.LookVector or UIS:IsKeyDown(Enum.KeyCode.S) and -Camera.CFrame.LookVector or Vector3.new(0,0,0)) * states.cFlySpeed
        else
            if seat:FindFirstChild("CarGyro") then seat.CarGyro:Destroy() end
            if seat:FindFirstChild("CarVel") then seat.CarVel:Destroy() end
        end
    end
    if states.fb then Lighting.Brightness = 2; Lighting.ClockTime = 14 end
end)

task.spawn(function()
    while true do
        if states.tornadoESP then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Sound") and (v.Name:lower():find("roar") or v.Name:lower():find("wind")) then
                    if v.RollOffMaxDistance > 500 and v.Parent and v.Parent:IsA("BasePart") then CreateESP(v.Parent, v.RollOffMaxDistance) end
                end
            end
        end; task.wait(3)
    end
end)
