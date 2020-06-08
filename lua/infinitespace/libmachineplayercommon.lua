local SPACEMACHINE_NW_UPDATE="SPACEMACHINE_NW_UPDATE"
if SERVER
then
	function ENT:GetEnvironment() return GetEnvironmentAtVector(self:GetPos()) end
	function ENT:GetAtmosphere() return self:GetEnvironment():GetAtmosphere(self:GetPhase()) end
	function ENT:GetTemperateRating() return self:GetEnvironment():GetTemperateRating(self) end
	util.AddNetworkString(SPACEMACHINE_NW_UPDATE)
end
function ENT:GetPhase() return (not self:IsInWorld() and "solid") or (self:WaterLevel()>=3 and "liquid") or "gas" end

function ENT:AssignPendingNWVar(var,val,type)
	if(not type) then type="Float" end
	self.PendingNWVars=self.PendingNWVars or {}
	self.PendingNWVars[var]={val=val,type=type}
end
function ENT:SynchronizeNWVars()
	for i,v in pairs(self.PendingNWVars or {})
	do
		local type=v.type
		if(type=="Table")
		then
			self.NWTables=self.NWTables or {}
			self.NWTables[i]=v.val
			net.Start(SPACEMACHINE_NW_UPDATE)
			net.WriteEntity(self)
			net.WriteString(i)
			net.WriteTable(v.val)
			if(SERVER) then net.Broadcast()
			else net.SendToServer() end
		else self["SetNW"..type](self,i,v.val) end
	end
	self.PendingNWVars={}
end
net.Receive(SPACEMACHINE_NW_UPDATE,function()
	local ent=net.ReadEntity()
	local name=net.ReadString()
	local tab=net.ReadTable()
	ent.NWTables=ent.NWTables or {}
	ent.NWTables[name]=tab
end)
function ENT:GetActualOrPendingNWVar(var,type)
	if(not type) then type="Float" end
	local pending=(self.PendingNWVars or {})[var]
	if pending then return pending.val end
	if(type=="Table") then return (self.NWTables or {})[var]
	else return self["GetNW"..type](self,var) end
end
function ENT:GetResource(res) return self:GetActualOrPendingNWVar("resource_current_"..res) or 0 end
function ENT:GetMaxResource(res) return self:GetActualOrPendingNWVar("resource_maximum_"..res) or 0 end
function ENT:SetResource(res,amt) return self:AssignPendingNWVar("resource_current_"..res,amt) end
function ENT:SetMaxResource(res,amt) return self:AssignPendingNWVar("resource_maximum_"..res,amt) end
function ENT:GetAcceptingResource(res) return self:GetMaxResource(res)-self:GetResource(res) end
function ENT:GetStorageTable()
	local retval={}
	for name,_ in pairs(IS_RESOURCES)
	do
		local current,maximum=self:GetResource(name),self:GetMaxResource(name)
		if(current>0 or maximum>0) then retval[name]={current=current,maximum=maximum,accepting=self:GetAcceptingResource(name)} end
	end
	return retval
end

function ENT:OfferResource(res,amt)
	local maxamt=amt
	for selfres,selfrestab in pairs(self:GetStorageTable())
	do
		local accepting=selfrestab.maximum-selfrestab.current
		local equivalencyMultiplier=(selfres==res and 1) or GetResourceData(selfres).equivalents[res] or 0
		if(equivalencyMultiplier>0 and accepting>0)
		then
			local effectiveAccepting=accepting/equivalencyMultiplier
			local taken=math.min(effectiveAccepting,amt)
			amt=amt-taken
			selfrestab.current=selfrestab.current+taken*equivalencyMultiplier
			self:SetResource(selfres,selfrestab.current)
		end
	end
	return maxamt-amt
end
function ENT:RequestResource(res,amt)
	local resTab=GetResourceData(res)
	local maxamt=amt
	local multipliers=table.Copy(resTab.equivalents)
	multipliers[res]=1
	for equiv,mul in pairs(multipliers)
	do
		local current=self:GetResource(equiv)
		if(current==0) then continue
		elseif(current*mul>=amt)
		then
			current=current-amt/mul
			self:SetResource(equiv,current)
			amt=0
			break
		else
			amt=amt-current*mul
			self:SetResource(equiv,0)
		end
	end
	return maxamt-amt
end
