--------------------------------------------------------------------------------------------
-- AllodsToolsAspect by:
-- Engam (Evolution)
-- Blutlust (P2P)
--------------------------------------------------------------------------------------------


---- VARIABLES ----
-- Change According to your localization:
Global( "Aspects", {
	["1"]="Aspekt des Angriffs",			-- Attack
	["2"] = "Aspekt der Verteidigung",		-- Defense
	["3"] = "Aspekt der Heilung",			-- Heal
	["4"] = "Aspekt der Unterstützung",		-- Support
	["5"] = "Aspekt der Unterdrückung",		-- Suppression
})
Global("Message", "Aspekt nicht aktiv" ) -- Aspect not active

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
Global( "wtATAspectMessage", nil )
Global( "fadeStatus", WIDGET_FADE_TRANSPARENT )
Global( "wtATAspectButton", nil )
wtATAspectMessage = mainForm:GetChildChecked( "wtATAspectMessage", true )
wtATAspectButton = mainForm:GetChildChecked( "wtATAspectButton", true )
wtATAspectButton:SetVal( "button_label", userMods.ToWString("ATA") )
wtATAspectButton:SetFade( 1.0 )


---- INITIALIZATION ----
function initAddon()
--common.LogInfo( "common", "Initializing")
	DnD.Init(165385, wtATAspectButton, wtATAspectButton, true)
	common.RegisterEventHandler( OnEventObjectBuffsChanged, "EVENT_OBJECT_BUFFS_CHANGED" )
	common.RegisterReactionHandler( OnwtATAspectButtonReaction, "wtATAspectButtonReaction")
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

---- FUNCTIONS ----
function loadSettings()
	--common.LogInfo( "common", "Loading Settings" )
	local loaded = userMods.GetAvatarConfigSection( "AllodsToolsAspect" )
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
	userMods.SetAvatarConfigSection( "AllodsToolsAspect", saves )
	--common.LogInfo( "common", "Enabled is " .. tostring(Settings["Enabled"] ) )
	--common.LogInfo( "common", "Saved Settings" )
end

function playWTMessage(input)
	wtATAspectMessage:SetVal("value", userMods.ToWString(input))
	wtATAspectMessage:Show( true )
	wtATAspectMessage:PlayFadeEffect( 0.0, 1.0, MESSAGE_FADE_IN_TIME, EA_MONOTONOUS_INCREASE )
	fadeStatus = WIDGET_FADE_IN
end

function fadeButton()
	if not Settings["Enabled"] then
		wtATAspectButton:SetFade( 0.5 )
		return
	end
	wtATAspectButton:SetFade( 1.0 )
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function isAspectLearned()
	local spellbook = avatar.GetSpellBook()
	for i, id in pairs( spellbook ) do
		local spellInfo = spellLib.GetDescription( id )
		if table.contains(Aspects, userMods.FromWString( spellInfo.name ) ) then
			return true
		end
	end
	return false
end

function isAspectActive()
	local buffs = object.GetBuffs( avatar.GetId() )
	if next ( buffs ) then
		local buffsInfo = object.GetBuffsInfo( buffs )
		for buffId, buffInfo in pairs( buffsInfo or {} ) do
			local buffName = userMods.FromWString( buffInfo.name )
			if table.contains( Aspects, buffName ) then
				return true
			end
		end
	end
	return false
end

---- EVENT HANDLERS ----
function OnEventObjectBuffsChanged( params )
	--common.LogInfo( "common", "Object Buffs changed" )
	--common.LogInfo( "common", "Testing Enabled" )
	if not Settings["Enabled"] then
		--common.LogInfo( "common", "--> Setting disabled" )
		return
	end
	--common.LogInfo( "common", "--> Setting enabled" )
	--common.LogInfo( "common", "Testing other Players" )
	if params.objectId ~= avatar.GetId() then
		--common.LogInfo( "common", "--> Object Buffs changed of other player" )
		return
	end
	--common.LogInfo( "common", "--> Object Buffs changed of self" )
	--common.LogInfo( "common", "Testing Aspect learned" )
	if not isAspectLearned() then
		--common.LogInfo( "common", "--> Aspect is not learned" )
		return
	end
	--common.LogInfo( "common", "--> Aspect is learned" )
	--common.LogInfo( "common", "Testing Aspect Active" )
	if isAspectActive() then
		--common.LogInfo( "common", "--> Aspect is active" )
		return
	end
	--common.LogInfo( "common", "--> Aspect is not active" )
	playWTMessage( Message )
end

function OnEventEffectFinished ( params )
	if params.wtOwner:IsEqual( wtATAspectMessage ) then
		if fadeStatus == WIDGET_FADE_IN then
			wtATAspectMessage:PlayFadeEffect( 1.0, 1.0, MESSAGE_FADE_SOLID_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_SOLID		
		elseif fadeStatus == WIDGET_FADE_SOLID then
			wtATAspectMessage:PlayFadeEffect( 1.0, 0.0, MESSAGE_FADE_OUT_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_OUT		
		elseif fadeStatus == WIDGET_FADE_OUT then
			fadeStatus = WIDGET_FADE_TRANSPARENT
			wtATAspectMessage:Show( false )
		end
	end
end

---- REACTION HANDLERS ----
function OnwtATAspectButtonReaction( params )
	if DnD.IsDragging() then return end
	--common.LogInfo( "common", "Button pressed" )
	Settings["Enabled"] = not Settings["Enabled"]
	fadeButton()
	saveSettings()
end