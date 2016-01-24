cdtgroups = {}
cdtmembers = {}

function CooldownTimers_OnLoad()
	this:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("SPELLS_CHANGED")
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	this:RegisterEvent("UNIT_PET")
	this:RegisterForDrag("LeftButton")
	
	SlashCmdList["COOLDOWNTIMERS"] = function(msg)
		CooldownTimers_slash(msg)
	end
	
	SLASH_COOLDOWNTIMERS1 = "/cdt"
end

function CooldownTimers_OnEvent(event)
	if( event == "VARIABLES_LOADED" ) then
		if( not cdtvars ) then
			cdtvars = {}
			cdtvars.on = true
		end
		if( not cdtvars["version"] ) or ( cdtvars["version"] ~= 1.2 ) then
			cdtvars = nil
			cdtvars = {}
			cdtvars.on = true
			cdtvars["version"] = 1.2						
			cdtvars["texture"] = "standard"
			cdtvars["itemcolor"] = {
				[1] = 0.7,
				[2] = 0.7,
				[3] = 1,
				[4] = 1
			}
			cdtvars["skillcolor"] = {
				[1] = 0,
				[2] = 0.8,
				[3] = 0,
				[4] = 1
			}
			cdtvars["textcolor"] = {
				[1] = .9,
				[2] = .9,
				[3] = .9,
				[4] = 1
			}
			
			cdtvars["timecolor"] = {
				[1] = .9,
				[2] = .9,
				[3] = .9,
				[4] = 1
			}
			
			cdtvars["bordercolor"] = {
				[1] = 1,
				[2] = 1,
				[3] = 1,
				[4] = 1
			}
			
			cdtvars["backdropcolor"] = {
				[1] = 0,
				[2] = 0,
				[3] = 0,
				[4] = 0.7
			}
			
		end
		if( not cdtvars["disabled"] ) then
			cdtvars["disabled"] = {}
		end
		if( not cdtvars["groups"] ) then
			cdtvars["groups"] = {}
		end
		if( not cdtvars["style"] ) then
			cdtvars["style"] = "seconds"
		end
		
		if( not cdtvars["checks"] ) then
			cdtvars["checks"] = {}
			for key, val in CDT_CHECKS do
				if( key > 1) and (key < 5 ) then
					cdtvars["checks"][val] = false
				else
					cdtvars["checks"][val] = true
				end
			end
		end
		
		if( cdtvars["checks"]["cascade"] == nil ) then
			cdtvars["checks"]["cascade"] = true
		end
		
		if( cdtvars["checks"]["sort"] == nil ) then
			cdtvars["checks"]["sort"] = true
		end
		
		if( not cdtvars["values"] ) then
			cdtvars["values"] = {
				["columns"] = 1,
				["bardistance"] = 10,
				["barthickness"] = 14,
				["trans"] = 1,
				["scale"] = 1,
				["minbar"] = 150,
				["minalert"] = 0
			}
		end
		
		if( not cdtvars["report"] ) then
			cdtvars["report"] = {}
			cdtvars["report"]["enable"] = false
			cdtvars["report"]["channel"] = "SELECT"
			cdtvars["report"]["current"] = "SELECT"
		end
		
		if( not cdtvars["values"]["precision"] ) then
			cdtvars["values"]["precision"] = 0
		end
		
		if( not cdtvars["values"]["announcescale"] ) then
			cdtvars["values"]["announcescale"] = 1
		end
		
		if( not cdtvars["groups"] ) then
			cdtvars["groups"] = {}
		end
		
		if( not cdtvars["omnigroup"] ) then
			cdtvars["omnigroup"] = {}
		end			
		if( cdtvars["checks"]["down"] == nil ) then
			cdtvars["checks"]["down"] = true
		end
		
		if( not cdtvars["values"]["mintime"] ) then
			cdtvars["values"]["mintime"] = 2
		end
		
		for i=1, CDT_NUM_SLIDERS do
			getglobal("CooldownTimersOptionsHorizontalSlider"..i.."SliderTitle"):SetText(CDT_SLIDERS_LOCALISED[i])
			getglobal("CooldownTimersOptionsHorizontalSlider"..i.."SliderLow"):SetText(CDT_SLIDERS_ENDS[i][1])
			getglobal("CooldownTimersOptionsHorizontalSlider"..i.."SliderHigh"):SetText(CDT_SLIDERS_ENDS[i][2])
		end
		
		for i=1, CDT_NUM_LABELS do 
			getglobal("CooldownTimersOptionsLabel"..i.."Label"):SetText(CDT_LABELS[i])
		end
		
		for i=1, CDT_NUM_CHECKS do --CDT_CHECKS[i]
			getglobal("CooldownTimersOptionsCheckButton"..i.."Text"):SetText(CDT_CHECKS_LOCALISED[i])
		end
		cdtvars.bagItems = true
		cdtvars.init = false
	end
	if( cdtvars.on == false ) then
		return
	end
	if( event == "SPELLS_CHANGED" ) or (event == "PLAYER_ENTERING_WORLD") then
		local _, class = UnitClass("player")
		local _, race = UnitRace("player")
		if not (class == "ROGUE" or class == "DRUID" or race == "NightElf") then
			this:UnregisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
		end
		
		CooldownTimers_init()
		CooldownTimers_findCooldowns()
	end
	if( event == "CHAT_MSG_SPELL_AURA_GONE_SELF" ) then
		if( arg1 == CDT_STEALTH_FADES ) or (arg1 == CDT_PROWL_FADES) or (arg1 == CDT_SHADOWMELD_FADES ) then
			local fade
			if (arg1 == CDT_STEALTH_FADES) then
				fade = CDT_STEALTH
			elseif arg1 == CDT_PROWL_FADES then
				fade = CDT_PROWL
			elseif arg1 == CDT_SHADOWMELD_FADES then
				fade = CDT_SHADOWMELD
			end
			
			for k,v in cdtvars.stealth do
			local name = GetSpellName( v, BOOKTYPE_SPELL )
			local startTime, duration, flag = GetSpellCooldown( v, BOOKTYPE_SPELL )
			
				if (duration > cdtvars["values"]["mintime"] and (name == fade)) then
					if( not cdtvars["disabled"][name] ) then
						for k, v in cdtvars["omnigroup"] do 
							if( string.find( name, k ) ) then
								name = v
								break
							end
						end
						if( cdtvars["groups"][name] ) then
							name = cdtvars["groups"][name]
						end
						
						if( startTime ~= cdtvars["cooldowns"][name] ) then					
							cdtvars["cooldowns"][name] = startTime
							CooldownTimers_addCooldown( name, startTime, duration, 1, GetSpellTexture(v, BOOKTYPE_SPELL) )		
						end
					end
				end
			end
		end
	elseif( event == "SPELL_UPDATE_COOLDOWN" ) then
		CooldownTimers_findCooldowns()
	elseif( event == "UNIT_PET" ) and (arg1 == "player") then
		local i = 1
		cdtvars.petSpells = {}
		while( GetSpellName(i, BOOKTYPE_PET) ) do 
			if( GetSpellName(i, BOOKTYPE_PET) ~= GetSpellName(i+1, BOOKTYPE_PET) ) and ( not IsSpellPassive(i, BOOKTYPE_PET) ) then
				table.insert(cdtvars.petSpells, i)
			end
			i = i+1
		end
	end
end

function CooldownTimers_slash(msg)
	if( msg == "on" ) then
		if( not cdtvars.on ) then
			cdtvars.on = true
			
			CooldownTimers_init()
			CooldownTimers_findCooldowns()
			
			DEFAULT_CHAT_FRAME:AddMessage("CDT on", 1, 1, 0 )
		else
			DEFAULT_CHAT_FRAME:AddMessage("CDT already on", 1, 1, 0 )
		end
	elseif( msg == "off" ) then
		if( cdtvars.on ) then
			cdtvars.on = false
			for i=1, 12 do
				getglobal( "CooldownBar"..i ).kill = true					
			end
			DEFAULT_CHAT_FRAME:AddMessage("CDT off", 1, 1, 0 )
		else
			DEFAULT_CHAT_FRAME:AddMessage("CDT not on", 1, 1, 0 )
		end
	elseif( msg == "menu" ) then
		CooldownTimers_ShowOptions()
	elseif( msg == "unlock" ) then
		cdtvars["checks"]["locked"] = false
		cdt_setlocks("moveable")
	elseif( msg == "lock" ) then
		cdtvars["checks"]["locked"] = true
		cdt_setlocks("moveable")
	elseif( string.find( msg, "report") ) then
		if msg == "report" then
			if cdtvars["report"]["enable"] == true then
				cdtvars["report"]["enable"] = false
				cdt_setlocks("report")
				DEFAULT_CHAT_FRAME:AddMessage("<CDT> Reporting |cffff0000disabled")
			else
				cdtvars["report"]["enable"] = true
				cdt_setlocks("report")
				DEFAULT_CHAT_FRAME:AddMessage("<CDT> Reporting |cff00ff00enabled")
			end
		else
			for channel in string.gfind( msg, "report (%a+)" ) do
				if (channel == "party") or (channel == "say") or (channel == "guild") or (channel == "yell") or (channel == "select") then
					cdtvars["report"]["channel"] = string.upper(channel)
				else
					DEFAULT_CHAT_FRAME:AddMessage("Invalid channel valid channels are: select, party, guild, say, yell")
				end
			end
		end
	elseif( string.find( msg, "style" ) ) then
		for style in string.gfind( msg, "style (%a+)" ) do
			if( style == "seconds" ) or (style == "minutes") then
				cdtvars["style"] = style
			else
				DEFAULT_CHAT_FRAME:AddMessage("Invalid style valid styles are: minutes, seconds")
			end
		end
	elseif( string.find( msg, "groups" ) ) then
		CDT_ShowGroups()
	else
		if( cdtvars.on ) then
			DEFAULT_CHAT_FRAME:AddMessage("CDT on", 1, 1, 0 )
		else
			DEFAULT_CHAT_FRAME:AddMessage("CDT off", 1, 1, 0 )
		end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00on: |cffffffffEnable CDT")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00off: |cffffffffDisable CDT")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lock: |cffffffffLock bars in place")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00unlock: |cffffffffUnlock bars")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00menu: |cffffffffShow Config Dialog")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00groups: |cffffffffShow Groups Dialog")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00report: |cffffffffEnable/Disable reporting of Cooldowns to party/raid")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00style <minutes/seconds>: |cffffffffChange formating of the time string")
	end
end

function CooldownTimers_GetItemName(bag, slot)
  local linktext = nil
  
  if (bag == -1) then
  	linktext = GetInventoryItemLink("player", slot)
  else
  	linktext = GetContainerItemLink(bag, slot)
  end

  if linktext then
    local _,_,name = string.find(linktext, "^.*%[(.*)%].*$")
    return name
  else
    return ""
  end
end


function CooldownTimers_findCooldowns()
	
	--[[ This checks the highest rank of every spell and checks whether or not they're cooling
		down. It'll then check if the start time is different from what the previously set start
		time was, and if it is add it to the cooldown bars. ]]
	for key, val in cdtvars.spells do
		local startTime, duration, flag = GetSpellCooldown( val, BOOKTYPE_SPELL )
		local name = GetSpellName( val, BOOKTYPE_SPELL )
		
		if( name == CDT_PREP and (startTime > (GetTime()-0.005)) and (duration == 600)) then
			CooldownTimers_cdReset(CDT_PREP_SKILLS)
		elseif( name == CDT_CS and (startTime > (GetTime()-0.005)) and (duration == 600)) then
			CooldownTimers_cdReset(CDT_CS_SKILLS)						
		end		
		
		if (duration > cdtvars["values"]["mintime"]) then
			if( not cdtvars["disabled"][name] ) then
				for k, v in cdtvars["omnigroup"] do 
					if( string.find( name, k ) ) then
						name = v
						break
					end
				end
				if( cdtvars["groups"][name] ) then
					name = cdtvars["groups"][name]
				end
				
				if( startTime ~= cdtvars["cooldowns"][name] ) then					
					cdtvars["cooldowns"][name] = startTime
					CooldownTimers_addCooldown( name, startTime, duration, 1, GetSpellTexture(val, BOOKTYPE_SPELL) )		
				end
			end
		end
	end
	if( cdtvars["checks"]["bagitems"] ) then
		--[[ Checks the bags for items that have cooldowns. These work slightly differently in addition to storing their start time these
			will also store which bar they're using to display(thus if you're equip the item and restart its 30 second cooldown then
			it will simply change the particular bar) ]]
		for i=0, 4 do
			local bagType = GetBagName(i)
			if (bagType ) and not ( string.find(bagType, "Ammo") or string.find(bagType, "Quiver") or string.find(bagType, "Wrapped") ) then
				for d=1, GetContainerNumSlots(i) do
					local texture = GetContainerItemInfo(i, d)
					if( texture ) then
						local startTime, duration = GetContainerItemCooldown(i,d)
						if( duration > cdtvars["values"]["mintime"] ) then
							local name = CooldownTimers_GetItemName(i,d)
							if( not cdtvars["disabled"][name] ) then
								for k, v in cdtvars["omnigroup"] do 
									if( string.find( name, k ) ) then
										name = v
										break
									end
								end
								if( cdtvars["groups"][name] ) then
									name = cdtvars["groups"][name]
								end
								if( not cdtvars["items"][name] ) then
									cdtvars["items"][name] = {}
								end
								if ( cdtvars["items"][name]["startTime"] ~= startTime ) and ( not cdtvars["disabled"][name] ) then
									cdtvars["items"][name]["startTime"] = startTime
									CooldownTimers_addCooldown( name, startTime, duration, 2, texture )
								end
							end
						end
					end
				end
			end
		end
		
		for i=0, 19 do
			if( GetInventoryItemTexture("player", i) ~= nil ) then
				local startTime, duration = GetInventoryItemCooldown("player", i)
				local name = CooldownTimers_GetItemName(-1,i)
					
				if( (name == CDT_RENATAKI) and (duration == 180) and (startTime > (GetTime()-0.005))) then
					CooldownTimers_cdReset(CDT_RENATAKI_SKILLS)			
				end		
					
				if( duration > cdtvars["values"]["mintime"] ) then					
					if( not cdtvars["disabled"][name] ) then
						for k, v in cdtvars["omnigroup"] do 
							if( string.find( name, k ) ) then
								name = v
								break
							end
						end
						if( cdtvars["groups"][name] ) then
							name = cdtvars["groups"][name]
						end
						if( not cdtvars["items"][name] ) then
							cdtvars["items"][name] = {}
						end
						if ( cdtvars["items"][name]["startTime"] ~= startTime ) and ( not cdtvars["disabled"][name] ) then
							cdtvars["items"][name]["startTime"] = startTime
							CooldownTimers_addCooldown( name, startTime, duration, 2, GetInventoryItemTexture("player", i) )
						end
					end
				end
			end
		end
		
		
	end
	--[[ PET Cooldowns ]]
	if( cdtvars["checks"]["petskills"] ) and UnitExists("pet") then
		for key, val in cdtvars.petSpells do
		
			local startTime, duration, flag = GetSpellCooldown(val, BOOKTYPE_PET)
			--local name = GetSpellName( val, BOOKTYPE_PET )
			--DEFAULT_CHAT_FRAME:AddMessage(name.." "..startTime.." "..duration.." "..flag, 1, 0, 0 )
			
			if (duration > cdtvars["values"]["mintime"] and ( flag ~= 0 ) ) then
				local name = GetSpellName( val, BOOKTYPE_PET )
				
				if( not cdtvars["disabled"][name] ) then
					for k, v in cdtvars["omnigroup"] do 
						if( string.find( name, k ) ) then
							name = v
							break
						end
					end
					if( cdtvars["groups"][name] ) then
						name = cdtvars["groups"][name]
					end
					if( startTime ~= cdtvars["cooldowns"][name] ) and ( not cdtvars["disabled"][name] ) then
						cdtvars["cooldowns"][name] = startTime
						CooldownTimers_addCooldown( name, startTime, duration, 1, GetSpellTexture(val, BOOKTYPE_PET) )
					end
				end
			end
			
		end
	end
end

function CooldownTimers_cdReset(t)
	for i=1, 12 do
		local barframe = getglobal( "CooldownBar"..i )
		local text = getglobal("CooldownBar"..i).name
		for k, v in t do
			if text == v then
				barframe.kill = true
			end
		end		
	end
end

function CooldownTimers_addCooldown( name, startTime, duration, item, texture, slot, bag )
	local i, d
	local time = GetTime()
	
	
	--[[slot and bag were put in for the tooltip, not sure why its not completely working yet]]
	
	if( cdtvars["checks"]["cascade"] and cdtvars["checks"]["sort"] ) then
		d = 1
		endTime = startTime + duration
		while( getglobal("CooldownBar"..d):IsVisible() and (d <= COOLDOWNBARS) ) do
			if( endTime <= getglobal("CooldownBar"..d).endTime ) then
				break
			else
				d = d + 1
			end
		end
		if( d == 13 ) then
			return
		end
		for b=1, COOLDOWNBARS do
			if( getglobal("CooldownBar"..b).channeling ) then
				local text = getglobal("CooldownBar"..b).name
				if( not getglobal("CooldownBar"..b):IsVisible() ) then
					break
				end
				if( text == name ) then
					i = b
					break
				end
			end
		end
		if( i ~= d ) then
			if( i ) then
				--DEFAULT_CHAT_FRAME:AddMessage(i.." "..d.." "..name)
				if( i < d ) then
					d = d - 1
				end
				CooldownBar_Cascade(i)
				CooldownBar_shift(d)
				i = d
			else
				--DEFAULT_CHAT_FRAME:AddMessage(d.." shift "..name)
				CooldownBar_shift(d)
				i = d
			end
		else
			--DEFAULT_CHAT_FRAME:AddMessage(i.." equals "..d.." "..name)
		end
	else
		for b=1, COOLDOWNBARS do
			if( getglobal("CooldownBar"..b).channeling ) then
				local text = getglobal("CooldownBar"..b).name
				if( text == name ) then
					i = b
				end
			end
		end
		if( not i ) then			
			for b=1, COOLDOWNBARS do -- else find the first unused bar
				local barframe = getglobal( "CooldownBar"..b )
				if( not barframe:IsVisible() ) then
					i = b
					break
				end
			end
		end
	end	
	
	if( not i ) then -- if no bar is found quit dont add the cooldown.
		return
	end
	
	local icon = getglobal("CooldownBar"..i.."Icon")
	local barframe = getglobal( "CooldownBar"..i )
	local text = getglobal( "CooldownBar"..i.."BarLeftText" )
	local timetext = getglobal( "CooldownBar"..i.."BarRightText" )
	local bar = getglobal( "CooldownBar"..i.."Bar" )
	local bg = getglobal( "CooldownBar"..i.."BGBar" )
	
	if( item == 2 ) then --use different colors for items and skills
		barframe.item = true
		bar:SetStatusBarColor( unpack(cdtvars["itemcolor"]) )
		local r,g,b,a = unpack(cdtvars["itemcolor"])
		bg:SetStatusBarColor( r,g,b,0.25*a )
		barframe.bag = bag
		barframe.slot = slot
	elseif( item == 1 ) then
		barframe.item = false
		bar:SetStatusBarColor( unpack(cdtvars["skillcolor"]) )
		local r,g,b,a = unpack(cdtvars["skillcolor"])
		bg:SetStatusBarColor( r,g,b,0.25*a )
		barframe.skill = slot
	end
	
	barframe.channeling = true
	barframe.startTime = startTime
	barframe.endTime = startTime + duration
	barframe.duration = duration
	barframe.texture = texture
	barframe.name = name
	icon:SetTexture(texture)
	icon:SetTexCoord(.078, .92, .079, .937)
	text:SetText( name )
	local timeleft = barframe.endTime - time
	if( not cdtvars["checks"]["showminutes"] ) then -- if style is set to seconds, show seconds regardless
		timetext:SetText( string.format( "%.1f", timeleft ) )
	else -- if style is set to minutes, show minutes unless its <1min
		if( timeleft > 60 ) then
			local minutes = 0
			while( timeleft > 60 ) do
				minutes = minutes + 1
				timeleft = timeleft - 60
			end
			timetext:SetText( string.format( "%d:%2d", minutes, timeleft ) )
			
		else
			timetext:SetText( string.format( "%.1f", timeleft ) )
		end
	end
	
	bar:SetMinMaxValues( barframe.startTime, barframe.endTime )
	bar:SetValue( barframe.endTime )
	CDT_SetWidths()
	barframe:Show()
	barframe:SetAlpha( cdtvars["values"]["trans"] )
end

function CDT_SetWidths()
	
	if( cdtvars["checks"]["autoresize"] ) then
		local largestwidth = cdtvars["values"]["minbar"]
		for i=1, COOLDOWNBARS do 
			local barframe = getglobal("CooldownBar"..i)
			if( barframe:IsVisible() ) then
				local width = getglobal("CooldownBar"..i.."BarLeftText"):GetWidth() + getglobal("CooldownBar"..i.."BarRightText"):GetWidth() + 30
				if( width > largestwidth ) then
					largestwidth = width
				end
			end
		end
		
		local totalwidth = largestwidth + 10
		if( cdtvars["checks"]["showicons"] ) then
			totalwidth = totalwidth + cdtvars["values"]["barthickness"]
		end
		for i=1, COOLDOWNBARS do 
			local barframe = getglobal("CooldownBar"..i)
			local bar = getglobal("CooldownBar"..i.."Bar")
			local bg = getglobal("CooldownBar"..i.."BGBar")
			
			barframe:SetWidth(totalwidth)
			bar:SetWidth(largestwidth)
			bg:SetWidth(largestwidth)
		end
	else
		local maxwidth = cdtvars["values"]["minbar"]
		for i=1, COOLDOWNBARS do
			local barframe = getglobal("CooldownBar"..i)
			if( barframe.channeling ) then
				local width = maxwidth - getglobal("CooldownBar"..i.."BarRightText"):GetWidth() - 30
				local textwidth = getglobal("CooldownBar"..i.."BarLeftText"):GetWidth()
				if( textwidth > width ) then
					local textbar = getglobal("CooldownBar"..i.."BarLeftText")
					local text = getglobal("CooldownBar"..i.."BarLeftText"):GetText()
					local percent = width/textwidth
					percent = percent - 0.1
					local len = string.len( text )
					len = tonumber( string.format( "%d", len*percent ) )
					text = string.sub( text, 1, len ).."..."
					textbar:SetText( text )
				end
			end
		end
	end
end
			

function CooldownTimers_OnUpdate( i )
	local barframe = getglobal( "CooldownBar"..i )
	local text = getglobal("CooldownBar"..i).name
	if( barframe.kill and ((not (text == CDT_PREP or text == CDT_CS or text == CDT_RENATAKI)) and ((barframe.endTime - GetTime()) > 0) ) ) then --on remove or don't track this kill will be set, next update kills the bar
		barframe.kill = false
		barframe.channeling = false
		barframe.fadeOut = true
		barframe.item = false
		barframe.bag = nil
		barframe.slot = nil
		barframe.bar = nil
		barframe.skill = nil
		barframe.enemy = false
		barframe.texture = nil
		barframe.name = nil
		return
	end
	if( barframe.channeling ) then
		
		local time = GetTime()
		local timetext = getglobal( "CooldownBar"..i.."BarRightText" )
		if( time >= barframe.endTime ) then --when the times up
			local name = barframe.name
			if( cdtvars["checks"]["alerts"] ) and ( barframe.duration > cdtvars["values"]["minalert"] ) then
				CooldownAlertText:SetText(name.." cooldown finished!")
				CooldownAlert:SetAlpha(1)
				CooldownAlert.holdtime = time + 2
				CooldownAlert.state = 1
				CooldownAlert:Show()
				if( cdtvars["checks"]["sound"] ) then
					PlaySound("Deathbind Sound")
				end
			end
			barframe.channeling = false
			barframe.fadeOut = true
			timetext:SetText("Ready!")
			if( barframe.item ) then
				barframe.item = false
				--cdtvars["items"][name]["bar"] = nil
			elseif( barframe.enemy ) then
				barframe.enemy = false
			end
			barframe.name = nil
			barframe.slot = nil
			barframe.bag = nil
			barframe.skill = nil
			CDT_SetWidths()
			return
		end
		
		local bar = getglobal( "CooldownBar"..i.."Bar" )
		local timetext = getglobal( "CooldownBar"..i.."BarRightText" )
		
		local timeleft = barframe.endTime - time
		local barval = barframe.startTime + barframe.endTime - time
		if( not cdtvars["checks"]["showminutes"] ) then
			if( cdtvars["values"]["precision"] ~= 0 ) then
				timetext:SetText( string.format( "%."..cdtvars["values"]["precision"].."f", timeleft ) )
			else
				timetext:SetText( string.format( "%ds", timeleft ) )
			end
		else
			if( timeleft > 60 ) then
				local minutes = 0
				while( timeleft > 60 ) do
					minutes = minutes + 1
					timeleft = timeleft - 60
				end
				
				timetext:SetText( string.format( "%d:%02d", minutes, timeleft ) )
				
			else
				if( cdtvars["values"]["precision"] ~= 0 ) then
					timetext:SetText( string.format( "%."..cdtvars["values"]["precision"].."f", timeleft ) )
				else
					timetext:SetText( string.format( "%ds", timeleft ) )
				end
			end
		end
		bar:SetValue( barval )
	elseif( barframe.fadeOut ) then
		local alpha = barframe:GetAlpha()
		if( alpha > 0 ) then
			barframe:SetAlpha( alpha - 0.05 )
		else
			barframe.fadeOut = false
			if( cdtvars["checks"]["cascade"] ) then
				CooldownBar_Cascade(i)
			else
				barframe:Hide()
			end
		end
	end
end
	
	
function CooldownTimers_init()
	cdtvars.init = true
	cdtvars.numSpells = 1
	cdtvars.spells = {}
	cdtvars.stealth = {}
	cdtvars.cooldowns = {}
	cdtvars.items = {}
	
	for i=1, COOLDOWNBARS do --make the popup look like a normal tooltip
		local popup = getglobal("CooldownBar"..i.."Popup")
		popup:SetBackdropBorderColor( TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b )
		popup:SetBackdropColor( TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b )
	end
	
	while( GetSpellName(cdtvars.numSpells, BOOKTYPE_SPELL) ) do --find the top rank of every spell
		local name = GetSpellName( cdtvars.numSpells, BOOKTYPE_SPELL )
		local nextName = GetSpellName( cdtvars.numSpells+1, BOOKTYPE_SPELL )
		if( name ~= nextName ) then
			if (name == CDT_STEALTH or name == CDT_PROWL or name == CDT_SHADOWMELD) then
				table.insert( cdtvars.stealth, cdtvars.numSpells)
			else 
				table.insert( cdtvars.spells, cdtvars.numSpells )
			end
		end
		cdtvars.numSpells = cdtvars.numSpells + 1
	end
	for key,val in cdtvars["cooldowns"] do
		cdtvars["cooldowns"][key] = false
	end
	for key,val in cdtvars["items"] do
		cdtvars["items"][key]["startTime"] = 0
	end

	cdt_setSettings()
		
end
function cdt_setSettings()
	local i = 1
	while( i <= COOLDOWNBARS ) do
		local m = 1
		for l=1, (cdtvars["values"]["columns"]-1) do
			if( (i+l) > COOLDOWNBARS ) then
				break
			end
			local barframe = getglobal("CooldownBar"..(i+l))
			barframe:ClearAllPoints()
			barframe:SetPoint("TOPLEFT", "CooldownBar"..(l-1+i), "TOPRIGHT", cdtvars["values"]["bardistance"]-5, 0 )
			m = m+1
		end
		m = i + m
		if( m > COOLDOWNBARS ) then
			break
		end
		local barframe = getglobal("CooldownBar"..m)
		barframe:ClearAllPoints()
		if( cdtvars["checks"]["down"] ) then
			barframe:SetPoint("TOPLEFT", "CooldownBar"..i, "BOTTOMLEFT", 0, -cdtvars["values"]["bardistance"]+5 )
		else
			barframe:SetPoint("BOTTOMLEFT", "CooldownBar"..i, "TOPLEFT", 0, cdtvars["values"]["bardistance"]-5 )
		end
		i = m
	end
	
	if ( cdtvars["checks"]["border"] ) then
		for i=1, COOLDOWNBARS do
			getglobal("CooldownBar"..i):SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
													edgeFile="Interface\\Addons\\CooldownTimers\\textures\\CC-Bar-Border",
													tile = true, tileSize = 16, edgeSize = 16,
													insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		end
	else
		for i=1, COOLDOWNBARS do
			getglobal("CooldownBar"..i):SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
													edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
													tile = true, tileSize = 16, edgeSize = 16,
													insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		end
	end
	
	if ( cdtvars["texture"] == "cilo" ) then
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."Bar"):SetStatusBarTexture("Interface\\Addons\\CooldownTimers\\textures\\cilo")
			getglobal("CooldownBar"..i.."BGBar"):SetStatusBarTexture("Interface\\Addons\\CooldownTimers\\textures\\cilo")
		end
	elseif ( cdtvars["texture"] == "smooth" ) then
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."Bar"):SetStatusBarTexture("Interface\\Addons\\CooldownTimers\\textures\\smooth")
			getglobal("CooldownBar"..i.."BGBar"):SetStatusBarTexture("Interface\\Addons\\CooldownTimers\\textures\\smooth")
		end
	elseif ( cdtvars["texture"] == "standard") then
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."Bar"):SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
			getglobal("CooldownBar"..i.."BGBar"):SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
		end
	end
	
	if( cdtvars["checks"]["showicons"] ) then
		for i=1, COOLDOWNBARS do
			local bar = getglobal("CooldownBar"..i.."Bar")
			local bg = getglobal("CooldownBar"..i.."BGBar")
			local barframe = getglobal("CooldownBar"..i)
			
			barframe:SetWidth(cdtvars["values"]["minbar"] + cdtvars["values"]["barthickness"] + 10)
			bar:SetWidth(cdtvars["values"]["minbar"])
			bg:SetWidth(cdtvars["values"]["minbar"])
			
			bar:ClearAllPoints()
			bar:SetPoint("LEFT", "CooldownBar"..i.."Icon", "RIGHT", 0, 0 )
			bg:ClearAllPoints()
			bg:SetPoint("LEFT", "CooldownBar"..i.."Icon", "RIGHT", 0, 0 )
		end
	else
		for i=1, COOLDOWNBARS do
			local bar = getglobal("CooldownBar"..i.."Bar")
			local bg = getglobal("CooldownBar"..i.."BGBar")
			local barframe = getglobal("CooldownBar"..i)
			
			barframe:SetWidth(cdtvars["values"]["minbar"] + 10)
			bar:SetWidth(cdtvars["values"]["minbar"])
			bg:SetWidth(cdtvars["values"]["minbar"])
			
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", "CooldownBar"..i, "TOPLEFT", 5, -5 )
			bg:ClearAllPoints()
			bg:SetPoint("TOPLEFT", "CooldownBar"..i, "TOPLEFT", 5, -5 )
		end
	end
	
	for i=1, COOLDOWNBARS do
		getglobal("CooldownBar"..i):SetHeight( cdtvars["values"]["barthickness"] + 10 )
		getglobal("CooldownBar"..i):SetScale( cdtvars["values"]["scale"] )
		getglobal("CooldownBar"..i.."Bar"):SetHeight( cdtvars["values"]["barthickness"] )
		getglobal("CooldownBar"..i.."BGBar"):SetHeight( cdtvars["values"]["barthickness"] )
		if( cdtvars["checks"]["showicons"] ) then
			getglobal("CooldownBar"..i.."Icon"):SetHeight( cdtvars["values"]["barthickness"] )
			getglobal("CooldownBar"..i.."Icon"):SetWidth( cdtvars["values"]["barthickness"] )
			getglobal("CooldownBar"..i.."Icon"):SetTexCoord(.078, .92, .079, .937)
			getglobal("CooldownBar"..i.."Icon"):Show()
		else
			getglobal("CooldownBar"..i.."Icon"):Hide()
		end
	end
	
	for i=1, COOLDOWNBARS do 
		getglobal("CooldownBar"..i):SetAlpha( cdtvars["values"]["trans"] )
	end
	
	if( cdtvars["checks"]["hidetext"] ) then
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."BarLeftText"):Hide()
		end
	else
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."BarLeftText"):Show()
		end
	end
	
	if( cdtvars["checks"]["hidetime"] ) then
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."BarRightText"):Hide()
		end
	else
		for i=1, COOLDOWNBARS do 
			getglobal("CooldownBar"..i.."BarRightText"):Show()
		end
	end
	
	for i=1, COOLDOWNBARS do
		getglobal("CooldownBar"..i.."BarLeftText"):SetTextColor(unpack(cdtvars["textcolor"]))
		getglobal("CooldownBar"..i.."BarRightText"):SetTextColor(unpack(cdtvars["timecolor"]))
		getglobal("CooldownBar"..i):SetBackdropBorderColor(unpack(cdtvars["bordercolor"]))
		getglobal("CooldownBar"..i):SetBackdropColor(unpack(cdtvars["backdropcolor"]))
	end
	
	CooldownAlert:SetScale(cdtvars["values"]["announcescale"])
		
	if cdtvars["report"]["enable"] == true then
		cdt_setlocks("report")
	else
		cdt_setlocks("moveable")
	end
end

function cdt_setlocks(type)
	if type == "moveable" then
		if( not cdtvars["checks"]["locked"] ) then
			CooldownAlert.locked = false
			CooldownAlert:Show()
			CooldownAlert:EnableMouse(1)
			CooldownAlert:SetAlpha(1)
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i):EnableMouse(1)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."Bar"):EnableMouse(1)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."BGBar"):EnableMouse(1)
			end
			CooldownFrame:Show()
		else
			CooldownAlert.locked = true
			CooldownAlert.state = 2
			CooldownAlert:EnableMouse(false)
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i):EnableMouse(false)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."Bar"):EnableMouse(false)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."BGBar"):EnableMouse(false)
			end
			CooldownFrame:Hide()
		end
	elseif type == "report" then
		if  cdtvars["report"]["enable"] == true then
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i):EnableMouse(1)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."Bar"):EnableMouse(1)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."BGBar"):EnableMouse(1)
			end
		else
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i):EnableMouse(false)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."Bar"):EnableMouse(false)
			end
			for i=1, COOLDOWNBARS do
				getglobal("CooldownBar"..i.."BGBar"):EnableMouse(false)
			end
		end
	end		
end

function CooldownTimers_OnClick( button, name )
	if( string.gfind( name, "Bar(%d+)Bar" ) ) and (button == "RightButton") then
		for w in string.gfind( name, "(CooldownBar%d+)%a") do
			getglobal(w.."Popup"):Show()
		end
	elseif( button == "LeftButton" ) then
		if IsShiftKeyDown() and  cdtvars["report"]["enable"] == true then
			for w in string.gfind( name, "(CooldownBar%d+)%a") do
				local skill = getglobal(name.."LeftText"):GetText()
				local timeleft = getglobal(name.."RightText"):GetText()
				
				if cdtvars["report"]["channel"] == "SELECT" then 
					if UnitInRaid("player") or ( UnitInParty("player") and GetNumPartyMembers() > 0 ) then
						if UnitInRaid("player") then
							cdtvars["report"]["current"] = "RAID"
						else
							cdtvars["report"]["current"] = "PARTY"
						end
					else
						cdtvars["report"]["current"] = "SAY"
					end
				else
					cdtvars["report"]["current"] = cdtvars["report"]["channel"]
				end				
				
				if cdtvars["report"]["current"] then
					SendChatMessage("<CDT> -="..skill.."=- available in: "..timeleft, cdtvars["report"]["current"] )
				end
			end		
		else
			for w,x in string.gfind( name, "CooldownBar(%d+)PopupButton(%d)" ) do
				getglobal("CooldownBar"..w.."Popup"):Hide()
				if( x == "1" ) then
					getglobal("CooldownBar"..w).kill = true
				elseif( x == "2" ) then
					getglobal( "CooldownBar"..w).kill = true
					cdtvars["disabled"][getglobal("CooldownBar"..w).name] = true
				end
			end
		end
	end
end

function CooldownTimers_ShowOptions()

	for i=1, CDT_NUM_CHECKS do 
		if( cdtvars["checks"][CDT_CHECKS[i]] ) then
			getglobal("CooldownTimersOptionsCheckButton"..i):SetChecked(1)
		else
			getglobal("CooldownTimersOptionsCheckButton"..i):SetChecked(0)
		end
	end
	
	if cdtvars["texture"] == "standard" then	
		UIDropDownMenu_SetSelectedValue(CooldownTimersOptionsTextures, 1)
		UIDropDownMenu_SetText(CDT_TEXTURES_STANDARD, CooldownTimersOptionsTextures)
	elseif cdtvars["texture"] == "cilo" then	
		UIDropDownMenu_SetSelectedValue(CooldownTimersOptionsTextures, 2)
		UIDropDownMenu_SetText(CDT_TEXTURES_CILO, CooldownTimersOptionsTextures)
	elseif cdtvars["texture"] == "smooth" then	
		UIDropDownMenu_SetSelectedValue(CooldownTimersOptionsTextures, 3)
		UIDropDownMenu_SetText(CDT_TEXTURES_SMOOTH, CooldownTimersOptionsTextures)
	end
	
	for i=1, CDT_NUM_SLIDERS do 
		getglobal("CooldownTimersOptionsHorizontalSlider"..i.."Slider"):SetValue( cdtvars["values"][CDT_SLIDERS[i]] )
	end
	--[[
	CooldownTimersOptionsColor1Swatch.r, CooldownTimersOptionsColor1Swatch.g, CooldownTimersOptionsColor1Swatch.b, CooldownTimersOptionsColor1Swatch.a = unpack(cdtvars["skillcolor"])
	CooldownTimersOptionsColor1Swatch:SetVertexColor(unpack(cdtvars["skillcolor"]))
	
	CooldownTimersOptionsColor2Swatch.r, CooldownTimersOptionsColor2Swatch.g, CooldownTimersOptionsColor2Swatch.b, CooldownTimersOptionsColor2Swatch.a = unpack(cdtvars["itemcolor"])
	CooldownTimersOptionsColor2Swatch:SetVertexColor(unpack(cdtvars["itemcolor"]))
	
	CooldownTimersOptionsColor3Swatch.r, CooldownTimersOptionsColor3Swatch.g, CooldownTimersOptionsColor3Swatch.b, CooldownTimersOptionsColor3Swatch.a = unpack(cdtvars["timecolor"])
	CooldownTimersOptionsColor3Swatch:SetVertexColor(unpack(cdtvars["timecolor"]))
	
	CooldownTimersOptionsColor4Swatch.r, CooldownTimersOptionsColor4Swatch.g, CooldownTimersOptionsColor4Swatch.b, CooldownTimersOptionsColor4Swatch.a = unpack(cdtvars["textcolor"])
	CooldownTimersOptionsColor4Swatch:SetVertexColor(unpack(cdtvars["textcolor"]))
	
	CooldownTimersOptionsColor5Swatch.r, CooldownTimersOptionsColor5Swatch.g, CooldownTimersOptionsColor5Swatch.b, CooldownTimersOptionsColor5Swatch.a = unpack(cdtvars["bordercolor"])
	CooldownTimersOptionsColor5Swatch:SetVertexColor(unpack(cdtvars["bordercolor"]))
	
	CooldownTimersOptionsColor6Swatch.r, CooldownTimersOptionsColor6Swatch.g, CooldownTimersOptionsColor6Swatch.b, CooldownTimersOptionsColor6Swatch.a = unpack(cdtvars["backdropcolor"])
	CooldownTimersOptionsColor6Swatch:SetVertexColor(unpack(cdtvars["backdropcolor"])) --]]
	
	for i=1, CDT_NUM_COLORS do
		local swatch = getglobal("CooldownTimersOptionsColor"..i.."Swatch")
		swatch.r, swatch.g, swatch.b, swatch.a = unpack(cdtvars[CDT_COLORS[i]])
		swatch:SetVertexColor(unpack(cdtvars[CDT_COLORS[i]]))
	end
	
	CooldownTimersOptions:Show()

end

function CooldownTimers_SaveOptions()
	for i=1, CDT_NUM_CHECKS do 
		if( getglobal("CooldownTimersOptionsCheckButton"..i):GetChecked() == 1 ) then
			cdtvars["checks"][CDT_CHECKS[i]] = true
		else
			cdtvars["checks"][CDT_CHECKS[i]] = false
		end
	end
	
	if UIDropDownMenu_GetSelectedValue( CooldownTimersOptionsTextures) == 1 then
		cdtvars["texture"] = "standard"
	elseif UIDropDownMenu_GetSelectedValue( CooldownTimersOptionsTextures) == 2 then
		cdtvars["texture"] = "cilo"
	elseif UIDropDownMenu_GetSelectedValue( CooldownTimersOptionsTextures) == 3 then
		cdtvars["texture"] = "smooth"
	end
	
	for i=1, CDT_NUM_SLIDERS do
		cdtvars["values"][CDT_SLIDERS[i]] = getglobal("CooldownTimersOptionsHorizontalSlider"..i.."Slider"):GetValue()
	end
	
	for i=1, CDT_NUM_COLORS do 
		local swatch = getglobal("CooldownTimersOptionsColor"..i.."Swatch")
		cdtvars[CDT_COLORS[i]] = { swatch.r, swatch.g, swatch.b, swatch.a }
	end
	--[[
	
	cdtvars["skillcolor"][1] = CooldownTimersOptionsColor1Swatch.r
	cdtvars["skillcolor"][2] = CooldownTimersOptionsColor1Swatch.g
	cdtvars["skillcolor"][3] = CooldownTimersOptionsColor1Swatch.b
	cdtvars["skillcolor"][4] = CooldownTimersOptionsColor1Swatch.a
	
	cdtvars["itemcolor"][1] = CooldownTimersOptionsColor2Swatch.r
	cdtvars["itemcolor"][2] = CooldownTimersOptionsColor2Swatch.g
	cdtvars["itemcolor"][3] = CooldownTimersOptionsColor2Swatch.b
	cdtvars["itemcolor"][4] = CooldownTimersOptionsColor2Swatch.a
	
	cdtvars["timecolor"][1] = CooldownTimersOptionsColor3Swatch.r
	cdtvars["timecolor"][2] = CooldownTimersOptionsColor3Swatch.g
	cdtvars["timecolor"][3] = CooldownTimersOptionsColor3Swatch.b
	cdtvars["timecolor"][4] = CooldownTimersOptionsColor3Swatch.a
	
	cdtvars["textcolor"][1] = CooldownTimersOptionsColor4Swatch.r
	cdtvars["textcolor"][2] = CooldownTimersOptionsColor4Swatch.g
	cdtvars["textcolor"][3] = CooldownTimersOptionsColor4Swatch.b
	cdtvars["textcolor"][4] = CooldownTimersOptionsColor4Swatch.a
	
	cdtvars["bordercolor"][1] = CooldownTimersOptionsColor5Swatch.r
	cdtvars["bordercolor"][2] = CooldownTimersOptionsColor5Swatch.g
	cdtvars["bordercolor"][3] = CooldownTimersOptionsColor5Swatch.b
	cdtvars["bordercolor"][4] = CooldownTimersOptionsColor5Swatch.a
	
	cdtvars["backdropcolor"][1] = CooldownTimersOptionsColor6Swatch.r
	cdtvars["backdropcolor"][2] = CooldownTimersOptionsColor6Swatch.g
	cdtvars["backdropcolor"][3] = CooldownTimersOptionsColor6Swatch.b
	cdtvars["backdropcolor"][4] = CooldownTimersOptionsColor6Swatch.a
	--]]
	CooldownTimersOptions:Hide()
	
	cdt_setSettings()
end

local CDTCancelFunc = {
	[1] = function(x) CDTCancelColor(1, x) end,
	[2] = function(x) CDTCancelColor(2, x) end,
	[3] = function(x) CDTCancelColor(3, x) end,
	[4] = function(x) CDTCancelColor(4, x) end,
	[5] = function(x) CDTCancelColor(5, x) end,
	[6] = function(x) CDTCancelColor(6, x) end
}

local CDTSetColorFunc = {
	[1] = function() CDTSetColor(1) end,
	[2] = function() CDTSetColor(2) end,
	[3] = function() CDTSetColor(3) end,
	[4] = function() CDTSetColor(4) end,
	[5] = function() CDTSetColor(5) end,
	[6] = function() CDTSetColor(6) end
}

local CDTSetOpacityFunc = {
	[1] = function() CDTSetOpacity(1) end,
	[2] = function() CDTSetOpacity(2) end,
	[3] = function() CDTSetOpacity(3) end,
	[4] = function() CDTSetOpacity(4) end,
	[5] = function() CDTSetOpacity(5) end,
	[6] = function() CDTSetOpacity(6) end
}

function CDT_ColorPicker(id)
	CloseMenus()
	local texture = getglobal("CooldownTimersOptionsColor"..id.."Swatch")
	ColorPickerFrame.func = CDTSetColorFunc[id]
	ColorPickerFrame:SetColorRGB(texture.r, texture.g, texture.b)
	ColorPickerFrame.previousValues = {r = texture.r, g = texture.g, b = texture.b, opacity =texture.a}
	ColorPickerFrame.cancelFunc = CDTCancelFunc[id]
	ColorPickerFrame.hasOpacity = true
	ColorPickerFrame.opacity = 1 - texture.a
	ColorPickerFrame.opacityFunc = CDTSetOpacityFunc[id]
	
	ColorPickerFrame:Show()
end

function CDTSetOpacity(id)
	local a = 1 - OpacitySliderFrame:GetValue()
	local texture = getglobal("CooldownTimersOptionsColor"..id.."Swatch")
	--DEFAULT_CHAT_FRAME:AddMessage(id)
	texture:SetAlpha(a)
	texture.a = a
end

function CDTSetColor(id)
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local texture = getglobal("CooldownTimersOptionsColor"..id.."Swatch")
	--SHTSetOpacity(id)
	texture:SetVertexColor(r, g, b)
	texture.r = r
	texture.g = g
	texture.b = b
end

function CDTCancelColor(id, prev)
	local texture = getglobal("CooldownTimersOptionsColor"..id.."Swatch")
	local r = prev.r
	local g = prev.g
	local b = prev.b
	local a = prev.opacity
	texture:SetVertexColor(r, g, b)
	texture:SetAlpha( a )
	texture.r = r
	texture.g = g
	texture.b = b
	texture.a = a
end

function CooldownAlert_OnLoad()
	this:RegisterForDrag("LeftButton")
end

function CooldownAlert_OnUpdate()
	if( this.locked ) then
		if( this.state == 1 ) then
			local time = GetTime()
			if( time >= this.holdtime ) then
				this.state = 2
			end
		elseif( this.state == 2 ) then
			local alpha = this:GetAlpha() - 0.05
			if( alpha > 0 ) then
				this:SetAlpha(alpha)
			else
				this.state = 0
				this:Hide()
			end
		end
	end
end

function CooldownBar_shift(id, pos)	
	if( not id ) then
		return
	end
	if( not pos ) then
		for i=1, COOLDOWNBARS do 
			if( not getglobal("CooldownBar"..i):IsVisible() ) then
				pos = i-1
				break
			end
		end
	end
	
	if( not pos ) then
		return
	end
	
	if( pos < id ) or ( (pos == 12 ) and (getglobal("CooldownBar"..pos):IsVisible() ) ) then
		CDT_SetWidths()
		return
	end
	
	CooldownBar_copy(pos+1, pos)
	getglobal("CooldownBar"..(pos+1)):Show()
	CooldownBar_shift(id, pos-1)
	
end

function CooldownBar_Cascade(id)
	if( (id == 12) or (not getglobal("CooldownBar"..(id+1)):IsVisible() ) ) then
		getglobal("CooldownBar"..id):Hide()
		CDT_SetWidths()
		return
	end
	
	CooldownBar_copy(id, id+1)
	CooldownBar_Cascade(id+1)
end

function CooldownBar_copy(to, from)
	
	local barframeto = getglobal("CooldownBar"..to)
	local barto = getglobal("CooldownBar"..to.."Bar")
	local bgto = getglobal("CooldownBar"..to.."BGBar")
	local lefttextto = getglobal("CooldownBar"..to.."BarLeftText")
	local righttextto = getglobal("CooldownBar"..to.."BarRightText")
	local texto = getglobal("CooldownBar"..to.."Icon")
	
	local barframe = getglobal("CooldownBar"..from)
	local bar = getglobal("CooldownBar"..from.."Bar")
	local bg = getglobal("CooldownBar"..from.."BGBar")
	local lefttext = getglobal("CooldownBar"..from.."BarLeftText")
	local righttext = getglobal("CooldownBar"..from.."BarRightText")
	local tex = getglobal("CooldownBar"..from.."Icon")
	
	barframeto.channeling = barframe.channeling
	barframeto.fadeOut = barframe.fadeOut
	barframeto.item = barframe.item
	barframeto.bag = barframe.bag
	barframeto.slot = barframe.slot
	barframeto.bar = barframe.bar
	barframeto.skill = barframe.skill
	barframeto.enemy = barframe.enemy
	barframeto.texture = barframe.texture
	barframeto.name = barframe.name
	barframeto.startTime = barframe.startTime
	barframeto.endTime = barframe.endTime
	barframeto.duration = barframe.duration
	barframeto.kill = false
	
	barto:SetMinMaxValues(barframeto.startTime, barframeto.endTime)
	barto:SetValue(bar:GetValue())
	local r,g,b,a
	if( barframe.item ) then
		r,g,b,a = unpack( cdtvars["itemcolor"] )
	else
		r,g,b,a = unpack( cdtvars["skillcolor"] )
	end
	barto:SetStatusBarColor(r,g,b,a)
	bgto:SetStatusBarColor(r,g,b,0.25*a)
	
	barframeto:SetAlpha(barframe:GetAlpha())
	
	lefttextto:SetText(lefttext:GetText())
	righttextto:SetText(righttext:GetText())
	texto:SetTexture(barframeto.texture)
end


function CDT_ShowGroups()
	cdtgroups = {}
	table.insert( cdtgroups, "disabled" )
	cdtmembers = {}
	cdtmembers["disabled"] = {}
	for key, val in cdtvars["groups"] do
		--DEFAULT_CHAT_FRAME:AddMessage(key.." "..val)
		if( not cdtmembers[val] ) then
			cdtmembers[val] = {}
			table.insert( cdtgroups, val )
		end
		
		table.insert( cdtmembers[val], key )
	end
	
	for key, val in cdtvars["omnigroup"] do 
		if( not cdtmembers[val] ) then
			cdtmembers[val] = {}
			table.insert( cdtgroups, val )
		end
		table.insert( cdtmembers[val], "%"..key )
	end
	
	for key, val in cdtvars["disabled"] do 
		table.insert( cdtmembers["disabled"], key )
	end
	
	CDTMembersScrollBar.selected = nil
	CDTGroupsScrollBar.selected = nil

	CDTMembersScrollBar_Update()
	CDTGroupsScrollBar_Update()
	CooldownTimersGroups:Show()
	
	
end

function CDT_AddGroup()
	local group = CooldownTimersGroupsSinglelineEditBox1:GetText()
	--DEFAULT_CHAT_FRAME:AddMessage(group)
	if(group) and (group ~= "") and ( not cdtmembers[group] ) then
		cdtmembers[group] = {}
		table.insert( cdtgroups, group )
		CDTMembersScrollBar_Update()
		CDTGroupsScrollBar_Update()
	end
end

function CDTButton_OnClick()
	this:LockHighlight()
	if( string.find(this:GetName(), "Groups") ) then
		CDTGroupsScrollBar.selected = this:GetID() + FauxScrollFrame_GetOffset(CDTGroupsScrollBar)
		CDTMembersScrollBar.selected = nil
		CDTMembersScrollBar_Update()
		CDTGroupsScrollBar_Update()
	else
		CDTMembersScrollBar.selected = this:GetID() + FauxScrollFrame_GetOffset(CDTMembersScrollBar)
	end
end

function CDTMembersScrollBar_Update()
	local line -- 1 through 10 of our window to scroll
	local lineplusoffset -- an index into our data calculated from the scroll offset
	local size = 0
	if( CDTGroupsScrollBar.selected ) then
		size = table.getn( cdtmembers[cdtgroups[CDTGroupsScrollBar.selected]] )
	end
	FauxScrollFrame_Update(CDTMembersScrollBar,size,10,16)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(CDTMembersScrollBar)
		if( lineplusoffset <= size ) and CDTGroupsScrollBar.selected then
			getglobal("CDTMembersButton"..line):SetText(cdtmembers[cdtgroups[CDTGroupsScrollBar.selected]][lineplusoffset])
			getglobal("CDTMembersButton"..line):Show()
		else
			getglobal("CDTMembersButton"..line):Hide()
		end
	end
end

function CDTGroupsScrollBar_Update()
	local line -- 1 through 10 of our window to scroll
	local lineplusoffset -- an index into our data calculated from the scroll offset
	local size = table.getn( cdtgroups )
	FauxScrollFrame_Update(CDTGroupsScrollBar,size,10,16)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(CDTGroupsScrollBar)
		if( lineplusoffset <= size ) then
			getglobal("CDTGroupsButton"..line):SetText(cdtgroups[lineplusoffset])
			getglobal("CDTGroupsButton"..line):Show()
		else
			getglobal("CDTGroupsButton"..line):Hide()
		end
	end
end
 
function CDT_DeleteGroup()
	if( CDTGroupsScrollBar.selected ) then
		cdtmembers[cdtgroups[CDTGroupsScrollBar.selected]] = nil
		table.remove( cdtgroups, CDTGroupsScrollBar.selected )
		CDTGroupsScrollBar.selected = nil
		CDTMembersScrollBar_Update()
		CDTGroupsScrollBar_Update()
	end
end

function CDTPopup_OnUpdate()
	if( not MouseIsOver( this ) ) and ( not MouseIsOver( this:GetParent() ) ) then
		this:Hide()
	end
end

function CDT_DeleteMember()
	if( CDTMembersScrollBar.selected ) then
		table.remove( cdtmembers[cdtgroups[CDTGroupsScrollBar.selected]], CDTMembersScrollBar.selected )
		CDTMembersScrollBar.selected = nil
		CDTMembersScrollBar_Update()
	end
end

function CDT_AddMember()
	local member = CooldownTimersGroupsSinglelineEditBox1:GetText()
	--DEFAULT_CHAT_FRAME:AddMessage(member)
	if (CDTGroupsScrollBar.selected) and (member) and (member ~= "") and ( not cdtmembers[member] ) then
		table.insert( cdtmembers[cdtgroups[CDTGroupsScrollBar.selected]], member )
		CDTMembersScrollBar_Update()
	end
	CooldownTimersGroupsSinglelineEditBox1:SetText("")
end


function CDT_SaveGroups()
	cdtvars["groups"] = {}
	cdtvars["disabled"] = {}
	for key, val in cdtmembers do
		for k, v in val do
			if( key == "disabled" ) then
				cdtvars["disabled"][v] = true
			elseif( string.sub( v, 1, 1 ) == "%" ) then
				cdtvars["omnigroup"][string.sub(v, 2 )] = key
			else
				cdtvars["groups"][v] = key
			end
		end
	end
	CooldownTimersGroups:Hide()
end