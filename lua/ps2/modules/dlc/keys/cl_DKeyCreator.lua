local PANEL = {}

function PANEL:Init( )
	self:addSectionTitle( "Key Settings" )
	
	/*
		Table Element
	*/
	
	
	self.selectMatElem = vgui.Create( "DPanel" )
	self.selectMatElem:SetTall( 64 )
	self.selectMatElem:SetWide( self:GetWide( ) )
	function self.selectMatElem:Paint( ) end
	
	self.materialPanel = vgui.Create( "DImage", self.selectMatElem )
	self.materialPanel:SetSize( 64, 64 )
	self.materialPanel:Dock( LEFT )
	self.materialPanel:SetMouseInputEnabled( true )
	self.materialPanel:SetTooltip( "Click to Select" )
	self.materialPanel:SetMaterial( "pointshop2/key63.png" )
	local frame = self
	function self.materialPanel:OnMousePressed( )
		--Open model selector
		local window = vgui.Create( "DMaterialSelector" )
		window:Center( )
		window:MakePopup( )
		Pointshop2View:getInstance( ):requestMaterials( "pointshop2" )
		:Done( function( files )
			window:SetMaterials( "pointshop2", files )
		end )
		function window:OnChange( )
			frame.manualEntry:SetText( window.matName )
			frame.materialPanel:SetMaterial( window.matName )
		end
	end
	
	local rightPnl = vgui.Create( "DPanel", self.selectMatElem )
	rightPnl:Dock( FILL )
	function rightPnl:Paint( )
	end

	self.manualEntry = vgui.Create( "DTextEntry", rightPnl )
	self.manualEntry:Dock( TOP )
	self.manualEntry:DockMargin( 5, 0, 5, 5 )
	self.manualEntry:SetText( "pointshop2/key63.png" )
	self.manualEntry:SetTooltip( "Click on the icon or manually enter the material path here and press enter" )
	function self.manualEntry:OnEnter( )
		frame.materialPanel:SetMaterial( self:GetText( ) )
	end

	self.infoPanel = vgui.Create( "DInfoPanel", self )
	self.infoPanel:SetSmall( true )
	self.infoPanel:Dock( TOP )
	self.infoPanel:SetInfo( "Materials Location", 
[[To add a material to the selector, put it into this folder: 
addons/ps2_drops/materials/pointshop2
Don't forget to upload the material to your fastdl, too!]] )
	self.infoPanel:DockMargin( 5, 5, 5, 5 )
	
	local cont = self:addFormItem( "Material", self.selectMatElem )
	cont:SetTall( 64 )
	
	self:addSectionTitle( "Crates" )
	
	local lbl = vgui.Create( "DLabel", self )
	lbl:Dock( TOP )
	lbl:SetText( "Select the crates that this key open" )
	lbl:SizeToContents( )
	lbl:DockMargin( 5, 0, 5, 5 )
	
	self.slotLayout = vgui.Create( "DIconLayout", self )
	self.slotLayout:Dock( TOP )
	self.slotLayout:DockMargin( 5, 5, 5, 5 )
	self.slotLayout:SetSpaceX( 10 )
	self.slotLayout:SetSpaceY( 5 )
	local old = self.slotLayout.PerformLayout
	function self.slotLayout:PerformLayout( )
		old( self )
	Pointshop2.GetCrateClasses( )
	end
	self.checkBoxes = {}
	for _, itemClass in pairs( Pointshop2.Drops.GetCrateClasses( ) ) do
		local chkBox = vgui.Create( "DCheckBoxLabel", self.slotLayout )
		chkBox:SetText( itemClass.PrintName )
		chkBox:SizeToContents( )
		self.checkBoxes[itemClass.name] = chkBox
	end
	
	timer.Simple( 0, function( )
		self:Center( )
	end )
end

function PANEL:SaveItem( saveTable )
	self.BaseClass.SaveItem( self, saveTable )
	
	saveTable.material = self.manualEntry:GetText( )
end

function PANEL:EditItem( persistence, itemClass )
	self.BaseClass.EditItem( self, persistence.ItemPersistence, itemClass )
	
	self.manualEntry:SetText( persistence.material )
	self.materialPanel:SetMaterial( persistence.material )
end

function PANEL:Validate( saveTable )
	local succ, err = self.BaseClass.Validate( self, saveTable )
	if not succ then
		return succ, err
	end
	
	return true
end

vgui.Register( "DKeyCreator", PANEL, "DItemCreator" )