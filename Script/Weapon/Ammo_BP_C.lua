--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local Ammo_BP_C = Class()

--function Ammo_BP_C:Initialize(Initializer)
--end

function Ammo_BP_C:DestroyAmmo() --弹夹销毁
    local co = coroutine.create(Ammo_BP_C.DestroyAmmo_Co)
    coroutine.resume(co, self, self.BodyDuration)
end

function Ammo_BP_C:DestroyAmmo_Co() 
    UE.UKismetSystemLibrary.Delay(self,3)
    self:K2_DestroyActor()
end
--function Ammo_BP_C:UserConstructionScript()
--end

--function Ammo_BP_C:ReceiveBeginPlay()
--end

--function Ammo_BP_C:ReceiveEndPlay()
--end

-- function Ammo_BP_C:ReceiveTick(DeltaSeconds)
-- end

--function Ammo_BP_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function Ammo_BP_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function Ammo_BP_C:ReceiveActorEndOverlap(OtherActor)
--end

return Ammo_BP_C
