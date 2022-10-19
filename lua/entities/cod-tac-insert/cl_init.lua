include( "shared.lua" )

local beamColor = Color( 128, 199, 103, 255 )
local textColor = Color( 255, 255, 255, 255 )
local laserMat = Material( "cable/hydra" )
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Draw()
	self:DrawShadow( false )
	self.Entity:DrawModel()
end

function ENT:Draw()
	self:DrawModel() 
	local vector1 = self:GetPos() + self:GetRight() * -4.5
	local vector2 = self:GetPos() + self:GetRight() * -4.5 + Vector( 0, 0, 40 )

	render.SetMaterial( laserMat )
	render.DrawBeam( vector1, vector2, 17, 1, 1, beamColor ) 
end

surface.CreateFont( "arialf", { font = "Arial", antialias = true, size = 35 } )

hook.Add( "HUDPaint", "TacInsertText", function()
	local visibleEnt = LocalPlayer():GetEyeTrace().Entity
	if not visibleEnt:IsValid() then return end
	if not LocalPlayer():GetEyeTrace().Entity then return end

	local entityClass = visibleEnt:GetClass()
	local textX = ScrW() / 2
	local textY = ScrH() / 2 + 150
	local playerToEntDistance = LocalPlayer():GetPos():Distance( visibleEnt:GetPos() )

	if entityClass  == "cod-tac-insert" then
		draw.DrawText( visibleEnt:GetNWString( "TacOwner" ) .."'s Tactical Insertion", "arialf", textX, textY, textColor, TEXT_ALIGN_CENTER )
	end
end )