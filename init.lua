function OnWorldPostUpdate() 
  if _alchemy_main then _alchemy_main() end
end

function OnPlayerSpawned( player_entity )
  dofile("data/alchemyrecipes/alchemy.lua")
end