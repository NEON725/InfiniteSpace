ENT.PrintName="Resource Pump"

ENT.Models={"models/props_lab/tpplugholder_single.mdl"}
local socketMount=Vector(5,13,10)
local plugMount=Vector(12,0,0)

function ENT:SpawnPlug()
	self:DestroyPlug()
	self.plug=ents.Create("prop_physics")
	if(!IsValid(self.plug)) then return end
	self.plug:SetModel("models/props_lab/tpplug.mdl")
	self.plug:SetPos(self:GetPos()+self:GetForward()*5)
	self.plug:Spawn()
	self.plug.socket=self
	self.elastic=constraint.Elastic(self,self.plug,0,0,socketMount,plugMount,1000,0,0,"cable/cable2",2,true)
	self:DeleteOnRemove(self.plug)
end
function ENT:DestroyPlug()
	if(IsValid(self.plug)) then self.plug:Remove() end
	self.plug=nil
	self.elastic=nil
	self.retracting=false
end
function ENT:EjectPlug()
	for _,e in pairs({self.socketed,self.plug})
	do
		if(IsValid(e))
		then
			e:GetPhysicsObject():EnableMotion(true)
			e:SetCollisionGroup(COLLISION_GROUP_NONE)
			if(IsValid(e.socketed))
			then
				e.socketed.socketed=nil
				e:GetPhysicsObject():ApplyForceCenter(e.socketed:GetForward()*10)
			end
			e.socketed=nil
		end
	end
end

function ENT:Use(ply,caller)
	if(IsValid(self.socketed)) then self:EjectPlug()
	elseif(IsValid(self.plug)) then self.retracting=true
	else self:SpawnPlug() end
end

function ENT:Think()
	self.BaseClass.Think(self)
	if(SERVER)
	then
		if(IsValid(self.plug))
		then
			local dist=self.plug:LocalToWorld(plugMount):Distance(self:LocalToWorld(socketMount)) 
			if(self.retracting)
			then
				dist=dist-10
				if(dist<=10) then self:DestroyPlug()
				else self.plug:GetPhysicsObject():EnableMotion(true) end
			elseif(self.plug:IsPlayerHolding())
			then
				dist=dist+100
			end
			if(IsValid(self.plug))
			then
				self.elastic:Fire("SetLength",dist,0)
				self.elastic:Fire("SetSpringLength",dist,0)
			end
		elseif(IsValid(self.socketed))
		then
			if(self.socketed:GetPhysicsObject():IsMotionEnabled()) then self:EjectPlug()
			else
				self.socketed:SetPos(self:LocalToWorld(socketMount))
				self.socketed:SetAngles(self:LocalToWorldAngles(Angle(0,0,0)))
			end
		end
	end
end

function ENT:PhysicsCollide(coldata,collider)
	local ent=coldata.HitEntity
	if(not self.plug and not self.socketed and ent!=self.plug and IsValid(ent.socket) and ent.socket.plug==ent and not ent.socket.retracting)
	then
		self.socketed=ent
		ent.socketed=self
		ent:GetPhysicsObject():EnableMotion(false)
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
	elseif(self.plug==ent and self.retracting)
	then
		self:DestroyPlug()
	end
end

function GenerateRemoteSocketFunction(remoteFunctionName,allowFlagName)
	return function(self,...)
		if(not self.infiniteLoop and (not allowFlagName or self[allowFlagName]))
		then
			local remoteSocket=nil
			if(IsValid(self.plug) and IsValid(self.plug.socketed)) then remoteSocket=self.plug.socketed
			elseif(IsValid(self.socketed)) then remoteSocket=self.socketed.socket end
			if(remoteSocket)
			then
				self.infiniteLoop=true
				local retval=remoteSocket[remoteFunctionName](remoteSocket,...)
				self.infiniteLoop=false
				return retval
			end
		end
		return 0
	end
end

ENT.RequestResource=GenerateRemoteSocketFunction("RequestResourceFromNetwork")
ENT.OfferResource=GenerateRemoteSocketFunction("OfferResourceToNetwork")
