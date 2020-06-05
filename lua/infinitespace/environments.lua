VISOR_UPDATE="IS_VISOR_UPDATE"
IS_postInitEntity=IS_postInitEntity or false

Environment=Environment or {}
Environment.__index=Environment
EnvironmentShape=EnvironmentShape or {}
EnvironmentShape.__index=EnvironmentShape
function EnvironmentShape:new(type,x,y,z)
	local retval={type=type,position=position,angle=angle}
	if(type=="sphere") then retval.radius=x
	elseif(type=="cube")
	then
		retval.x=x
		retval.y=y
		retval.z=z
	end
	setmetatable(retval,EnvironmentShape)
	return retval
end
setmetatable(EnvironmentShape,{__call=EnvironmentShape.new})
function EnvironmentShape:GetVolume()
	if(self.type=="sphere") then return (4/3)*math.pi*self.radius*self.radius*self.radius
	elseif(self.type=="cube") then return self.x*self.y*self.z
	else return 0 end
end
function EnvironmentShape:ContainsVector(envPos,envAng,v)
	local diff=WorldToLocal(v,Angle(0,0,0),envPos,envAng)
	if(self.type=="sphere") then return diff:LengthSqr()<=self.radius*self.radius
	elseif(self.type=="cube") then return math.abs(diff.x)<=self.x/2 and math.abs(diff.y)<=self.y/2 and math.abs(diff.z)<=self.z/2
	else return false end
end

function Environment:new(configurator)
	local retval=
	{
		name="Unnamed Planet",
		position=Vector(0,0,0),
		rotation=Angle(0,0,0),
		radius=0,
		shape=EnvironmentShape("sphere",0),
		atmosphere=
		{
			gas={},
			liquid={},
			solid={}
		}
	}
	function applyConfigurator(host,configurator)
		for i,v in pairs(configurator)
		do
			if(type(host[i])=="table" and type(v)=="table") then applyConfigurator(host[i],v)
			else host[i]=v end
		end
	end
	applyConfigurator(retval,configurator or {})
	setmetatable(retval,Environment)
	return retval
end
setmetatable(Environment,{__call=Environment.new})

function Environment:GetVolume() return self.shape:GetVolume() end
function Environment:ContainsVector(v) return self.shape:ContainsVector(self.position,self.rotation,v) end
function Environment:GetPressure(phase)
	local atmosphere=self.atmosphere[phase or "gas"]
	local total=0
	for _,n in pairs(atmosphere) do total=total+n end
	return total/self:GetVolume()
end
function Environment:GetAtmosphere(phase) return self.atmosphere[phase or "gas"] end

function Environment:IsBreathable()
	local volume=self:GetVolume()
	local atmosphere=self:GetAtmosphere()
	local pressure=100*self:GetPressure()
	local oxygen=100*(atmosphere.Oxygen or 0)/volume
	return oxygen>=GetConVar("infinitespace_percent_livable_oxygen"):GetInt() and pressure>=GetConVar("infinitespace_percent_livable_min_pressure"):GetInt()
end
function Environment:IsOutside(arg)
	local filter=nil
	local v
	if(type(arg)=="Vector") then v=arg
	else
		v=arg:LocalToWorld(arg:OBBCenter())
		filter=arg
	end
	local sunlightHeight=GetConVar("infinitespace_sunlight_height"):GetFloat()
	local trace=util.QuickTrace(v,Vector(0,0,sunlightHeight),filter)
	if(not trace) then return false end
	return (not trace.Hit) or (trace.HitSky) or (not self:ContainsVector(trace.HitPos))
end

if SERVER
then
	AllEnvironments=AllEnvironments or {}
	function AddNewEnvironment(env) table.insert(AllEnvironments,env) end
	function GetEnvironmentAtVector(v)
		local retval,retvol=AllEnvironments[1],(1/0)
		for _,env in pairs(AllEnvironments)
		do
			if(env:ContainsVector(v))
			then
				local vol=env:GetVolume()
				if(vol<=retvol)
				then
					retval=env
					retvol=vol
				end
			end
		end
		return retval
	end

	include("infinitespace/legacyplanetloader.lua")
	function ApplyDefaultFluids()
		for name,env in pairs(AllEnvironments)
		do
			env:GetAtmosphere("liquid")["Water"]=env:GetVolume()
		end
	end
	function ApplyDefaultOres()
		for name,env in pairs(AllEnvironments)
		do
			env:GetAtmosphere("solid")["Vespene Gas"]=env:GetVolume()
		end
	end

	local environmentsLoaded=false
	function ReloadEnvironments()
		environmentsLoaded=true
		LoadMapDefinedEnvironments()
		ApplyDefaultFluids()
		ApplyDefaultOres()
	end

	util.AddNetworkString(VISOR_UPDATE)
	function ProcessPlayerEnvironments()
		if(not environmentsLoaded) then ReloadEnvironments() end
		for _,plr in pairs(player.GetAll())
		do
			local env=GetEnvironmentAtVector(plr:GetPos())
			if(plr:Alive())
			then
				local atmos=plr:GetAtmosphere()
				local oxygenNeeded=GetConVar("infinitespace_oxygen_use"):GetInt()
				local drawingFromAtmos=plr.visorUp
				if(not drawingFromAtmos)
				then
					oxygenNeeded=oxygenNeeded-plr:RequestResourceFromNetwork("Oxygen",oxygenNeeded)
					if(oxygenNeeded>0) then	oxygenNeeded=oxygenNeeded-plr:RequestResource("Oxygen",oxygenNeeded) end
					if(oxygenNeeded>0) then drawingFromAtmos=true end
				end
				if(drawingFromAtmos and env:IsBreathable())
				then
					local oxygenInAtmos=atmos.Oxygen
					if(oxygenInAtmos)
					then
						local takenFromAtmos=math.min(oxygenInAtmos,oxygenNeeded)
						atmos.Oxygen=oxygenInAtmos-takenFromAtmos
						oxygenNeeded=oxygenNeeded-takenFromAtmos
					end
				end
				if(oxygenNeeded>0)
				then
					local dmg=DamageInfo()
					dmg:SetAttacker(plr)
					dmg:SetInflictor(plr)
					dmg:SetDamage(GetConVar("infinitespace_suffocation_damage"):GetInt())
					dmg:SetDamagePosition(plr:GetPos()+Vector(0,0,100))
					dmg:SetDamageType(DMG_DROWN)
					plr:TakeDamageInfo(dmg)
				end
			end
			net.Start(VISOR_UPDATE)
			net.WriteTable({env=env})
			net.Send(plr)
			plr:SynchronizeNWVars()
		end
	end
	timer.Create("environment_playerproc",1,0,ProcessPlayerEnvironments)
end
