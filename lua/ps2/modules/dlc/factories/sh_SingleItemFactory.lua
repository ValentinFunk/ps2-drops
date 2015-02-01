Pointshop2.SingleItemFactory = class( "Pointshop2.SingleItemFactory", Pointshop2.ItemFactory )
local SingleItemFactory = Pointshop2.SingleItemFactory

SingleItemFactory.Name = "Item"
SingleItemFactory.Icon = "pointshop2/cowboy5.png"
SingleItemFactory.Description = "Pick a single item from the shop."

SingleItemFactory.Settings = {
	BasicSettings = {
		info = {
			label = "Item Settings",
		},
		ItemClass = "" 
	}
}

/*
	Creates an item as needed
*/
function SingleItemFactory:CreateItem( )
	local item = Pointshop2.GetItemClassByName( self.settings["BasicSettings.ItemClass"] ):new( )
	return item:save( )
	:Then( function( item )
		return item
	end )
end

/*
	Name of the control used to configurate this factory
*/
function SingleItemFactory:GetConfiguratorControl( )
	return "DSingleItemFactoryConfigurator"
end

function SingleItemFactory:GetShortDesc( )
	local class = Pointshop2.GetItemClassByName( self.settings["BasicSettings.ItemClass"] )
	return class.PrintName
end

Pointshop2.ItemFactory.RegisterFactory( SingleItemFactory )