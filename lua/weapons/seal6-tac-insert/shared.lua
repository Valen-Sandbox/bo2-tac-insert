AddCSLuaFile( "shared.lua" )

SWEP.Author			= "Hoff"
SWEP.Category 		= "Other"
SWEP.Spawnable		= true
SWEP.AdminSpawnable	= true

SWEP.ViewModel		= "models/hoff/weapons/tac_insert/c_tac_insert.mdl"
SWEP.WorldModel		= "models/hoff/weapons/tac_insert/w_tac_insert.mdl"
SWEP.ViewModelFOV 	= 75

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= ""
SWEP.Primary.Delay			= 0

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "Tactical Insertion"
SWEP.Slot				= 4
SWEP.SlotPos			= 1
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true
SWEP.DrawWeaponInfoBox	= false

SWEP.UseHands = true

SWEP.Next = CurTime()
SWEP.Primed = 0

SWEP.Offset = {
	Pos = {
		Up = -1,
		Right = 0,
		Forward = 2,
	},
	Ang = {
		Up = 45,
		Right = 180,
		Forward = 45,
	}
}

local zapSound = "npc/assassin/ball_zap1.wav"
local clipSound = "hoff/mpl/seal_tac_insert/clip.wav"
local beepSound = "hoff/mpl/seal_tac_insert/beep.wav"
local flick1Sound = "hoff/mpl/seal_tac_insert/flick_1.wav"
local flick2Sound = "hoff/mpl/seal_tac_insert/flick_2.wav"

local respawnLimitCvar = CreateConVar( "sv_tacinsert_respawnlimit", 0, { CHEAT, FCVAR_REPLICATED } )

function SWEP:DrawWorldModel()
	local owner = self:GetOwner()
	if not IsValid( owner ) then self:DrawModel() return end

	local bone = owner:LookupBone( "ValveBiped.Bip01_R_Hand" )
	if not bone then self:DrawModel() return end

	local pos, ang = owner:GetBonePosition( bone )
	pos = pos + ang:Right() * self.Offset.Pos.Right + ang:Forward() * self.Offset.Pos.Forward + ang:Up() * self.Offset.Pos.Up

	ang:RotateAroundAxis( ang:Right(), self.Offset.Ang.Right )
	ang:RotateAroundAxis( ang:Forward(), self.Offset.Ang.Forward )
	ang:RotateAroundAxis( ang:Up(), self.Offset.Ang.Up )

	self:SetRenderOrigin( pos )
	self:SetRenderAngles( ang )
	self:DrawModel()
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_IDLE )
	self.Next = CurTime()
	self.Primed = 0
	self:GetOwner().Tacs = self:GetOwner().Tacs or {}
end

function SWEP:Initialize()
	self:SetHoldType( "fist" )
end

function SWEP:Holster()
	self.Next = CurTime()
	self.Primed = 0
	return true
end

function SWEP:PrimaryAttack()
	if self:GetNWBool( "clickclick" ) == true and self.Primed == 2 then return end
	self:SetNWBool( "clickclick", true )

	if self.Next >= CurTime() then return end
	if self.Primed ~= 0 then return end

	local owner = self:GetOwner()
	self.Next = CurTime() + self.Primary.Delay

	if not IsValid( owner ) then return end
	if owner:Health() <= 0 then return end

	timer.Simple( 0.35, function() if self:IsValid() then self:EmitSound( clipSound ) end end )
	timer.Simple( 0.7, function() if self:IsValid() then self:EmitSound( beepSound ) end end )
	timer.Simple( 0.95, function() if self:IsValid() then self:EmitSound( beepSound ) end end )
	timer.Simple( 1.2, function() if self:IsValid() then self:EmitSound( flick1Sound ) end end )
	timer.Simple( 1.3, function() if self:IsValid() then self:EmitSound( flick2Sound ) end end )

	self:SendWeaponAnim( ACT_VM_PULLPIN )
	self.Primed = 1
end

function SWEP:DeployShield()
	self.Primed = 3
	if CLIENT then return end
	local owner = self:GetOwner()

	timer.Simple( 0.4, function()
		if owner:Health() > 0 and IsValid( owner ) then
			for k, v in pairs( owner.Tacs ) do
				timer.Simple( 0.01 * k, function()
					if IsValid( self and v ) then
						v:Remove()
						table.remove( owner.Tacs, k )
					end
				end )
			end
		end

		local ent = ents.Create( "cod-tac-insert" )
		ent:SetPos( owner:GetPos() )

		local trace = util.TraceLine( {
			start = owner:GetPos(),
			endpos = owner:GetPos() + Vector( 0, 0, -75 ),
			filter = function( filterEnt )
				if not IsValid( filterEnt ) then return false end
				if filterEnt:GetClass() == "player" or filterEnt:GetClass() == "seal6-tac-insert" then return false end

				return true
			end
		} )

		if trace.Hit then
			ent:SetPos( trace.HitPos )
		end

		ent:Spawn()
		ent:SetOwner( owner )
		ent:SetNWString( "TacOwner", owner:Nick() )
		ent:SetNWString( "TacOwnerID", owner:SteamID() )
		ent:SetAngles( Angle( owner:GetAngles().x, owner:GetAngles().y, owner:GetAngles().z ) + Angle( 0, -90, 0 ) )
		table.insert( owner.Tacs, ent )

		undo.Create( "Tactical Insertion" )
		undo.AddEntity( ent )
		undo.SetPlayer( owner )
		undo.AddFunction( function( undoList )
			local undoEnt = undoList.Entities[1]

			-- Check if the entity is still valid
			if IsValid( undoEnt ) then
				-- Remove the entity from the owner's Tac table
				table.RemoveByValue( owner.Tacs, undoEnt )
			else
				-- The Tac doesn't exist anymore (probably exploded)
				return false
			end
		end )
		undo.Finish()

		owner:AddCount( "sents", ent ) -- Add to the SENTs count ( ownership )
		owner:AddCount( "my_props", ent ) -- Add count to our personal count
		owner:AddCleanup( "sents", ent ) -- Add item to the sents cleanup
		owner:AddCleanup( "my_props", ent ) -- Add item to the cleanup

		if CPPI then
			ent:CPPISetOwner( owner )
		end
	end )

	hook.Add( "PlayerSpawn", "TacInsert_Spawner_" .. owner:SteamID(), function( ply )
		if ply.Tacs == nil then ply.Tacs = {} end
		for k, v in pairs( ply.Tacs ) do
			timer.Simple( 0, function()
				if not IsValid( v ) then return end
				ply:SetPos( v:GetPos() )
				ply:SetAngles( v:GetAngles() )

				v.RespawnCounter = v.RespawnCounter + 1
				local respawnLimit = respawnLimitCvar:GetInt()

				if respawnLimit <= 0 then return end
				if v.RespawnCounter < respawnLimit then return end
				if not IsValid( ply ) then return end
				if ply:Health() <= 0 then return end

				if not IsValid( v ) then return end
				local effect = EffectData()
				effect:SetStart( v:GetPos() )
				effect:SetOrigin( v:GetPos() )
				util.Effect( "cball_explode", effect, true, true )
				sound.Play( zapSound, v:GetPos(), 100, 100 )
				hook.Remove( "PlayerSpawn", "TacInsert_Spawner_" .. self:GetNWString( "TacOwnerID" ) )
				v:Remove()
				table.remove( ply.Tacs, k )
			end )
		end
	end )

	timer.Simple( 0.5, function()
		if not SERVER then return end
		if not IsValid( self ) then return end
		self:SetNWBool( "clickclick", false )
		owner:StripWeapon( "seal6-tac-insert" )
	end )
end

function SWEP:SetNext()
	if self.Next < CurTime() + 0.5 then return end
	self.Next = CurTime()
end

function SWEP:Think()
	if self.Next >= CurTime() then return end
	if self.Primed == 1 and not self:GetOwner():KeyDown( IN_ATTACK ) then
		self.Primed = 2
		self:SetNext()
	elseif self.Primed == 2 and CurTime() > self.Next + 1.3 then
		self.Primed = 0
		self:DeployShield()
		self:SendWeaponAnim( ACT_VM_THROW )
		self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
	end
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire( CurTime() + 1.1 )
	self:SetNextSecondaryFire( CurTime() + 1.2 )
end

function SWEP:ShouldDropOnDie()
	return false
end