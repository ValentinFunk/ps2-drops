/*
	Instances of this type are created through the points factory.
	No persistence is available as it does not make sense (buy points for points?)
*/

ITEM.PrintName = "Pointshop 2 Points Item"
ITEM.baseClass = "base_single_use"
ITEM.category = "Misc"

ITEM.material = "pointshop2/dollar103.png"
ITEM.currencyType = "points"
ITEM.amount = 100

function ITEM:initialize( )
	--Fields that are JSON saved for each item
	self.saveFields = self.saveFields or {}
	table.insert(self.saveFields, "currencyType" )
	table.insert(self.saveFields, "amount" )
end

function ITEM:postLoad( )
	return ITEM.super.postLoad( self )
	:Then( function( )
		local currencyStr
		if self.currencyType == "points" then
			currencyStr = "Points"
			self.material = "pointshop2/dollar103.png"
		else
			currencyStr = "Premium Points"
			self.material = "pointshop2/donation.png"
		end
		self.PrintName = self.amount .. " " ..  currencyStr
		self.Description = "Gives you " .. self.amount .. " " .. currencyStr .. " when used." 
	end )
end

-- Can always redeem
function ITEM:CanBeUsed( )
	return true
end

--Give points on use
function ITEM:OnUse( )
	if self.currencytype == "points" then
		self:GetOwner( ):PS2_AddStandardPoints( self.amount, "Item Redeemed", false, true )
	else
		self:GetOwner( ):PS2_AddPremiumPoints( self.amount, "Item Redeemed", false, true )
	end
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