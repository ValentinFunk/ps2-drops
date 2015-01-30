local PANEL = {}

function PANEL:Init( )
	self:SetSize( 800, 600 )
	self:SetTitle( "Crate Contents" )
	self:SetSkin( Pointshop2.Config.DermaSkin )
	
	self.itemsTable = vgui.Create( "DItemChanceTable", self )
	self.itemsTable:Dock( FILL )
	self.itemsTable:DockMargin( 5, 10, 5, 5 )
	self.itemsTable:DockPadding( 5, 5, 5, 5 )
	Derma_Hook( self.itemsTable, "Paint", "Paint", "InnerPanel" )
	
	self.bottom = vgui.Create( "DPanel", self )
	self.bottom:Dock( BOTTOM )
	self.bottom:DockMargin( 5, 0, 5, 5 )
	self.bottom:SetTall( 40 )
	self.bottom:DockPadding( 5, 5, 5, 5 )
	Derma_Hook( self.bottom, "Paint", "Paint", "InnerPanel" )
	
	self.save = vgui.Create( "DButton", self.bottom )
	self.save:SetText( "Save" )
	self.save:SetImage( "pointshop2/floppy1.png" )
	self.save:SetWide( 180 )
	self.save.m_Image:SetSize( 16, 16 )
	self.save:Dock( RIGHT )
	function self.save.DoClick( )
		self:OnSave( self.itemsTable:GetSaveData( ) )
	end
end

function PANEL:Load( data )
	self.itemsTable:LoadSaveData( data )
end

function PANEL:OnSave( data )

end

vgui.Register( "DCrateSettingsDialog", PANEL, "DFrame" )