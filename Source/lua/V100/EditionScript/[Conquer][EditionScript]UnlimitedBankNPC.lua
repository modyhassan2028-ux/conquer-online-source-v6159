----------------------------------------------------------------------------
-- Name:     [Conquer][EditionScript]UnlimitedBankNPC.lua
-- Purpose:  Unlimited Bank NPC Dialogue & Logic System (English Version)
-- Description: Stores money in 64-bit split format inside task statistics to bypass 32-bit limits.
----------------------------------------------------------------------------

tNpcGossip = tNpcGossip or {}

-- Bind to task ID 40400
tNpcGossip[40400] = tNpcGossip[40400] or {}

tNpcGossip[40400].AIFunc_New = function(self, nNpcId, sIndex, nPage, nPageNum)
    local nUserId = Get_UserId()
    
    if sIndex == "1" then
        -- Load current bank balance
        local nBillions = Get_UserStatisticValue(8888, 1, nUserId) or 0
        local nSilvers = Get_UserStatisticValue(8888, 2, nUserId) or 0
        local nTotalBalance = nBillions * 1000000000 + nSilvers
        
        Sys_DialogTaskClear()
        Sys_DialogText("Welcome to the Server's Infinite Silver Bank!\n\n")
        Sys_DialogText("Your current Bank Balance is: " .. string.format("%.0f", nTotalBalance) .. " Silver.\n")
        Sys_DialogText("Your current Bag Balance is: " .. string.format("%.0f", Get_UserMoney(nUserId)) .. " Silver.\n\n")
        Sys_DialogText("What transaction would you like to perform today?")
        
        Sys_DialogOption("Deposit Silver", "</F>Bank_DepositPrompt</N>"..nNpcId)
        Sys_DialogOption("Withdraw Silver", "</F>Bank_WithdrawPrompt</N>"..nNpcId)
        Sys_DialogOption("Exit", "NULL")
        Sys_DialogEnd()
    end
end

-- Prompt for deposit amount
function Bank_DepositPrompt(nNpcId)
    Sys_DialogTaskClear()
    Sys_DialogText("Please enter the amount of Silver you want to deposit:\n")
    Sys_DialogText("(Minimum 1 Silver)")
    Sys_DialogOptEdit("Amount:", 10, "Bank_ExecuteDeposit</N>"..nNpcId, 0)
    Sys_DialogEnd()
end

-- Process deposit
function Bank_ExecuteDeposit(nNpcId)
    local nUserId = Get_UserId()
    local nAmount = tonumber(Get_SysAcceptStr())
    
    if not nAmount or nAmount <= 0 or nAmount % 1 ~= 0 then
        Sys_DialogTaskClear()
        Sys_DialogText("The amount you entered is invalid!")
        Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
        Sys_DialogEnd()
        return
    end
    
    local nUserMoney = Get_UserMoney(nUserId)
    if nUserMoney < nAmount then
        Sys_DialogTaskClear()
        Sys_DialogText("Sorry, you do not have enough Silver in your bag!")
        Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
        Sys_DialogEnd()
        return
    end
    
    -- Deduct from player bag
    User_AddMoney(-nAmount, nUserId)
    
    -- Load current bank balance
    local nBillions = Get_UserStatisticValue(8888, 1, nUserId) or 0
    local nSilvers = Get_UserStatisticValue(8888, 2, nUserId) or 0
    
    -- Calculate new balance
    local nTotalSilvers = nSilvers + nAmount
    local nAddBillions = math.floor(nTotalSilvers / 1000000000)
    local nRemainingSilvers = nTotalSilvers % 1000000000
    local nNewBillions = nBillions + nAddBillions
    
    -- Save to DB (Save=1)
    Task_SetStatistic(8888, 1, nNewBillions, 1, nUserId)
    Task_SetStatistic(8888, 2, nRemainingSilvers, 1, nUserId)
    
    Sys_DialogTaskClear()
    Sys_DialogText("Deposit successful!\n\n")
    Sys_DialogText("Deposited Amount: " .. string.format("%.0f", nAmount) .. " Silver.\n")
    Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
    Sys_DialogEnd()
end

-- Prompt for withdraw amount
function Bank_WithdrawPrompt(nNpcId)
    Sys_DialogTaskClear()
    Sys_DialogText("Please enter the amount of Silver you want to withdraw:\n")
    Sys_DialogText("(Note: Your bag cannot hold more than 2 Billion Silver)")
    Sys_DialogOptEdit("Amount:", 10, "Bank_ExecuteWithdraw</N>"..nNpcId, 0)
    Sys_DialogEnd()
end

-- Process withdraw
function Bank_ExecuteWithdraw(nNpcId)
    local nUserId = Get_UserId()
    local nAmount = tonumber(Get_SysAcceptStr())
    
    if not nAmount or nAmount <= 0 or nAmount % 1 ~= 0 then
        Sys_DialogTaskClear()
        Sys_DialogText("The amount you entered is invalid!")
        Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
        Sys_DialogEnd()
        return
    end
    
    -- Load current bank balance
    local nBillions = Get_UserStatisticValue(8888, 1, nUserId) or 0
    local nSilvers = Get_UserStatisticValue(8888, 2, nUserId) or 0
    
    -- Calculate balance
    local nTotalBalance = nBillions * 1000000000 + nSilvers
    
    if nTotalBalance < nAmount then
        Sys_DialogTaskClear()
        Sys_DialogText("Sorry, your bank balance is less than the requested amount!")
        Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
        Sys_DialogEnd()
        return
    end
    
    -- Check player bag limit (max 2,000,000,000)
    local nUserMoney = Get_UserMoney(nUserId)
    if nUserMoney + nAmount > 2000000000 then
        Sys_DialogTaskClear()
        Sys_DialogText("Sorry, your bag cannot hold more than 2 Billion Silver. Please withdraw a smaller amount!")
        Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
        Sys_DialogEnd()
        return
    end
    
    -- Deduct from bank balance
    local nNewTotalBalance = nTotalBalance - nAmount
    local nNewBillions = math.floor(nNewTotalBalance / 1000000000)
    local nNewSilvers = nNewTotalBalance % 1000000000
    
    -- Save to DB (Save=1)
    Task_SetStatistic(8888, 1, nNewBillions, 1, nUserId)
    Task_SetStatistic(8888, 2, nNewSilvers, 1, nUserId)
    
    -- Add to player bag
    User_AddMoney(nAmount, nUserId)
    
    Sys_DialogTaskClear()
    Sys_DialogText("Withdrawal successful!\n\n")
    Sys_DialogText("Withdrawn Amount: " .. string.format("%.0f", nAmount) .. " Silver.\n")
    Sys_DialogOption("Return to Main Menu", "</F>LinkNpcGossipFunc_New</N>"..nNpcId.."</S>1")
    Sys_DialogEnd()
end
