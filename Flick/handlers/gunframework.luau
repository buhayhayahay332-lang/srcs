-- Script Path: game:GetService("ReplicatedStorage").ModuleScripts.GunModules.GunFramework
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

game:GetService("Debris")

local cj = require(ReplicatedStorage.ModuleScripts.cj)
local Projectile = require(script.Projectile)
local CameraHandler = require(script.CameraHandler)

require(script.Parent.ProjectileRender)

local SoundModule = require(ReplicatedStorage:WaitForChild("SoundModule"))
local SignalManager = require(ReplicatedStorage:WaitForChild("SignalManager"))
local Maid = require(ReplicatedStorage:WaitForChild("Maid"))
local MaidTracker = require(ReplicatedStorage:WaitForChild("MaidTracker"))
local Data = require(Players.LocalPlayer.PlayerScripts:FindFirstChild("Data"))
local BulletHandler = require(ReplicatedStorage.ModuleScripts.GunModules:WaitForChild("BulletHandler"))
local ProjectileRender = ReplicatedStorage.ModuleScripts.GunModules.Remote.ProjectileRender
local ProjectileFinished = ReplicatedStorage.ModuleScripts.GunModules.Remote.ProjectileFinished
local ConnectM6D = ReplicatedStorage.ModuleScripts.GunModules.Remote.ConnectM6D
local v1 = nil

local function getChildOrWait(p1, p2) --[[ getChildOrWait | Line: 38 ]]
    local v1 = p1:FindFirstChild(p2)

    while not v1 do
        p1.ChildAdded:Wait()
        v1 = p1:FindFirstChild(p2)
    end

    return v1
end

return {
    new = function(p1) --[[ new | Line: 53 | Upvalues: Maid (copy), MaidTracker (copy), getChildOrWait (copy), Players (copy), Data (copy), ReplicatedStorage (copy), Projectile (copy), RunService (copy), ProjectileRender (copy), ProjectileFinished (copy), BulletHandler (copy), SoundModule (copy), cj (copy), CameraHandler (copy), SignalManager (copy), ConnectM6D (copy), TweenService (copy), v1 (ref) ]]
        local t = {}
        local v12 = Maid.new()
        local v2 = nil

        MaidTracker.track(p1, v12)

        local v3 = getChildOrWait(p1, "BodyAttach")
        local v4 = nil
        local v5 = nil
        local v6 = nil
        local v7 = nil
        local LocalPlayer = Players.LocalPlayer
        local v8 = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local Humanoid = v8:WaitForChild("Humanoid")
        local CurrentCamera = workspace.CurrentCamera
        local fovSettings = Data.Sett.fovSettings
        local ClientRemotes = LocalPlayer:WaitForChild("ClientRemotes")
        local CheckFire = ClientRemotes:WaitForChild("CheckFire")
        local CheckShot = ClientRemotes:WaitForChild("CheckShot")
        local Reload = ClientRemotes:WaitForChild("Reload")
        local ExplosionHitmarker = ClientRemotes:FindFirstChild("ExplosionHitmarker")
        local Model = p1:FindFirstChild("Model")
        local v9 = Model and Model:FindFirstChild("Before")
        local v10 = Model and Model:FindFirstChild("After")
        local t2 = {}

        local function loadConfig(p12, p2) --[[ loadConfig | Line: 89 | Upvalues: p1 (copy), t2 (copy) ]]
            local v1 = p1:GetAttribute(p12)

            if v1 == nil then
                t2[p12] = p2
            else
                t2[p12] = v1
            end
        end

        local v11 = p1:GetAttribute("CanReload")

        if v11 == nil then
            t2.CanReload = true
        else
            t2.CanReload = v11
        end

        local v122 = p1:GetAttribute("Ammo")

        if v122 == nil then
            t2.Ammo = 1
        else
            t2.Ammo = v122
        end

        local v13 = p1:GetAttribute("Damage")

        if v13 == nil then
            t2.Damage = 10
        else
            t2.Damage = v13
        end

        local v14 = p1:GetAttribute("DamageDropoff")

        if v14 == nil then
            t2.DamageDropoff = 300
        else
            t2.DamageDropoff = v14
        end

        local v15 = p1:GetAttribute("FireRate")

        if v15 == nil then
            t2.FireRate = 0.1
        else
            t2.FireRate = v15
        end

        local v16 = p1:GetAttribute("PelletAmount")

        if v16 == nil then
            t2.PelletAmount = 1
        else
            t2.PelletAmount = v16
        end

        local v17 = p1:GetAttribute("isAuto")

        if v17 == nil then
            t2.isAuto = false
        else
            t2.isAuto = v17
        end

        local v18 = p1:GetAttribute("reloadTime")

        if v18 == nil then
            t2.reloadTime = 1
        else
            t2.reloadTime = v18
        end

        local v19 = p1:GetAttribute("spread")

        if v19 == nil then
            t2.spread = 1
        else
            t2.spread = v19
        end

        local v20 = p1:GetAttribute("ViewModelOffset")

        if v20 == nil then
            t2.ViewModelOffset = Vector3.new(0, 0, 0)
        else
            t2.ViewModelOffset = v20
        end

        local v21 = p1:GetAttribute("Cross")

        if v21 == nil then
            t2.Cross = "Normal"
        else
            t2.Cross = v21
        end

        local v22 = p1:GetAttribute("Recoil")

        if v22 == nil then
            t2.Recoil = Vector3.new(0.3, 0, 0.3)
        else
            t2.Recoil = v22
        end

        local v23 = p1:GetAttribute("BulletForce")

        if v23 == nil then
            t2.BulletForce = 110
        else
            t2.BulletForce = v23
        end

        local v24 = p1:GetAttribute("Bullet")

        if v24 == nil then
            t2.Bullet = "Bullet"
        else
            t2.Bullet = v24
        end

        local v25 = p1:GetAttribute("HitEffect")

        if v25 == nil then
            t2.HitEffect = "Gib_T"
        else
            t2.HitEffect = v25
        end

        local v26 = p1:GetAttribute("DelayedShell")

        if v26 == nil then
            t2.DelayedShell = false
        else
            t2.DelayedShell = v26
        end

        local v27 = p1:GetAttribute("EquipTime")

        if v27 == nil then
            t2.EquipTime = 0.4
        else
            t2.EquipTime = v27
        end

        local v28 = p1:GetAttribute("DelayedFire")

        if v28 == nil then
            t2.DelayedFire = false
        else
            t2.DelayedFire = v28
        end

        local v29 = p1:GetAttribute("Animations")

        if v29 == nil then
            t2.Animations = "Pistol"
        else
            t2.Animations = v29
        end

        local v30 = p1:GetAttribute("FireCAnim")

        if v30 == nil then
            t2.FireCAnim = Vector3.new(0, 0.1, 0.4)
        else
            t2.FireCAnim = v30
        end

        local v31 = p1:GetAttribute("SlideValue")

        if v31 == nil then
            t2.SlideValue = Vector3.new(0, 0, 0)
        else
            t2.SlideValue = v31
        end

        local v32 = p1:GetAttribute("SlideTime")

        if v32 == nil then
            t2.SlideTime = 0.05
        else
            t2.SlideTime = v32
        end

        local v33 = p1:GetAttribute("Gravity")

        if v33 == nil then
            t2.Gravity = 0
        else
            t2.Gravity = v33
        end

        local v34 = p1:GetAttribute("isExplosive")

        if v34 == nil then
            t2.isExplosive = false
        else
            t2.isExplosive = v34
        end

        local v35 = p1:GetAttribute("ExplosionRadius")

        if v35 == nil then
            t2.ExplosionRadius = 15
        else
            t2.ExplosionRadius = v35
        end

        local v36 = Color3.new(255/255, 153/255, 51/255)
        local v37 = p1:GetAttribute("ExplosionColor")

        if v37 == nil then
            t2.ExplosionColor = v36
        else
            t2.ExplosionColor = v37
        end

        local v38 = p1:GetAttribute("ExplosionSoundId")

        if v38 == nil then
            t2.ExplosionSoundId = "rbxassetid://2814354338"
        else
            t2.ExplosionSoundId = v38
        end

        local v39 = p1:GetAttribute("CanScope")

        if v39 == nil then
            t2.CanScope = true
        else
            t2.CanScope = v39
        end

        local v40 = p1:GetAttribute("AimFOV")

        if v40 == nil then
            t2.AimFOV = 50
        else
            t2.AimFOV = v40
        end

        local v41 = p1:GetAttribute("AimTime")

        if v41 == nil then
            t2.AimTime = 0.2
        else
            t2.AimTime = v41
        end

        local v42 = p1:GetAttribute("AimViewModelOffset")

        if v42 == nil then
            t2.AimViewModelOffset = Vector3.new(0, 0, 8)
        else
            t2.AimViewModelOffset = v42
        end

        local v43 = p1:GetAttribute("SwapPartsOnFire")

        if v43 == nil then
            t2.SwapPartsOnFire = false
        else
            t2.SwapPartsOnFire = v43
        end

        local v44 = p1:GetAttribute("InspectAnimation")

        if v44 == nil then
            t2.InspectAnimation = "Inspect"
        else
            t2.InspectAnimation = v44
        end

        local v45 = p1:GetAttribute("ShotSound")

        if v45 == nil then
            t2.ShotSound = "GunShot"
        else
            t2.ShotSound = v45
        end

        local v46 = p1:GetAttribute("CharmLimLeft")

        if v46 == nil then
            t2.CharmLimLeft = 360
        else
            t2.CharmLimLeft = v46
        end

        local v47 = p1:GetAttribute("CharmLimRight")

        if v47 == nil then
            t2.CharmLimRight = 360
        else
            t2.CharmLimRight = v47
        end

        local v48 = p1:GetAttribute("CharmLimFwd")

        if v48 == nil then
            t2.CharmLimFwd = 360
        else
            t2.CharmLimFwd = v48
        end

        local v49 = p1:GetAttribute("CharmLimBack")

        if v49 == nil then
            t2.CharmLimBack = 360
        else
            t2.CharmLimBack = v49
        end

        local v50 = p1:GetAttribute("IsLaser")

        if v50 == nil then
            t2.IsLaser = false
        else
            t2.IsLaser = v50
        end

        local v51 = Color3.new(0/255, 255/255, 255/255)
        local v52 = p1:GetAttribute("LaserColor")

        if v52 == nil then
            t2.LaserColor = v51
        else
            t2.LaserColor = v52
        end

        local v53 = p1:GetAttribute("LaserWidth")

        if v53 == nil then
            t2.LaserWidth = 3
        else
            t2.LaserWidth = v53
        end

        local v54 = p1:GetAttribute("LaserFadeTime")

        if v54 == nil then
            t2.LaserFadeTime = 0.7
        else
            t2.LaserFadeTime = v54
        end

        local v55 = p1:GetAttribute("LaserTexture")

        if v55 == nil then
            t2.LaserTexture = "rbxassetid://4813348676"
        else
            t2.LaserTexture = v55
        end

        local v56 = p1:GetAttribute("LaserTextureSpeed")

        if v56 == nil then
            t2.LaserTextureSpeed = 10
        else
            t2.LaserTextureSpeed = v56
        end

        local v57 = p1:GetAttribute("LaserTextureLength")

        if v57 == nil then
            t2.LaserTextureLength = 5
        else
            t2.LaserTextureLength = v57
        end

        local v58 = p1:GetAttribute("LaserLightEmission")

        if v58 == nil then
            t2.LaserLightEmission = 1
        else
            t2.LaserLightEmission = v58
        end

        local v59 = false
        local v60 = false
        local v61 = false
        local v62 = false
        local v63 = false
        local v64 = true
        local Ammo = t2.Ammo
        local v65 = Instance.new("NumberValue")

        v65.Value = Ammo

        local Seed = p1:WaitForChild("Seed", 1)
        local v66 = nil
        local v67 = nil
        local v68 = nil
        local GunOverlay = script.GunOverlay
        local v69 = Instance.new("StringValue")
        local v70 = Instance.new("NumberValue")
        local v71 = ReplicatedStorage.ModuleScripts.GunModules.Animations:FindFirstChild(t2.Animations)
        local t3 = {}
        local t4 = {
            Reload = script.GunSounds.Reload,
            Equip = script.GunSounds.equip,
            Gunshot = script.GunSounds:FindFirstChild(t2.ShotSound),
            Hit = script.Sounds.HitSound,
            Pump = script.GunSounds:FindFirstChild("Pump"),
            Inspect = script.GunSounds:FindFirstChild("Inspect")
        }

        Projectile.new(t2.Gravity, Vector3.new(0, 0, 0), 5, false)

        local function ForceResetStates() --[[ ForceResetStates | Line: 166 | Upvalues: v8 (ref) ]]
            if not v8 then
                return
            end

            v8:SetAttribute("IsFiring", false)
            v8:SetAttribute("IsInspecting", false)
        end

        local function syncTime(p1) --[[ syncTime | Line: 173 | Upvalues: RunService (ref) ]]
            local v1 = tick() + p1

            repeat
                RunService.Stepped:Wait()
            until v1 <= tick()
        end

        v65.Changed:Connect(function() --[[ Line: 178 | Upvalues: v69 (copy), v65 (copy) ]]
            v69.Value = if v65.Value > 9999 then "\226\136\158" else tostring(v65.Value)
        end)

        local v72 = if Seed then Seed.Value else 0

        local function getSpreadVector(p1, p2) --[[ getSpreadVector | Line: 185 | Upvalues: Seed (ref), v72 (ref) ]]
            if Seed then
                if v72 == 0 then
                    v72 = Seed.Value
                end

                v72 = v72 + 11
            else
                v72 = math.random(1, 1000)
            end

            math.randomseed(v72)

            local v1 = math.random(-p2, p2) / 100
            local v2 = math.random(-p2, p2) / 100

            return (p1 + Vector3.new(v1, v2, math.random(-p2, p2) / 100)).Unit, v72
        end

        local function castProjectile(p1, p2) --[[ castProjectile | Line: 205 | Upvalues: CurrentCamera (copy), getSpreadVector (copy), t2 (copy), t4 (copy), LocalPlayer (copy), v8 (ref), ProjectileRender (ref), CheckShot (copy), ProjectileFinished (ref), v65 (copy), BulletHandler (ref) ]]
            local v1 = CurrentCamera.CFrame
            local v2, v3 = getSpreadVector(v1.LookVector, t2.spread)

            BulletHandler.Fire({
                Origin = v1.Position,
                VisualOrigin = p1,
                Direction = v2,
                Force = t2.BulletForce,
                Gravity = t2.Gravity,
                BulletId = p2,
                Visuals = {
                    BulletType = t2.Bullet,
                    HitEffect = t2.HitEffect
                },
                Logic = {
                    IsExplosive = t2.isExplosive,
                    ExplosionRadius = t2.ExplosionRadius,
                    ExplosionColor = t2.ExplosionColor,
                    ExplosionSoundId = t2.ExplosionSoundId,
                    HitSound = t4.Hit,
                    HitMarker = script.HitMarker,
                    IsLaser = t2.IsLaser,
                    LaserColor = t2.LaserColor,
                    LaserWidth = t2.LaserWidth,
                    LaserTime = t2.LaserFadeTime,
                    LaserTexture = t2.LaserTexture,
                    LaserSpeed = t2.LaserTextureSpeed,
                    LaserLength = t2.LaserTextureLength,
                    LaserEmission = t2.LaserLightEmission
                },
                Network = {
                    Player = LocalPlayer,
                    Character = v8,
                    RenderEvent = ProjectileRender,
                    CheckShotEvent = CheckShot,
                    FinishedEvent = ProjectileFinished
                },
                Misc = {
                    AmmoCount = v65.Value,
                    MaxAmmo = t2.Ammo,
                    Spread = t2.spread,
                    ReloadTime = t2.reloadTime,
                    CamCFrame = v1,
                    NewSeed = v3,
                    ShotID = p2
                }
            })
        end

        local function fireTool() --[[ fireTool | Line: 259 | Upvalues: CheckFire (copy), CurrentCamera (copy), p1 (copy), SoundModule (ref), v8 (ref), t4 (copy), t2 (copy), castProjectile (copy) ]]
            local v1 = tick()

            CheckFire:FireServer(v1, CurrentCamera.CFrame.Position)

            local Muz = p1:FindFirstChild("Muz")
            local Muz2 = p1:FindFirstChild("Muz2")

            if Muz then
                if Muz:FindFirstChild("Flash") then
                    Muz.Flash:Emit(3)
                end

                if Muz:FindFirstChild("Smoke") then
                    Muz.Smoke:Emit(3)
                end
            end

            if Muz2 then
                if Muz2:FindFirstChild("Flash") then
                    Muz2.Flash:Emit(3)
                end

                if Muz2:FindFirstChild("Smoke") then
                    Muz2.Smoke:Emit(3)
                end
            end

            SoundModule.requestFromServer(v8.Torso, t4.Gunshot.SoundId)

            for i = 1, t2.PelletAmount do
                local v2 = if Muz then Muz.LOC.WorldPosition else Muz

                if Muz2 then
                    v2 = i % 2 == 1 and Muz.LOC.WorldPosition or Muz2.LOC.WorldPosition
                end

                castProjectile(v2, v1)
            end
        end

        local v73 = nil
        local Slide = v3:FindFirstChild("Slide")
        local v74 = Slide and Slide.C1
        local t5 = {
            firing = {
                start = function() --[[ start | Line: 297 | Upvalues: v60 (ref), v59 (ref), v65 (copy), v61 (ref), v8 (ref), v62 (ref), v73 (ref), v64 (ref), t2 (copy), t3 (copy), cj (ref), t4 (copy), p1 (copy), v74 (copy), Slide (copy), v9 (ref), v10 (ref), fireTool (copy), CameraHandler (ref), syncTime (copy) ]]
                    if v60 or (not v59 or v65.Value <= 0) then
                        return
                    end

                    v61 = false

                    if v8 then
                        v8:SetAttribute("IsFiring", false)
                        v8:SetAttribute("IsInspecting", false)
                    end

                    if v8 then
                        v8:SetAttribute("IsFiring", true)
                    end

                    repeat
                        if v62 then
                            v73(false)
                        end

                        v64 = true

                        local v1 = v62 and t2.AimViewModelOffset or t2.ViewModelOffset

                        t3.Shot:Play()
                        cj:onViewModelOffsetChanged(v1 + t2.FireCAnim, t2.FireRate / 2, Enum.EasingStyle.Back)

                        local v2 = t4.Gunshot:Clone()

                        v2.Parent = p1.Audio
                        v2:Play()
                        v2.Ended:Connect(function() --[[ Line: 316 | Upvalues: v2 (copy) ]]
                            v2:Destroy()
                        end)

                        if v74 then
                            task.delay(0, function() --[[ Line: 319 | Upvalues: Slide (ref), v74 (ref), t2 (ref) ]]
                                Slide.C1 = v74 * CFrame.new(t2.SlideValue)
                                task.wait(t2.SlideTime)
                                Slide.C1 = v74
                            end)
                        end

                        local Shell = p1:FindFirstChild("Shell")

                        if Shell then
                            Shell.ParticleEmitter:Emit(1)
                        end

                        local Shell2 = p1:FindFirstChild("Shell2")

                        if Shell2 then
                            Shell2.ParticleEmitter:Emit(1)
                        end

                        local v3 = v65

                        v3.Value = v3.Value - 1
                        v9 = p1:FindFirstChild("Before", true)
                        v10 = p1:FindFirstChild("After", true)

                        if t2.SwapPartsOnFire and (v9 and v10) then
                            v9.Transparency = 1
                            v10.Transparency = 0
                        end

                        task.wait()

                        if not t2.DelayedFire then
                            fireTool()
                        end

                        local X = t2.Recoil.X

                        CameraHandler:accelerate(0.4, 40, {
                            x = X,
                            y = {
                                min = -X / 2,
                                max = X / 2
                            }
                        }, "gun_recoil")
                        syncTime(t2.FireRate / 2)
                        cj:onViewModelOffsetChanged(v1, t2.FireRate / 2, Enum.EasingStyle.Linear)
                        syncTime(t2.FireRate / 2)

                        if t2.isAuto then
                            continue
                        end

                        v59 = false
                    until not v59 or (v65.Value <= 0 or (v60 or (not p1:FindFirstChild("EquippedValue") or (not p1.EquippedValue.Value or v61))))

                    if v8 then
                        task.delay(0.2, function() --[[ Line: 353 | Upvalues: v59 (ref), v8 (ref) ]]
                            if v59 then
                                return
                            end

                            v8:SetAttribute("IsFiring", false)
                        end)
                    end

                    t3.Shot:Stop(0)
                    t3.Idle:Play(0)

                    if v65.Value <= 0 or v61 then
                        return "reload"
                    end
                end
            },
            reload = {
                start = function() --[[ start | Line: 366 | Upvalues: t2 (copy), v62 (ref), v73 (ref), v8 (ref), v74 (copy), Slide (copy), v60 (ref), v61 (ref), t4 (copy), v69 (copy), v70 (copy), cj (ref), v9 (ref), v10 (ref), v65 (copy), Ammo (copy), Reload (copy), v64 (ref), v63 (ref), v59 (ref) ]]
                    if not t2.CanReload then
                        return
                    end

                    if v62 then
                        v73(false)
                    end

                    if v8 then
                        v8:SetAttribute("IsFiring", false)
                        v8:SetAttribute("IsInspecting", false)
                    end

                    if v74 then
                        Slide.C1 = v74
                    end

                    v60 = true
                    v61 = false
                    t4.Reload:Play()
                    v69.Value = "[Reloading]"
                    v70.Value = t2.reloadTime
                    cj:onViewModelOffsetChanged(Vector3.new(3, -6, 5), t2.reloadTime / 2, Enum.EasingStyle.Quad)
                    task.wait(t2.reloadTime / 2)
                    cj:onViewModelOffsetChanged(t2.ViewModelOffset, t2.reloadTime / 2, Enum.EasingStyle.Exponential)

                    if t2.SwapPartsOnFire and (v9 and v10) then
                        v10.Transparency = 1
                        v9.Transparency = 0
                    end

                    task.wait(t2.reloadTime / 2)
                    v65.Value = Ammo
                    v70.Value = 0
                    Reload:FireServer()
                    v60 = false
                    v64 = false

                    if v63 then
                        task.delay(0, function() --[[ Line: 399 | Upvalues: v73 (ref) ]]
                            v73(true)
                        end)
                    end

                    if v59 then
                        return "firing"
                    end
                end
            },
            equip = {
                start = function() --[[ start | Line: 407 | Upvalues: v8 (ref), cj (ref), SignalManager (ref), v3 (copy), ConnectM6D (ref), p1 (copy), Seed (ref), t3 (copy), v74 (copy), Slide (copy), v69 (copy), v65 (copy), v60 (ref), v59 (ref), v62 (ref), t2 (copy), v64 (ref), v63 (ref), v73 (ref), v61 (ref) ]]
                    if v8 then
                        v8:SetAttribute("IsFiring", false)
                        v8:SetAttribute("IsInspecting", false)
                    end

                    cj:onViewModelOffsetChanged(Vector3.new(-16, -16, 16), 0)
                    SignalManager.Fire("ViewModelVisable", true)

                    local v1 = v8:FindFirstChild("Torso") or v8:FindFirstChild("UpperTorso")

                    if v1 and v3 then
                        local ToolGrip = v1:FindFirstChild("ToolGrip")

                        if ToolGrip then
                            ToolGrip.Part0 = v1
                            ToolGrip.Part1 = v3
                        end
                    end

                    ConnectM6D:FireServer(p1)
                    Seed = p1:FindFirstChild("Seed")

                    if t3.Idle then
                        t3.Idle:Play(0)
                    else
                        task.delay(0.1, function() --[[ Line: 429 | Upvalues: t3 (ref) ]]
                            if not t3.Idle then
                                return
                            end

                            t3.Idle:Play(0)
                        end)
                    end

                    if v74 then
                        Slide.C1 = v74
                    end

                    v69.Value = tostring(v65.Value)

                    if p1:FindFirstChild("EquippedValue") then
                        p1.EquippedValue.Value = true
                    end

                    v60 = false
                    v59 = false
                    v62 = false
                    SignalManager.Fire("AimStateChanged", false)
                    cj:onViewModelOffsetChanged(t2.ViewModelOffset, t2.EquipTime, Enum.EasingStyle.Exponential)
                    task.wait(t2.EquipTime)
                    v64 = false

                    if v63 then
                        task.delay(0, function() --[[ Line: 445 | Upvalues: v73 (ref) ]]
                            v73(true)
                        end)
                    end

                    if v65.Value <= 0 or v61 then
                        return "reload"
                    end

                    if v59 then
                        return "firing"
                    end

                    return
                end
            },
            inspect = {
                start = function() --[[ start | Line: 454 | Upvalues: t3 (copy), v62 (ref), v73 (ref), t4 (copy) ]]
                    if not t3.Inspect then
                        return
                    end

                    if v62 then
                        v73(false)
                    end

                    t3.Inspect:Play()

                    if not t4.Inspect then
                        t3.Inspect.Ended:Wait()
                        t3.Inspect:Stop(0)
                        t3.Idle:Play(0)

                        return
                    end

                    t4.Inspect:Play()
                    t3.Inspect.Ended:Wait()
                    t3.Inspect:Stop(0)
                    t3.Idle:Play(0)
                end
            }
        }
        local v75 = nil
        local v76 = false

        local function v77(p1, p2) --[[ processState | Line: 476 | Upvalues: v76 (ref), v68 (ref), v8 (ref), v75 (ref), t3 (copy), t4 (copy), t5 (copy), v77 (copy) ]]
            if v76 then
                if not (if p1 == "firing" or p1 == "reload" then if v68 == "inspect" then true else false else false) then
                    return false
                end

                if v8 then
                    v8:SetAttribute("IsFiring", false)
                    v8:SetAttribute("IsInspecting", false)
                end

                if v75 then
                    task.cancel(v75)
                end

                if t3.Inspect and t3.Inspect.IsPlaying then
                    t3.Inspect:Stop(0)
                end

                if t4.Inspect and t4.Inspect.IsPlaying then
                    t4.Inspect:Stop()
                end

                v76 = false
            end

            v76 = true
            v68 = p1
            v75 = task.spawn(function() --[[ Line: 494 | Upvalues: p2 (copy), v76 (ref), v68 (ref), t5 (ref), v77 (ref) ]]
                local v1 = p2()

                v76 = false
                v68 = nil

                if type(v1) ~= "string" or not t5[v1] then
                    return
                end

                v77(v1, t5[v1].start)
            end)

            return true
        end

        local function f78(p1) --[[ Line: 505 | Upvalues: v68 (ref), v8 (ref), v75 (ref), t3 (copy), t4 (copy), v76 (ref), v64 (ref), t2 (copy), v62 (ref), SignalManager (ref), Data (ref), v66 (ref), v67 (ref), fovSettings (copy), TweenService (ref), CurrentCamera (copy), cj (ref) ]]
            if p1 and v68 == "inspect" then
                if v8 then
                    v8:SetAttribute("IsFiring", false)
                    v8:SetAttribute("IsInspecting", false)
                end

                if v75 then
                    task.cancel(v75)
                end

                if t3.Inspect and t3.Inspect.IsPlaying then
                    t3.Inspect:Stop(0)
                end

                if t4.Inspect and t4.Inspect.IsPlaying then
                    t4.Inspect:Stop()
                end

                v76 = false
                v68 = nil
            elseif p1 and (v76 or v64) then
                return
            end

            if not t2.CanScope or v62 == p1 then
                return
            end

            v62 = p1
            SignalManager.Fire("AimStateChanged", p1)

            local ScopeTransSettings = Data.Sett.ScopeTransSettings

            if v66 then
                v66.Visible = p1

                local DonutCenter = v66:FindFirstChild("DonutCenter")

                if DonutCenter then
                    DonutCenter.ImageTransparency = ScopeTransSettings
                end

                local Reticle = v66:FindFirstChild("Reticle")

                if Reticle then
                    Reticle.ImageTransparency = ScopeTransSettings
                end

                for k, v in pairs(v66:GetChildren()) do
                    if v:IsA("Frame") and v.Name:find("Bar_") then
                        v.BackgroundTransparency = ScopeTransSettings
                    end
                end
            end

            if v67 and Data.Sett.ScopeTransSettings ~= 1 then
                v67.Visible = not p1
            end

            TweenService:Create(CurrentCamera, TweenInfo.new(t2.AimTime, Enum.EasingStyle.Quad), {
                FieldOfView = p1 and t2.AimFOV or fovSettings
            }):Play()
            cj:onViewModelOffsetChanged(p1 and t2.ViewModelOffset + t2.AimViewModelOffset or t2.ViewModelOffset, 0)
        end

        local v79 = nil

        local function handleUI(p1) --[[ handleUI | Line: 562 | Upvalues: v79 (ref), GunOverlay (copy), v66 (ref), LocalPlayer (copy), v67 (ref), t2 (copy), v69 (copy), CurrentCamera (copy), v1 (ref), v70 (copy), TweenService (ref) ]]
            if p1 and not v79 then
                v79 = GunOverlay:Clone()
                v66 = v79:FindFirstChild("Scope", true)
                v79.Parent = LocalPlayer.PlayerGui

                local TextLabel = v79.ScreenSize.AmmoFrame.BarCon.TextLabel

                v67 = v79.ScreenSize.Cross
                v67[t2.Cross].Visible = true
                TextLabel.Text = v69.Value

                local function updateCrosshairScale() --[[ updateCrosshairScale | Line: 573 | Upvalues: v67 (ref), CurrentCamera (ref) ]]
                    if not v67 then
                        return
                    end

                    local UIScale = v67:FindFirstChild("UIScale")

                    if not UIScale then
                        local UIScale2 = Instance.new("UIScale")

                        UIScale2.Parent = v67
                        UIScale = UIScale2
                    end

                    UIScale.Scale = math.clamp(CurrentCamera.ViewportSize.Y / 1080, 0.5, 4)
                end

                if v67 then
                    local UIScale = v67:FindFirstChild("UIScale")

                    if not UIScale then
                        local UIScale2 = Instance.new("UIScale")

                        UIScale2.Parent = v67
                        UIScale = UIScale2
                    end

                    UIScale.Scale = math.clamp(CurrentCamera.ViewportSize.Y / 1080, 0.5, 4)
                end

                if not v1 then
                    v1 = CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCrosshairScale)
                    v69.Changed:Connect(function(p13) --[[ Line: 591 | Upvalues: v79 (ref), TextLabel (copy) ]]
                        if not v79 then
                            return
                        end

                        TextLabel.Text = p13
                    end)
                    v70.Changed:Connect(function(p13) --[[ Line: 592 | Upvalues: v79 (ref), TweenService (ref) ]]
                        if not v79 then
                            return
                        end

                        local Reload = v79.ScreenSize.Reload

                        Reload.Visible = p13 > 0

                        if not (p13 > 0) then
                            return
                        end

                        Reload.Bar.Size = UDim2.new(0, 0, 1, 0)
                        TweenService:Create(Reload.Bar, TweenInfo.new(p13, Enum.EasingStyle.Linear), {
                            Size = UDim2.new(1, 0, 1, 0)
                        }):Play()
                    end)

                    return
                end

                v1:Disconnect()
                v1 = CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCrosshairScale)
                v69.Changed:Connect(function(p13) --[[ Line: 591 | Upvalues: v79 (ref), TextLabel (copy) ]]
                    if not v79 then
                        return
                    end

                    TextLabel.Text = p13
                end)
                v70.Changed:Connect(function(p13) --[[ Line: 592 | Upvalues: v79 (ref), TweenService (ref) ]]
                    if not v79 then
                        return
                    end

                    local Reload = v79.ScreenSize.Reload

                    Reload.Visible = p13 > 0

                    if not (p13 > 0) then
                        return
                    end

                    Reload.Bar.Size = UDim2.new(0, 0, 1, 0)
                    TweenService:Create(Reload.Bar, TweenInfo.new(p13, Enum.EasingStyle.Linear), {
                        Size = UDim2.new(1, 0, 1, 0)
                    }):Play()
                end)
            else
                if p1 or not v79 then
                    return
                end

                if v1 then
                    v1:Disconnect()
                    v1 = nil
                end

                v79:Destroy()
                v79 = nil
                v66 = nil
            end
        end

        local function setupCharacter(p12) --[[ setupCharacter | Line: 614 | Upvalues: v8 (ref), Humanoid (ref), t3 (copy), v71 (copy), t2 (copy), t4 (copy), p1 (copy), fireTool (copy) ]]
            v8 = p12
            Humanoid = p12:WaitForChild("Humanoid")

            local Animator = Humanoid:WaitForChild("Animator")

            for k, v in pairs(t3) do
                if v then
                    v:Stop()
                end
            end

            t3.Idle = Animator:LoadAnimation(v71:WaitForChild("Idle"))
            t3.Reload = Animator:LoadAnimation(v71:WaitForChild("Reload"))
            t3.Shot = Animator:LoadAnimation(v71:WaitForChild("Shot"))

            if v71:FindFirstChild(t2.InspectAnimation) then
                t3.Inspect = Animator:LoadAnimation(v71:FindFirstChild(t2.InspectAnimation))
            end

            t3.Shot:GetMarkerReachedSignal("Pump"):Connect(function() --[[ Line: 629 | Upvalues: t4 (ref), p1 (ref) ]]
                if t4.Pump then
                    t4.Pump:Play()
                end

                local Shell = p1:FindFirstChild("Shell")

                if not Shell then
                    return
                end

                Shell.ParticleEmitter:Emit(1)
            end)

            if not t2.DelayedFire then
                return
            end

            t3.Shot:GetMarkerReachedSignal("Fire"):Connect(fireTool)
        end

        CheckShot.OnClientEvent:Connect(function(p1) --[[ Line: 633 | Upvalues: v65 (copy) ]]
            if v65.Value == p1 then
                return
            end

            v65.Value = p1
        end)

        if not ExplosionHitmarker then
            setupCharacter(v8)
            LocalPlayer.CharacterAdded:Connect(setupCharacter)
            p1.Equipped:Connect(function() --[[ Line: 644 | Upvalues: v2 (ref), Maid (ref), cj (ref), v8 (ref), setupCharacter (copy), LocalPlayer (copy), v70 (copy), handleUI (copy), v4 (ref), p1 (copy), v5 (ref), v6 (ref), v3 (copy), v7 (ref), SignalManager (ref), v59 (ref), v77 (copy), t5 (copy), v60 (ref), v65 (copy), Ammo (copy), v61 (ref), v63 (ref), f78 (ref), v76 (ref), v68 (ref), v75 (ref), CurrentCamera (copy), RunService (ref), Humanoid (ref), t2 (copy) ]]
                if v2 then
                    v2:Destroy()
                end

                v2 = Maid.new()
                cj:onViewModelOffsetChanged(Vector3.new(-16, -16, 16), 0)

                if not (v8 and v8.Parent) then
                    setupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
                end

                v70.Value = 0
                handleUI(true)
                v4 = p1:FindFirstChild("Charm")
                v5 = v4 and v4:FindFirstChildWhichIsA("Motor6D")
                v6 = v3 and v3:FindFirstChild("RotationPoint")

                if not v7 and v5 then
                    v7 = v5.C1
                end

                if v5 and v7 then
                    v5.C1 = v7
                end

                v2:GiveTask(SignalManager.Connect("FireWeapon", function(p13) --[[ Line: 661 | Upvalues: p1 (ref), v59 (ref), v77 (ref), t5 (ref) ]]
                    if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                        return
                    end

                    if p13 == Enum.UserInputState.Begin then
                        v59 = true

                        if not v77("firing", t5.firing.start) then
                            v59 = true
                        end
                    else
                        v59 = false
                    end
                end))
                v2:GiveTask(SignalManager.Connect("FireWeaponMoblie", function(p13) --[[ Line: 669 | Upvalues: p1 (ref), v60 (ref), v59 (ref), v77 (ref), t5 (ref) ]]
                    if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                        return
                    end

                    if p13 == Enum.UserInputState.Begin and not v60 then
                        v59 = true

                        if not v77("firing", t5.firing.start) then
                            v59 = true
                        end
                    else
                        v59 = false
                    end
                end))
                v2:GiveTask(SignalManager.Connect("ReloadWeapon", function() --[[ Line: 677 | Upvalues: p1 (ref), v60 (ref), v65 (ref), Ammo (ref), v61 (ref), v77 (ref), t5 (ref) ]]
                    if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                        return
                    end

                    if v60 or not (v65.Value < Ammo) then
                        return
                    end

                    v61 = true
                    v77("reload", t5.reload.start)
                end))
                v2:GiveTask(SignalManager.Connect("AimWeapon", function(p13) --[[ Line: 684 | Upvalues: p1 (ref), v63 (ref), f78 (ref) ]]
                    if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                        return
                    end

                    v63 = p13 == Enum.UserInputState.Begin
                    f78(v63)
                end))
                v2:GiveTask(SignalManager.Connect("InspectWeapon", function() --[[ Line: 689 | Upvalues: p1 (ref), t5 (ref), v76 (ref), v68 (ref), v75 (ref), v77 (ref) ]]
                    if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                        return
                    end

                    local start = t5.inspect.start

                    if not v76 then
                        v76 = true
                        v68 = "inspect"
                        v75 = task.spawn(function() --[[ Line: 494 | Upvalues: start (copy), v76 (ref), v68 (ref), t5 (ref), v77 (ref) ]]
                            local v1 = start()

                            v76 = false
                            v68 = nil

                            if type(v1) ~= "string" or not t5[v1] then
                                return
                            end

                            v77(v1, t5[v1].start)
                        end)
                    end
                end))

                if v4 and (v5 and (v6 and v7)) then
                    local v52 = v3.CFrame
                    local v62 = v8 and v8.PrimaryPart and v8.PrimaryPart.AssemblyLinearVelocity or Vector3.new()
                    local v72 = CurrentCamera.CFrame
                    local v82 = Vector3.new()
                    local v9 = Vector3.new(0, -1, 0)

                    v2:GiveTask((RunService.RenderStepped:Connect(function(p13) --[[ Line: 710 | Upvalues: v9 (ref), v82 (ref), v5 (ref), v3 (ref), v6 (ref), v8 (ref), Humanoid (ref), CurrentCamera (ref), v62 (ref), v72 (ref), t2 (ref), v7 (ref), v52 (ref) ]]
                        if v9.X ~= v9.X or v82.X ~= v82.X then
                            v9 = Vector3.new(0, -1, 0)
                            v82 = Vector3.new()
                        end

                        if not (v5 and (v5.Part1 and (v3 and (v6 and (v8 and (Humanoid and v8.PrimaryPart)))))) then
                            return
                        end

                        local v1 = math.min(p13, 0.03333333333333333)
                        local v2 = v3.CFrame
                        local v32 = CurrentCamera.CFrame
                        local v4 = v8.PrimaryPart and v8.PrimaryPart.AssemblyLinearVelocity or Vector3.new()
                        local v53 = (v4 - v62) / v1

                        if v53.Magnitude > 300 then
                            v53 = v53.Unit * 300
                        end

                        local v63, v73 = v72:ToObjectSpace(v32):ToAxisAngle()
                        local v83 = v63 * math.min(v73 / v1, 15)
                        local v92 = v9:Cross((v2:VectorToObjectSpace(Vector3.new(0, -1, 0)))) * 200
                        local v10 = -v53 * 0.3
                        local v11 = (v32.RightVector * -v83.Y + v32.UpVector * -v83.X) * -4

                        if v10.Magnitude > 50 then
                            v10 = v10.Unit * 50
                        end

                        if v11.Magnitude > 50 then
                            v11 = v11.Unit * 50
                        end

                        local v122 = v92 + v9:Cross(v2:VectorToObjectSpace(v10 + v11)) - v82 * 10

                        if v122.Magnitude > 1000 then
                            v122 = v122.Unit * 1000
                        end

                        local v13 = v82 + v122 * v1

                        if v13.Magnitude > 30 then
                            v13 = v13.Unit * 30
                        end

                        local v14 = v13 * v1
                        local Unit = (CFrame.fromAxisAngle(v14.Unit, v14.Magnitude) * v9).Unit
                        local v16 = math.atan2(Unit.X, -Unit.Y)
                        local v18 = math.atan2(Unit.Z, -Unit.Y)
                        local v19 = -math.rad(t2.CharmLimLeft)
                        local v20 = math.rad(t2.CharmLimRight)
                        local v21 = -math.rad(t2.CharmLimFwd)
                        local v222 = math.rad(t2.CharmLimBack)

                        if v16 == math.clamp(v16, v19, v20) and v18 == math.clamp(v18, v21, v222) then
                            v82 = v13
                            v9 = Unit
                        else
                            v82 = Vector3.new(0, 0, 0)

                            local v24 = math.atan2(v9.X, -v9.Y)
                            local v26 = math.atan2(v9.Z, -v9.Y)
                            local v27 = math.clamp(v24, v19, v20)
                            local v28 = math.clamp(v26, v21, v222)

                            if v24 ~= v27 or v26 ~= v28 then
                                v9 = (CFrame.Angles(v28, 0, -v27) * Vector3.new(0, -1, 0)).Unit
                            end
                        end

                        local v29 = (Vector3.new(0, -1, 0)):Cross(v9)
                        local v30 = if v29.Magnitude < 0.001 then (Vector3.new(0, -1, 0)):Dot(v9) > 0 and CFrame.new() or CFrame.fromAxisAngle(Vector3.new(1, 0, 0), math.pi) else CFrame.fromAxisAngle(v29.Unit, (math.acos((math.clamp((Vector3.new(0, -1, 0)):Dot(v9), -1, 1)))))
                        local v36 = v6.CFrame

                        v5.C1 = v36 * v30 * v36:Inverse() * v7
                        v52 = v2
                        v62 = v4
                        v72 = v32
                    end)))
                end

                local start = t5.equip.start

                if not v76 then
                    v76 = true
                    v68 = "equip"
                    v75 = task.spawn(function() --[[ Line: 494 | Upvalues: start (copy), v76 (ref), v68 (ref), t5 (ref), v77 (ref) ]]
                        local v1 = start()

                        v76 = false
                        v68 = nil

                        if type(v1) ~= "string" or not t5[v1] then
                            return
                        end

                        v77(v1, t5[v1].start)
                    end)
                end
            end)
            p1.Unequipped:Connect(function() --[[ Line: 808 | Upvalues: SignalManager (ref), v2 (ref), v62 (ref), f78 (ref), v64 (ref), v63 (ref), v8 (ref), cj (ref), p1 (copy), v79 (ref), v1 (ref), v66 (ref), v76 (ref), v68 (ref), v75 (ref), t4 (copy), t3 (copy) ]]
                SignalManager.Fire("ViewModelVisable", false)

                if v2 then
                    v2:Destroy()
                    v2 = nil
                end

                if v62 then
                    f78(false)
                end

                v64 = true
                v63 = false

                if v8 then
                    v8:SetAttribute("IsFiring", false)
                    v8:SetAttribute("IsInspecting", false)
                end

                cj:onViewModelOffsetChanged(Vector3.new(-3, -16, 16), 0)

                if p1:FindFirstChild("Seed") then
                    p1.Seed.Value = 0
                end

                if v79 then
                    if v1 then
                        v1:Disconnect()
                        v1 = nil
                    end

                    v79:Destroy()
                    v79 = nil
                    v66 = nil
                end

                v76 = false
                v68 = nil

                if v75 then
                    task.cancel(v75)
                end

                t4.Reload:Stop()
                t4.Equip:Stop()

                if p1:FindFirstChild("EquippedValue") then
                    p1.EquippedValue.Value = false
                end

                for k2, v in pairs(t3) do
                    v:Stop()
                end
            end)

            return t
        end

        ExplosionHitmarker.OnClientEvent:Connect(function() --[[ Line: 638 ]] end)
        setupCharacter(v8)
        LocalPlayer.CharacterAdded:Connect(setupCharacter)
        p1.Equipped:Connect(function() --[[ Line: 644 | Upvalues: v2 (ref), Maid (ref), cj (ref), v8 (ref), setupCharacter (copy), LocalPlayer (copy), v70 (copy), handleUI (copy), v4 (ref), p1 (copy), v5 (ref), v6 (ref), v3 (copy), v7 (ref), SignalManager (ref), v59 (ref), v77 (copy), t5 (copy), v60 (ref), v65 (copy), Ammo (copy), v61 (ref), v63 (ref), f78 (ref), v76 (ref), v68 (ref), v75 (ref), CurrentCamera (copy), RunService (ref), Humanoid (ref), t2 (copy) ]]
            if v2 then
                v2:Destroy()
            end

            v2 = Maid.new()
            cj:onViewModelOffsetChanged(Vector3.new(-16, -16, 16), 0)

            if not (v8 and v8.Parent) then
                setupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
            end

            v70.Value = 0
            handleUI(true)
            v4 = p1:FindFirstChild("Charm")
            v5 = v4 and v4:FindFirstChildWhichIsA("Motor6D")
            v6 = v3 and v3:FindFirstChild("RotationPoint")

            if not v7 and v5 then
                v7 = v5.C1
            end

            if v5 and v7 then
                v5.C1 = v7
            end

            v2:GiveTask(SignalManager.Connect("FireWeapon", function(p13) --[[ Line: 661 | Upvalues: p1 (ref), v59 (ref), v77 (ref), t5 (ref) ]]
                if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                    return
                end

                if p13 == Enum.UserInputState.Begin then
                    v59 = true

                    if not v77("firing", t5.firing.start) then
                        v59 = true
                    end
                else
                    v59 = false
                end
            end))
            v2:GiveTask(SignalManager.Connect("FireWeaponMoblie", function(p13) --[[ Line: 669 | Upvalues: p1 (ref), v60 (ref), v59 (ref), v77 (ref), t5 (ref) ]]
                if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                    return
                end

                if p13 == Enum.UserInputState.Begin and not v60 then
                    v59 = true

                    if not v77("firing", t5.firing.start) then
                        v59 = true
                    end
                else
                    v59 = false
                end
            end))
            v2:GiveTask(SignalManager.Connect("ReloadWeapon", function() --[[ Line: 677 | Upvalues: p1 (ref), v60 (ref), v65 (ref), Ammo (ref), v61 (ref), v77 (ref), t5 (ref) ]]
                if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                    return
                end

                if v60 or not (v65.Value < Ammo) then
                    return
                end

                v61 = true
                v77("reload", t5.reload.start)
            end))
            v2:GiveTask(SignalManager.Connect("AimWeapon", function(p13) --[[ Line: 684 | Upvalues: p1 (ref), v63 (ref), f78 (ref) ]]
                if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                    return
                end

                v63 = p13 == Enum.UserInputState.Begin
                f78(v63)
            end))
            v2:GiveTask(SignalManager.Connect("InspectWeapon", function() --[[ Line: 689 | Upvalues: p1 (ref), t5 (ref), v76 (ref), v68 (ref), v75 (ref), v77 (ref) ]]
                if not (p1:FindFirstChild("EquippedValue") and p1.EquippedValue.Value) then
                    return
                end

                local start = t5.inspect.start

                if not v76 then
                    v76 = true
                    v68 = "inspect"
                    v75 = task.spawn(function() --[[ Line: 494 | Upvalues: start (copy), v76 (ref), v68 (ref), t5 (ref), v77 (ref) ]]
                        local v1 = start()

                        v76 = false
                        v68 = nil

                        if type(v1) ~= "string" or not t5[v1] then
                            return
                        end

                        v77(v1, t5[v1].start)
                    end)
                end
            end))

            if v4 and (v5 and (v6 and v7)) then
                local v52 = v3.CFrame
                local v62 = v8 and v8.PrimaryPart and v8.PrimaryPart.AssemblyLinearVelocity or Vector3.new()
                local v72 = CurrentCamera.CFrame
                local v82 = Vector3.new()
                local v9 = Vector3.new(0, -1, 0)

                v2:GiveTask((RunService.RenderStepped:Connect(function(p13) --[[ Line: 710 | Upvalues: v9 (ref), v82 (ref), v5 (ref), v3 (ref), v6 (ref), v8 (ref), Humanoid (ref), CurrentCamera (ref), v62 (ref), v72 (ref), t2 (ref), v7 (ref), v52 (ref) ]]
                    if v9.X ~= v9.X or v82.X ~= v82.X then
                        v9 = Vector3.new(0, -1, 0)
                        v82 = Vector3.new()
                    end

                    if not (v5 and (v5.Part1 and (v3 and (v6 and (v8 and (Humanoid and v8.PrimaryPart)))))) then
                        return
                    end

                    local v1 = math.min(p13, 0.03333333333333333)
                    local v2 = v3.CFrame
                    local v32 = CurrentCamera.CFrame
                    local v4 = v8.PrimaryPart and v8.PrimaryPart.AssemblyLinearVelocity or Vector3.new()
                    local v53 = (v4 - v62) / v1

                    if v53.Magnitude > 300 then
                        v53 = v53.Unit * 300
                    end

                    local v63, v73 = v72:ToObjectSpace(v32):ToAxisAngle()
                    local v83 = v63 * math.min(v73 / v1, 15)
                    local v92 = v9:Cross((v2:VectorToObjectSpace(Vector3.new(0, -1, 0)))) * 200
                    local v10 = -v53 * 0.3
                    local v11 = (v32.RightVector * -v83.Y + v32.UpVector * -v83.X) * -4

                    if v10.Magnitude > 50 then
                        v10 = v10.Unit * 50
                    end

                    if v11.Magnitude > 50 then
                        v11 = v11.Unit * 50
                    end

                    local v122 = v92 + v9:Cross(v2:VectorToObjectSpace(v10 + v11)) - v82 * 10

                    if v122.Magnitude > 1000 then
                        v122 = v122.Unit * 1000
                    end

                    local v13 = v82 + v122 * v1

                    if v13.Magnitude > 30 then
                        v13 = v13.Unit * 30
                    end

                    local v14 = v13 * v1
                    local Unit = (CFrame.fromAxisAngle(v14.Unit, v14.Magnitude) * v9).Unit
                    local v16 = math.atan2(Unit.X, -Unit.Y)
                    local v18 = math.atan2(Unit.Z, -Unit.Y)
                    local v19 = -math.rad(t2.CharmLimLeft)
                    local v20 = math.rad(t2.CharmLimRight)
                    local v21 = -math.rad(t2.CharmLimFwd)
                    local v222 = math.rad(t2.CharmLimBack)

                    if v16 == math.clamp(v16, v19, v20) and v18 == math.clamp(v18, v21, v222) then
                        v82 = v13
                        v9 = Unit
                    else
                        v82 = Vector3.new(0, 0, 0)

                        local v24 = math.atan2(v9.X, -v9.Y)
                        local v26 = math.atan2(v9.Z, -v9.Y)
                        local v27 = math.clamp(v24, v19, v20)
                        local v28 = math.clamp(v26, v21, v222)

                        if v24 ~= v27 or v26 ~= v28 then
                            v9 = (CFrame.Angles(v28, 0, -v27) * Vector3.new(0, -1, 0)).Unit
                        end
                    end

                    local v29 = (Vector3.new(0, -1, 0)):Cross(v9)
                    local v30 = if v29.Magnitude < 0.001 then (Vector3.new(0, -1, 0)):Dot(v9) > 0 and CFrame.new() or CFrame.fromAxisAngle(Vector3.new(1, 0, 0), math.pi) else CFrame.fromAxisAngle(v29.Unit, (math.acos((math.clamp((Vector3.new(0, -1, 0)):Dot(v9), -1, 1)))))
                    local v36 = v6.CFrame

                    v5.C1 = v36 * v30 * v36:Inverse() * v7
                    v52 = v2
                    v62 = v4
                    v72 = v32
                end)))
            end

            local start = t5.equip.start

            if not v76 then
                v76 = true
                v68 = "equip"
                v75 = task.spawn(function() --[[ Line: 494 | Upvalues: start (copy), v76 (ref), v68 (ref), t5 (ref), v77 (ref) ]]
                    local v1 = start()

                    v76 = false
                    v68 = nil

                    if type(v1) ~= "string" or not t5[v1] then
                        return
                    end

                    v77(v1, t5[v1].start)
                end)
            end
        end)
        p1.Unequipped:Connect(function() --[[ Line: 808 | Upvalues: SignalManager (ref), v2 (ref), v62 (ref), f78 (ref), v64 (ref), v63 (ref), v8 (ref), cj (ref), p1 (copy), v79 (ref), v1 (ref), v66 (ref), v76 (ref), v68 (ref), v75 (ref), t4 (copy), t3 (copy) ]]
            SignalManager.Fire("ViewModelVisable", false)

            if v2 then
                v2:Destroy()
                v2 = nil
            end

            if v62 then
                f78(false)
            end

            v64 = true
            v63 = false

            if v8 then
                v8:SetAttribute("IsFiring", false)
                v8:SetAttribute("IsInspecting", false)
            end

            cj:onViewModelOffsetChanged(Vector3.new(-3, -16, 16), 0)

            if p1:FindFirstChild("Seed") then
                p1.Seed.Value = 0
            end

            if v79 then
                if v1 then
                    v1:Disconnect()
                    v1 = nil
                end

                v79:Destroy()
                v79 = nil
                v66 = nil
            end

            v76 = false
            v68 = nil

            if v75 then
                task.cancel(v75)
            end

            t4.Reload:Stop()
            t4.Equip:Stop()

            if p1:FindFirstChild("EquippedValue") then
                p1.EquippedValue.Value = false
            end

            for k2, v in pairs(t3) do
                v:Stop()
            end
        end)

        return t
    end
}
