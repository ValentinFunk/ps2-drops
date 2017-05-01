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

	self:Unbox()
	:Then( function( )
		Pointshop2Controller:getInstance( ):removeItemFromPlayer( ply, key )
		KLogf( 4, "Player %s unboxed a crate", ply:Nick( ) )
	end, function( errid, err )
		KLogf( 2, "Error unboxing crate item: %s", err )
	end )
end

function ITEM:GetChanceTable()
	local sumTbl = {} -- Table with accumulated weights
	local sum = 0
	for k, info in ipairs(self.itemMap) do
		local factoryClass = getClass( info.factoryClassName )
		if not factoryClass then
			KLogf(2, "[WARN] Crate %s invalid factory %s", self.crate:GetPrintName(), info.factoryClassName)
			continue
		end

		local instance = factoryClass:new( )
		instance.settings = info.factorySettings
		if not instance:IsValid( ) then
 			KLogf( 2, "[WARN] Crate %s factory %s IsValid() false: %s", self.crate:GetPrintName(), info.factoryClassName, instance:GetShortDesc( ) )
			continue
		end

		-- Here we iterate over each of the items a factory can generate, and multiply it's
		-- relative weight inside the factory with the factory's weight to get the items global weight.
		local factoryWeight = info.chance
		local chanceMap = instance:GetChanceTable()
		local factoryItemWeightsSum = LibK._.reduce(
			LibK._.pluck(chanceMap, 'chance'), 0, function(sum, item)
				return sum + item
			end )
		
		for _, info in ipairs(chanceMap) do
			local itemOrInfo, chance = info.itemOrInfo, info.chance
			
			local weight = factoryWeight * ( chance / factoryItemWeightsSum )
			sum = sum + weight
			table.insert(sumTbl, { sum = sum, itemOrInfo = itemOrInfo, chance = weight })
		end
	end

	return sumTbl, sum
end

function ITEM:PickRandomItems(iterations)
	local sumTbl, sum = self:GetChanceTable()
	--Pick element
	local function getRandomItem()
		local r = math.random() * sum
		print("RandomCalled: ", r)
		local itemOrInfo
		for _, info in ipairs( sumTbl ) do
			if info.sum >= r then
				itemOrInfo = info.itemOrInfo
				itemOrInfo._chance = info.chance / sum
				break
			end
		end

		return itemOrInfo
	end

	local itemsPicked = {}
	for i = 1, iterations do
		table.insert(itemsPicked, getRandomItem())
	end
	return itemsPicked
end

function ITEM:Unbox( )
	local ply = self:GetOwner( )

	local seed = math.random(10000)
	math.randomseed(seed)
	local items = self:PickRandomItems(Pointshop2.Drops.WINNING_INDEX )
	for k, itemOrInfo in pairs(items) do
		print(k, itemOrInfo.printName, itemOrInfo.PrintName)
	end
	local winningItem = items[Pointshop2.Drops.WINNING_INDEX]
	local rarity = Pointshop2.GetRarityInfoFromNormalized(winningItem._chance)

	return Promise.Resolve()
	:Then(function()
		if winningItem.isInfoTable then
			return winningItem.createItem()
		else
			return winningItem:new( )
		end
	end)
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
			item.purchaseData.amount = price.premiumPoints
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
			return item
		end )
		:Then( function(item) 
			Pointshop2.Drops.DisplayCrateOpenDialog({
				ply = ply,
				crateItemId = self.id,
				seed = seed,
				wonItemId = item.id
			})

			return Promise.Delay(10, item) -- Wait for animation before broadcasting the chat message
		end )
	end )
	:Fail( function( errid, err )
		KLogf( 2, "[ERROR UNBOX] Error: %s %s", tostring( errid ), tostring( err ) )
	end )
	:Done( function( item )
		if not Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastUnbox" ) then
			return
		end

		local minimumBroadcastChance = Pointshop2.GetRarityInfoFromName( Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastRarity" ) ).chance
		if rarity.chance > minimumBroadcastChance then
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
				rarity.color,
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
