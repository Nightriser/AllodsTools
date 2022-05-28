--------------------------------------------------------------------------------------------
-- AllodsToolsLootpet by:
-- Engam (Evolution)
-- Blutlust (P2P)
--------------------------------------------------------------------------------------------


---- VARIABLES ----
-- Change According to your localization:
Global("Lootpets", {
	["1"] = "Helfer: Sonnenstrahl",
	["2"] = "Helfer: Sunny",			-- exists twice
	["3"] = "Helfer: Tamarind",
	["4"] = "Helfer: Tommy",
	["5"] = "Helfer: Yakub ibn Yasin",
	["6"] = "Helfer: Elster",
	["7"] = "Helfer: Martin",
	["8"] = "Helfer Wilder Ferkel",
	["9"] = "Helfer-Ferkel",
	["10"] = "Helfer: Baal",
	["11"] = "Helfer: Fasil ibn Fahim",
	["12"] = "Helfer: Füchslein",
	["13"] = "Helfer: Kapitän Flügler",
	["14"] = "Helfer: Kohle",
	["15"] = "Helfer: Leutnant Feder",
	["16"] = "Helfer: Manul",
	["17"] = "Helfer: Rollo",
	["18"] = "Begleiter: Pfirsich",
	["19"] = "Begleiter: Zimt",
	["20"] = "Helfer: Fliegerassistent",
	["21"] = "Helfer: Rote Elster",
	["22"] = "Helfer: Fackel",
	["23"] = "Fee-Helfer",
	["24"] = "Helfer: Crunchy",
	["25"] = "Helfer: Bei" .. string.char(223) .. "er", -- ß
})
Global("Message", "Lootpet nicht aktiv" ) -- Lootpet not active

-- Shouldn't be changed, changes appearance of announce message
Global( "MESSAGE_FADE_IN_TIME", 350 )
Global( "MESSAGE_FADE_SOLID_TIME", 4000 )
Global( "MESSAGE_FADE_OUT_TIME", 1000 )
Global( "WIDGET_FADE_TRANSPARENT", 1 )
Global( "WIDGET_FADE_IN", 2 )
Global( "WIDGET_FADE_SOLID", 3 )
Global( "WIDGET_FADE_OUT", 4 )

-- Changes how often the message appears
Global ( "SECOND_COUNTER_MAX", 10 )
Global ( "SECOND_COUNTER", 0 ) -- Do not change

-- used for saving and loading
Global( "Settings", {
	["Enabled"] = true,
})

---- WIDGETS ----
Global( "wtATLootpetMessage", nil )
Global( "fadeStatus", WIDGET_FADE_TRANSPARENT )
Global( "wtATLootpetButton", nil )
wtATLootpetMessage = mainForm:GetChildChecked( "wtATLootpetMessage", true )
wtATLootpetButton = mainForm:GetChildChecked( "wtATLootpetButton", true )
wtATLootpetButton:SetVal( "button_label", userMods.ToWString("ATL") )
wtATLootpetButton:SetFade( 1.0 )


---- FUNCTIONS ----
function loadSettings()
	--common.LogInfo( "common", "Loading Settings" )
	local loaded = userMods.GetAvatarConfigSection( "AllodsToolsLootpet" )
	if not loaded then
		Settings["Enabled"] = true
		--common.LogInfo( "common", "Used default Settings" )
		fadeButton()
		return
	end
	Settings["Enabled"] = loaded["Enabled"]
	--common.LogInfo( "common", "Loaded Settings" )
	fadeButton()
end

function saveSettings()
	--common.LogInfo( "common", "Saving Settings" )
	local saves = {}
	saves["Enabled"] = Settings["Enabled"]
	userMods.SetAvatarConfigSection( "AllodsToolsLootpet", saves )
	--common.LogInfo( "common", "Enabled is " .. tostring(Settings["Enabled"] ) )
	--common.LogInfo( "common", "Saved Settings" )
end

function playWTMessage(input)
	wtATLootpetMessage:SetVal("value", userMods.ToWString(input))
	wtATLootpetMessage:Show( true )
	wtATLootpetMessage:PlayFadeEffect( 0.0, 1.0, MESSAGE_FADE_IN_TIME, EA_MONOTONOUS_INCREASE )
	fadeStatus = WIDGET_FADE_IN
end

function fadeButton()
	if not Settings["Enabled"] then
		wtATLootpetButton:SetFade( 0.5 )
		return
	end
	wtATLootpetButton:SetFade( 1.0 )
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end


function isLootpetActive()
	local spellbook = avatar.GetSpellBook()
	for i, id in pairs( spellbook ) do
		local spellInfo = spellLib.GetDescription( id )
		if table.contains(Lootpets, userMods.FromWString( spellInfo.name ) ) then
			local spellState = spellLib.GetState( id )
			local spellActive = spellState.isActive
			if spellActive == true then
				return true
			end
		end
	end
	return false
end

---- EVENT HANDLERS ----
function OnEventLootBagAppeared( params )
	--common.LogInfo( "common", "Lootbag appeared" )
	--common.LogInfo( "common", "Testing Enabled" )
	if not Settings["Enabled"] then
		--common.LogInfo( "common", "--> Setting disabled" )
		return
	end
	--common.LogInfo( "common", "--> Setting enabled" )
	--common.LogInfo( "common", "Testing Lootpet Active" )
	if isLootpetActive() then
		--common.LogInfo( "common", "--> Lootpet active" )
		return
	end
	--common.LogInfo( "common", "--> Lootpet inactive" )
	playWTMessage( Message )
end

function OnEventEffectFinished ( params )
	if params.wtOwner:IsEqual( wtATLootpetMessage ) then
		if fadeStatus == WIDGET_FADE_IN then
			wtATLootpetMessage:PlayFadeEffect( 1.0, 1.0, MESSAGE_FADE_SOLID_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_SOLID		
		elseif fadeStatus == WIDGET_FADE_SOLID then
			wtATLootpetMessage:PlayFadeEffect( 1.0, 0.0, MESSAGE_FADE_OUT_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_OUT		
		elseif fadeStatus == WIDGET_FADE_OUT then
			fadeStatus = WIDGET_FADE_TRANSPARENT
			wtATLootpetMessage:Show( false )
		end
	end
end

---- REACTION HANDLERS ----
function OnwtATLootpetButtonReaction( params )
	if DnD.IsDragging() then return end
	--common.LogInfo( "common", "Button pressed" )
	Settings["Enabled"] = not Settings["Enabled"]
	fadeButton()
	saveSettings()
end


---- INITIALIZATION ----
function initAddon()
--common.LogInfo( "common", "Initializing")
	DnD.Init(165386, wtATLootpetButton, wtATLootpetButton, true)
	common.RegisterEventHandler( OnEventLootBagAppeared, "EVENT_LOOT_BAG_APPEARED" )
	common.RegisterReactionHandler( OnwtATLootpetButtonReaction, "wtATLootpetButtonReaction")
	common.RegisterEventHandler( OnEventEffectFinished, "EVENT_EFFECT_FINISHED" )
	loadSettings()
	--common.LogInfo( "common", "Successful Init")
end

function OnEventAvatarCreated()
	if avatar.IsExist() then
		initAddon()
		common.UnRegisterEventHandler( OnEventAvatarCreated, "EVENT_AVATAR_CREATED" )
	end
end

function init()
	if avatar.IsExist() then
		initAddon()
	else
		common.RegisterEventHandler( OnEventAvatarCreated, "EVENT_AVATAR_CREATED" )
	end
end

init()