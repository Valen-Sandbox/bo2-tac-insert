include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local drawColor = Color( 255, 255, 255, 255 )
local textFont = "TargetID"
local matWhiteStripe = Material( "models/hoff/weapons/tac_insert/sprites/fxt_lensflare_stripe_white" )
local matHeadlight = Material( "models/hoff/weapons/tac_insert/sprites/fxt_light_headlight" )
local matRaySpread = Material( "models/hoff/weapons/tac_insert/sprites/fxt_light_ray_spread" )

local startTime = CurTime()
local animationSpeed = 0.5 -- Seconds to go from start to end
local startScale = 1.5
local endScale = 0.1

local vecRenderStripe = Vector( 0, 0, 28 )
local vecRenderSpread = Vector( 0, 0, 36 )
local vecRenderHeadlight = Vector( 0, 0, 3.2 )
local vecStartOffset = Vector( 0, 0, 18 )
local vecEndOffset = Vector( 0, 0, 48 )

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos() + self:GetRight() * -4.5
	local angle = Angle( 0, LocalPlayer():EyeAngles().yaw, 0 )

	angle.Pitch = angle.Pitch - 180
	local forward = angle:Forward()

	render.SetMaterial( matWhiteStripe )
	render.DrawQuadEasy( pos + vecRenderStripe, forward, 3, 70, drawColor, angle.pitch )

	render.SetMaterial( matRaySpread )
	render.DrawQuadEasy( pos + vecRenderSpread, forward, 60, 70, drawColor, angle.pitch )

	render.SetMaterial( matHeadlight )
	render.DrawQuadEasy( pos + vecRenderHeadlight, angle:Up(), 12, 12, drawColor, angle.pitch + 64 )

	local startPos = pos + vecStartOffset
	local endPos = pos + vecEndOffset

	local curTime = CurTime()
	local delta = ( curTime - startTime ) / animationSpeed
	delta = math.Clamp( delta, 0, 1 )

	if curTime < startTime + animationSpeed then -- Animation is still running
		local progress = ( curTime - startTime ) / animationSpeed
		local currentPos = LerpVector( progress, startPos, endPos )
		local currentScale = Lerp( delta, startScale, endScale )
		render.SetMaterial( matWhiteStripe )
		render.DrawQuadEasy( currentPos, forward, 5 * currentScale, 28, drawColor, angle.pitch )
	else -- Animation has finished, reset the start time for the next animation
		startTime = curTime
	end
end

hook.Add( "HUDPaint", "TacInsert_DrawText", function()
	local locPly = LocalPlayer()
	local visibleEnt = locPly:GetEyeTrace().Entity
	if not IsValid( visibleEnt ) then return end

	local entityClass = visibleEnt:GetClass()
	if entityClass ~= "cod-tac-insert" then return end

	local playerToEntDist = locPly:GetPos():Distance( visibleEnt:GetPos() )
	if playerToEntDist >= 85 then return end

	local textX = ScrW() / 2
	local textY = ScrH() / 2 + 150
	draw.DrawText( visibleEnt:GetNWString( "TacOwner" ) .. "'s Tactical Insertion", textFont, textX, textY, drawColor, TEXT_ALIGN_CENTER )

	if visibleEnt:GetNWString( "TacOwnerID" ) ~= locPly:SteamID() then return end
	local useKey = input.LookupBinding( "+use" ) or "E" -- Fall back to "E" if not bound
	draw.DrawText( "Press " .. string.upper( useKey ) .. " to Pick Up", textFont, textX, textY + 50, drawColor, TEXT_ALIGN_CENTER )
end )