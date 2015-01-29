Pointshop2.CratePersistence = class( "Pointshop2.CratePersistence" )
local CratePersistence = Pointshop2.CratePersistence 

CratePersistence.static.DB = "Pointshop2"

CratePersistence.static.model = {
	tableName = "ps2_cratepersistence",
	fields = {
		itemPersistenceId = "int",
		material = "string",
		itemMap = "luadata" --lazy way
	},
	belongsTo = {
		ItemPersistence = {
			class = "Pointshop2.ItemPersistence",
			foreignKey = "itemPersistenceId",
			onDelete = "CASCADE"
		}
	}
}

CratePersistence:include( DatabaseModel )
CratePersistence:include( Pointshop2.EasyExport )


function CratePersistence.static.createOrUpdateFromSaveTable( saveTable, doUpdate )
	return Pointshop2.ItemPersistence.createOrUpdateFromSaveTable( saveTable, doUpdate )
	:Then( function( itemPersistence )
		if doUpdate then
			return CratePersistence.findByItemPersistenceId( itemPersistence.id )
		else
			local crate = CratePersistence:new( )
			crate.itemPersistenceId = itemPersistence.id
			return crate
		end
	end )
	:Then( function( crate )
		crate.material = saveTable.material
		crate.itemMap = saveTable.itemMap
		return crate:save( )
	end )
end