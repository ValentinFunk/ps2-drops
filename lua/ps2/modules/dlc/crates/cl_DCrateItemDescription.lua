local PANEL = {}

function PANEL:Init( )
	local itemDesc = self
	function self.buttonsPanel:AddUseButton( )
		self.useButton = vgui.Create( "DButton", self )
		local name
		local keyClass = itemDesc.itemClass:GetRequiredKeyClass( )
		if not keyClass then
			KLogf( 3, "[ERROR] Invalid key class for item %s", tostring( itemDesc.itemClass ) )
			name = "ERROR"
		else
			name = keyClass.PrintName
		end
		self.useButton:SetText( "Open (Uses 1 " .. name .. ")" )
		self.useButton:DockMargin( 0, 5, 0, 0 )
		self.useButton:Dock( TOP )
		function self.useButton:DoClick( )
			if itemDesc.item:UseButtonClicked( ) then
				self:SetDisabled( true )
			end
		end
		function self.useButton:Think( )
			local canBeUsed, hint = itemDesc.item:CanBeUsed( )
			if not canBeUsed then
				self:SetDisabled( true )
				self:SetTooltip( hint )
			else
				self:SetDisabled( false )
			end
		end
	end
end

function PANEL:AddKeyInfo( )
	if IsValid( self.singleUsePanel ) then
		self.singleUsePanel:Remove( )
	end

	self.singleUsePanel = vgui.Create( "DPanel", self )
	self.singleUsePanel:Dock( TOP )
	self.singleUsePanel:DockMargin( 0, 8, 0, 0 )
	Derma_Hook( self.singleUsePanel, "Paint", "Paint", "InnerPanelBright" )
	self.singleUsePanel:SetTall( 50 )
	self.singleUsePanel:DockPadding( 5, 5, 5, 5 )
	function self.singleUsePanel:PerformLayout( )
		self:SizeToChildren( false, true )
	end

	local name
	local keyClass = self.itemClass:GetRequiredKeyClass( )
	if not keyClass then
		KLogf( 3, "[WARN] Invalid key class for item %s", tostring( self.itemClass.PrintName ) )
		name = "<No Key Available>"
	else
		name = keyClass.PrintName
	end

	local label = vgui.Create( "DLabel", self.singleUsePanel )
	label:SetText( "This item requires a " .. name .. " to open" )
	label:Dock( TOP )
	label:SizeToContents( )
end

function PANEL:AddCrateContentInfo( )
	if IsValid( self.crateContentPanel ) then
		self.crateContentPanel:Remove( )
	end

	self.crateContentPanel = vgui.Create( "DPanel", self )
	self.crateContentPanel:Dock( TOP )
	self.crateContentPanel:DockMargin( 0, 8, 0, 0 )
	Derma_Hook( self.crateContentPanel, "Paint", "Paint", "InnerPanelBright" )
	self.crateContentPanel:SetTall( 50 )
	self.crateContentPanel:DockPadding( 5, 5, 5, 5 )
	function self.crateContentPanel:PerformLayout( )
		self:SizeToChildren( false, true )
	end

	local label = vgui.Create( "DLabel", self.crateContentPanel )
	label:SetText( "Contains one of the following items:" )
	label:Dock( TOP )
	label:SizeToContents( )

	local pnl = vgui.Create( "DPanel", self.crateContentPanel )
	pnl:Dock( TOP )
	pnl:DockPadding( 5, 0, 5, 5 )
	pnl:DockMargin( 0, 5, 0, 0 )
	function pnl:Paint( w, h )
		surface.SetDrawColor( 200, 200, 200 )
		surface.DrawRect( 0, 0, w, h )
	end
	function pnl:PerformLayout( )
		self:SizeToChildren( false, true )
	end
	Derma_Hook( pnl, "Paint", "Paint", "InnerPanel" )

	for k, info in pairs( self.itemClass.itemMapSorted ) do
		local factoryClass = getClass( info.factoryClassName )
		if not factoryClass then continue end
		local factory = factoryClass:new( )
		factory.settings = info.factorySettings

		if not factory:IsValid( ) then
			continue
		end

		local label = vgui.Create( "DLabel", pnl )
		label:SetText( factory:GetShortDesc( ) )
		label:SetColor( Pointshop2.RarityColorMap[info.chance] )
		label:Dock( TOP )
		label:DockMargin( 0, 5, 0, 0 )
		label:SetFont( self:GetSkin( ).fontName )
		label:SizeToContents( )
	end
end

function PANEL:SetItem( item, noButtons )
	self.BaseClass.SetItem( self, item, noButtons )
	self:AddKeyInfo( )
	self:AddCrateContentInfo( )
	if not noButtons then
		self.buttonsPanel:AddUseButton( )
	end
end

function PANEL:SetItemClass( itemClass, noBuyPanel )
	self.BaseClass.SetItemClass( self, itemClass, noBuyPanel )
	self:AddKeyInfo( )
	self:AddCrateContentInfo( )
end

function PANEL:SelectionReset( )
	self.BaseClass.SelectionReset( self )
	if self.singleUsePanel then
		self.singleUsePanel:Remove( )
	end
	if self.crateContentPanel then
		self.crateContentPanel:Remove( )
	end
end

derma.DefineControl( "DCrateItemDescription", "", PANEL, "DPointshopItemDescription" )
