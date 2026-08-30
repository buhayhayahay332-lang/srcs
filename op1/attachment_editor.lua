local Module = {
    _initialized = false,
    shared = nil,
    _replicatedStorage = nil,
    _viewmodels = nil,
    _attachmentModules = {},
    _viewmodelsAddedConn = nil,
    _localViewmodelChildConn = nil,
    _pendingAutoApply = false,
    config = {
        fixSkins = false,
        skin = "Default",
        charm = "Default",
    },
    options = {
        skin = { "Default","TidalWaveAK", "CherryBlossom","RoyalCAL12","RedLineAW50","RedLineReaper", "BlueFlowers", "Synthwave", "TigerCamo", "Toxic", "ToyGunM4", "YellowPattern", "RedRoses", "BlackCamo", "Blue", "CarbonFiber", "Cardboard", "CheckeredSkin", "ClassicAA12", "CrackedEarth", "DarkRedCamo", "DeepRed", "DesertCamo", "Diamond", "FestiveLightsM4", "ForestCamo", "FrenchSticker", "Ghillie", "GhostShipSkin", "GhostSkin", "GhostStickerSkin", "Golden", "Green", "HalloweenParty", "HazardMP7", "HazardSkin", "HotRedL85", "Kalash", "MakeshiftBeretta", "NeonShapesM249", "OilSpill", "PurpleFadeC775", "Red", "RustyAUG", "Skulls", "SnowCamo", "Space", "SpiderWebSkin", "Splattered", "Steyr", "Tan", "Toxic", "WastelandRSh12", "White", "Yellow" },
        charm = { "Default", "DiamondBurgerCharm", "FishCharm", "GoldMedal", "GoldenTrophy", "HourglassCharm", "JussisCharm", "LoveHeart", "MedalTVCharm", "NXTCharm", "StaffCharm", "TSKCharm", "WalkieTalkieCharm", "YinYangCharm", "8BallCharm", "AceCard", "BananaCharm", "BellCharm", "BlueBall", "BulletCharm", "ChristmasTreeCharm", "ColorfulSquares", "DiamondCharm", "DogTagCharm", "EyeballCharm", "GhostCharm", "LoveHeart", "LuckyCharm", "PumpkinCharm", "S1Bronze", "S1Champion", "S1Diamond", "S1Gold", "S1Platinum", "S1Silver", "S2Bronze", "S2Champion", "S2Diamond", "S2Gold", "S2Platinum", "S2Silver", "SnowGlobeCharm", "SnowflakeCharm", "TargetPracticeCharm" },
    },
}

function Module:setShared(shared)
    if type(shared) ~= "table" then
        return false, "shared must be table"
    end

    self.shared = shared
    if type(shared.applyToEnv) == "function" then
        shared:applyToEnv()
    end

    return true
end

function Module:_getLocalPlayerGun()
    local viewmodels = self._viewmodels
    if not viewmodels then
        return nil
    end

    local localViewmodel = viewmodels:FindFirstChild("LocalViewmodel")
    if not localViewmodel then
        return nil
    end

    for _, child in ipairs(localViewmodel:GetChildren()) do
        if child:FindFirstChild("Gun") then
            return { instance = child }
        end
    end

    for _, child in ipairs(localViewmodel:GetChildren()) do
        if child:FindFirstChild("Shield") then
            return { instance = child }
        end
    end

    return nil
end

function Module:_findAttachmentAsset(moduleFolder, assetName)
    if not moduleFolder then
        return nil
    end

    local directChild = moduleFolder:FindFirstChild(assetName)
    if directChild then
        return directChild
    end

    for _, descendant in ipairs(moduleFolder:GetDescendants()) do
        if descendant.Name == assetName then
            return descendant
        end
    end

    return nil
end

function Module:_applyAttachment(moduleName, settingKey)
    local gun = self:_getLocalPlayerGun()
    if not gun then
        return false, "local gun not found"
    end

    local attachmentModule = self._attachmentModules[moduleName]
    if not attachmentModule then
        return false, "attachment module not found: " .. tostring(moduleName)
    end

    local selectedValue = self.config[settingKey]
    if selectedValue == "Default" then
        attachmentModule.remove(attachmentModule, gun)
        return true
    end

    local assetModule = self:_findAttachmentAsset(attachmentModule.module, selectedValue)
    if not assetModule then
        return false, "attachment asset not found: " .. tostring(selectedValue)
    end

    attachmentModule.remove(attachmentModule, gun)
    attachmentModule.apply(require(assetModule), gun)

    local selfRef = self
    task.defer(function()
        if not gun or not gun.instance then return end
        for _, v in ipairs(gun.instance:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Name == "ReticuleSight" or v.Name == "RedDot" or v.Name == "Dot" then
                    v.Transparency = 0
                    v.LocalTransparencyModifier = 0
                end

               
                if selfRef.config.fixSkins then
                    local original = v:GetAttribute("OriginalTransparency")
                    if original and v.Transparency > original then
                        v.Transparency = original
                        v.LocalTransparencyModifier = 0
                    end
                end
            end
        end
    end)

    return true
end

function Module:_shouldAutoApply()
    return self.config.skin ~= "Default" or self.config.charm ~= "Default"
end

function Module:_scheduleAutoApply()
    if not self:_shouldAutoApply() or self._pendingAutoApply then
        return
    end

    self._pendingAutoApply = true
    task.delay(0.2, function()
        self._pendingAutoApply = false
        if not self:_shouldAutoApply() then
            return
        end

        pcall(function()
            self:applyAll()
        end)
    end)
end

function Module:_bindLocalViewmodel(localViewmodel)
    if self._localViewmodelChildConn then
        self._localViewmodelChildConn:Disconnect()
        self._localViewmodelChildConn = nil
    end

    if not localViewmodel then
        return
    end

    self._localViewmodelChildConn = localViewmodel.ChildAdded:Connect(function(child)
        if child:FindFirstChild("Gun") or child:FindFirstChild("Shield") then
            self:_scheduleAutoApply()
        end
    end)

    for _, child in ipairs(localViewmodel:GetChildren()) do
        if child:FindFirstChild("Gun") or child:FindFirstChild("Shield") then
            self:_scheduleAutoApply()
            break
        end
    end
end

function Module:init(force)
    if self._initialized and not force then
        return true
    end

    self._replicatedStorage = game:GetService("ReplicatedStorage")
    self._viewmodels = workspace:WaitForChild("Viewmodels")

    local attachmentRoot = self._replicatedStorage.Modules.Items.Item.Attachment
    local loadedModules = {}
    for _, moduleScript in ipairs(attachmentRoot:GetChildren()) do
        local okRequire, attachmentModule = pcall(require, moduleScript)
        if okRequire and type(attachmentModule) == "table" then
            loadedModules[moduleScript.Name] = attachmentModule
            attachmentModule.module = moduleScript
        end
    end

    self._attachmentModules = loadedModules

    if not self._viewmodelsAddedConn then
        self._viewmodelsAddedConn = self._viewmodels.ChildAdded:Connect(function(child)
            if child.Name == "LocalViewmodel" then
                self:_bindLocalViewmodel(child)
                self:_scheduleAutoApply()
            end
        end)
    end

    self:_bindLocalViewmodel(self._viewmodels:FindFirstChild("LocalViewmodel"))
    self._initialized = true
    return true
end

function Module:load(force)
    return self:init(force)
end

function Module:setOption(key, value)
    if self.config[key] == nil then
        return false, "unknown attachment key: " .. tostring(key)
    end

    local okInit, initErr = self:init(false)
    if not okInit then
        return false, initErr
    end

    if key == "fixSkins" then
        self.config[key] = value == true
        self:applyAll()
        return true
    end

    self.config[key] = tostring(value)

    local moduleMap = {
        skin = "Skin",
        charm = "Charm",
    }

    if self.config[key] ~= "Default" then
        return self:_applyAttachment(moduleMap[key], key)
    end

    return true
end

function Module:updateConfig(newConfig)
    if type(newConfig) ~= "table" then
        return false, "config must be table"
    end

    for key, value in pairs(newConfig) do
        if self.config[key] ~= nil then
            if key == "fixSkins" then
                self.config[key] = value == true
            else
                self.config[key] = tostring(value)
            end
        end
    end

    return true
end

function Module:getOptions()
    return self.options
end

function Module:getConfig()
    return self.config
end

function Module:applyAll()
    local okInit, initErr = self:init(false)
    if not okInit then
        return false, initErr
    end

    local order = {
        { module = "Skin", key = "skin" },
        { module = "Charm", key = "charm" },
    }

    for _, entry in ipairs(order) do
        local okApply, applyErr = self:_applyAttachment(entry.module, entry.key)
        if okApply == false then
            return false, applyErr
        end
    end

    return true
end

return Module
