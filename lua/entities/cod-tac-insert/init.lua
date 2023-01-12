AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

ENT.HealthAmnt = 75 -- from ttt
local zapSound = "npc/assassin/ball_zap1.wav"

function ENT:SpawnFunction( ply, tr )
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
	self:Remove()
end