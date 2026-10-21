------------------------------------------------------------------------------------
--Name:        [RealConquer][ActiveScript]GlobalDrop
--Purpose:     Handles global monster drops, VIP rewards and auto item conversions
--
--Developers:  Epoch & Colin
--Copyright © 2026 RealConquer Team
--All Rights Reserved.
------------------------------------------------------------------------------------

local tGlobalMonsterDrop_Items = {}
tGlobalMonsterDrop_Items["ChanceSum"] = 10000

tGlobalMonsterDrop_Items[1] = { ItemId = 722136,  Chance  =  150  }   -- ExpBall
tGlobalMonsterDrop_Items[2] = { ItemId = 1088001, Chance  =  30   }   -- Meteor
tGlobalMonsterDrop_Items[3] = { ItemId = 1088000, Chance  =  50   }   -- DragonBall
tGlobalMonsterDrop_Items[4] = { ItemId = 721016,  Chance  =  9000 }   -- 5 CP
tGlobalMonsterDrop_Items[5] = { ItemId = 721019,  Chance  =  7500 }   -- 25 CP

local tGlobalMonsterDrop_Constant = {}
	tGlobalMonsterDrop_Constant["MinUserLevel"]      = 1
	tGlobalMonsterDrop_Constant["LevelRange"]        = 20
	tGlobalMonsterDrop_Constant["OutOfRangeDivisor"] = 3

function GlobalMonsterDrop_GetMultiplier(nUserLevel, nMonsterLevel)
	local nNum, nDen = 1, 1
	local nDelta = math.abs(nUserLevel - nMonsterLevel)

	if nDelta > tGlobalMonsterDrop_Constant["LevelRange"] then
		nDen = nDen * tGlobalMonsterDrop_Constant["OutOfRangeDivisor"]
	end

	return nNum, nDen
end

local function TryAutoConvert(nUserId, nVip, nMinVip, nFrom, nTo, nNeeded)
    if nVip < nMinVip then return end
    if not Item_ChkAccItem(nFrom, nNeeded, 0, nUserId) then return end
    Item_DelMulItem(nFrom, nFrom, nNeeded, 1, 0, nUserId)
    Item_AddItem(nTo, 0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, nUserId)
end

function GlobalMonsterDrop_OnMonsterKilled(nMonsterTypeId)
	local nUserId = tonumber(Get_UserId())
	if not nUserId or nUserId <= 0 then return end

	local nVip = Get_UserVip() or 0
	local nUserLevel = Get_UserLevel() or 0
	if nUserLevel < tGlobalMonsterDrop_Constant["MinUserLevel"] then return end

	local nMonsterLevel = Get_MonsterLevel() or 1
	local nMulNum, nMulDen = GlobalMonsterDrop_GetMultiplier(nUserLevel, nMonsterLevel)

	for i = 1, #tGlobalMonsterDrop_Items do
		local tDrop = tGlobalMonsterDrop_Items[i]

		if tDrop and tDrop.Chance > 0 then
			local nChance = math.floor(tDrop.Chance * nMulNum / nMulDen)

			if math.random(1, 10000) <= nChance then

				if tDrop.ItemId == 721016 or tDrop.ItemId == 721019 then
					if nVip >= 4 then
						local nReward = (tDrop.ItemId == 721016) and 5 or 25
						User_AddEMoney(nReward, nUserId)
						User_TalkChannel2003("You received " .. nReward .. " CPs", nUserId)
					else
						Monster_SysDropItem(tDrop.ItemId)
					end
				else
					if nVip >= 5 then
						Item_AddItem(tDrop.ItemId,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,nUserId)
					else
						Monster_SysDropItem(tDrop.ItemId)
					end
				end

			end
		end
	end

    TryAutoConvert(nUserId, nVip, 5, 1088001, 720027, 10)
    TryAutoConvert(nUserId, nVip, 5, 1088000, 720028, 10)
    TryAutoConvert(nUserId, nVip, 6, 720027, 3004611, 10)
    TryAutoConvert(nUserId, nVip, 6, 720028, 3004615, 10)
end

tMonsterFunction = tMonsterFunction or {}
table.insert(tMonsterFunction, GlobalMonsterDrop_OnMonsterKilled)

if type(tMonster) == "table" then
	for nMid, tInfo in pairs(tMonster) do
		if type(nMid) == "number" and type(tInfo) == "table" then
			tInfo["tFunction"] = tInfo["tFunction"] or {}
			table.insert(tInfo["tFunction"], GlobalMonsterDrop_OnMonsterKilled)
		end
	end
end