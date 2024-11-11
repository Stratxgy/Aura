-- Global Settings
getgenv().spin = {
    enabled = false,      -- Toggle strafing and spinning
    straferadius = 10,   -- Distance from the target player
    strafespeed = 2,     -- Speed of strafing (higher = faster)
    spinspeed = 5,       -- Speed of spinning (higher = faster)
    angle = 0,           -- Current angle (used internally for calculations)
    keybind = Enum.KeyCode.E -- Keybind to toggle strafing
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local selectedPlayer = nil
local isStrafing = false

-- Function to update references when the player respawns
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Function to find the closest player to the mouse
local function getClosestPlayerToMouse()
    local mouse = localPlayer:GetMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPosition = player.Character.HumanoidRootPart.Position
            local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(playerPosition)
            
            if onScreen then
                local distance = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPosition.X, screenPosition.Y)).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Start strafing around the selected player
local function startStrafing(targetPlayer)
    if getgenv().spin.enabled then
        selectedPlayer = targetPlayer
        isStrafing = true
    end
end

-- Stop strafing
local function stopStrafing()
    selectedPlayer = nil
    isStrafing = false
end

-- Handle key press to toggle strafing
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == getgenv().spin.keybind then
        if not isStrafing then
            local closestPlayer = getClosestPlayerToMouse()
            if closestPlayer then
                startStrafing(closestPlayer)
            end
        else
            stopStrafing()
        end
    end
end)

-- Update the strafing movement
RunService.RenderStepped:Connect(function(deltaTime)
    if isStrafing and selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetRootPart = selectedPlayer.Character.HumanoidRootPart
        getgenv().spin.angle = getgenv().spin.angle + getgenv().spin.strafespeed * deltaTime
        local spinAngle = getgenv().spin.angle * getgenv().spin.spinspeed

        -- Calculate the strafing position
        local offset = Vector3.new(
            math.cos(getgenv().spin.angle) * getgenv().spin.straferadius, 
            0, 
            math.sin(getgenv().spin.angle) * getgenv().spin.straferadius
        )
        local targetPosition = targetRootPart.Position + offset

        -- Apply spinning without changing the camera orientation
        local spinRotation = CFrame.Angles(0, math.rad(spinAngle), 0)
        humanoidRootPart.CFrame = CFrame.new(targetPosition) * spinRotation
    end
end)
