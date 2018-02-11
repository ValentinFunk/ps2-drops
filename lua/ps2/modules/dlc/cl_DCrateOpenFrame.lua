local PANEL = {}

function PANEL:Init() 
	self:DockPadding( 0, 5, 0, 0 )
	self.stripContainer = vgui.Create("DPanel", self)
	self.stripContainer:Dock(FILL)
	function self.stripContainer:Paint() end
	function self.stripContainer.PerformLayout()
		if self.strip then
			self.strip:SetTall(self:GetTall())
		end
	end

	self.strip = vgui.Create("DPanel", self.stripContainer)
	self.strip.Paint = function(self, w, h)
		surface.SetDrawColor( 0, 0, 0, 1 )
		surface.DrawRect(0, 0, w, h)
	end

	-- Arrange in singe row
	function self.strip:PerformLayout()
		local icons = self:GetChildren()
		local x = 0
		for k, icon in pairs(icons) do
			icon:SetPos(x, 0)
			icon:SetTall(self:GetTall() - 10)
			x = x + icon:GetWide() + 5
		end
		self:SetWide(x - 5)
	end
end

--[[
	Generates the icon controls for the table of items
	supplied.
]]--
function PANEL:GenerateStripIcons(itemsOnStrip)
	for k, itemOrInfo in pairs(itemsOnStrip) do
		local icon
		if itemOrInfo.isInfoTable then
			icon = itemOrInfo.getIcon()
		else
			local itemClass = itemOrInfo
			icon = vgui.Create(itemClass.GetPointshopIconControl(), self)
			icon:SetItemClass(itemClass)
		end
		
		local itemChance = itemOrInfo._displayChance
		local rarity = Pointshop2.GetRarityInfoFromAbsolute(itemChance)
		icon:SetRarity(rarity)
		icon.noSelect = true
		icon:SetWide(128)
		icon:SetParent(self.strip)
		local children = self.strip:GetChildren()
		table.RemoveByValue( children, self )
		table.insert(children, icon)
		print(k, itemOrInfo.printName, itemOrInfo.PrintName)
	end
end

function PANEL:SetCrate(crate)
	self.crate = crate.class
end

function PANEL:Spin(targetItemIndex)
	local minX = (targetItemIndex - 1) * 128 + (targetItemIndex - 1) * 5
	local maxX = minX + 128
	local pos = math.random(minX, maxX)
	local promise, tweenInstance = LibK.tween( easing.outQuart, 10, function( p )
		if IsValid(self.strip) then
			self.strip:SetPos(-pos * p + self:GetWide() / 2, 0 )
		end
	end )
	self.tweenInstance = tweenInstance
	return promise
end

function PANEL:Paint(w, h)
	if self.tweenInstance then
		if self.tweenInstance:update() then
			self.tweenInstance = nil
		end
	end
end

function PANEL:PaintOver(w, h)
	surface.SetDrawColor(self:GetSkin().Highlight or color_white)
	surface.DrawRect(w / 2 - 2, 0, 4, h)
end

vgui.Register( "DCrateOpenSpinner", PANEL, "DPanel" )


local PANEL = {}

function PANEL:Init()
	self:SetSkin(Pointshop2.Config.DermaSkin)
	self:DockPadding( 16, 8, 16, 16 )

	self.m_fCreateTime = SysTime()
	self:Center()
	self:MakePopup()
	self:DoModal()

	self.loading = vgui.Create( "DLoadingNotifier", self )
	self.loading:Dock( TOP )

	self.crateIcon = vgui.Create("DCenteredImage", self)
	self.crateIcon:Dock( TOP )
	self.crateIcon:DockMargin( 16, 32, 16, 8 )
	self.crateIcon:SetTall( 64 )

	self.crateText = vgui.Create("DLabel", self)
	self.crateText:SetText( "Unboxing Crate" )
	self.crateText:Dock( TOP )
	self.crateText:DockMargin( 16, 8, 16, 32 )
	self.crateText:SetContentAlignment(5)
	self.crateText:SetFont(self:GetSkin().SmallTitleFont)
	self.crateText:SetColor(color_white)
	self.crateText:SizeToContents()


	self.crateSpinner = vgui.Create("DCrateOpenSpinner", self)
	self.crateSpinner:Dock(TOP)
	self.crateSpinner:SetTall(128 + 10)
	self.crateSpinner:SetWide(5 * 128 + 4 * 128)
end

function PANEL:PerformLayout()
	self.crateSpinner:SetWide(5 * 128 + 4 * 5)
	self:SizeToChildren(true, true)
	--self:SetWide(self.crateSpinner:GetWide() + 32)
	self:Center()
end

--[[
	Preloads icons that will be used to avoid lagg
	when spinning.
]]
function PANEL:LoadIcons(items)
	local promises = {}
	for k, itemOrInfo in pairs(items) do
		if itemOrInfo.isInfoTable then
			continue
		end

		local itemClass = itemOrInfo
		local control = _G[itemClass:GetConfiguredIconControl()]
		if not control then
			KLogf(2, "[WARNING] Pointshop 2 item class %s: Cannot find control %s in _G", itemClass.className, itemClass:GetConfiguredIconControl() or "<INVALID>")
			continue
		end
		
		if control.PreloadIcon then
			table.insert(promises, control.PreloadIcon(itemClass))
		end
	end

	return WhenAllFinished(promises)
end

function PANEL:UnpackCrate(crate, seed, itemId)
	self.loading:Expand()
	self.crateSpinner:SetCrate(crate)
	self.crateText:SetText( "Unboxing " .. crate:GetPrintName() )
	self.crateIcon:SetImage(crate.class.material)

	math.randomseed(seed)
	local items = crate:PickRandomItems(Pointshop2.Drops.WINNING_INDEX + 5)
	
	return self:LoadIcons(items)
	:Then(function()
		if not IsValid(self) or not IsValid(self.crateSpinner) then return end

		self.crateSpinner:GenerateStripIcons(items)
		self.loading:Collapse()
		return self.crateSpinner:Spin(Pointshop2.Drops.WINNING_INDEX) -- Spins to the left border
	end)
	:Then(function()
		Pointshop2View:getInstance():displayItemAddedNotify(KInventory.ITEMS[itemId], "You unboxed " .. crate:GetPrintName() .. ":")
		
		if not IsValid(self) or not IsValid(self.crateSpinner) then return end
		local itemIcon = self.crateSpinner.strip:GetChildren()[Pointshop2.Drops.WINNING_INDEX]
		itemIcon:SetParent(nil)
		self:Remove()
		Pointshop2.ItemInYourFace(itemIcon)
	end)
end

function PANEL:Paint(w, h)
	DisableClipping(true)
		surface.SetDrawColor(Color(0, 0, 0, 150))
		local x, y = self:LocalToScreen( 0, 0 )
		surface.DrawRect( x * -1, y * -1, ScrW(), ScrH() )
		Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
	DisableClipping(false)
	derma.SkinHook("Paint", "PointshopFrame", self, w, h)
end
vgui.Register( "DCrateOpenFrame", PANEL, "EditablePanel" )