local config = {
	waypointDirectory = "mods/otcbot/waypoints/",
}

local walkEvent = nil
local stop = false
local isAttacking = false
local isFollowing = false
local currentTargetPositionId = 1
local waypoints = {}
local autowalkTargetPosition = waypoints[currentTargetPositionId]
local atkLoopId = nil
local atkSpellLoopId = nil
local itemHealingLoopId = nil
local spellHealingLoopId = nil
local manaLoopId = nil
local hasteLoopId = nil
local buffLoopId = nil
local hasLured = false
local shieldLoopId = nil
local player = nil
local healingItem 
local manaItem


function init()
	luniaBotWindow = g_ui.displayUI('luniabot')
	player = g_game.getLocalPlayer()
	waypointList = luniaBotWindow:getChildById("waypoints")
	luniaBotWindow:hide()
	luniaBotButton = modules.client_topmenu.addLeftGameButton('luniaBotButton', tr('LuniaBot'), 'icon', toggle)

	atkButton = luniaBotWindow:getChildById("autoAttack")
	walkButton = luniaBotWindow:getChildById("walking")
	healthSpellButton = luniaBotWindow:getChildById("AutoHealSpell")
	healthItemButton = luniaBotWindow:getChildById("AutoHealItem")
	manaRestoreButton = luniaBotWindow:getChildById("AutoMana")
	atkSpellButton = luniaBotWindow:getChildById("AtkSpell")
	manaTrainButton = luniaBotWindow:getChildById("ManaTrain")
	hasteButton = luniaBotWindow:getChildById("AutoHaste")
	buffButton = luniaBotWindow:getChildById("AutoBuff")
	lureButton = luniaBotWindow:getChildById("LureMonsters")
	manaShieldButton = luniaBotWindow:getChildById("AutoManaShield")

	healthItemButton.onCheckChange = autoHealPotion
	manaRestoreButton.onCheckChange = autoManaPotion

	luniaBotWindow:getChildById("AtkSpellText").onTextChange = saveBotText
	luniaBotWindow:getChildById("HealSpellText").onTextChange = saveBotText
	luniaBotWindow:getChildById("HealthSpellPercent").onTextChange = saveBotText
	luniaBotWindow:getChildById("HealItem").onTextChange = saveBotText
	luniaBotWindow:getChildById("HealItemPercent").onTextChange = saveBotText
	luniaBotWindow:getChildById("ManaItem").onTextChange = saveBotText
	luniaBotWindow:getChildById("ManaPercent").onTextChange = saveBotText
	luniaBotWindow:getChildById("WptName").onTextChange = saveBotText
	luniaBotWindow:getChildById("ManaSpellText").onTextChange = saveBotText
	luniaBotWindow:getChildById("ManaTrainPercent").onTextChange = saveBotText
	luniaBotWindow:getChildById("HasteText").onTextChange = saveBotText
	luniaBotWindow:getChildById("BuffText").onTextChange = saveBotText
	luniaBotWindow:getChildById("LureMinimum").onTextChange = saveBotText
	luniaBotWindow:getChildById("LureMaximum").onTextChange = saveBotText

	connect(g_game, { onGameStart = logIn})
end


function saveBotText()
	g_settings.set(player:getName() .. " " .. luniaBotWindow:getFocusedChild():getId(), luniaBotWindow:getFocusedChild():getText())
end


function logIn()
	player = g_game.getLocalPlayer()

		--Fixes default values
	if(luniaBotWindow:getChildById("HealItem"):getText()) == ",266" then
		luniaBotWindow:getChildById("HealItem"):setText('266')
	end
	if(luniaBotWindow:getChildById("ManaItem"):getText()) == ",268" then
		luniaBotWindow:getChildById("ManaItem"):setText('268')
	end

	local checkButtons = {atkButton, healthSpellButton, walkButton, healthItemButton, manaRestoreButton, atkSpellButton, manaTrainButton, hasteButton, manaShieldButton, buffButton, lureButton}
	for _,checkButton in ipairs(checkButtons) do
		checkButton:setChecked(g_settings.getBoolean(player:getName() .. " " .. checkButton:getId()))
	end

	local textBoxes = {luniaBotWindow.ManaSpellText, luniaBotWindow.HasteText, luniaBotWindow.AtkSpellText, luniaBotWindow.HealSpellText, luniaBotWindow.HealthSpellPercent, luniaBotWindow.HealItem, luniaBotWindow.HealItemPercent, luniaBotWindow.ManaItem, luniaBotWindow.ManaPercent, luniaBotWindow.WptName, luniaBotWindow.BuffText, luniaBotWindow.LureMinimum, luniaBotWindow.LureMaximum}
	for _,textBox in ipairs(textBoxes) do
		local storedText = g_settings.get(player:getName() .. " " .. textBox:getId())
		if (string.len(storedText) >= 1) then
			textBox:setText(g_settings.get(player:getName() .. " " .. textBox:getId()))
		end
	end
end


function terminate()
	luniaBotWindow:destroy()
	luniaBotButton:destroy()
end


function disable()
	luniaBotButton:hide()
end


function hide()
	luniaBotWindow:hide()
end


function show()
	luniaBotWindow:show()
	luniaBotWindow:raise()
	luniaBotWindow:focus()
end


function toggleLoop(key)
	--maybe remove some looops, for example healing could be done through events
	local bts = {
		autoAttack = {atkLoop, atkLoopId},
		walking = {walkToTarget, walkEvent},
		AutoHealSpell = {healingSpellLoop, spellHealingLoopId},
		AtkSpell = {atkSpellLoop, atkSpellLoopId},
		ManaTrain = {manaTrainLoop, manaLoopId},
		AutoHaste = {hasteLoop, hasteLoopId},
		AutoManaShield = {shieldLoop, shieldLoopId},
		AutoBuff = {buffLoop, buffLoopId},
	}

	local btn = luniaBotWindow:getChildById(key)
	local bt = bts[btn:getId()]
	if (btn:isChecked()) then
		g_settings.set(player:getName() .. " " .. btn:getId(), true)
		if (bt) then
			bt[1]()
		end
	else
		g_settings.set(player:getName() .. " " .. btn:getId(), false)
		if (bt) then
			removeEvent(bt[2])
		end
	end
end


function autoHealPotion()
	healingItem = healthItemButton:isChecked()
	g_settings.set(player:getName() .. " " .. healthItemButton:getId(), healthItemButton:isChecked())
	if (healingItem and itemHealingLoopId == nil) then
		itemHealingLoop()
	end
	if (not manaItem and not healingItem) then
		removeEvent(itemHealingLoopId)
		itemHealingLoopId = nil
	end
end


function autoManaPotion()
	manaItem = manaRestoreButton:isChecked()
	g_settings.set(player:getName() .. " " .. manaRestoreButton:getId(), manaRestoreButton:isChecked())
	if (manaItem and itemHealingLoopId == nil) then
		itemHealingLoop()
	end
	if (not manaItem and not healingItem) then
		removeEvent(itemHealingLoopId)
		itemHealingLoopId = nil
	end
end


function toggle()
	if luniaBotWindow:isVisible() then
		hide()
	else
		show()
	end
end


local function getDistanceBetween(p1, p2)
    return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end


function Player.canAttack(self)
    return not self:hasState(16384) and not g_game.isAttacking()
end


function Creature:canReach(creature)
	--function from candybot
	if not creature then
		return false
	end
	local myPos = self:getPosition()
	local otherPos = creature:getPosition()

	local neighbours = {
		{x = 0, y = -1, z = 0},
		{x = -1, y = -1, z = 0},
		{x = -1, y = 0, z = 0},
		{x = -1, y = 1, z = 0},
		{x = 0, y = 1, z = 0},
		{x = 1, y = 1, z = 0},
		{x = 1, y = 0, z = 0},
		{x = 1, y = -1, z = 0}
	}

	for k,v in pairs(neighbours) do
	local checkPos = {x = myPos.x + v.x, y = myPos.y + v.y, z = myPos.z + v.z}
	if postostring(otherPos) == postostring(checkPos) then
		return true
	end

	local steps, result = g_map.findPath(otherPos, checkPos, 40000, 0)
		if result == PathFindResults.Ok then
			return true
		end
	end
	return false
end


function atkLoop() 
	if(player:canAttack()) then
		local pPos = player:getPosition()
		local luredMob = {}
		local lureAmount = tonumber(luniaBotWindow:getChildById("LureMaximum"):getText())
		local lureMinimum =  tonumber(luniaBotWindow:getChildById("LureMinimum"):getText())
		local luring = lureButton:isChecked()
		if pPos then --solves some weird bug, in the first login, the players position is nil in the start for some reason
			local creatures = g_map.getSpectators(pPos, false)
			if (luring) then
				for _, mob in ipairs(creatures) do
					cPos = mob:getPosition()
					if getDistanceBetween(pPos, cPos) <= 5 and mob:isMonster() and player:canReach(mob) then
						table.insert(luredMob, mob)
					end
				end
			end
			if (luring and #luredMob >= lureAmount) then
				hasLured = true
			end
			if (luring and #luredMob <= lureMinimum) then
				hasLured = false
			end
			for _, creature in ipairs(creatures) do
				cPos = creature:getPosition()
				if getDistanceBetween(pPos, cPos) <= 5 and creature:isMonster() and player:canReach(creature) then
					if (not luring or hasLured) then
						g_game.attack(creature)
						atkLoopId = scheduleEvent(atkLoop, 200)
						return
					end
				end
			end
		end
	end
	atkLoopId = scheduleEvent(atkLoop, 200)
end


function fag()
	local label = g_ui.createWidget('Waypoint', waypointList)
	local pos = player:getPosition()
	label:setText(pos.x .. "," .. pos.y .. "," .. pos.z)
	table.insert(waypoints, pos)
end


function walkToTarget()
	--found this function made by gesior, i edited it abit, maybe there's better ways to walk? 
	autowalkTargetPosition = waypoints[currentTargetPositionId]
    if not g_game.isOnline() then
		walkEvent = scheduleEvent(walkToTarget, 500)
        return
	end

	local playerPos = player:getPosition()
	if (playerPos and autowalkTargetPosition) then
		if (getDistanceBetween(playerPos, autowalkTargetPosition) >= 150) then
			currentTargetPositionId = currentTargetPositionId + 1
			if (currentTargetPositionId > #waypoints) then
				currentTargetPositionId = 1
			end
			walkEvent = scheduleEvent(walkToTarget, 1500)
			return 
		end
	end
	-- if g_game.getLocalPlayer():getStepTicksLeft() > 0 then
	-- 	walkEvent = scheduleEvent(walkToTarget, g_game.getLocalPlayer():getStepTicksLeft())
    --     return
	-- end
	if g_game.isAttacking() or isFollowing then
		walkEvent = scheduleEvent(walkToTarget, 100)
        return
	end
	if not autowalkTargetPosition then
		currentTargetPositionId = currentTargetPositionId + 1
		if (currentTargetPositionId > #waypoints) then
			currentTargetPositionId = 1
		end
		walkEvent = scheduleEvent(walkToTarget, 100)
		return
	end
    -- fast search path on minimap (known tiles)
    steps, result = g_map.findPath(g_game.getLocalPlayer():getPosition(), autowalkTargetPosition, 5000, 0)
	if result == PathFindResults.Ok then
        g_game.walk(steps[1], true)
	elseif result == PathFindResults.Position then
		currentTargetPositionId = currentTargetPositionId + 1
		if (currentTargetPositionId > #waypoints) then
			currentTargetPositionId = 1
		end
    else
        -- slow search path on minimap, if not found, start 'scanning' map
        steps, result = g_map.findPath(g_game.getLocalPlayer():getPosition(), autowalkTargetPosition, 25000, 1)
        if result == PathFindResults.Ok then
            g_game.walk(steps[1], true)
		else
			-- can't reach?  so skip this waypoint. improve this somehow
			currentTargetPositionId = currentTargetPositionId + 1
		end
    end
    -- limit steps to 10 per second (100 ms between steps)
    walkEvent = scheduleEvent(walkToTarget, math.max(100, g_game.getLocalPlayer():getStepTicksLeft()))
end


function saveWaypoints() 
	local saveText = '{\n'
	for _,v in pairs(waypoints) do
		saveText = saveText .. '{x = '.. v.x ..', y = ' .. v.y .. ', z = ' .. v.z .. '},\n'
	end
	saveText = saveText .. '}'
	local file = io.open(config.waypointDirectory .. luniaBotWindow:getChildById("WptName"):getText() .. ".lua", "w")
	file:write(saveText)
	file:close()
end


function loadWaypoints() 
	local f = io.open(config.waypointDirectory .. luniaBotWindow:getChildById("WptName"):getText() ..'.lua', "r")
	local content = f:read("*all")
	f:close()
	clearWaypoints()
	waypoints = loadstring("return "..content)()
	for _,v in ipairs(waypoints) do
		local labelt = g_ui.createWidget('Waypoint', waypointList)
		labelt:setText(v.x .. "," .. v.y .. "," .. v.z)
	end
end


function clearWaypoints()
	waypoints = {}
	autowalkTargetPosition = currentTargetPositionId
	autowalkTargetPosition = waypoints[currentTargetPositionId]
	clearLabels()
	walkButton:setChecked(false)
end


function clearLabels()
	while waypointList:getChildCount() > 0 do
		local child = waypointList:getLastChild()
		waypointList:destroyChildren(child)
	end
end


function itemHealingLoop()
	-- Prioritize healing item instead of mana
	if healingItem then
		local hpItemPercentage = tonumber(luniaBotWindow:getChildById("HealItemPercent"):getText())
		local hpItemId = tonumber(luniaBotWindow:getChildById("HealItem"):getText())
		if (player:getHealth() <= (player:getMaxHealth() * (hpItemPercentage/100))) then
			g_game.useInventoryItemWith(hpItemId, player)
			-- maybe don't try using mana after healing item?
		end
	end
	if manaItem then
		local manaItemPercentage = tonumber(luniaBotWindow.ManaPercent:getText())
		local manaItemId = tonumber(luniaBotWindow.ManaItem:getText())
		if (player:getMana() <= (player:getMaxMana() * (manaItemPercentage/100))) then
			g_game.useInventoryItemWith(manaItemId, player)
		end
	end
	itemHealingLoopId = scheduleEvent(itemHealingLoop, 250)
end


function healingSpellLoop()
	local healingSpellPercentage = tonumber(luniaBotWindow:getChildById("HealthSpellPercent"):getText())
	local healSpell = luniaBotWindow:getChildById("HealSpellText"):getText()
	if (not player) then
		spellHealingLoopId = scheduleEvent(healingSpellLoop, 502)
	end
	if (player:getHealth() <= (player:getMaxHealth() * (healingSpellPercentage/100))) then
		g_game.talk(healSpell)
	end
	spellHealingLoopId = scheduleEvent(healingSpellLoop, 502)
end


function manaTrainLoop()
	local manaTrainPercentage = tonumber(luniaBotWindow:getChildById("ManaTrainPercent"):getText())
	local manaSpell = luniaBotWindow:getChildById("ManaSpellText"):getText()
	if (not player) then
		manaLoopId = scheduleEvent(manaTrainLoop, 1000)
	end
	if (player:getMana() >= (player:getMaxMana() * (manaTrainPercentage/100))) then
		g_game.talk(manaSpell)
	end
	manaLoopId = scheduleEvent(manaTrainLoop, 1000)
end


function hasteLoop()
	local hasteSpell = luniaBotWindow:getChildById("HasteText"):getText()
	if (not player) then
		hasteLoopId = scheduleEvent(hasteLoop, 1000)
	end
	if (player:getHealth() >= (player:getMaxHealth() * (70/100))) then -- only cast when healthy
		if (not player:hasState(PlayerStates.Haste, player:getStates())) then
			g_game.talk(hasteSpell)
		end
	end
	hasteLoopId = scheduleEvent(hasteLoop, 1000)
end


function buffLoop()
	local buffSpell = luniaBotWindow:getChildById("BuffText"):getText()
	if (not player) then
		buffLoopId = scheduleEvent(buffLoop, 1000)
	end
	if (not player:hasState(PlayerStates.PartyBuff, player:getStates())) then
		g_game.talk(buffSpell)
	end
	buffLoopId = scheduleEvent(buffLoop, 1000)
end


function shieldLoop()
	if (not player) then
		shieldLoopId = scheduleEvent(shieldLoop, 1000)
	end
	if (not player:hasState(PlayerStates.ManaShield, player:getStates())) then
		g_game.talk('utamo vita')
	end
	shieldLoopId = scheduleEvent(shieldLoop, 1000)
end


function atkSpellLoop()
	local atkSpell = luniaBotWindow:getChildById("AtkSpellText"):getText()
	if (g_game.isAttacking()) then
		g_game.talk(atkSpell)
	end
	atkSpellLoopId = scheduleEvent(atkSpellLoop, 502)
end

