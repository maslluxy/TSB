-- Character Customizer Module
-- Place this in a .lua file on GitHub for loadstring usage

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local localplayer = Players.LocalPlayer

-- Character Library
local charLibrary = {
    Saitama = "Bald",
    Garou = {
        Base = "Hunter",
        MonsterForm = "Monster"
    },
    Genos = "Cyborg",
    Sonic = "Ninja",
    MetalBat = "Batter",
    AtomicSamurai = "Blade",
    Tatsumaki = "Esper",
    Suiryu = "Purple",
    ChildEmperor = "Tech",
    KJ = "KJ",
    Gojo = "Gojo"
}

-- Module State
local module = {}
local state = {
    character = nil,
    characterValue = nil,
    isValidCharacter = false,
    
    baseMoves = { 
        ["1"] = nil, 
        ["2"] = nil, 
        ["3"] = nil, 
        ["4"] = nil 
    },
    
    ultMoves = { 
        ["1"] = nil, 
        ["2"] = nil, 
        ["3"] = nil, 
        ["4"] = nil 
    },
    
    ultName = {
        Text = nil,
    },
    
    barColor = nil,
    cooldownColor = nil,
    
    charLabel = {
        Text = nil,
    },
    
    charImage = {
        Image = nil,
    },
    
    defaultTextProperties = nil,
    
    animConfig = {}
}

-- Internal Variables
local activeanims = {}
local replacetracks = {}
local connections = {}
local updateloop
local hasShownNotification = false
local character = localplayer.Character
local playerGui = localplayer.PlayerGui
local animLookup = {}

-- Initialize animation lookup
for _, v in pairs(state.animConfig) do 
    if v and v.detectid then
        animLookup[tostring(v.detectid)] = v 
    end
end

-- Utility Functions
local function validateCharacter()
    if not state.isValidCharacter then
        warn("Invalid or no character set. Use setCharacter() first with a valid character name.")
        return false
    end
    return true
end

local function isCorrectCharacter()
    return character and character:GetAttribute("Character") == state.characterValue
end

local function safeApplyProperties(element, properties)
    if not element or not properties or type(properties) ~= "table" then 
        return 
    end
    
    for prop, value in pairs(properties) do
        local success, err = pcall(function()
            if element[prop] ~= nil then
                element[prop] = value
            end
        end)
        
        if not success then
            warn("Failed to apply property " .. tostring(prop) .. ": " .. tostring(err))
        end
    end
end

local function applyTextProperties(textLabel, moveData)
    if not textLabel then 
        return 
    end
    
    -- Set text first
    local text = ""
    if type(moveData) == "table" and moveData.text then
        text = moveData.text
    elseif type(moveData) == "string" then
        text = moveData
    end
    
    pcall(function()
        textLabel.Text = text
    end)
    
    -- Apply custom properties or defaults
    if type(moveData) == "table" and moveData.text then
        for prop, value in pairs(moveData) do
            if prop ~= "text" then
                pcall(function()
                    if textLabel[prop] ~= nil then 
                        textLabel[prop] = value 
                    end
                end)
            end
        end
    elseif state.defaultTextProperties then
        safeApplyProperties(textLabel, state.defaultTextProperties)
    end
end

local function updateTopbarInfo()
    local topbar = playerGui:FindFirstChild("TopbarPlus")
    if not topbar then 
        return 
    end
    
    local container = topbar:FindFirstChild("TopbarContainer")
    if not container then 
        return 
    end
    
    for _, unnamedIcon in pairs(container:GetChildren()) do
        if unnamedIcon.Name == "UnnamedIcon" then
            local dropdown = unnamedIcon:FindFirstChild("DropdownContainer")
            if dropdown then
                local frame = dropdown:FindFirstChild("DropdownFrame")
                if frame then
                    local charButton = frame:FindFirstChild(state.characterValue)
                    if charButton then
                        local iconButton = charButton:FindFirstChild("IconButton")
                        if iconButton then
                            -- Update label
                            local label = iconButton:FindFirstChild("IconLabel")
                            if label and state.charLabel.Text and state.charLabel.Text ~= "" then
                                safeApplyProperties(label, state.charLabel)
                            end
                            
                            -- Update image
                            if state.charImage.Image and state.charImage.Image ~= "" then
                                local imageObj = iconButton:FindFirstChild("IconImage")
                                if imageObj and imageObj:IsA("ImageLabel") then
                                    local imageConfig = table.clone(state.charImage)
                                    imageConfig.Image = "http://www.roblox.com/asset/?id=" .. imageConfig.Image
                                    safeApplyProperties(imageObj, imageConfig)
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end

local function updateMoveLabels()
    if not isCorrectCharacter() then 
        return 
    end
    
    local hotbar = playerGui:FindFirstChild("Hotbar")
    if not hotbar then 
        return 
    end
    
    local backpack = hotbar:FindFirstChild("Backpack")
    if not backpack then 
        return 
    end
    
    local hotbarFrame = backpack:FindFirstChild("Hotbar")
    if not hotbarFrame then 
        return 
    end
    
    local isUlted = character:GetAttribute("Ulted")
    
    for i = 1, 4 do
        local slot = hotbarFrame:FindFirstChild(tostring(i))
        if slot then
            local moveData = isUlted and state.ultMoves[tostring(i)] or state.baseMoves[tostring(i)]
            if moveData and moveData ~= "" then
                -- Update main tool name
                local base = slot:FindFirstChild("Base")
                if base then
                    local toolName = base:FindFirstChild("ToolName")
                    if toolName and (toolName:IsA("TextLabel") or toolName:IsA("TextButton")) then
                        applyTextProperties(toolName, moveData)
                    end
                end
                
                -- Update reuse label
                local reuseLabel = slot:FindFirstChild("Reuse")
                if reuseLabel then
                    reuseLabel.Visible = true
                    if reuseLabel:IsA("TextLabel") or reuseLabel:IsA("TextButton") then
                        applyTextProperties(reuseLabel, moveData)
                        
                        -- Update child reuse label
                        local childReuse = reuseLabel:FindFirstChild("Reuse")
                        if childReuse and (childReuse:IsA("TextLabel") or childReuse:IsA("TextButton")) then
                            pcall(function()
                                childReuse.Text = reuseLabel.Text
                            end)
                            
                            if state.defaultTextProperties then
                                for prop, _ in pairs(state.defaultTextProperties) do
                                    pcall(function()
                                        if reuseLabel[prop] ~= nil and childReuse[prop] ~= nil then
                                            childReuse[prop] = reuseLabel[prop]
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updateCooldownColors()
    if not isCorrectCharacter() or not state.cooldownColor then 
        return 
    end
    
    local hotbar = playerGui:FindFirstChild("Hotbar")
    if not hotbar then 
        return 
    end
    
    local backpack = hotbar:FindFirstChild("Backpack")
    if not backpack then 
        return 
    end
    
    local hotbarFrame = backpack:FindFirstChild("Hotbar")
    if not hotbarFrame then 
        return 
    end
    
    for i = 1, 4 do
        local slot = hotbarFrame:FindFirstChild(tostring(i))
        if slot and slot:FindFirstChild("Base") then
            local cooldownFrame = slot.Base:FindFirstChild("Cooldown")
            if cooldownFrame then
                pcall(function()
                    cooldownFrame.BackgroundColor3 = state.cooldownColor
                end)
            end
        end
    end
end

local function updateBarAndUlt()
    if not isCorrectCharacter() then 
        return 
    end
    
    local bar = playerGui:FindFirstChild("Bar")
    if not bar then 
        return 
    end
    
    local magicHealth = bar:FindFirstChild("MagicHealth")
    if not magicHealth then 
        return 
    end
    
    -- Update bar color
    if state.barColor then
        local health = magicHealth:FindFirstChild("Health")
        if health then
            local barFrame = health:FindFirstChild("Bar")
            if barFrame then
                local innerBar = barFrame:FindFirstChild("Bar")
                if innerBar and innerBar:IsA("ImageLabel") then 
                    pcall(function()
                        innerBar.ImageColor3 = state.barColor
                    end)
                end
            end
        end
    end
    
    -- Update ult text
    if state.ultName.Text and state.ultName.Text ~= "" then
        local ultTextLabel = magicHealth:FindFirstChild("TextLabel")
        if ultTextLabel then
            safeApplyProperties(ultTextLabel, state.ultName)
        end
    end
end

local function mainSystem()
    -- Update character reference
    character = localplayer.Character
    
    -- Always update topbar
    updateTopbarInfo()
    
    -- Only update character-specific elements if correct character
    if isCorrectCharacter() then
        updateMoveLabels()
        updateBarAndUlt()
        updateCooldownColors()
    end
end

local function animationSystem(animTrack)
    if not isCorrectCharacter() or not animTrack or not animTrack.Animation then 
        return 
    end
    
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then 
        return 
    end
    
    local cleanId = tostring(animTrack.Animation.AnimationId):gsub("rbxassetid://", "")
    local animConfig = animLookup[cleanId]
    if not animConfig then 
        return 
    end
    
    local detectStr = tostring(animConfig.detectid)
    if activeanims[detectStr] then 
        return 
    end
    activeanims[detectStr] = true
    
    -- Clean up existing track
    if replacetracks[detectStr] then
        pcall(function()
            replacetracks[detectStr]:Stop()
        end)
        replacetracks[detectStr] = nil
    end
    
    -- Stop original animation if replacing
    if animConfig.detectid ~= animConfig.replaceid then
        local cleanDetectId = tostring(animConfig.detectid):gsub("rbxassetid://", "")
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            if track.Animation then
                local trackId = tostring(track.Animation.AnimationId):gsub("rbxassetid://", "")
                if trackId == cleanDetectId then
                    pcall(function()
                        track:Stop()
                    end)
                    break
                end
            end
        end
    end
    
    -- Get or create animator
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    -- Create and load animation
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animConfig.replaceid
    
    local success, loadedTrack = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    
    anim:Destroy()
    
    if not success or not loadedTrack then
        activeanims[detectStr] = nil
        return
    end
    
    -- Configure track
    replacetracks[detectStr] = loadedTrack
    
    pcall(function()
        loadedTrack.Looped = animConfig.looped
        if animConfig.priority then 
            loadedTrack.Priority = animConfig.priority 
        end
        
        loadedTrack:Play()
        
        if animConfig.timeposition > 0 then
            loadedTrack.TimePosition = animConfig.timeposition
        end
        if animConfig.speed ~= 1 then
            loadedTrack:AdjustSpeed(animConfig.speed)
        end
    end)
    
    -- Handle end position
    if animConfig.endposition then
        task.delay(animConfig.endposition, function()
            pcall(function()
                if loadedTrack and loadedTrack.IsPlaying then
                    loadedTrack:Stop()
                end
            end)
        end)
    end
    
    -- Run custom function if provided
    if animConfig.run then
        task.spawn(animConfig.run, loadedTrack, animConfig, character, humanoid, animTrack)
    end
    
    -- Cleanup function
    local function cleanup()
        activeanims[detectStr] = nil
        if replacetracks[detectStr] == loadedTrack then
            replacetracks[detectStr] = nil
        end
    end
    
    -- Connect cleanup events
    pcall(function()
        loadedTrack.Stopped:Connect(cleanup)
        loadedTrack.AncestryChanged:Connect(function(_, parent)
            if not parent then 
                cleanup() 
            end
        end)
    end)
end

local function cleanup()
    for _, connection in pairs(connections) do
        pcall(function()
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end)
    end
    table.clear(connections)
    
    if updateloop then
        pcall(function()
            updateloop:Disconnect()
        end)
        updateloop = nil
    end
    
    -- Stop all active tracks
    for _, track in pairs(replacetracks) do
        pcall(function()
            if track and track.IsPlaying then
                track:Stop()
            end
        end)
    end
    table.clear(replacetracks)
    table.clear(activeanims)
end

local function setupConnections()
    cleanup()
    character = localplayer.Character
    
    if not character then 
        return 
    end
    
    -- Character attribute changes
    pcall(function()
        connections.attrChanged = character.AttributeChanged:Connect(function(attr)
            if attr == "Character" or attr == "Ulted" then
                mainSystem()
            end
        end)
    end)
    
    -- Character removal
    pcall(function()
        connections.ancestry = character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanup()
            end
        end)
    end)
    
    -- Animation system (only for correct character)
    if isCorrectCharacter() then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            table.clear(activeanims)
            for _, track in pairs(replacetracks) do
                pcall(function()
                    if track and track.IsPlaying then
                        track:Stop()
                    end
                end)
            end
            table.clear(replacetracks)
            
            pcall(function()
                connections.animplay = humanoid.AnimationPlayed:Connect(animationSystem)
            end)
        end
    end
end

local function showCharacterNotification()
    if hasShownNotification or isCorrectCharacter() then 
        return 
    end
    
    hasShownNotification = true
    
    local bindable = Instance.new("BindableFunction")
    function bindable.OnInvoke(button)
        if button == "OK" then
            pcall(function()
                if localplayer.Character and localplayer.Character:FindFirstChild("Humanoid") then
                    localplayer.Character.Humanoid.Health = 0
                end
            end)
        elseif button == "NUH UH" then
            localplayer:Kick("tf u mean nuh uh???💔💔")
        end
    end
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "NOT CORRECT CHARACTER",
            Text = 'Switch character to "' .. state.characterValue .. '" to run script.',
            Duration = 7.5,
            Button1 = "OK",
            Button2 = "NUH UH",
            Callback = bindable
        })
    end)
end

-- Module Functions
function module.setCharacter(charName)
    if not charName or type(charName) ~= "string" then
        warn("setCharacter: Invalid character name provided")
        state.isValidCharacter = false
        return
    end
    
    local charValue = charLibrary[charName]
    if not charValue then
        warn("setCharacter: Character '" .. charName .. "' not found in library")
        state.isValidCharacter = false
        return
    end
    
    -- Handle nested character values (like Garou)
    if type(charValue) == "table" then
        if charValue.Base then
            charValue = charValue.Base
        else
            warn("setCharacter: Complex character structure found, please specify the exact form")
            state.isValidCharacter = false
            return
        end
    end
    
    state.character = charName
    state.characterValue = charValue
    state.isValidCharacter = true
    
    print("Character set to: " .. charName .. " (" .. charValue .. ")")
    
    -- Initialize system
    setupConnections()
    mainSystem()
    showCharacterNotification()
end

function module.setMoveName(moveType, slot, name, properties)
    if not validateCharacter() then return end
    
    warn("setMoveName called with type: " .. tostring(moveType) .. ", slot: " .. tostring(slot) .. ", name: " .. tostring(name))
    
    if type(moveType) ~= "string" or (moveType ~= "base" and moveType ~= "ult") then
        warn("setMoveName: Invalid move type. Use 'base' or 'ult'")
        return
    end
    
    if type(slot) ~= "number" or slot < 1 then
        warn("setMoveName: Invalid slot number. Use 1-4")
        return
    end
    
    if slot > 4 then
        warn("setMoveName: Invalid move number " .. slot .. " put for " .. moveType .. ". Max is 4, setting to 4")
        slot = 4
    end
    
    if type(name) ~= "string" then
        warn("setMoveName: Invalid name provided")
        return
    end
    
    local slotStr = tostring(slot)
    local moveData = {text = name}
    
    -- Add custom properties if provided
    if properties and type(properties) == "table" then
        for prop, value in pairs(properties) do
            moveData[prop] = value
        end
    end
    
    if moveType == "base" then
        state.baseMoves[slotStr] = moveData
    else
        state.ultMoves[slotStr] = moveData
    end
    
    mainSystem()
end

function module.setAnimations(animTable)
    if not validateCharacter() then return end
    
    warn("setAnimations called")
    
    if type(animTable) ~= "table" then
        warn("setAnimations: Invalid animation table provided")
        return
    end
    
    local defaultAnimProps = {
        detectid = 0,
        replaceid = 0,
        speed = 1,
        timeposition = 0,
        looped = false,
        priority = Enum.AnimationPriority.Action
    }
    
    for animName, animData in pairs(animTable) do
        if type(animData) == "table" then
            local newAnimConfig = {}
            
            -- Apply defaults and validate
            for prop, defaultValue in pairs(defaultAnimProps) do
                if animData[prop] ~= nil then
                    newAnimConfig[prop] = animData[prop]
                else
                    newAnimConfig[prop] = defaultValue
                    warn("setAnimations: Missing property '" .. prop .. "' for animation '" .. animName .. "', using default: " .. tostring(defaultValue))
                end
            end
            
            -- Add any additional properties
            for prop, value in pairs(animData) do
                if not defaultAnimProps[prop] then
                    newAnimConfig[prop] = value
                end
            end
            
            state.animConfig[animName] = newAnimConfig
            
            -- Update lookup table
            animLookup[tostring(newAnimConfig.detectid)] = newAnimConfig
        else
            warn("setAnimations: Invalid animation data for '" .. animName .. "'")
        end
    end
    
    setupConnections()
end

function module.setUltText(text, color3)
    if not validateCharacter() then return end
    
    warn("setUltText called with text: " .. tostring(text))
    
    if type(text) ~= "string" then
        warn("setUltText: Invalid text provided")
        return
    end
    
    state.ultName.Text = text
    
    if color3 and typeof(color3) == "Color3" then
        state.ultName.TextColor3 = color3
    elseif color3 then
        warn("setUltText: Invalid Color3 value provided")
    end
    
    mainSystem()
end

function module.setBarColor(color3)
    if not validateCharacter() then return end
    
    warn("setBarColor called")
    
    if not color3 or typeof(color3) ~= "Color3" then
        warn("setBarColor: Invalid Color3 value provided")
        return
    end
    
    state.barColor = color3
    mainSystem()
end

function module.setCharLabel(text)
    if not validateCharacter() then return end
    
    warn("setCharLabel called with text: " .. tostring(text))
    
    if type(text) ~= "string" then
        warn("setCharLabel: Invalid text provided")
        return
    end
    
    state.charLabel.Text = text
    mainSystem()
end

function module.setCharImage(imageId)
    if not validateCharacter() then return end
    
    warn("setCharImage called with imageId: " .. tostring(imageId))
    
    if type(imageId) ~= "string" and type(imageId) ~= "number" then
        warn("setCharImage: Invalid image ID provided")
        return
    end
    
    state.charImage.Image = tostring(imageId)
    mainSystem()
end

function module.setBothChar(data)
    if not validateCharacter() then return end
    
    warn("setBothChar called")
    
    if type(data) ~= "table" then
        warn("setBothChar: Invalid data table provided")
        return
    end
    
    if not data.Text or not data.Image then
        warn("setBothChar: Missing Text or Image property")
        return
    end
    
    if type(data.Text) ~= "string" then
        warn("setBothChar: Invalid Text value provided")
        return
    end
    
    if type(data.Image) ~= "string" and type(data.Image) ~= "number" then
        warn("setBothChar: Invalid Image value provided")
        return
    end
    
    state.charLabel.Text = data.Text
    state.charImage.Image = tostring(data.Image)
    mainSystem()
end

function module.setCooldownColor(color3)
    if not validateCharacter() then return end
    
    warn("setCooldownColor called")
    
    if not color3 or typeof(color3) ~= "Color3" then
        warn("setCooldownColor: Invalid Color3 value provided")
        return
    end
    
    state.cooldownColor = color3
    mainSystem()
end

function module.setDefaultProperties(props)
    if not validateCharacter() then return end
    
    warn("setDefaultProperties called")
    
    if type(props) ~= "table" then
        warn("setDefaultProperties: Invalid properties table provided")
        return
    end
    
    for prop, value in pairs(props) do
        state.defaultTextProperties[prop] = value
    end
    
    mainSystem()
end

function module.changePropertiesOf(element, properties)
    if not validateCharacter() then return end
    
    warn("changePropertiesOf called")
    
    if not element then
        warn("changePropertiesOf: No element provided")
        return
    end
    
    if type(properties) ~= "table" then
        warn("changePropertiesOf: Invalid properties table provided")
        return
    end
    
    safeApplyProperties(element, properties)
end

-- Initialize the system
local function initialize()
    -- Set up initial connections
    localplayer.CharacterAdded:Connect(function(char)
        character = char
        task.wait(0.1) -- Brief wait for character to fully load
        if state.isValidCharacter then
            setupConnections()
            mainSystem()
        end
    end)
    
    -- Start update loop only if character is set
    if state.isValidCharacter then
        updateloop = RunService.Heartbeat:Connect(mainSystem)
    end
    
    -- Cleanup on script removal
    if script then
        script.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanup()
            end
        end)
    end
end

-- Auto-initialize when module is loaded
initialize()

return module
