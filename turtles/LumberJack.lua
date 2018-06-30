-- LumberJack script.
-- This program requires the TBotAPI software.
--

-- SETTINGS SECTION --
-- Minimum quantity of fuel units required before the turtle
-- accepts to start the job.
local init_target_fuel = 50
-- Minimum quantity of fuel the turtle is going to try
-- having in stock at all times.
local target_fuel = 100
-- Minimum number of saplings the turtle is going to try
-- having in stock at all times. When this number is reached,
-- it will skip collecting them until it needs more again.
local target_num_saplings = 32
-- Wood block types to collect. Any other type would be seen as walls.
local wood_types = {"minecraft:log", "minecraft:log2", "ic2:rubber_wood"}
-- Sapling types to detect.
local sapling_types = {"minecraft:sapling", "ic2:sapling"}
-- Refuel items that should be ignored by the turtle when refueling.
local refuel_items_to_ignore = sapling_types
-- END OF SETTINGS SECTION --




os.loadAPI("TBotAPI")
local t = turtle




function runCycle()
  local step = "findTree"
  
  while step ~= "done" do
    print("Step '" .. step .. "'...")
    -- Refuel before each step.
    _refuel()
    if step == "findTree" then
      step = _step_findTree()
    elseif step == "harvestTree" then
      step = _step_harvestTree()
    elseif step == "collectAndPlant" then
      step = _step_collectAndPlant()
    elseif step == "unload" then
      step = _step_unload()
    elseif step == "unloadingEnd" then
      _turnAround()
      step = "done"
    end
  end
  
  print("Done.")
end

function _step_findTree()
  local inspect_res, front_item = t.inspect()
  
  if inspect_res then
    if _in_array(front_item.name, wood_types) then
      return "harvestTree"
    elseif _in_array(front_item.name, sapling_types) then
      -- Wait a bit until trying again. We're basically waiting for the sapling
      -- to grow.
      os.sleep(5)
    else
      return "unload"
    end
  else
    TBotAPI.moveF()
  end
  
  return "findTree"
end

function _step_harvestTree()
  -- Organize inventory to ensure ther's space for wood.
  TBotAPI.groupInventoryResources()
  
  -- Dig tree.
  TBotAPI.dig()
  TBotAPI.moveF()
  
  local inspect_res, up_item = t.inspectUp()
  while inspect_res and _in_array(up_item.name, wood_types) do
    TBotAPI.digU()
    TBotAPI.movePlusY()
    
    inspect_res, up_item = t.inspectUp()
  end

  -- Get back down.
  local inspect_res, down_item = t.inspectDown()
  while not inspect_res do
    TBotAPI.moveMinusY()
    
    inspect_res, down_item = t.inspectDown()
  end

  return "collectAndPlant"
end

function _step_collectAndPlant()
  -- If total number of saplings reached the target,
  -- skip collecting resources and directly plant a tree.
  local resources_collection_needed = true
  if TBotAPI.getTotalNumResources(sapling_types) >= target_num_saplings then
    resources_collection_needed = false
  end
  
  -- Collect resources if needed.
  if resources_collection_needed then
    _suckAndMoveF()
    TBotAPI.turnR()
    
    for i = 1, 4 do
      _suckAndMoveF()
      TBotAPI.turnL()
      _suckAndMoveF(0)
      _turnAround()
      _suckAndMoveF()
      TBotAPI.turnL()
      _suckAndMoveF(0)
      TBotAPI.turnR()
    end
    
    TBotAPI.turnR()
    _suckAndMoveF(0)
  else
    TBotAPI.moveF(-1)
    _turnAround()
  end
  
  -- Plant a tree.
  local sapling_slot = TBotAPI.searchForItemsSlot(sapling_types)
  if sapling_slot ~= nil then
    t.select(sapling_slot)
    t.place()
  end
  
  _turnAround()

  return "findTree"
end

function _step_unload()
  -- If a chest is in front, unload.
  -- Otherwise, stop the unloading and carry on immediately.
  local inspect_res, front_item = t.inspect()
  
  if not inspect_res or front_item.name ~= "minecraft:chest" then
	return "unloadingEnd"
  end
  
  -- Drop all logs and apples.
  _drop_all_items(wood_types)
  _drop_all_items({"minecraft:apple"})
  
  return "unloadingEnd"
end

-- Unloads all items of given types from the turtle, in front of it.
-- @param array item_types: List of item types to drop. Ex: {"minecraft:apple", "minecraft:sapling"}.
function _drop_all_items(item_types)
  local item_slot_num = TBotAPI.searchForItemsSlot(item_types)
  while item_slot_num ~= nil do
    t.select(item_slot_num)
    local drop_res = t.drop()
    
    if not drop_res then
      break
    end
    
    item_slot_num = TBotAPI.searchForItemsSlot(item_types)
  end
end

function _suckAndMoveF(num_moves)
  local remaining_moves = TBotAPI.clone(num_moves)
  while t.suck() do end
  
  if remaining_moves == nil then
    remaining_moves = 1
  end
  
  while remaining_moves > 0 do
    TBotAPI.moveF(-1)
    while t.suck() do end
    remaining_moves = remaining_moves - 1
  end
end

-- Refuels.
-- @param Target num of fuel units.
--   Optional. Defaults to the global target_fuel variable.
-- Returns false if it could not reach target minimum fuel.
function _refuel(target_num_fuel_units)
  if target_num_fuel_units == nil then
    target_num_fuel_units = target_fuel
  end
  
  return TBotAPI.checkAndRefuel(target_num_fuel_units, refuel_items_to_ignore)
end

-- Turns the turtle around (turns it left twice).
function _turnAround()
  TBotAPI.turnL()
  TBotAPI.turnL()
end

-- Checks whether given value is in given array.
-- @param mixed needle: The searched value.
-- @param array haystack: The array.
-- @return boolean: True if needle was found in given array.
--   False otherwise.
function _in_array(needle, haystack)
  for key, value in ipairs(haystack) do
    if value == needle then
      return true
    end
  end

  return false
end




-- MAIN --

-- Check is there is fuel first.
local initial_refuel = _refuel(init_target_fuel)
if not initial_refuel then
  print("The turtle needs at least " .. init_target_fuel .. " units of fuel to start.")
  print("It currently has " .. t.getFuelLevel() .. " units of fuel.")
  print("Please add more fuel items to it and restart the program.")
  return
end

-- Confirm launch.
print("")
print("IMPORTANT: This program works for a certain pattern only.")
print()
print("About to start the mission.")
print("Are you sure your turtle is properly positionned and you want to continue?")
print("Hold Ctrl+T now to cancel, or ENTER to proceed.")
read()
print("Starting job.")

-- Initial inventory sorting.
print("Initial inventory sorting...")
TBotAPI.groupInventoryResources()
print("Done.")

while true do
  runCycle()
end