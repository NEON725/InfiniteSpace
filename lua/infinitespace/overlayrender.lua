if SERVER
then
	AddCSLuaFile()
	return
end

local POPUP_MOVE_ASIDE_RADIUS=100
local POPUP_TEXT_SCALE=1/256
local POPUP_TEXT_PAD=150
local POPUP_TEXT_FONT="IS_POPUP_FONT"
TOOL_TEXT_FONT="IS_TOOL_FONT"
local POPUP_TEXT_FONT_CONFIGURATOR={
	font = "Roboto",
	size = 0.8/POPUP_TEXT_SCALE,
	extended = false,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
}
local TOOL_TEXT_FONT_CONFIGURATOR=table.Copy(POPUP_TEXT_FONT_CONFIGURATOR)
TOOL_TEXT_FONT_CONFIGURATOR.size=30
surface.CreateFont(POPUP_TEXT_FONT,POPUP_TEXT_FONT_CONFIGURATOR)
surface.CreateFont(TOOL_TEXT_FONT,TOOL_TEXT_FONT_CONFIGURATOR)
POPUP_TEXT_LINES={}
local contextMenuOpen=false
local OverlayHeight=ScrH()
local VisorUp=true
concommand.Add("toggle_visor",function() VisorUp=not VisorUp end)
CreateClientConVar("visor_movement_rate",10,true,false,"Rate in pixels per frame that visor moves up or down.",0,100)
CreateClientConVar("visor_max_alpha",100,true,false,"How opaque the visor should be when lifted, from 0-255.",0,255)

hook.Add("HUDPaint","is_overlay",function()
	local MaxAlpha=GetConVar("visor_max_alpha"):GetFloat()
	local MovementRate=GetConVar("visor_movement_rate"):GetFloat()
	local InfoHeight=100
	local TargetHeight=ScrH()
	if VisorUp then TargetHeight=InfoHeight end
	local HeightDiff=math.Clamp(TargetHeight-OverlayHeight,-MovementRate,MovementRate)
	OverlayHeight=OverlayHeight+HeightDiff
	local HeightFromMin=OverlayHeight-InfoHeight
	local MaxHeightFromMin=ScrH()-InfoHeight
	local AlphaMul=1-HeightFromMin/MaxHeightFromMin
	surface.SetDrawColor(200,200,255,AlphaMul*MaxAlpha)
	surface.DrawTexturedRect(0,0,ScrW(),OverlayHeight)
end)

hook.Add("PostDrawTranslucentRenderables","is_devicepopup",function(Depth,Skybox)
	if(SkyBox) then return end
	local wep=LocalPlayer():GetActiveWeapon()
	local tr=LocalPlayer():GetEyeTrace()
	local ent=tr.Entity
	if(not ent or not ent.IsSpaceMachine)
	then
		POPUP_TEXT_LINES={}
		return
	end
	local vars=ent:GetNWVarTable()
	local lines={ent.PrintName.." x"..(vars.storageMultiplier or "???")}
	local storageLines={}
	local surplusLines={}
	local resources={}
	if(vars.Power and vars.Power!=0) then table.insert(lines,"Powered On") end
	for res,_ in pairs(IS_RESOURCES)
	do
		local current=ent:GetResource(res)
		local max=ent:GetMaxResource(res)
		if(max>0) then table.insert(storageLines,res..": "..current.."/"..max) end
		if(current>max) then table.insert(surplusLines,res..": "..(current-max)) end
	end
	function addLines(newlines)
		for _,line in pairs(newlines) do table.insert(lines,line) end
	end
	local miscLines=ent:TooltipDisplayLines()
	addLines(miscLines)
	if(#storageLines>0) then table.insert(lines,"Storage:") end
	addLines(storageLines)
	if(#surplusLines>0) then table.insert(lines,"Output:") end
	addLines(surplusLines)
	POPUP_TEXT_LINES=lines
	if(not contextMenuOpen) then return end
	local width=math.Clamp(LocalPlayer():GetShootPos():Distance(tr.HitPos)/3,12,80)
	local origin,normal
	if(ent:GetModelRadius()<POPUP_MOVE_ASIDE_RADIUS)
	then
		origin=tr.HitPos+Vector(0,0,1+width/2)
		normal=-tr.Normal
		if(normal.x==0 and normal.y==0) then normal=Vector(0,0,1)
		else
			normal.z=0
			normal:Normalize()
		end
	else
		origin=tr.HitPos+tr.HitNormal*width/10
		normal=tr.HitNormal
	end
	render.SetMaterial(Material("models/props_combine/combine_interface_disp"))
	render.DrawQuadEasy(origin,normal,width,width,Color(255,255,255,255))
	local textAng=normal:Angle()
	textAng:RotateAroundAxis(textAng:Up(),90)
	textAng:RotateAroundAxis(textAng:Forward(),90)
	local appliedScale=POPUP_TEXT_SCALE*width*0.1
	cam.Start3D2D(origin+normal*0.125,textAng,appliedScale)
	local y=width/(appliedScale*-2)+POPUP_TEXT_PAD
	local x=y
	for _,line in pairs(lines)
	do
		draw.SimpleTextOutlined(line,POPUP_TEXT_FONT,x,y,Color(0,0,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,5,Color(0,0,0,255))
		local tW,tH=surface.GetTextSize(line)
		y=y+tH
	end
	cam.End3D2D()
end)

hook.Add("OnContextMenuOpen","IS_CONTEXTMENU_OPEN",function() contextMenuOpen=true end)
hook.Add("OnContextMenuClose","IS_CONTEXTMENU_CLOSE",function() contextMenuOpen=false end)
