-- Script Path: game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler

game:GetService("ReplicatedStorage")
game:GetService("Players")

local Debris = game:GetService("Debris")
local Projectile = require(script.Parent.Projectile)
local ProjectileRender = require(script.Parent.ProjectileRender)
local t = {}
local t2 = {}

function t.Fire(p1) --[[ Fire | Line: 24 | Upvalues: ProjectileRender (copy), Projectile (copy), Debris (copy), t2 (copy) ]]
    local Origin = p1.Origin
    local VisualOrigin = p1.VisualOrigin
    local Force = p1.Force
    local Gravity = p1.Gravity
    local BulletId = p1.BulletId
    local Visuals = p1.Visuals
    local Logic = p1.Logic
    local Network = p1.Network
    local Misc = p1.Misc
    local v1 = Origin + p1.Direction * 800

    if (v1 - VisualOrigin).Magnitude > 4 then
        local t = {
            Wind = Vector3.new(0, 0, 0),
            Life = 5,
            Index = BulletId,
            Owner = Network.Character,
            Origin = VisualOrigin,
            Endpoint = v1,
            Force = Force,
            Gravity = Gravity,
            Type = Visuals.BulletType
        }

        ProjectileRender:Cast(t)
        Network.RenderEvent:FireServer(t)
    end

    local v2 = Projectile.new(Gravity, Vector3.new(0, 0, 0), 5, false)

    t2[BulletId] = task.spawn(function() --[[ Line: 72 | Upvalues: v2 (copy), BulletId (copy), Origin (copy), v1 (copy), Force (copy), Network (copy), Logic (copy), Debris (ref), Visuals (copy), VisualOrigin (copy), Misc (copy), ProjectileRender (ref), t2 (ref) ]]
        local _, v12 = v2:Cast(BulletId, Origin, v1, Force)
        local v22 = false
        local v3 = v1
        local v4, v5

        if v12 then
            v3 = v12.Position

            local v6 = CFrame.new(v12.Position, v12.Position + v12.Normal)

            v4 = v12.Instance

            local v7 = v4:FindFirstAncestorOfClass("Model")

            if v7 and (v7:FindFirstChild("Humanoid") and v7.Humanoid.Health > 0) then
                v22 = true

                local PlayerGui = Network.Player:FindFirstChild("PlayerGui")

                if PlayerGui and PlayerGui:FindFirstChild("GunOverlay") then
                    if Logic.HitSound then
                        local v8 = Logic.HitSound:Clone()

                        v8.Parent = PlayerGui.GunOverlay.ScreenSize
                        v8:Play()
                        Debris:AddItem(v8, 1)
                    end

                    if Logic.HitMarker then
                        local v9 = Logic.HitMarker:Clone()

                        v9.Parent = PlayerGui.GunOverlay.ScreenSize
                        Debris:AddItem(v9, 0.05)
                    end
                end
            end

            v5 = v6
        else
            v4 = nil
            v5 = nil
        end

        local t = {
            Index = BulletId,
            CFrame = v5,
            Effect = Visuals.HitEffect,
            HitPlayer = v22,
            Explosive = Logic.IsExplosive,
            ExpRadius = Logic.ExplosionRadius,
            ExpColor = Logic.ExplosionColor,
            ExpSound = Logic.ExplosionSoundId,
            Origin = VisualOrigin,
            IsLaser = Logic.IsLaser,
            LaserColor = Logic.LaserColor,
            LaserWidth = Logic.LaserWidth,
            LaserTime = Logic.LaserTime,
            LaserTexture = Logic.LaserTexture,
            LaserSpeed = Logic.LaserSpeed,
            LaserLength = Logic.LaserLength,
            LaserEmission = Logic.LaserEmission
        }

        Network.CheckShotEvent:FireServer(Misc.AmmoCount, Misc.Spread, Misc.MaxAmmo, Misc.ReloadTime, Misc.CamCFrame, v3, v4, Misc.NewSeed, BulletId)
        ProjectileRender:Delete(t)
        Network.FinishedEvent:FireServer(t)
        t2[BulletId] = nil
    end)
end

return t

-- // Function Dumper made by King.Kevin
-- // Script Path: game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler

--[[
Function Dump: Fire

Function Upvalues: Fire
        1 [table]:
        1 [table] table: 0xf0c9db7bbee6185a
                1 [function] = Cast
                2 [function] = Delete
        2 [table]:
        2 [table] table: 0x449195fd8c0f516a
                1 [function] = Cast
                2 [table] (Recursive table detected)
                3 [function] = new
        3 [Instance] = Debris
        4 [table]:
        4 [table] table: 0x4827486a7d445e1a

Function Constants: Fire
        1 [string] = Origin
        2 [string] = VisualOrigin
        3 [string] = Direction
        4 [string] = Force
        5 [string] = Gravity
        6 [string] = BulletId
        7 [string] = Visuals
        8 [string] = Logic
        9 [string] = Network
        10 [string] = Misc
        11 [number] = 800
        12 [string] = Magnitude
        13 [string] = Index
        14 [string] = Owner
        15 [string] = Endpoint
        16 [string] = Wind
        17 [Vector3] = 0, 0, 0
        18 [string] = Life
        19 [number] = 5
        20 [string] = Type
        21 [table]:
        21 [table] table: 0x67e7759d60f6783a
                1 [Vector3] = 0, 0, 0
                2 [number] = 0
                3 [number] = 0
                4 [number] = 0
                5 [number] = 0
                6 [number] = 5
                7 [number] = 0
                8 [number] = 0
                9 [number] = 0
        22 [string] = Character
        23 [string] = BulletType
        24 [string] = Cast
        25 [string] = RenderEvent
        26 [string] = FireServer
        27 [string] = new
        28 [string] = task
        29 [string] = spawn
        30 [userdata] = userdata: 0x3bc1aea83b08bf1a

====================================================================================================
]]
