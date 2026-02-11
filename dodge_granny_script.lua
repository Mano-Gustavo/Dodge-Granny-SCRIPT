local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Mano-Gustavo/Mano-Gustavo-Library/refs/heads/main/library.lua"
))()

local Window = Library:CreateWindow({
    Title = "Dodge Granny - SCRIPT",
    Keybind = Enum.KeyCode.RightControl
})

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("Auto Parry")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
end)

local FLIPFLOP_FOLDER =
    workspace:WaitForChild("Arena"):WaitForChild("FlipFlops")

local Config = {
    Enabled = false,
    Distance = 12.6,
    Cooldown = 0.1
}

Section:CreateToggle("Auto Parry", function(v)
    Config.Enabled = v
end, false)

Section:CreateSlider("Parry Distance", 8, 18, Config.Distance, function(v)
    Config.Distance = v
end)

Section:CreateSlider("Cooldown", 0.1, 0.5, Config.Cooldown, function(v)
    Config.Cooldown = v
end)

local IS_MOBILE = UserInputService.TouchEnabled

local function parryInput()
    if IS_MOBILE then
        local cam = workspace.CurrentCamera
        local size = cam.ViewportSize
        local pos = Vector2.new(size.X / 2, size.Y / 2)
        VirtualInputManager:SendTouchEvent(0, pos, true)
        VirtualInputManager:SendTouchEvent(0, pos, false)
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

local function getPart(model)
    if model.PrimaryPart then
        return model.PrimaryPart
    end
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            return v
        end
    end
end

local myHighlight = "Highlight_Player:" .. player.UserId
local isTargeted = false

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Highlight") and obj.Name == myHighlight and obj.Adornee == character then
        isTargeted = true
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Highlight") and obj.Name == myHighlight then
        isTargeted = false
    end
end)

local FlipFlops = {}

FLIPFLOP_FOLDER.ChildAdded:Connect(function(model)
    if model:IsA("Model") and model.Name:lower():find("flipflop") then
        FlipFlops[model] = { busy = false, confirmed = false }
        model.AncestryChanged:Connect(function(_, parent)
            if not parent and FlipFlops[model] then
                FlipFlops[model] = nil
            end
        end)
    end
end)

FLIPFLOP_FOLDER.ChildRemoved:Connect(function(model)
    FlipFlops[model] = nil
end)

local lastParry = 0

RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    if not isTargeted then return end
    if os.clock() - lastParry < Config.Cooldown then return end

    for model, state in pairs(FlipFlops) do
        if not state.busy then
            local part = getPart(model)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist <= Config.Distance then
                    state.busy = true
                    lastParry = os.clock()
                    parryInput()
                    task.delay(0.08, function()
                        if FlipFlops[model] then
                            state.busy = false
                        end
                    end)
                    break
                end
            end
        end
    end
end)

