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
		base = "base_crate",
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