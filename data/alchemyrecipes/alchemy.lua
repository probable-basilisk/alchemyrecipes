local function hax_prng_next(v)
  local hi = math.floor(v / 127773.0)
  local lo = v % 127773
  v = 16807 * lo - 2836 * hi
  if v <= 0 then
    v = v + 2147483647
  end
  return v
end

local function shuffle(arr, seed)
  local v = math.floor(seed / 2) + 0x30f6
  v = hax_prng_next(v)
  for i = #arr, 1, -1 do
    v = hax_prng_next(v)
    local fidx = v / 2^31
    local target = math.floor(fidx * i) + 1
    arr[i], arr[target] = arr[target], arr[i]
  end
end

local LIQUIDS = {"water", "water_ice", "water_swamp",
"oil", "alcohol", "swamp", "mud", "blood",
"blood_fungi", "blood_worm", "radioactive_liquid",
"cement", "acid", "lava", "urine",
"poison", "magic_liquid_teleportation",
"magic_liquid_polymorph", "magic_liquid_random_polymorph",
"magic_liquid_berserk", "magic_liquid_charm",
"magic_liquid_invisibility"}

local ORGANICS = {"sand", "bone", "soil", "honey",
"slime", "snow", "rotten_meat", "wax",
"gold", "silver", "copper", "brass", "diamond",
"coal", "gunpowder", "gunpowder_explosive",
"grass", "fungi"}

local function copy_arr(arr)
  local ret = {}
  for k, v in pairs(arr) do ret[k] = v end
  return ret
end

local function random_material(v, mats)
  for _ = 1, 1000 do
    v = hax_prng_next(v)
    local rval = v / 2^31
    local sel_idx = math.floor(#mats * rval) + 1
    local selection = mats[sel_idx]
    if selection then
      mats[sel_idx] = false
      return v, selection
    end
  end
end

local function random_recipe(rand_state, seed)
  local liqs = copy_arr(LIQUIDS)
  local orgs = copy_arr(ORGANICS)
  local m1, m2, m3, m4 = "?", "?", "?", "?"
  rand_state, m1 = random_material(rand_state, liqs)
  rand_state, m2 = random_material(rand_state, liqs)
  rand_state, m3 = random_material(rand_state, liqs)
  rand_state, m4 = random_material(rand_state, orgs)
  local combo = {m1, m2, m3, m4}

  rand_state = hax_prng_next(rand_state)
  local prob = 10 + math.floor((rand_state / 2^31) * 91)
  rand_state = hax_prng_next(rand_state)

  shuffle(combo, seed)
  return rand_state, {combo[1], combo[2], combo[3]}, prob
end

local function get_alchemy()
  local seed = tonumber(StatsGetValue("world_seed"))
  local rand_state = math.floor(seed * 0.17127000 + 1323.59030000)

  for i = 1, 6 do
    rand_state = hax_prng_next(rand_state)
  end

  local lc_combo, ap_combo = {"?"}, {"?"}
  rand_state, lc_combo, lc_prob = random_recipe(rand_state, seed)
  rand_state, ap_combo, ap_prob = random_recipe(rand_state, seed)

  return lc_combo, ap_combo, lc_prob, ap_prob
end

local function localize_material(mat)
  local n = GameTextGet("$mat_" .. mat)
  if n and n ~= "" then return n else return "[" .. mat .. "]" end
end

local function format_combo(combo, prob, localize)
  local ret = {}
  for idx, mat in ipairs(combo) do
    ret[idx] = (localize and localize_material(mat)) or mat
  end
  return table.concat(ret, ", ") .. " (" .. prob .. "%)"
end

local lc_combo, ap_combo, lc_prob, ap_prob = get_alchemy()
local combos = {
  AP = {
    [false]=format_combo(ap_combo, ap_prob, false),
    [true]=format_combo(ap_combo, ap_prob, true)
  },
  LC = {
    [false]=format_combo(lc_combo, lc_prob, false),
    [true]=format_combo(lc_combo, lc_prob, true)
  }
}

local created_gui = false

if not _alchemy_gui then
  print("Alchemy creating GUI")
  _alchemy_gui = GuiCreate()
  created_gui = true
else
  print("Alchemy reloading onto existing GUI")
end
local gui = _alchemy_gui
local alchemy_button_id = 323

local is_open = true
local localized = true

local function alchemy_gui_func()
  GuiLayoutBeginHorizontal( gui, 1, 0 )
  if GuiButton( gui, 0, 0, (is_open and "[<]") or "[>]", alchemy_button_id ) then
    is_open = not is_open
  end
  if is_open then
    local combo_text = (" LC: %s | AP: %s"):format(
      combos.LC[localized], combos.AP[localized]
    )
    if GuiButton( gui, 0, 0, combo_text, alchemy_button_id+1 ) then
      localized = not localized
    end
  end
  GuiLayoutEnd( gui)
end

_alchemy_gui_func = alchemy_gui_func

function _alchemy_main()
  if not created_gui then return end
  if not (gui and _alchemy_gui_func) then return end
  GuiStartFrame( gui )
  local happy, errstr = pcall(_alchemy_gui_func)
  if not happy then
    print("Gui error: " .. errstr)
    _alchemy_gui_func = nil
  end
end