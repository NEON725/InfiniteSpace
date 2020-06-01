--Credit to Nebual for most of this script.

local num=tonumber

local function Extract_Bit(bit, field)
	if not bit or not field then return false end
	if ((field <= 7) and (bit <= 4)) then
		if (field >= 4) then
			field = field - 4
			if (bit == 4) then return true end
		end
		if (field >= 2) then
			field = field - 2
			if (bit == 2) then return true end
		end
		if (field >= 1) then
			field = field - 1
			if (bit == 1) then return true end
		end
	end
	return false
end

function GetEarthComposition(volume)
	return {
		gas=
		{
			Oxygen=volume*0.2,
			Nitrogen=volume*0.78,
			Helium=volume*0.01,
			Hydrogen=volume*0.01
		},
		liquid=
		{
			Water=volume
		},
		solid=
		{
		}
	}
end

function LoadMapDefinedEnvironments()
	AllEnvironments={Environment({name="Space",shape=EnvironmentShape("cube",50000,50000,50000)})}
	for _,logic in pairs(ents.FindByClass("logic_case"))
	do
		local keyValues=logic:GetKeyValues()
		local style = keyValues.Case01
		if style == "" or style == "1" or style == "01" then continue end
		local radius=num(keyValues.Case02)
		local gravity=num(keyValues.Case03)
		local atmosphere=num(keyValues.Case04)
		local name=tostring((style=="planet") and "" or keyValues.Case13)
		if(name and #name>0) then environment.name=name end
		local flags=num((style=="planet") and keyValues.Case16 or keyValues.Case08)
		local habitable,unstable,sunburn=false,false,false
		if(isnumber(flags))
		then
			local habitable=Extract_Bit(1, flags)
			local unstable=Extract_Bit(2, flags)
			local sunburn=Extract_Bit(3, flags)
		end
		local environment=Environment({position=logic:GetPos(),rotation=logic:GetAngles()})
		if style == "planet" then
			environment.shape=EnvironmentShape("sphere",radius)
			local shadetemp=num(keyValues.Case05)
			local littemp=num(keyValues.Case06)
			local colorref=keyValues.Case07
			if(colorref and string.sub(colorref,1,6) == "color_") then environment.name = string.upper(string.sub(colorref,7,7))..string.sub(colorref,8) end -- Some 'planet's reference a planet_color logic_case like 'color_kobol'
			local volume=environment:GetVolume()
			if(habitable) then environment.atmosphere=GetEarthComposition(volume*atmosphere) end
		elseif style == "planet2" or style == "cube" then
			environment.name=tostring(keyValues.Case14)
			if style == "cube" then
				local xyz = string.Explode(" ",keyValues.Case02)
				environment.shape=EnvironmentShape("cube",xyz[1],xyz[2],xyz[3])
			else
				environment.shape=EnvironmentShape("sphere",num(keyValues.Case02))
			end
			local pressure=num(keyValues.Case05)
			local shadetemp=num(keyValues.Case06)
			local littemp=num(keyValues.Case07)
			local o2,co2,n,h=(num(keyValues.Case09) or 0),(num(keyValues.Case10) or 0),(num(keyValues.Case11) or 0),(num(keyValues.Case12) or 0)
			local filledAtmosphereMul=(atmosphere+pressure)/2
			local volume=environment:GetVolume()
			environment.atmosphere.gas=
			{
				Oxygen=o2*volume*filledAtmosphereMul,
				["Carbon Dioxide"]=co2*volume*filledAtmosphereMul,
				Nitrogen=n*volume*filledAtmosphereMul,
				Hydrogen=h*volume*filledAtmosphereMul
			}

		elseif style == "star" or style == "star2" then
			environment.name="Star #"..#AllEnvironments
			environment.shape.radius=num(keyValues.Case02)
			environment.atmosphere.gas.Hydrogen=environment:GetVolume()
		else
			print("NS3 Er- IS: Skipping unhandled environment type '"..style.."'...\n")
			continue
		end
		AddNewEnvironment(environment)
		print("Loaded map environment: "..environment.name.." ("..style..")")
	end
end
