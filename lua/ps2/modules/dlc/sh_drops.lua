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
			value = {},
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

Pointshop2.Drops.Rarities = {
	{ name = "Very Common", chance = 101 },
	{ name = "Common", chance = 47 },
	{ name = "Uncommon", chance = 21 },
	{ name = "Rare", chance = 10 },
	{ name = "Very Rare", chance = 4 },
	{ name = "Extremely Rare", chance = 1 },
}

--Chance -> Name
Pointshop2.Drops.RarityMap = {
	[101] = "Very Common",
	[47] = "Common",
	[21] = "Uncommon",
	[10] = "Rare",
	[4] = "Very Rare",
	[1] = "Extremely Rare"
}

Pointshop2.Drops.RarityColorMap = {
	[101] = Color( 157, 157, 157 ),
	[47] = color_white,
	[21] = Color( 30, 255, 0 ),
	[10] = Color( 0, 112, 255 ),
	[4] = Color( 163, 53, 236 ),
	[1] = Color( 255, 128, 0 )
}

if SERVER then
	util.AddNetworkString( "PS2D_AddChatText" )
end
if CLIENT then
	net.Receive( "PS2D_AddChatText", function( )
		chat.AddText( unpack( net.ReadTable( ) ) )
	end )
end
