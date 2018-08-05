ITEM.PrintName = "Pointshop 2 Crate Base"
ITEM.baseClass = "base_single_use"

ITEM.material = ""

ITEM.category = "Misc"
ITEM.itemMap = {} --Maps chance to item factory

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
    local sortedChances = table.Copy(itemTable.itemMap)
    table.SortByMember( sortedChances, "chance", true )
    itemTable.itemMapSorted = sortedChances
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
        if subclassOf( KInventory.Items.base_key, itemClass ) and
            tonumber( itemClass.validCrate ) == tonumber( self.className ) then
                return itemClass
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

    return self:Unbox()
    :Then( function( )
        KLogf( 4, "Player %s unboxed a crate", ply:Nick( ) )
    end, function( errid, err )
        KLogf( 2, "Error unboxing crate item: %s", err )
    end )
end

function ITEM:GetChanceTable()
    local sumTbl = {} -- Table with accumulated weights
    local sum = 0
    for k, info in ipairs( self.itemMap ) do
        local factoryClass = getClass( info.factoryClassName )
        if not factoryClass then
            KLogf(2, "[WARN] Crate %s invalid factory %s", self.crate:GetPrintName(), info.factoryClassName)
            continue
        end

        local instance = factoryClass:new( )
        instance.settings = info.factorySettings
        if not instance:IsValid( ) then
             KLogf( 2, "[WARN] Crate %s factory %s IsValid() false: %s", self:GetPrintName(), info.factoryClassName, instance:GetShortDesc( ) )
            continue
        end

        -- Here we iterate over each of the items a factory can generate, and multiply it's
        -- relative weight inside the factory with the factory's weight to get the items global weight.
        local factoryWeight = info.chance
        local chanceMap = instance:GetChanceTable()
        local factoryItemWeightsSum = LibK._.reduce(
            LibK._.pluck( chanceMap, 'chance' ), 0, function( sum, item )
                return sum + item
            end )

        for _, chanceInfo in ipairs(chanceMap) do
            local itemOrInfo, chance = chanceInfo.itemOrInfo, chanceInfo.chance
            local displayChance = chanceInfo.displayChance or factoryWeight
            local weight = factoryWeight * ( chance / factoryItemWeightsSum )
            if not LibK.isProperNumber(weight) then
                print( factoryWeight, chance, factoryItemWeightsSum,chance / factoryItemWeightsSum, weight )
                LibK.GLib.Error( "BaseCrate:GetChanceTable - Invalid item weight!" )
            end
            sum = sum + weight
            -- Chance represents the actual chance, display
            table.insert( sumTbl, { sum = sum, itemOrInfo = itemOrInfo, chance = weight, displayChance = displayChance } )
        end
    end

    return sumTbl, sum
end
-- Modified from original single use as everything is now wrapped in a transaction
function ITEM:InternalOnUse( )
    --Avoid double use
    if self.used or not self:CanBeUsed( ) then
        return
    end
    self.used = true

    local ply = self:GetOwner( )
    ply._ItemUseLock = ply._ItemUseLock or Promise.Resolve()
    if getPromiseState(ply._ItemUseLock) != "pending" then
        ply._ItemUseLock = Promise.Resolve()
    end

    ply._ItemUseLock = ply._ItemUseLock:Then(function()
        if not IsValid( ply ) then
            return Promise.Reject( "Player disconnected during use" )
        end

        local succ, err = pcall( self.OnUse, self )
        if not succ then
            LibK.GLib.Error( Format( "[ERROR] Item %s Use failed: %s", self.class.name, err ) )
            ply._ItemUseLock = nil
            return
        end

        -- Pcall returns either the argument or the returned value
        -- By wrapping the return value in a promise here we make sure
        -- that if a promise is returned we wait on it.
        return err
    end):Then( function( )
        KLogf( 4, "Player %s used an item", ply:Nick( ) )
    end, function( errid, err )
        LibK.GLib.Error( Format( "Error using item: %s %s", tostring( errid ), tostring( err ) ) )
    end )
end

function ITEM:PickRandomItems( iterations )
    local sumTbl, sum = self:GetChanceTable( )
    --Pick element
    local function getRandomItem( )
        local r = math.random( ) * sum
        local itemOrInfo
        for _, info in ipairs( sumTbl ) do
            if info.sum >= r then
                itemOrInfo = info.itemOrInfo
                itemOrInfo._chance = info.chance / sum
                itemOrInfo._displayChance = info.displayChance
                break
            end
        end

        return itemOrInfo
    end

    local itemsPicked = { }
    for i = 1, iterations do
        local item = getRandomItem( )
        table.insert( itemsPicked, item )
    end
    return itemsPicked
end

function ITEM:Unbox( )
    local ply = self:GetOwner( )
    local key = self:GetOwner( ):PS2_GetFirstItemOfClass( self.class:GetRequiredKeyClass( ) )
    if not key then LibK.GLib.Error("ITEM:Unbox - Invalid Key") end

    local seed = math.random(10000)
    math.randomseed(seed)
    local items = self:PickRandomItems( Pointshop2.Drops.WINNING_INDEX )
    local winningItem = items[Pointshop2.Drops.WINNING_INDEX]
    local rarity = Pointshop2.GetRarityInfoFromAbsolute( winningItem._displayChance )
    local crateId = self.id
    local keyId
    return Promise.Resolve( )
    :Then( function( )
        if winningItem.isInfoTable then
            return winningItem.createItem( true )
        else
            return winningItem:new( )
        end
    end )
    :Then( function( item )
        local price = item.class:GetBuyPrice( ply )
        item.purchaseData = {
            time = os.time( ),
            rarity = rarity.chance,
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

        item.inventory_id = ply.PS2_Inventory.id
        item:preSave( )
        keyId = key.id
        if Pointshop2.DB.CONNECTED_TO_MYSQL then
            local transaction = LibK.TransactionMysql:new(Pointshop2.DB)
            transaction:begin( )
            transaction:add( item:getSaveSql( ) ) -- Create Item
            transaction:add( Format( "DELETE FROM kinv_items WHERE id IN(%i, %i)", self.id, key.id ) ) -- Remove crate & key
            return transaction:commit( ):Then( function( )
                return Pointshop2.DB.DoQuery( "SELECT LAST_INSERT_ID() as id" )
            end ):Then( function( id )
                item.id = id[1].id
                return item
            end):Then( Promise.Resolve, function( err )
                LibK.GLib.Error( "BaseCrate:Unbox - Error running sql " + tostring( err ) )
                return Pointshop2.DB.DoQuery("ROLLBACK"):Then( function( )
                    return Promise.Reject( "Error!" )
                end )
            end )
        else
            sql.Begin( )
            -- Remove crate and key
            self:remove( true ):Then( function( )
                return key:remove( true )
            end):Then( function( )
                item.inventory_id = ply.PS2_Inventory.id
                return item:save()
            end):Then( function( )
                sql.Commit()
            end, function( err )
                sql.Query( "ROLLBACK")
                return Promise.Reject( err )
            end)
            return Promise.Resolve( item )
        end
    end )
    :Then( function( item )
        Pointshop2.Drops.DisplayCrateOpenDialog({
            ply = ply,
            crateItemId = crateId,
            seed = seed,
            wonItemId = item.id
        })

        KInventory.ITEMS[crateId] = nil
        KInventory.ITEMS[keyId] = nil
        Pointshop2.LogCacheEvent( 'REMOVE', 'unbox', crateId )
        Pointshop2.LogCacheEvent( 'REMOVE', 'unbox', keyId )
        ply.PS2_Inventory:notifyItemRemoved( crateId )
        ply.PS2_Inventory:notifyItemRemoved( keyId )

        ply.PS2_Inventory:notifyItemAdded( item )
        KLogf( 4, "Player %s unboxed %s, got item %s", ply:Nick( ), self:GetPrintName( ) or self.class.PrintName, item:GetPrintName( ) or item.class.PrintName )
        item:OnPurchased( )

        if not Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastUnbox" ) then
            return
        end
        if not IsValid( ply ) then
            return
        end

        local minimumBroadcastChance = table.KeyFromValue(Pointshop2.RarityMap, Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastRarity" ))
        if rarity.chance > minimumBroadcastChance then
            return
        end

        local nick, rarityColor, itemName = ply:Nick( ), rarity.color, item:GetPrintName( )
        -- Wait for animation before broadcasting the chat message
        Promise.Delay( 10 ):Then( function( )
            net.Start( "PS2D_AddChatText" )
                net.WriteTable{
                    Color( 151, 211, 255 ),
                    "Player ",
                    Color( 255, 255, 0 ),
                    nick,
                    Color( 151, 211, 255 ),
                    " unboxed ",
                    rarityColor,
                    itemName,
                    Color( 151, 211, 255 ),
                    "!"
                }
            net.Broadcast( )
        end )
    end )
    :Fail( function( errid, err )
        KLogf( 2, "[ERROR UNBOX] Error: %s %s", tostring( errid ), tostring( err ) )
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
