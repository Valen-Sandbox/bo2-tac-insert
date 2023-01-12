AddCSLuaFile( "shared.lua" )

SWEP.Author			= "Hoff"
SWEP.Category 		= "Other"
SWEP.Spawnable		= true
SWEP.AdminSpawnable	= true

SWEP.ViewModel		= "models/hoff/weapons/tac_insert/v_insert_seal6.mdl"
SWEP.WorldModel		= "models/hoff/weapons/tac_insert/w_tac_insert.mdl"
SWEP.ViewModelFOV 	= 65

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

SWEP.Next = CurTime()
SWEP.Primed = 0

SWEP.Offset = {
	Pos = {
		Up = 0.2,
		Right = 2,
		Forward = 2,
	},
	Ang = {
		Up = 240,
		Right = 0,
		Forward = 0,
	}
}

function SWEP:DrawWorldModel()
	local hand, offset
	local owner = self:GetOwner()
	if not owner:IsValid() then self:DrawModel() return end

	if not self.Hand then
		self.Hand = owner:LookupAttachment( "anim_attachment_rh" )
	end

	hand = owner:GetAttachment( self.Hand )

	if not hand then self:DrawModel() return end

	offset = hand.Ang:Right() * self.Offset.Pos.Right + hand.Ang:Forward() * self.Offset.Pos.Forward + hand.Ang:Up() * self.Offset.Pos.Up

	hand.Ang:RotateAroundAxis( hand.Ang:Right(), self.Offset.Ang.Right )
	hand.Ang:RotateAroundAxis( hand.Ang:Forward(), self.Offset.Ang.Forward )
	hand.Ang:RotateAroundAxis( hand.Ang:Up(), self.Offset.Ang.Up )

	self:SetRenderOrigin( hand.Pos + offset )
	self:SetRenderAngles( hand.Ang )
	self:DrawModel()
end

function SWEP:Deploy()
	self.Next = CurTime()
	self.Primed = 0
	self:GetOwner().Tacs = self:GetOwner().Tacs or {}
end

function SWEP:Initialize()
	self:SetWeaponHoldType( "fist" )
end

function SWEP:Holster()
	self.Next = CurTime()
	self.Primed = 0
	return true
end

function SWEP:PrimaryAttack()
	if self:GetNWString( "clickclick" ) == "true" then return end
	self:SetNWString( "clickclick", "true" )
	local owner = self:GetOwner()

	if self.Next < CurTime() and self.Primed == 0 then
		self.Next = CurTime() + self.Primary.Delay

		if not owner:IsValid() then return end
		if owner:Health() <= 0 then return end

		timer.Simple( 0.6, function() if self:IsValid() then self:EmitSound( "hoff/mpl/seal_tac_insert/clip.wav" ) end end )
		timer.Simple( 1.1, function() if self:IsValid() then self:EmitSound( "hoff/mpl/seal_tac_insert/beep.wav" ) end end )
		timer.Simple( 1.4, function() if self:IsValid() then self:EmitSound( "hoff/mpl/seal_tac_insert/beep.wav" ) end end )
		timer.Simple( 1.7, function() if self:IsValid() then self:EmitSound( "hoff/mpl/seal_tac_insert/flick_1.wav" ) end end )
		timer.Simple( 1.8, function() if self:IsValid() then self:EmitSound( "hoff/mpl/seal_tac_insert/flick_2.wav" ) end end )

		self:SendWeaponAnim( ACT_VM_PULLPIN )
		self.Primed = 1
	end
end

function SWEP:DeployShield()
	if CLIENT then return end
	local owner = self:GetOwner()

	timer.Simple( 0.4, function()
		if owner:Health() > 0 and owner:IsValid() then
			-- thanks chief tiger
			for k, v in pairs( owner.Tacs ) do
				timer.Simple( 0.1 * k, function()
					if v:IsValid() then
						v:Remove()
					end
					table.remove( owner.Tacs, k )
				end )
			end
		end

		local ent = ents.Create( "cod-tac-insert" )
		ent:SetPos( owner:GetPos() )
		ent:Spawn()
		ent.Owner = owner
		ent:SetNWString( "TacOwner", owner:Nick() )
		ent:SetAngles( Angle( owner:GetAngles().x, owner:GetAngles().y, owner:GetAngles().z ) + Angle( 0, -90, 0 ) )
		table.insert( owner.Tacs, ent )

		if CPPI then
			ent:CPPISetOwner( owner )
		end
	end )

	hook.Add( "PlayerSpawn", "TacSpawner", function( ply )
		if ply.Tacs == nil then ply.Tacs = {} end
		for _, v in pairs( ply.Tacs ) do
			timer.Simple( 0, function()
				if not v:IsValid() then return end
				ply:SetPos( v:GetPos() )
				ply:SetAngles( v:GetAngles() )
			end )
		end
	end )

	timer.Simple( 1, function() if IsValid( self ) then self:Remove() end end )
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
	elseif self.Primed == 2 and CurTime() > self.Next + 2 then
		self.Primed = 0
		self:DeployShield()
		self:SendWeaponAnim( ACT_VM_THROW )
	end
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire( CurTime() + 1.1 )
	self:SetNextSecondaryFire( CurTime() + 1.2 )
end