local DEFAULT_FLAGS=((not client) and FCVAR_ARCHIVE or 0)+FCVAR_REPLICATED+FCVAR_NOTIFY

CreateConVar("infinitespace_oxygen_use",5,DEFAULT_FLAGS,"Oxygen breathed per second.",0)
CreateConVar("infinitespace_percent_livable_oxygen",20,DEFAULT_FLAGS,"Minimum percent oxygen for breathable atmosphere.",0,100)
CreateConVar("infinitespace_percent_livable_min_pressure",80,DEFAULT_FLAGS,"Minimum percent breathable air pressure.",0,100)
CreateConVar("infinitespace_suffocation_damage",5,DEFAULT_FLAGS,"Damage per second from suffocation.",0)
CreateConVar("infinitespace_max_suit_resources",1000,DEFAULT_FLAGS,"Maximum of each essential resource that can be stored in the suit.",0)

include("infinitespace/resources.lua")
include("infinitespace/overlayrender.lua")
include("infinitespace/environments.lua")
include("infinitespace/playeroverrides.lua")
