do
	local PANEL = {}

	function PANEL:Init( )
		self.keyPanel = vgui.Create( "DKeyCreator_Stage1" )
		self.stepsPanel:AddStep( "Key Settings", self.keyPanel )
	end

	vgui.Register( "DKeyCreator", PANEL, "DItemCreator_Steps" )
end

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
		window:DoModal()
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
	lbl:SetText( "Select the crate type that this key can unlock:" )
	lbl:SizeToContents( )
	lbl:DockMargin( 5, 0, 5, 5 )
	
	self.scroll = vgui.Create( "DScrollPanel", self ) 
	self.scroll:SetTall( 80 )
	self.scroll:Dock( TOP )
	self.scroll:DockMargin( 5, 5, 5, 5 )
	
	self.choice = vgui.Create( "DRadioChoice", self.scroll )
	self.choice:DockMargin( 5, 5, 5, 5 )
	self.choice:Dock( TOP )
	function self.choice:PerformLayout( )
		self:SizeToChildren( false, true )
	end
	
	local classes = Pointshop2.Drops.GetCrateClasses( )
	for _, itemClass in pairs( classes ) do
		self.choice:AddOption( itemClass.PrintName ).class = itemClass
	end
	
	if #classes == 0 then
		local lbl = vgui.Create( "DLabel", self )
		lbl:Dock( TOP )
		lbl:SetText( "No crates created yet" )
		lbl:SizeToContents( )
		lbl:DockMargin( 20, 0, 5, 5 )
		lbl:SetColor( color_white )
	end
	
	timer.Simple( 0, function( )
		self:Center( )
	end )
end

function PANEL:SaveItem( saveTable )
	saveTable.material = self.manualEntry:GetText( )
	saveTable.validCrate = self.choice:GetSelectedOption( ).class.className
end

function PANEL:EditItem( persistence, itemClass )
	self.manualEntry:SetText( persistence.material )
	self.materialPanel:SetMaterial( persistence.material )
end

function PANEL:Validate( saveTable )
	if not self.choice:GetSelectedOption( ) then
		return false, "You must select a crate type"
	end
	
	return true
end

function PANEL:Paint()
end

vgui.Register( "DKeyCreator_Stage1", PANEL, "DItemCreator_Stage" )