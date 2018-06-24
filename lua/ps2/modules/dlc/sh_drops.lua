hook.Add( "PS2_ModulesLoaded", "DLC_Drops", function( )
	local MODULE = Pointshop2.GetModule( "Pointshop 2 DLC" )
	table.insert( MODULE.Blueprints, {
		label = "Crate",
		base = "base_crate",
		icon = "pointshop2/box39.png",
		creator = "DCrateCreator"
	} )
	table.insert( MODULE.Blueprints, {
		label = "Key",
		base = "base_key",
		icon = "pointshop2/key63.png",
		creator = "DKeyCreator"
	} )
	
	MODULE.Settings.Server.DropsTableSettings = {
		info = {
			label = "Drops Settings",
			isManualSetting = true, --Ignored by AutoAddSettingsTable
		},
		DropsData = {
			value = { },
			type = "table"
		},
	}
	
	MODULE.Settings.Server.DropsSettings = {
		info = {
			label = "Drops Settings",
		},
		EnableDrops = {
			value = true,
			label = "Enable Drops system",
		},
		UseGamemodeDrops = {
			value = true,
			label = "Use Gamemode Events",
			tooltip = "Uses gamemode events to give drops only on round end. Only works for gamemodes with an integration plugin."
		},
		DropFrequency = {
			value = 5,
			label = "Drop frequency (in Minutes)",
			tooltip = "Set the drop frequency."
		},
		DropChance = {
			value = 10,
			label = "Drop Chance (in Percent)",
			tooltip = "Chance that a player gets a drop when a drop is triggered."
		},
	}
	
	MODULE.Settings.Server.BroadcastDropsSettings = {
		info = {
			label = "Drops Chat Print Settings",
		},
		BroadcastRarity = {
			value = "Uncommon", 
			type = "option",
			label = "Broadcast minimum Rarity",
			tooltip = "Broadcast only unbox / drops if the item is above this rarity treshold",
			possibleValues = {
				"Very Common",
				"Common",
				"Uncommon",
				"Rare",
				"Very Rare",
				"Extremely Rare"
			}
		},
		BroadcastDrops = {
			value = true, 
			label = "Broadcast drops in chat",
			tooltip = "Posts a message to chat whenever a player gets a drop."
		},
		BroadcastUnbox = {
			value = true,
			label = "Broadcast unbox rewards in chat",
			tooltip = "Posts a message to chat whenever a player unboxes a crate."
		},
	}
	
	table.insert( MODULE.SettingButtons, {
		label = "Drops Setup",
		icon = "pointshop2/inbox3.png",
		control = "DPointshopDropsConfigurator"
	} )
	
	print( "Loaded PS2-Drops for Pointshop 2 v. " .. "{{ user_id }}" )
end )

Pointshop2.Drops = {}

function Pointshop2.Drops.GetCrateClasses( )
	local classes = { }
	for _, itemClass in pairs( KInventory.Items ) do
		if subclassOf( KInventory.Items.base_crate, itemClass ) then
			table.insert( classes, itemClass )
		end
	end
	return classes
end

Pointshop2.Drops.WINNING_INDEX = 35

if SERVER then
	util.AddNetworkString( "PS2D_AddChatText" )
	util.AddNetworkString( "PS2D_OpenCrate" )

	function Pointshop2.Drops.DisplayCrateOpenDialog(tbl)
		net.Start("PS2D_OpenCrate")
			net.WriteUInt(tbl.crateItemId, 32)
			net.WriteUInt(tbl.seed, 32)
			net.WriteUInt(tbl.wonItemId, 32)
		net.Send(tbl.ply)
	end
end
if CLIENT then
	net.Receive( "PS2D_AddChatText", function( )
		chat.AddText( unpack( net.ReadTable( ) ) )
	end )

	net.Receive( "PS2D_OpenCrate", function( len )
		local crateItemId = net.ReadUInt(32)
		local seed = net.ReadUInt(32)
		local wonItemId = net.ReadUInt(32)

		local crate = KInventory.ITEMS[crateItemId]
		if not crate then
			KLogf(1, "[ERROR] Error displaying unbox dialog, crate %s not found in cache", crateItemId)
			return
		end

		if Pointshop2.ClientSettings.GetSetting('BasicSettings.NoUnbox') then
			if not KInventory.ITEMS[wonItemId] then
				KLogf(2, "[WARN] You unboxed item %i but it wasnt cached clientside", wonItemId)
				return
			end

			Pointshop2View:getInstance():displayItemAddedNotify(KInventory.ITEMS[wonItemId], "You unboxed " .. crate:GetPrintName() .. ":")
			return
		end

		if IsValid(Pointshop2.CrateOpenFrame) then
			KLogf(2, "[WARN] Tried to open crate open frame - but another is already spinning")
			return
		end

		-- Failsafe 
		timer.Simple( 10.2, function()
			if IsValid( Pointshop2.CrateOpenFrame ) then
				Pointshop2.CrateOpenFrame:Remove()
				Pointshop2View:getInstance():displayError( "There was a problem showing the crate unboxing. Please contact an admin and send them a console log.")
				KLogf(1, "Had to kill the unboxing frame! %s", LibK.GLib.StackTrace ())
			end
		end )

		Pointshop2.CrateOpenFrame = vgui.Create("DCrateOpenFrame")
		Pointshop2.CrateOpenFrame:UnpackCrate(crate, seed, wonItemId)

	end )

	hook.Add("Think", "PS2_BlackenInv", function()
		if IsValid(Pointshop2.Menu) then
			if IsValid(Pointshop2.CrateOpenFrame) and not Pointshop2.Menu.dropsBlackened then
				Pointshop2.Menu.dropsBlackened = true
				function Pointshop2.Menu:PaintOver(w, h)
					surface.SetDrawColor(0, 0, 0)
					surface.DrawRect(0, 0, w, h)
				end
				print("done1")
			elseif (not IsValid(Pointshop2.CrateOpenFrame)) and Pointshop2.Menu.dropsBlackened then
				Pointshop2.Menu.PaintOver = function() end
				Pointshop2.Menu.dropsBlackened = false
				print("done2")
			end
		end
	end)

	-- Disable rendering when in the full screen crate thing to gain some extra FPS
	local performanceHooks = {
		"PreDrawOpaqueRenderables",
		"PreDrawTranslucentRenderables",
		"RenderScene"
	}
	for k, v in pairs(performanceHooks) do
		hook.Add(v, "DisableForPerf", function()
			if IsValid(Pointshop2.CrateOpenFrame) and not Pointshop2.CrateOpenFrame.ItemsLoading then
				return true
			end
		end)
	end
end