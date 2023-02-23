AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

ENT.CanUse = true
ENT.RespawnCounter = 0
ENT.HealthAmnt = 75 -- From TTT

local zapSound = "npc/assassin/ball_zap1.wav"
local pickupSound = "hoff/mpl/seal_tac_insert/ammo.wav"

function ENT:SpawnFunction( _, tr )
	if not tr.Hit then return end

	local spawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( "cod-tac-insert" )

	ent:SetPos( spawnPos )
	ent:Spawn()
	ent:Activate()
	ent:GetOwner()

	return ent
end

function ENT:Initialize()
	self:SetModel( "models/hoff/weapons/tac_insert/w_tac_insert.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self:DrawShadow( false )
	self:SetMaxHealth( 5 )
	self:SetHealth( 5 )
	local phys = self:GetPhysicsObject()

	if phys:IsValid() then
		phys:Wake()
	end
	self.Hit = false
end

function ENT:OnTakeDamage( dmg )
	self:TakePhysicsDamage( dmg )

	if self.HealthAmnt <= 0 then return end

	self.HealthAmnt = self.HealthAmnt - dmg:GetDamage()

	if self.HealthAmnt > 0 then return end
	local effect = EffectData()
	effect:SetStart( self:GetPos() )
	effect:SetOrigin( self:GetPos() )
	util.Effect( "cball_explode", effect, true, true )

	sound.Play( zapSound, self:GetPos(), 100, 100 )
	local owner = self:GetOwner()
	owner:ChatPrint( "Your Tactical Insertion has been destroyed!" )
	hook.Remove( "PlayerSpawn", "TacInsert_Spawner_" .. self:GetNWString( "TacOwnerID" ) )
	self:Remove()
end

function ENT:Use( activator )
	if not SERVER then return end
	local owner = self:GetOwner()

	if not IsValid( owner ) then return end
	if activator ~= owner then return end
	if not self.CanUse then return end
	self.CanUse = false
	if owner:Health() <= 0 then return end

	for k, v in pairs( owner.Tacs ) do
		timer.Simple( 0, function()
			if IsValid( v ) then
				if not owner:HasWeapon( "seal6-tac-insert" ) then
					owner:Give( "seal6-tac-insert" )
					owner:EmitSound( pickupSound )
				else
					local effect = EffectData()
					effect:SetStart( v:GetPos() )
					effect:SetOrigin( v:GetPos() )
					util.Effect( "cball_explode", effect, true, true )
					sound.Play( zapSound, v:GetPos(), 100, 100 )
				end

				v:Remove()
			end

			hook.Remove( "PlayerSpawn", "TacInsert_Spawner_" .. self:GetNWString( "TacOwnerID" ) )
			table.remove( owner.Tacs, k )
		end )
	end
end

function ENT:CanTool()
	return false
end

function ENT:PhysgunPickup( _, ent )
	if not IsValid( ent ) then return end
	if ent:GetClass() ~= self:GetClass() then return end

	return false
end

hook.Add( "PhysgunPickup", "TacInsert_StopPhysgun", function( ply, ent )
	if not IsValid( ent ) then return end
	if not ent.PhysgunPickup then return end

	return ent:PhysgunPickup( ply, ent )
end )