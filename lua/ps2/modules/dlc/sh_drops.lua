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