ITEM.PrintName = "Pointshop 2 Crate Base"
ITEM.baseClass = "base_single_use"

ITEM.material = ""

ITEM.category = "Misc"
ITEM.itemMap = {} --Maps chance to item factory

function ITEM:initialize( )
end

function ITEM.static:GetPointshopIconControl( )
	return "DPointshopMaterialIcon"
end

function ITEM.static:GetPointshopLowendIconControl( )
	return "DPointshopMaterialIcon" 
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

function ITEM.static.GetPointshopDescriptionControl( )
	return "DCrateItemDescription"
end

function ITEM.static:GetCumulatedChances( )
	local sum = 0
	for k, v in pairs( self.itemMap ) do
		sum = sum + v.chance
	end
	return sum
end

function ITEM.static:GetRequiredKeyClass( )
	for k, itemClass in pairs( Pointshop2.GetRegisteredItems( ) ) do
		if subclassOf( KInventory.Items.base_key, itemClass ) then
			if tonumber( itemClass.validCrate ) == tonumber( self.className ) then
				return itemClass
			end
		end
	end
end

function ITEM:CanBeUsed( )
	if not self:GetOwner( ):PS2_GetFirstItemOfClass( self.class:GetRequiredKeyClass( ) ) then
		return false, "You do not own the required key to open this crate"
	end
	
	return true
end

function ITEM:OnUse( )
	local ply = self:GetOwner( )
	
	local key = self:GetOwner( ):PS2_GetFirstItemOfClass( self.class:GetRequiredKeyClass( ) )
	Pointshop2Controller:getInstance( ):removeItemFromPlayer( ply, key )
	:Then( function( )
		--timer.Simple( 0.5, function( )
			self:Unbox( )
		--end )
		KLogf( 4, "Player %s unboxed a crate", ply:Nick( ) )
	end, function( errid, err ) 
		KLogf( 2, "Error unboxing crate item: %s", err )
	end )
end

function ITEM:Unbox( )
	local ply = self:GetOwner( )
	
	--Generate cumulative sum table
	local sumTbl = {}
	local sum = 0
	for k, info in pairs( self.itemMap ) do
		sum = sum + info.chance
		local factoryClass = getClass( info.factoryClassName )
		if not factoryClass then
			continue
		end
		
		local instance = factoryClass:new( )
		instance.settings = info.factorySettings
		if instance:IsValid( ) then
			table.insert( sumTbl, {sum = sum, factory = instance, chance = info.chance })
		end
	end

	if #sumTbl == 0 then
		KLogf( 2, "[DROPS] Error, crate %s: No valid item factories", self:GetPrintName( ) or self.class.PrintName )
		return
	end
	
	--Pick element
	local r = math.random() * sum
	local factory, chance
	for _, info in ipairs( sumTbl ) do
		if info.sum >= r then
			factory = info.factory
			chance = info.chance
			break
		end
	end
	
	if not factory then 
		KLogf( 2, "[ERROR] Could not unbox crate!" )
		PrintTable( sumTbl )
		print( r )
		error( ) --Abort and try to restore
		return
	end
	
	local item = factory:CreateItem( )
	:Then( function( item )
		local price = item.class:GetBuyPrice( ply )
		item.purchaseData = {
			time = os.time( ),
			origin = "Crate"
		}
		if price.points then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "points" 
		elseif price.premiumPoints then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "premiumPoints" 
		else
			item.purchaseData.amount = 0
			item.purchaseData.currency = "points" 
		end
		return item:save( )
	end )
	:Then( function( item )
		KInventory.ITEMS[item.id] = item
		return ply.PS2_Inventory:addItem( item )
		:Then( function( )
			KLogf( 4, "Player %s unboxed %s, got item %s", ply:Nick( ), self:GetPrintName( ) or self.class.PrintName, item:GetPrintName( ) or item.class.PrintName )
			item:OnPurchased( )
			Pointshop2Controller:getInstance( ):startView( "Pointshop2View", "displayItemAddedNotify", ply, item )
			return item
		end )
	end )
	:Fail( function( errid, err ) 
		KLogf( 2, "[ERROR UNBOX] Error: %s %s", tostring( errid ), tostring( err ) )
	end )
	:Done( function( item )
		if not Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastUnbox" ) then 
			return
		end
		
		local minimumBroadcastChance = table.KeyFromValue( Pointshop2.Drops.RarityMap, Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastRarity" ) )
		if chance > minimumBroadcastChance then
			return
		end
		
		net.Start( "PS2D_AddChatText" )
			net.WriteTable{
				Color( 151, 211, 255 ),
				"Player ",
				Color( 255, 255, 0 ),
				ply:Nick( ),
				Color( 151, 211, 255 ),
				" unboxed ",
				Pointshop2.Drops.RarityColorMap[chance],
				item:GetPrintName( ),
				Color( 151, 211, 255 ),
				"!"
			}
		net.Broadcast( )
	end )
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