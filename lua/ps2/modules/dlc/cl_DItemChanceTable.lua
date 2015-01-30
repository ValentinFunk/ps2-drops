local PANEL = {}

function PANEL:Init( )
	self.itemTable = vgui.Create( "DListView", self )
	self.itemTable:Dock( FILL )
	self.itemTable:SetMultiSelect( false )
	self.itemTable:AddColumn( "Item" )
	self.itemTable:AddColumn( "Chance" ):SetMaxWidth( 220 )
	self.itemTable:AddColumn( "Actions" ):SetMaxWidth( 170 )
	self.itemTable:SetDataHeight( 30 )
	
	self.bottomBar = vgui.Create( "DPanel", self )
	self.bottomBar:Dock( BOTTOM )
	self.bottomBar:DockMargin( 0, 5, 0, 0 )
	self.bottomBar.Paint = function() end
	self.bottomBar:SetTall( 40 )
	
	self.addBtn = vgui.Create( "DButton", self.bottomBar )
	self.addBtn:SetImage( "pointshop2/plus24.png" )
	self.addBtn.m_Image:SetSize( 16, 16 )
	self.addBtn:SetText( "Add" )
	self.addBtn:Dock( LEFT )
	self.addBtn:SetSize( 100, 40 )
	function self.addBtn.DoClick( )
		local frame = vgui.Create( "DItemFactoryConfigurationFrame" )
		frame:MakePopup( )
		frame:Center( )
		function frame.OnFinish( frame, class, settings )
			frame:Remove( )
			self:AddFactory( class, settings )
		end
	end
end

function PANEL:GenerateChanceControl( line )
	local pnl = vgui.Create( "DPanel", line )
	pnl:DockPadding( 10, 3, 10, 3 )
	
	pnl.dropdown = vgui.Create( "DComboBox", pnl )
	for rarity, name in pairs( Pointshop2.Drops.RarityMap ) do
		pnl.dropdown:AddChoice( name, rarity )
	end
	
	pnl.dropdown:Dock( LEFT )
	pnl.dropdown:SetWide( 120 )
	pnl.dropdown:SetSkin( "Default" )
	function pnl:GetChanceAmount( )
		return self.dropdown.chance
	end
	function pnl:SetChanceAmount( amount )
		for id, data in pairs( self.dropdown.Data ) do
			if amount == data then
				pnl.dropdown:ChooseOptionID( id )
			end
		end
	end
	function pnl.dropdown.OnSelect( _self, index, value, data )
		pnl.dropdown.chance = data
		timer.Simple( 0, function( )
			hook.Call( "UpdateChance" )
		end)
	end
	
	pnl.lbl = vgui.Create( "DLabel", pnl )
	pnl.lbl:Dock( LEFT )
	pnl.lbl:DockMargin ( 5, 0, 0, 0 )
	hook.Add( "UpdateChance", pnl.lbl, function( )
		local calcPercentage = ( pnl:GetChanceAmount( ) / self:GetCumulatedChance() ) * 100
		pnl.lbl:SetText( Format( " = %.3f%%", calcPercentage ) )
		pnl.lbl:SizeToContents( )
		pnl.lbl:SetColor( color_black )
	end )

	pnl.dropdown:ChooseOptionID( 2 )
	return pnl
end

function PANEL:GetCumulatedChance( )
	local sum = 0
	for k, v in pairs( self.itemTable:GetLines( ) ) do
		local amount = v.Columns[2]:GetChanceAmount( )
		sum = sum + amount
	end
	return sum
end

function PANEL:GenerateActionsControl( line )
	local pnl = vgui.Create( "DPanel", line )
	pnl:DockPadding( 10, 3, 10, 3 )
	
	pnl.edit = vgui.Create( "DButton", pnl )
	pnl.edit:SetText( "Configure" )
	function pnl.edit.DoClick( )
		local frame = vgui.Create( "DFrame" )
		frame:SetSize( 400, 600 )
		frame:SetTitle( "Edit Settings" )
		frame:SetSkin( Pointshop2.Config.DermaSkin )
		
		local ctrl = vgui.Create( line.factory:GetConfiguratorControl( ), frame )
		ctrl:Dock( FILL )
		ctrl:Edit( line.factory:GetLoadedSettings( ) )
		
		frame.save = vgui.Create( "DButton", frame )
		frame.save:Dock( BOTTOM )
		frame.save:SetText( "Save" )
		function frame.save.DoClick( )
			line.factory.settings = ctrl:GetSettingsForSave( )
			line.Columns[1]:SetText( line.factory:GetShortDesc( ) )
			frame:Remove( )
		end
		frame:MakePopup( )
		frame:Center( )
	end
	pnl.edit:Dock( LEFT )
	
	pnl.remove = vgui.Create( "DButton", pnl )
	pnl.remove:SetText( "Remove" )
	function pnl.remove.DoClick( )
		self.itemTable:RemoveLine( line:GetID( ) )
	end
	pnl.remove:Dock( LEFT )
	pnl.remove:DockMargin ( 5, 0, 0, 0 )
	
	return pnl
end

function PANEL:AddFactory( factoryClass, settings )
	local instance = factoryClass:new( )
	instance.settings = settings
	
	local line = self.itemTable:AddLine( instance:GetShortDesc( ) )
	line.Columns[2] = self:GenerateChanceControl( line )
	line.Columns[3] = self:GenerateActionsControl( line )
	
	line.factory = instance
end

function PANEL:GetSaveData( )
	local data = { }
	for k, v in pairs( self.itemTable:GetLines( ) ) do
		table.insert( data, { 
			factoryClassName = v.factory.class.name, 
			factorySettings = v.factory.settings,
			chance = v.Columns[2]:GetChanceAmount( ) 
		} ) 
	end
	return data
end

function PANEL:LoadSaveData( data )
	for k, v in pairs( data ) do
		local factoryClass = getClass( v.factoryClassName )
		if not factoryClass then
			KLogf( 3, "[ERROR] Invalid factory class %s", tostring( v.factoryClassName ) )
			continue
		end
		self:AddFactory( factoryClass, v.factorySettings )
	end
end

function PANEL:Paint( )

end

vgui.Register( "DItemChanceTable", PANEL, "DPanel" )