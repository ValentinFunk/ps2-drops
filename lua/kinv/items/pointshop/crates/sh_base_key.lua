ITEM.PrintName = "Pointshop 2 Key Base"
ITEM.baseClass = "base_pointshop_item"

ITEM.material = ""

ITEM.category = "Misc"
ITEM.validCrates = {} --Array of crate base classes to unlock

function ITEM.static:GetPointshopIconControl( )
	return "DPointshopMaterialIcon"
end

function ITEM.static:GetPointshopLowendIconControl( )
	return "DPointshopMaterialIcon" 
end

function ITEM.static.getPersistence( )
	return Pointshop2.KeyPersistence
end

function ITEM.static.generateFromPersistence( itemTable, persistenceItem )
	ITEM.super.generateFromPersistence( itemTable, persistenceItem.ItemPersistence )
	itemTable.material = persistenceItem.material
	itemTable.validCrate = persistenceItem.validCrate
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