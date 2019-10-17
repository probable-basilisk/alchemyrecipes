import sys

LIQUIDS = ["water", "water_ice", "water_swamp",
"oil", "alcohol", "swamp", "mud", "blood",
"blood_fungi", "blood_worm", "radioactive_liquid",
"cement", "acid", "lava", "urine",
"poison", "magic_liquid_teleportation",
"magic_liquid_polymorph", "magic_liquid_random_polymorph",
"magic_liquid_berserk", "magic_liquid_charm",
"magic_liquid_invisibility"]

ORGANICS = ["sand", "bone", "soil", "honey",
"slime", "snow", "rotten_meat", "wax",
"gold", "silver", "copper", "brass", "diamond",
"coal", "gunpowder", "gunpowder_explosive",
"grass", "fungi"]

def swap(arr, idx1, idx2):
    v1 = arr[idx1]
    v2 = arr[idx2]
    arr[idx1] = v2
    arr[idx2] = v1

def rand_update(v):
    hi = v // 127773
    lo = v % 127773
    v = 16807 * lo - 2836 * hi
    if v <= 0:
        v += 2147483647
    return v #, v*4.656612875e-10

def random_material(v, mats):
    for i in range(9999):
        v = rand_update(v)
        rval = v / 2**31
        sel_idx = int(len(mats) * rval)
        selection = mats[sel_idx]
        if selection != 0:
            mats[sel_idx] = 0
            return v, selection

def shuffle(arr, seed):
    v = (seed >> 1) + 0x30f6
    v = rand_update(v)
    for i in range(len(arr)-1, -1, -1):
        #print("next?", i)
        v = rand_update(v)
        fidx = v / 2**31
        target = int(fidx * (i+1))
        #print(i, target)
        swap(arr, i, target)
    return v

def random_recipe(world_seed, rand_state):
    liqs = LIQUIDS[:]
    orgs = ORGANICS[:]
    rand_state, m1 = random_material(rand_state, liqs)
    rand_state, m2 = random_material(rand_state, liqs)
    rand_state, m3 = random_material(rand_state, liqs)
    rand_state, m4 = random_material(rand_state, orgs)
    recipe = [m1, m2, m3, m4]
    shuffle(recipe, world_seed)
    return rand_state, recipe[0:3]

def get_recipes(seed):
    rand_state = int(seed * 0.17127000 + 1323.59030000)

    for i in range(6):
        rand_state = rand_update(rand_state)

    rand_state, lc_combo = random_recipe(seed, rand_state)
    rand_state = rand_update(rand_state)
    prob_lc = rand_state / (2**31 - 1)
    prob_lc = 10 + int(prob_lc * 91.0)
    rand_state = rand_update(rand_state)
    prob_ap = 0 # ???
    rand_state, ap_combo = random_recipe(seed, rand_state)
    return lc_combo, ap_combo, (prob_lc, prob_ap)

def main():
    if len(sys.argv) < 2:
        print("recipes.py seed")
        return
    lc, ap, probs = get_recipes(int(sys.argv[1]))
    print("LC: " + ",".join(lc))
    print("AP: " + ",".join(ap))

if __name__ == "__main__":
    main()