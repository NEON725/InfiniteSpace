if SERVER
then
	function ENT:GetEnvironment() return GetEnvironmentAtVector(self:GetPos()) end
	function ENT:GetAtmosphere() return self:GetEnvironment():GetAtmosphere(self:GetPhase()) end
end
function ENT:GetPhase() return (not self:IsInWorld() and "solid") or (self:WaterLevel()>=3 and "liquid") or "gas" end

function ENT:AssignPendingNWVar(var,val,type)
        if(not type) then type="Float" end
        self.PendingNWVars=self.PendingNWVars or {}
        self.PendingNWVars[var]={val=val,type=type}
end
function ENT:SynchronizeNWVars()
        for i,v in pairs(self.PendingNWVars or {}) do self["SetNW"..v.type](self,i,v.val) end
        self.PendingNWVars={}
end
function ENT:GetActualOrPendingNWVar(var,type)
        if(not type) then type="Float" end
        local pending=(self.PendingNWVars or {})[var]
        if pending then return pending.val end
        return self["GetNW"..type](self,var)
end
function ENT:GetResource(res) return self:GetActualOrPendingNWVar("resource_current_"..res) or 0 end
function ENT:GetMaxResource(res) return self:GetActualOrPendingNWVar("resource_maximum_"..res) or 0 end
function ENT:SetResource(res,amt) return self:AssignPendingNWVar("resource_current_"..res,amt) end
function ENT:SetMaxResource(res,amt) return self:AssignPendingNWVar("resource_maximum_"..res,amt) end
function ENT:GetStorageTable()
        local retval={}
        for name,_ in pairs(IS_RESOURCES)
        do
                local current,maximum=self:GetResource(name),self:GetMaxResource(name)
                if(current>0 or maximum>0) then retval[name]={current=current,maximum=maximum} end
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
