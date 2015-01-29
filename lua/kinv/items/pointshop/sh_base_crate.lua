ITEM.PrintName = "Pointshop 2 Crate Base"
ITEM.baseClass = "base_single_use"

ITEM.material = ""

ITEM.category = "Misc"
ITEM.itemMap = {} --Maps chance to item factory

function ITEM:initialize( )
end

function ITEM.static:GetPointshopIconControl( )
	return "DPointshopTrailIcon"
end

function ITEM.static.getPersistence( )
	return Pointshop2.CratePersistence
end

function ITEM.static.generateFromPersistence( itemTable, persistenceItem )
	ITEM.super.generateFromPersistence( itemTable, persistenceItem.ItemPersistence )
	itemTable.material = persistenceItem.material
	itemTable.itemMap = persistenceItem.itemMap
end

function ITEM.static.GetPointshopIconDimensions( )
	return Pointshop2.GenerateIconSize( 2, 4 )
end

/*
	Inventory icon
*/
function ITEM:getIcon( )
	self.icon = vgui.Create( "DPointshopMaterialInvIcon" )
	self.icon:SetItem( self )
	self.icon:SetSize( 64, 64 )
	return self.icon
end