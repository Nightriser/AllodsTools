--------------------------------------------------------------------------------------------
-- AllodsToolsPetsby:
-- Engam (Evolution)
-- Blutlust (P2P)
--------------------------------------------------------------------------------------------


---- VARIABLES ----
-- Change According to your localization:
Global( "ITEM", "B" .. string.char(228) .. "ndiger") -- Capture-Item
Global( "MESSAGE", "Du kannst wieder Begleiter fangen" ) -- Tool is ready

-- Shouldn't be changed, changes appearance of announce message
Global( "MESSAGE_FADE_IN_TIME", 350 )
Global( "MESSAGE_FADE_SOLID_TIME", 4000 )
Global( "MESSAGE_FADE_OUT_TIME", 1000 )
Global( "WIDGET_FADE_TRANSPARENT", 1 )
Global( "WIDGET_FADE_IN", 2 )
Global( "WIDGET_FADE_SOLID", 3 )
Global( "WIDGET_FADE_OUT", 4 )

-- used for saving and loading
Global( "Settings", {
	["Enabled"] = true,
})

-- Check every X seconds, if the item is off cooldown.
-- Increment this to reduce accuracy but increase overall performance
Global ( "CHECK_INTERVAL", 600 )
Global ( "CHECK_INTERVAL_COUNTER", 580 )

-- Is Item ready (off cooldown), do not change
Global ( "ITEM_IS_READY", false )

---- WIDGETS ----
Global( "wtATPetsMessage", nil )
Global( "fadeStatus", WIDGET_FADE_TRANSPARENT )
Global( "wtATPetsButton", nil )
wtATPetsMessage = mainForm:GetChildChecked( "wtATPetsMessage", true )
wtATPetsButton = mainForm:GetChildChecked( "wtATPetsButton", true )
wtATPetsButton:SetVal( "button_label", userMods.ToWString("ATP") )
wtATPetsButton:SetFade( 1.0 )


---- INITIALIZATION ----
function initAddon()
--common.LogInfo( "common", "Initializing")
	DnD.Init(165387, wtATPetsButton, wtATPetsButton, true)
	common.RegisterReactionHandler( OnwtATPetsButtonReaction, "wtATPetsButtonReaction")
	common.RegisterEventHandler( OnEventEffectFinished, "EVENT_EFFECT_FINISHED" )
	common.RegisterEventHandler( OnEventSecondTimer, "EVENT_SECOND_TIMER" )
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
	local loaded = userMods.GetAvatarConfigSection( "AllodsToolsPets" )
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
	userMods.SetAvatarConfigSection( "AllodsToolsPets", saves )
	--common.LogInfo( "common", "Enabled is " .. tostring(Settings["Enabled"] ) )
	--common.LogInfo( "common", "Saved Settings" )
end

function playWTMessage(input)
	wtATPetsMessage:SetVal("value", userMods.ToWString(input))
	wtATPetsMessage:Show( true )
	wtATPetsMessage:PlayFadeEffect( 0.0, 1.0, MESSAGE_FADE_IN_TIME, EA_MONOTONOUS_INCREASE )
	fadeStatus = WIDGET_FADE_IN
end

function fadeButton()
	if not Settings["Enabled"] then
		wtATPetsButton:SetFade( 0.5 )
		return
	end
	wtATPetsButton:SetFade( 1.0 )
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function checkItems()
	local itemIDs = avatar.GetInventoryItemIds()
	for key, value in pairs(itemIDs) do
		checkCapture(key, value)
	end
end


function checkCapture(key, itemId)
	if not itemId then
		--common.LogInfo( "common", "Slot " .. tostring(key) .. " nicht belegt" )
		return
	end
	
	local itemName = itemLib.GetName( itemId )
	--common.LogInfo( "common", "Slot " .. tostring(key) .. " belegt mit " .. userMods.FromWString( itemName ) )
	if userMods.FromWString( itemName ) ~= ITEM then
		--common.LogInfo( "common", "Item ist nicht Bändiger" )
		return
	end
	
	--common.LogInfo( "common", "Item ist Bändiger" )
	local spellId = itemLib.GetSpell ( itemId )
	local cooldown = spellLib.GetCooldown( spellId )
	local remainingCD = cooldown.remainingMs
	if remainingCD > 0 then
		--common.LogInfo( "common", "Item hat noch " .. remainingCD/(60 * 1000) .. " Minuten Cooldown" )
		ITEM_IS_READY = false
		return
	end
	--common.LogInfo( "common", "Cooldown abgelaufen" )
	ITEM_IS_READY = true
end

-- ~


---- EVENT HANDLERS ----
function OnEventSecondTimer( params )
	--common.LogInfo( "common", "CHECK_INTERVAL_COUNTER = " .. tostring( CHECK_INTERVAL_COUNTER ) )
	if CHECK_INTERVAL_COUNTER ~= CHECK_INTERVAL then
		CHECK_INTERVAL_COUNTER = CHECK_INTERVAL_COUNTER + 1
		return
	end
	CHECK_INTERVAL_COUNTER = 0
	if not Settings["Enabled"] then
		return
	end
	checkItems()
	if not ITEM_IS_READY then
		return
	end
	playWTMessage( MESSAGE )
end

function OnEventEffectFinished ( params )
	if params.wtOwner:IsEqual( wtATPetsMessage ) then
		if fadeStatus == WIDGET_FADE_IN then
			wtATPetsMessage:PlayFadeEffect( 1.0, 1.0, MESSAGE_FADE_SOLID_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_SOLID		
		elseif fadeStatus == WIDGET_FADE_SOLID then
			wtATPetsMessage:PlayFadeEffect( 1.0, 0.0, MESSAGE_FADE_OUT_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_OUT		
		elseif fadeStatus == WIDGET_FADE_OUT then
			fadeStatus = WIDGET_FADE_TRANSPARENT
			wtATPetsMessage:Show( false )
		end
	end
end

---- REACTION HANDLERS ----
function OnwtATPetsButtonReaction( params )
	if DnD.IsDragging() then return end
	--common.LogInfo( "common", "Button pressed" )
	Settings["Enabled"] = not Settings["Enabled"]
	fadeButton()
	saveSettings()
end