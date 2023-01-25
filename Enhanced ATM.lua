--[[
	Copyright © 2022-2023 Hun2Memory
	
	This file is main of Enhanced ATM LUA Script.
]]
if EnhancedATM then
	return
end

menu.create_thread(function()
collectgarbage("incremental", 110, 100)
math.randomseed(math.floor(os.clock()) + os.time())
EnhancedATM = "Enhanced ATM V1"

local menu = menu
local system = system
local utils = utils
local IniParser = IniParser
local input = input
local native = native

local function notif(str, iserr)
	local col = 0xFF8C8C8C
		if iserr then
			col = 0xFF3232F4
		end
	menu.notify(tostring(str),
		string.format("#FF72CC72#%s#DEFAULT#", EnhancedATM), 6, col)
end

if not menu.is_trusted_mode_enabled(1 << 2) then
	notif("You must turn on Natives trusted mode to use this script.", true)
	menu.exit()
	return
end

local natives = {
	is_control_on = function()
		local ret = native.call(0x49C32D60007AFA47, player.player_id()):__tointeger()
		return (ret == 1 and true or false)
	end,
	busyspinner_is_on = function()
		local ret = native.call(0xD422FCC5F239A915):__tointeger()
		return (ret == 1 and true or false)
	end,
	busyspinner_is_displaying = function()
		local ret = native.call(0xB2A592B04648A9CB):__tointeger()
		return (ret == 1 and true or false)
	end,
	stat_get_int = function(stat)
		local hash = native.call(0xD24D37CC275948CC, stat):__tointeger()
		local out = native.ByteBuffer8()
		native.call(0x767FBC2AC802EF3D, hash, out, -1)
		return out:__tointeger()
	end,
	
	deposit = function(slot, amount)
		local ret = native.call(0xC2F7FE5309181C7D, slot, amount):__tointeger()
		return (ret == 1 and true or false)
	end,
	deposit_status = function()
		local ret = native.call(0x350AA5EBC03D3BD2):__tointeger()
		return (ret == 1 and true or false)
	end,
	
	withdraw = function(slot, amount)
		local ret = native.call(0xD47A2C1BA117471D, slot, amount):__tointeger()
		return (ret == 1 and true or false)
	end,
	withdraw_status = function()
		local ret = native.call(0x23789E777D14CE44):__tointeger()
		return (ret == 1 and true or false)
	end,
	
	nonce = function()
		local ret = native.call(0x498C1E05CE5F7877):__tointeger()
		return (ret == 1 and true or false)
	end,
}

local function isBusySpinnerOn()
	return (natives.busyspinner_is_on() or natives.busyspinner_is_displaying())
end
	
local function ATM(val, isWithdraw)
	isWithdraw = (isWithdraw or 0)
	if not network.is_session_started() then
		notif("Session is not started.", true)
		return
	end
	while not natives.is_control_on() do
		system.yield(1500)
	end
	while isBusySpinnerOn() do
		notif("Waiting for Busy Spinner...")
		system.yield(1500)
	end
	
	local mp = natives.stat_get_int("MPPLY_LAST_MP_CHAR")
	
	if isWithdraw == 1 then
		local set = natives.withdraw(mp, val)
		natives.nonce()
		system.yield(100)
		local status = natives.withdraw_status()
		if set and status then
			notif(string.format("Withdrawal $%s #FF72CC72#Success#DEFAULT#.", tostring(val)))
		else
			notif(string.format("Withdrawal $%s #FF3232F4#Failed#DEFAULT#.\n#FF5585FF#Please try again later...", tostring(val)))
		end
	else
		local set = natives.deposit(mp, val)
		natives.nonce()
		system.yield(100)
		local status = natives.deposit_status()
		if set and status then
			notif(string.format("Deposit $%s #FF72CC72#Success#DEFAULT#.", tostring(val)))
		else
			notif(string.format("Deposit $%s #FF3232F4#Failed#DEFAULT#.\n#FF5585FF#Please try again later...", tostring(val)))
		end
	end
end


local feats, feat_vals, tmp = {}, {}, {}
tmp.last = 0
local ini = IniParser(utils.get_appdata_path("PopstarDevs", "2Take1Menu") .. "\\scripts\\Enhanced ATM.ini")

local function Save()
    for k, v in pairs(feats) do
        ini:set_b("Toggles", k, v.on)
    end
    for k, v in pairs(feat_vals) do
        ini:set_i("Values", k, v.value)
    end
    ini:write()
end

local function Load()
    if ini:read() then
        for k, v in pairs(feats) do
            local exists, val = ini:get_b("Toggles", k)
            if exists then
                v.on = val
            end
        end
    
        for k, v in pairs(feat_vals) do
            local exists, val = ini:get_i("Values", k)
            if exists then
                v.value = val
            end
        end
    end
end

local main = menu.add_feature("Enhanced ATM", "parent")

feats.randomizervalue = menu.add_feature("Randomizer Value", "toggle", main.id, function(f)
	if f.on then
		feat_vals.value.hidden = true
		feat_vals.value_min.hidden = false
		feat_vals.value_max.hidden = false
	else
		feat_vals.value.hidden = false
		feat_vals.value_min.hidden = true
		feat_vals.value_max.hidden = true
	end
	Save()
	system.yield(0)
end)

feat_vals.value = menu.add_feature("Value", "action_value_i", main.id, function(f)
	local r,i = input.get(f.name, "", 10, 3)
	if (r == 1) then
		return HANDLER_CONTINUE
	end

	if (r == 2) then
		return HANDLER_POP
	end

	f.value = i
	Save()
	return HANDLER_POP
end)
feat_vals.value.min = 1 feat_vals.value.max = 2147483647 feat_vals.value.mod = 1 feat_vals.value.value = 1000000

feat_vals.value_min = menu.add_feature("Value Min", "action_value_i", main.id, function(f)
	local r,i = input.get(f.name, "", 10, 3)
	if (r == 1) then
		return HANDLER_CONTINUE
	end

	if (r == 2) then
		return HANDLER_POP
	end

	if tonumber(i) >= feat_vals.value_max.value then
		notif("Minimum value need to be lower than Maximum value.", true)
		return HANDLER_POP
	end
	
	f.value = i
	Save()
	return HANDLER_POP
end)
feat_vals.value_min.hidden = true
feat_vals.value_min.min = 1 feat_vals.value_min.max = 2147483647 feat_vals.value_min.mod = 1 feat_vals.value_min.value = 500000

feat_vals.value_max = menu.add_feature("Value Max", "action_value_i", main.id, function(f)
	local r,i = input.get(f.name, "", 10, 3)
	if (r == 1) then
		return HANDLER_CONTINUE
	end

	if (r == 2) then
		return HANDLER_POP
	end

	if tonumber(i) <= feat_vals.value_min.value then
		notif("Maximum value need to be greater than Minimum value.", true)
		return HANDLER_POP
	end
	
	f.value = i
	Save()
	return HANDLER_POP
end)
feat_vals.value_max.hidden = true
feat_vals.value_max.min = 1 feat_vals.value_max.max = 2147483647 feat_vals.value_max.mod = 1 feat_vals.value_max.value = 1000000

menu.add_feature("Deposit", "action", main.id, function(f)
	tmp.last = 0
	local val = feat_vals.value.value
		if feats.randomizervalue.on then
			math.randomseed(math.floor(os.clock()) + os.time())
			val = math.random(feat_vals.value_min.value, feat_vals.value_max.value)
		end
		
	ATM(val, tmp.last)
	system.yield(0)
end)

menu.add_feature("Withdraw", "action", main.id, function(f)
	tmp.last = 1
	local val = feat_vals.value.value
		if feats.randomizervalue.on then
			math.randomseed(math.floor(os.clock()) + os.time())
			val = math.random(feat_vals.value_min.value, feat_vals.value_max.value)
		end
		
	ATM(val, tmp.last)
	system.yield(0)
end)

menu.add_feature("Toggle Last Action", "toggle", main.id, function(f)
	if feat_vals.delay.hidden then
		feat_vals.delay.hidden = false
	end
	
	local val = feat_vals.value.value
		if feats.randomizervalue.on then
			math.randomseed(math.floor(os.clock()) + os.time())
			val = math.random(feat_vals.value_min.value, feat_vals.value_max.value)
		end
	ATM(val, tmp.last)
	
	if f.on then
		system.yield(feat_vals.delay.value)
		return HANDLER_CONTINUE
	else
		feat_vals.delay.hidden = true
		system.yield(0)
		return HANDLER_POP
	end
end)

feat_vals.delay = menu.add_feature("Delay (ms)", "action_value_i", main.id, function(f)
	local r,i = input.get(f.name, "", 5, 3)
	if (r == 1) then
		return HANDLER_CONTINUE
	end

	if (r == 2) then
		return HANDLER_POP
	end

	f.value = i
	Save()
	return HANDLER_POP
end)
feat_vals.delay.min = 5 feat_vals.delay.max = 10000 feat_vals.delay.mod = 5 feat_vals.delay.value = 3000
feat_vals.delay.hidden = true
feat_vals.delay.hint = "Delay for toggle\nNot recommended lower than 3000ms (3 Seconds)."
Load()
end, nil)