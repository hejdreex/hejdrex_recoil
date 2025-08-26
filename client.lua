local cfg = {
    baseRecoil         = 0.6,
    steps              = 6,
    stepDelayMs        = 10,
    vehicleMultiplier  = 1.25,
    adsMultiplier      = 0.90,
    hipfireMultiplier  = 1.10,
}

local groupMult = {
    -- Guns
    [GetHashKey("GROUP_PISTOL")]   = 0.90,
    [GetHashKey("GROUP_SMG")]      = 1.15,
    [GetHashKey("GROUP_RIFLE")]    = 1.35,
    [GetHashKey("GROUP_MG")]       = 1.50,
    [GetHashKey("GROUP_SHOTGUN")]  = 1.65,
    [GetHashKey("GROUP_SNIPER")]   = 1.85,
    [GetHashKey("GROUP_HEAVY")]    = 2.00,
    -- You can add here more groups
    -- Melee
    [GetHashKey("GROUP_MELEE")]    = 0.00,
    [GetHashKey("GROUP_THROWN")]   = 0.00,
    [GetHashKey("GROUP_PETROLCAN")] = 0.00,
    -- You can add here more groups
}

local function EnsureNoDrunkShake()
    if IsGameplayCamShaking() then
        StopGameplayCamShaking(true)
    end
end

local function GetRecoilForCurrentShot(ped)
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == 0 or weapon == nil then return 0.0 end

    local groupHash = GetWeapontypeGroup(weapon)
    local gm = groupMult[groupHash] or 1.0

    local recoil = cfg.baseRecoil * gm

    if IsPlayerFreeAiming(PlayerId()) then
        recoil = recoil * cfg.adsMultiplier
    else
        recoil = recoil * cfg.hipfireMultiplier
    end

    if IsPedInAnyVehicle(ped, false) then
        recoil = recoil * cfg.vehicleMultiplier
    end

    return recoil
end

local function ApplyRecoilStep(amount)
    local current = GetGameplayCamRelativePitch()
    local target = current - amount
    SetGameplayCamRelativePitch(target, 1.0)
end

local function ApplyRecoilSmooth(totalAmount, steps, delayMs)
    if totalAmount <= 0.0 or steps <= 0 then return end
    local stepAmount = totalAmount / steps
    for i = 1, steps do
        ApplyRecoilStep(stepAmount)
        Wait(delayMs)
    end
end

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        EnsureNoDrunkShake()

        if not IsEntityDead(ped) and IsPedArmed(ped, 4) then
            if IsPedShooting(ped) then
                local recoil = GetRecoilForCurrentShot(ped)

                local steps = cfg.steps
                if IsControlPressed(0, 24) then
                    steps = steps + 2
                end

                ApplyRecoilSmooth(recoil, steps, cfg.stepDelayMs)
            end
        end
    end
end)
