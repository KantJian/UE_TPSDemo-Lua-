--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"


local SinglePlayer_BP_C = Class()




function SinglePlayer_BP_C:ReceiveBeginPlay()
    self:MainUI()
end

function SinglePlayer_BP_C:MainUI1() --玩家持枪/子弹数量/血量 UI
    local Widget = UE4.UWidgetBlueprintLibrary.Create(self, UE4.UClass.Load("/Game/UI/PlayerMain_UI"))
    Widget:AddToViewport()
    self.CurrentHealth=self.MaxHealth
end

function SinglePlayer_BP_C:MoveForward(AxisValue)  --前后
    if self then
        local Rotation = self:GetControlRotation(self.ControRot)
        Rotation:Set(0,Rotation.Yaw,0)
        local Direction = Rotation:ToVector(self.ForwardVec)
        self:AddMovementInput(Direction,AxisValue)
        -- print("WWWWWWSSSSSSS")
    end
end

function SinglePlayer_BP_C:MoveRight(AxisValue)   --左右
	if self then
		local Rotation = self:GetControlRotation(self.ControlRot)
		Rotation:Set(0, Rotation.Yaw, 0)
		local Direction = Rotation:GetRightVector(self.RightVec)
		self:AddMovementInput(Direction, AxisValue)
        -- print("AAAAAAAAADDDDDDD")
	end
end

function SinglePlayer_BP_C:Turn(AxisValua)    --视角左右移动
    local PlayerCharacter = UE4.UGameplayStatics.GetPlayerController(self, 0)
    PlayerCharacter:AddYawInput(AxisValua)
    -- print("左左右右")
end     

function SinglePlayer_BP_C:LookUP(AxisValue)  --视角上下移动
    local PlayerCharacter = UE4.UGameplayStatics.GetPlayerController(self, 0)
	PlayerCharacter:AddPitchInput(AxisValue)
    -- print("上上下下")
end

function SinglePlayer_BP_C:Jump_Pressed() --跳跃
    self:Jump()
end

function SinglePlayer_BP_C:Jump_Released()  --停止跳跃
    self:StopJumping()
end

function SinglePlayer_BP_C:MoveMode(a,b) --玩家的行动模式（使用控制器旋转Yaw和将旋转朝向运动两种行动模式）
    self.bUseControllerRotationYaw=a
    self.CharacterMovement.bOrientRotationToMovement=b
end

function SinglePlayer_BP_C:HoldWeapon() --把当前持有武器挂载到背部插槽蒙太奇播放通知时执行的更换插槽事件
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    self.CurrentWeapon:K2_AttachToComponent(self.Mesh,WeaponInfo.WeaponHoldSocket, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget)   
    self:HoldWeaponSound_RPC()
end
function SinglePlayer_BP_C:HoldWeaponSound()
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    UE4.UGameplayStatics.PlaySound2D(self,WeaponInfo.HoldSound) --, float VolumeMultiplier, float PitchMultiplier, float StartTime, USoundConcurrency* ConcurrencySettings, AActor* OwningActor, bool bIsUISound
end

function SinglePlayer_BP_C:EquipWeapon() --把当前挂载武器装备到手部插槽蒙太奇播放通知时执行的更换插槽事件
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    self.CurrentWeapon:K2_AttachToComponent(self.Mesh,WeaponInfo.WeaponEquipSocket, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget)
    self:EquipWeaponSound_RPC()
end

function SinglePlayer_BP_C:EquipWeaponSound()
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    UE.UGameplayStatics.PlaySound2D(self,WeaponInfo.EquipSound) --, float VolumeMultiplier, float PitchMultiplier, float StartTime, USoundConcurrency* ConcurrencySettings, AActor* OwningActor, bool bIsUISound
end
function SinglePlayer_BP_C:EquipOrUnEquip_Pressed() --按E键装备或挂载枪支
    
    self.CurrentWeapon:IsValid()
        if self.WeaponInHand==true then
            self:PutAwayTheGuns_RPC()
       else
            self:DrawAGun_RPC()
        end
end

function SinglePlayer_BP_C:PutAwayTheGuns()  --挂载武器
    self.WeaponInHand=false
    self:PutAwayMotage_RPC()
    self.HoldTime=1.73
    self:MoveMode(false,true)
end
function SinglePlayer_BP_C:PutAwayMotage()
    local AnimMontage =LoadObject("/Game/AnimStarterPack/UnEquip")
    self:PlayAnimMontage(AnimMontage,2.0,nil);
end

function SinglePlayer_BP_C:DrawAGun()  --装备武器
    self.WeaponInHand=true
    self:DrawMotage_RPC()
    self:MoveMode(false,true)
end
function SinglePlayer_BP_C:DrawMotage()
    local AnimMontage =LoadObject("/Game/AnimStarterPack/Equip")
    self:PlayAnimMontage(AnimMontage,2.0,nil);
end

function SinglePlayer_BP_C:GetAmmo()  --从背后生成弹夹添加到hand_r插槽，武器换弹动画结束后再销毁插槽上的弹夹
    local co = coroutine.create(SinglePlayer_BP_C.GetAmmoCoroutine)
    coroutine.resume(co, self, self.BodyDuration)
end

function SinglePlayer_BP_C:GetAmmoCoroutine() --GetAmmo()中生成弹夹 创建协同
    local WeaponInfo=self.CurrentWeapon.Weapon_Info
    local SpawnClass = WeaponInfo.AmmoType --根据对应的枪生成对应的弹夹类
    local SpawnTransform = self.Mesh:GetSocketTransform("hand_l",UE4.ERelativeTransformSpace.RTS_World)
    local Undefined = UE.ESpawnActorCollisionHandlingMethod.Undefined
    local World = self:GetWorld()
    local SpawnReturn= World:SpawnActor(SpawnClass,SpawnTransform,Undefined,self,self)
    SpawnReturn.RootComponent:K2_AttachToComponent(self.Mesh,"hand_l",UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget,true)
    UE.UKismetSystemLibrary.Delay(self, 0.5)
    SpawnReturn:K2_DestroyActor()
end

function SinglePlayer_BP_C:UnloadAmmo() --拔掉弹夹并掉在地面
    local co = coroutine.create(SinglePlayer_BP_C.UnloadAmmoCoroutine)
    coroutine.resume(co, self, self.BodyDuration)
end

function SinglePlayer_BP_C:UnloadAmmoCoroutine() --拔掉弹夹 协同
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    self.CurrentWeapon.SkeletalMesh:HideBoneByName("b_gun_mag",UE4.EPhysBodyOp.PBO_None)
    local SpawnClass=WeaponInfo.AmmoType --根据对应的枪生成对应的弹夹类
    local SpawnTransform = self.Mesh:GetSocketTransform("hand_l",UE4.ERelativeTransformSpace.RTS_World)
    local Undefined = UE.ESpawnActorCollisionHandlingMethod.Undefined
    local World = self:GetWorld()
    local SpawnReturn=World:SpawnActor(SpawnClass,SpawnTransform,Undefined,self,self)
   
    self.EmptyAmmo=SpawnReturn
    UE.UKismetSystemLibrary.Delay(self, 0.1)
    self.EmptyAmmo.StaticMesh:SetSimulatePhysics(true)
    local Rotations=UE4.UKismetMathLibrary.BreakTransform(SpawnTransform,Location,Rotation,Scale)
    local GetUpVector=UE.UKismetMathLibrary.GetUpVector(Rotations.Rotation)
    local GettDownVector=UE.UKismetMathLibrary.NegateVector(GetUpVector)
    local Impulse= GettDownVector* 100
    self.EmptyAmmo.StaticMesh:AddImpulse(Impulse,nil,false)
    self:HideEmpty()
end

-- function SinglePlayer_BP_C:PickUpWeapon(Weapon) --捡起武器
--     self.Weapon=Weapon
--     print("开始执行协同程序")
--     self.Weapon.SkeletalMesh:SetSimulatePhysics(false)
--     print("捡起枪支时把枪支设为模拟物理")
--     Weapons=self.Weapon.Weapon_info
--     if self.WeaponInHand==true then
--     print("手中有枪")
--     local co = coroutine.create(SinglePlayer_BP_C.Coroutine1)
--     coroutine.resume(co, self, self.BodyDuration)
--     local ValueIsValid=UE.UKismetInputLibrary.Key_IsValid(Value1)
--         if ValueIsValid==true then
--             print("此插槽已被武器占用了，不能拾取了")
--         end
--         if ValueIsValid==false then
--             self:Pick_RPC()
--             UE.UBlueprintMapLibrary.Map_Add(self.WeaponsSocketState,self.Weapon.Weapon_info.WeaponHoldSocket,self.Weapon)
--             UE4.UGameplayStatics.PlaySound2D(self,Weapons.HoldSound)
--             self.Weapon:CloseComponent()
--         end
--     end
--     if self.WeaponInHand==false then
--         print("手中没枪")
--         local co = coroutine.create(SinglePlayer_BP_C.FindMapCoroutine)
--         coroutine.resume(co, self, self.BodyDuration)
--         print("执行FindMap协同程序")
--         local ValueIsValid=UE.UKismetInputLibrary.Key_IsValid(Value)
--         print(ValueIsValid)
--         if ValueIsValid==true then
--             print("这个插槽被占用了")
--         end
--         if ValueIsValid==false then
--             self.CurrentWeapon=self.Weapon
--             self:Pick2_RPC()
--             UE.UBlueprintMapLibrary.Map_Add(self.WeaponsSocketState,self.CurrentWeapon.Weapon_info.WeaponEquipSocket,self.CurrentWeapon)
--             UE4.UGameplayStatics.PlaySound2D(self,self.CurrentWeapon.Weapon_info.EquipSound,1.0,1.0,0,nil,nil,true)
--             self.WeaponInHand=true
--             self:MoveMode(true,false)
--             self.Weapon:CloseComponent()
--         end
--     end
-- end

--  function SinglePlayer_BP_C:FindMapCoroutine()
--     Value=UE.UBlueprintMapLibrary.Map_Find(self.WeaponsSocketState,Weapons.WeaponHoldSocket)
--  end

--  function SinglePlayer_BP_C:Pick2()
--     local co = coroutine.create(SinglePlayer_BP_C.PickAttachCoroutine)
--     coroutine.resume(co, self, self.BodyDuration)
-- end

--  function SinglePlayer_BP_C:PickAttachCoroutine()
--     self.CurrentWeapon:K2_AttachToComponent(self.Mesh,self.CurrentWeapon.Weapon_info.WeaponEquipSocket,UE4.EAttachmentRule.SnapToTarget,UE4.EAttachmentRule.SnapToTarget,UE4.EAttachmentRule.SnapToTarget,true)
-- end

--  function SinglePlayer_BP_C:Coroutine1()
--     print("我是1111")
--     Value1=UE.UBlueprintMapLibrary.Map_Find(self.WeaponsSocketState,self.Weapon.Weapon_info.WeaponHoldSocket)
--  end

--  function SinglePlayer_BP_C:Pick()
--         local co = coroutine.create(SinglePlayer_BP_C.Coroutine2)
--         coroutine.resume(co, self, self.BodyDuration)
--  end
--  function SinglePlayer_BP_C:Coroutine2()
--     self.Weapon:K2_AttachToComponent(self.Mesh,Weapons.WeaponHoldSocket,UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget,true)
--  end

-- function SinglePlayer_BP_C:SwitchWeapon_Pressed()
--     self:SwitchWeapon_RPC()
-- end
-- function SinglePlayer_BP_C:SwitchWeapon()
--     if self.WeaponInHand==true then
--         print("按切枪时手里有枪")
--         local MapLength=UE.UBlueprintMapLibrary.Map_Length(self.WeaponsSocketState)
--         print(MapLength)
--         if MapLength>1 then
--             local AllValuesArray=UE.UBlueprintMapLibrary.Map_Values(self.WeaponsSocketState)
--             self.WeaponsArrayCache=AllValuesArray
--             local Index=UE.UBlueprintMapLibrary.Map_Find(self.WeaponsArrayCache,self.CurrentWeapon)
--             self.CurrentWeaponNextIndex=Index+1
--             local IsValidIndex=UE.UKismetArrayLibrary.Array_IsValidIndex(self.WeaponsArrayCache,self.CurrentWeaponNextIndex)
--             if IsValidIndex==true then
--                 self:PutAwayTheGuns_RPC()
--                 UE.UKismetSystemLibrary.Delay(self, self.HoldTime/2)
--                 local Copy=UE.UKismetArrayLibrary.Array_Get(self.WeaponsArrayCache,self.CurrentWeaponNextIndex)
--                 self.CurrentWeapon=Copy
--                 self:DrawAGun_RPC()
--             end
--             if IsValidIndex==false then
--                 self:PutAwayTheGuns_RPC()
--                 UE.UKismetSystemLibrary.Delay(self, self.HoldTime/2)
--                 local Copy=UE.UKismetArrayLibrary.Array_Get(self.WeaponsArrayCache,0)
--                 self.CurrentWeapon=Copy
--                 self:DrawAGun_RPC()
--             end
--         end
--     end
-- end

function SinglePlayer_BP_C:ReLoadAmmo_Pressed() --对于能否换弹的判断并实施换弹动作
    self:ReLoadedAmmo_RPC()
end

function SinglePlayer_BP_C:Reload()
    if self.WeaponInHand==true then
        local ValueIsValid=UE.UKismetInputLibrary.Key_IsValid(self.CurrentWeapon)
        if ValueIsValid==true then
            if self.CurrentWeapon.Weapon_info.MaxAmmo==0 then
                print("身上没有弹药了")
                local PlaySound2D=LoadObject("/Game/Resources/A_Grapple")
                UE4.UGameplayStatics.PlaySound2D(self,PlaySound2D)
            end
        else
            if self.CurrentWeapon.Weapon_info.ClipCapacity==self.CurrentWeapon.Weapon_info.CurrentAmmunition then
                print("弹夹已满，无需换弹")
            end
            if self.CurrentWeapon.Weapon_info.ClipCapacity~=self.CurrentWeapon.Weapon_info.CurrentAmmunition then
               self:ReloadMontage_RPC()
            end
        end
    end
end
function  SinglePlayer_BP_C:ReloadMontage()
    local AnimMontage =self.CurrentWeapon.Weapon_info.ReLoadAmmo
    self:PlayAnimMontage(AnimMontage,1.0,nil);
end

function SinglePlayer_BP_C:ReLoadedAmmoChange() --换弹数量计算
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    if self.WeaponInHand==true then
            self:HideAmmo_RPC()
            if WeaponInfo.MaxAmmo>0 then
              self:NeedAmmo1_RPC()
            end
    end
end
function SinglePlayer_BP_C:HideAmmo()
    self.CurrentWeapon.SkeletalMesh:UnHideBoneByName("b_gun_mag")
end
function SinglePlayer_BP_C:NeedAmmo1()
    local WeaponInfo=self.CurrentWeapon.Weapon_info
    self.NeedAmmo=WeaponInfo.ClipCapacity-WeaponInfo.CurrentAmmunition
    if WeaponInfo.MaxAmmo<=self.NeedAmmo then
        WeaponInfo.CurrentAmmunition=WeaponInfo.CurrentAmmunition+WeaponInfo.MaxAmmo
        WeaponInfo.MaxAmmo=0
        else
            WeaponInfo.CurrentAmmunition=WeaponInfo.ClipCapacity
            WeaponInfo.MaxAmmo=WeaponInfo.MaxAmmo-self.NeedAmmo
    end
end
return SinglePlayer_BP_C
