Pointshop2.KeyPersistence = class( "Pointshop2.KeyPersistence" )
local KeyPersistence = Pointshop2.KeyPersistence 

KeyPersistence.static.DB = "Pointshop2"

KeyPersistence.static.model = {
	tableName = "ps2_keypersistence",
	fields = {
		itemPersistenceId = "int",
		material = "string",
		validCrate = "int"
	},
	belongsTo = {
		ItemPersistence = {
			class = "Pointshop2.ItemPersistence",
			foreignKey = "itemPersistenceId",
			onDelete = "CASCADE"
		},
		CratePersistence = {
			class = "Pointshop2.ItemPersistence",
			foreignKey = "validCrate",
			onDelete = "CASCADE"
		}
	}
}

KeyPersistence:include( DatabaseModel )
KeyPersistence:include( Pointshop2.EasyExport )


function KeyPersistence.static.createOrUpdateFromSaveTable( saveTable, doUpdate )
	return Pointshop2.ItemPersistence.createOrUpdateFromSaveTable( saveTable, doUpdate )
	:Then( function( itemPersistence )
		if doUpdate then
			return KeyPersistence.findByItemPersistenceId( itemPersistence.id )
		else
			local key = KeyPersistence:new( )
			key.itemPersistenceId = itemPersistence.id
			return key
		end
	end )
	:Then( function( key )
		key.material = saveTable.material
		key.validCrate = saveTable.validCrate
		return key:save( )
	end )
end