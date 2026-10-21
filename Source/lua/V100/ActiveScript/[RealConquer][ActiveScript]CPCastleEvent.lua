-- =========================================================
-- CONFIG
-- =========================================================

local CP_CONFIG = {
    NPC_ENTRANCE = 999889,
    NPC_EXIT     = 999778,
    MAP_EVENT    = 9978,
    MAP_TOWN     = 1002,
    MONSTER_ID   = 3323,
    MIN_LEVEL    = 100,
}

local VIP6_CP_MULTIPLIER = 1.0       
local VIP4_DOUBLE_DROP_CHANCE = 0.20 

local EVENT_POOL = {
    [721026] = {val=50,  name="FlameCPBag"},
    [721027] = {val=100, name="StarCPBag"},
    [721028] = {val=200, name="CyanCPBag"},
    [721029] = {val=250, name="SnowCPBag"},
    [721038] = {val=500, name="JadeCPBag"},
}

local EVENT_POOL_KEYS = {
    721026, 721026, 721027, 721027, 721028, 721029, 721038
}

-- =========================================================
-- DIALOG ENTRANCE
-- =========================================================

local nEntId = CP_CONFIG.NPC_ENTRANCE

tNpcGossip[nEntId] = tNpcGossip[nEntId] or DefaultNpc:new{}
tNpcGossip[nEntId]["OptionHidden"] = 1

tNpcGossip[nEntId]["Text1-1"] = {111}

tNpcGossip[nEntId]["Text111"] =
    "The CP Castle is an extremely dangerous place where the world's greatest\n" ..
    "treasures can be found. You may enter everyday at 14:00 and 20:00.\n" ..
    "It will only be open for 15 minutes each time, so be quick about it!"

tNpcGossip[nEntId]["tOption1-1"] = {1, 2}

tNpcGossip[nEntId]["Option1"] = "Send me there!"
tNpcGossip[nEntId]["OptionFunc1"] = "CP_Castle_Enter</N>" .. nEntId

tNpcGossip[nEntId]["Option2"] = "Just passing by."
tNpcGossip[nEntId]["OptionFunc2"] = "CP_Castle_Close</N>" .. nEntId

-- =========================================================
-- DIALOG EXIT
-- =========================================================

local nExitId = CP_CONFIG.NPC_EXIT

tNpcGossip[nExitId] = tNpcGossip[nExitId] or DefaultNpc:new{}

tNpcGossip[nExitId]["Text1-1"] = {"Return to Twin City?"}
tNpcGossip[nExitId]["tOption1-1"] = {1}

tNpcGossip[nExitId]["Option1"] = "Yes"
tNpcGossip[nExitId]["OptionFunc1"] = "CP_Castle_Exit</N>" .. nExitId

-- =========================================================
-- CALLBACKS
-- =========================================================

function CP_Castle_Enter()
    local uid = Get_UserId()
    if not uid then return end

    if Get_UserLevel() < CP_CONFIG.MIN_LEVEL then
        return
    end

    User_ChgMap(CP_CONFIG.MAP_EVENT, 245, 241)
end

function CP_Castle_Close()
    LinkNpcGossipFunc_New(CP_CONFIG.NPC_ENTRANCE, "1-1")
end

function CP_Castle_Exit()
    User_ChgMap(CP_CONFIG.MAP_TOWN, 313, 294)
end

-- =========================================================
-- DROP SYSTEM
-- =========================================================

function CP_Castle_DeliverItem(pUserId, nItemId, nVipLevel)
    local data = EVENT_POOL[nItemId]
    if not data then return end

    local hasSpace = User_CheckLeftSpace(1, pUserId)

    if nVipLevel >= 6 then
        local cps = math.floor(data.val * VIP6_CP_MULTIPLIER)
        User_AddEMoney(cps, pUserId)
        User_TalkChannel2003("You received " .. cps .. " CPs directly!", pUserId)

    elseif hasSpace then
        Item_AddItem(nItemId, 0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, pUserId)
    
    else
        Monster_SysDropItem(nItemId)
    end

    if nVipLevel >= 4 and math.random() <= VIP4_DOUBLE_DROP_CHANCE then
        if nVipLevel >= 6 then
            local cps = math.floor(data.val * VIP6_CP_MULTIPLIER)
            User_AddEMoney(cps, pUserId)
            User_TalkChannel2003("VIP Double Drop: You received " .. cps .. " CPs!", pUserId)
        elseif User_CheckLeftSpace(1, pUserId) then
            Item_AddItem(nItemId, 0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, pUserId)
        else
            Monster_SysDropItem(nItemId)
        end
    end
end

-- =========================================================
-- MONSTER DROP HOOK
-- =========================================================

function CP_Castle_Monster_Drop()
    if Get_MonsterType() ~= CP_CONFIG.MONSTER_ID then
        return
    end

    local uid = tonumber(Get_UserId())
    if not uid or uid <= 0 then
        return
    end

    local vip = Get_UserVip() or 0
    local chance = 0.06

    if math.random() <= chance then
        local item = EVENT_POOL_KEYS[math.random(1, #EVENT_POOL_KEYS)]
        if item then
            CP_Castle_DeliverItem(uid, item, vip)
        end
    end
end

-- =========================================================
-- REGISTER
-- =========================================================

if type(tMonster) == "table" then
    tMonster[CP_CONFIG.MONSTER_ID] = tMonster[CP_CONFIG.MONSTER_ID] or {}
    tMonster[CP_CONFIG.MONSTER_ID]["tFunction"] = tMonster[CP_CONFIG.MONSTER_ID]["tFunction"] or {}
    table.insert(tMonster[CP_CONFIG.MONSTER_ID]["tFunction"], CP_Castle_Monster_Drop)
end