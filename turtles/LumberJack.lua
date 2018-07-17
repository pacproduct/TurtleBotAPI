-- LumberJack script.
-- This program requires the TBotAPI software.

local version = "1.2.2"
print("LumberJack v" .. version)
print()

-- SETTINGS SECTION --
-- Minimum quantity of fuel units required before the turtle
-- accepts to start the job.
local init_target_fuel = 20
-- Minimum quantity of fuel the turtle is going to try
-- having in stock at all times.
local target_fuel = 50
-- Turtle will check its fuel level every X units, where X is the following value.
local fuel_check_window = 5
-- Minimum number of saplings the turtle is going to try
-- having in stock at all times. When this number is reached,
-- it will skip collecting them until it needs restocking again.
local target_num_saplings = 32
-- Wood block types to collect. Any other type would be seen as walls.
local wood_types = {"minecraft:log", "minecraft:log2", "ic2:rubber_wood"}
-- Sapling types to detect.
local sapling_types = {"minecraft:sapling", "ic2:sapling"}
-- Types of dirts for planting trees.
local dirt_types = {"minecraft:dirt", "minecraft:grass"}
-- Refuel items that should be ignored by the turtle when refueling.
local refuel_items_to_ignore = sapling_types
-- END OF SETTINGS SECTION --

-- Fuel level during last fuel check. Used to determine whether fuel check should be done.
local last_fuel_check_level = nil
-- Whether GPS positionning is available.
-- This gets tested when launching the program. If true, the turtle will
-- Regularly mark checkpoints so it can get back to it in case of server restart, and
-- continue its duty. If false, no GPS signal was found: the turtle won't restart automatically
-- after a server failure.
local gps_is_active = false
-- Whether direction could be determined.
local gps_direction_determined = false




os.loadAPI("TBotAPI/init.lua")
local TBotAPI = init
local t = turtle




-- Runs through a cycle.
-- @param 
function runCycle()
  local step = "findNextTask"
  
  -- Test whether GPS is available.
  -- If so, flag GPS as active.
  
  while step ~= "done" do
    print("Step '" .. step .. "'...")
    -- Refuel before each step.
    _refuelIfNeeded()
    
    -- No fuel even after a refuel? We're doomed.
    -- Bail.
    local fuelLevel = t.getFuelLevel()
    while fuelLevel ~= "unlimited" and fuelLevel < 1 do
      print("Damn it, I'm out of fuel :(")
      print("Gimme more and press Enter to continue...")
      print("Or hold Ctrl+T to terminate the program.")
      print("[Press Enter when you're ready to carry on]")
      
      read()
      
      _refuelIfNeeded()
      fuelLevel = t.getFuelLevel()
    end
    
    if step == "findNextTask" then
      step = _step_findNextTask()
    elseif step == "harvestTree" then
      step = _step_harvestTree()
    elseif step == "collectAndPlant" then
      step = _step_collectAndPlant()
    elseif step == "unloadFront" then
      step = _step_unloadFront()
    elseif step == "turnAround" then
      _turnAround()
      step = "done"
    end
  end
  
  print("Done.")
  
  return true
end

function _step_findNextTask()
  -- Whether the turtle detected some dirt below it, meaning a tree should be planted
  -- here after its next move.
  local plant_after_next_move = false

  -- First, check whether there's a chest below the turtle.
  local inspect_res, down_item = t.inspectDown()
  if inspect_res and down_item.name == "minecraft:chest" then
    -- If so, unload the turtle down.
    _unloadDown()
    -- Then, check if there is dirt below the turtle
  elseif inspect_res and _in_array(down_item.name, dirt_types) then
    plant_after_next_move = true
  end
  
  -- Then search for next task, in front of it.
  local inspect_res, front_item = t.inspect()
  if inspect_res then
    -- Resource is wood: harvest.
    if _in_array(front_item.name, wood_types) then
      return "harvestTree"
    
    -- Resource is sapling: Wait for it to grow.
    elseif _in_array(front_item.name, sapling_types) then
      -- Wait a bit until trying again. We're basically waiting for the sapling
      -- to grow.
      os.sleep(5)
    
    -- Resource is wool: React to it by changing direction.
    elseif front_item.name == 'minecraft:wool' then
      local color = front_item.state.color
      if (color == 'red') then
        TBotAPI.turnL()
      elseif (color == 'green') then 
        TBotAPI.turnR()
      elseif (color == 'brown') then 
        TBotAPI.moveMinusY()
      elseif (color == 'blue') then
        TBotAPI.movePlusY()
        
        if plant_after_next_move then
          _plantTree('below')
          plant_after_next_move = false
        end
      end
    elseif front_item.name == "minecraft:chest" then
      return "unloadFront"
    end
  else
    _suckAndMoveF()
    
    if plant_after_next_move then
      _plantTree('behind')
      plant_after_next_move = false
    end
  end
  
  return "findNextTask"
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
    
    _suckAndMoveF(0)
    TBotAPI.turnR()
    _suckAndMoveF(0)
  else
    TBotAPI.moveF(-1)
    _turnAround()
  end
  
  -- Plant a tree.
  _plantTree('front')
  _turnAround()

  return "findNextTask"
end

function _step_unloadFront()
  -- If a chest is in front, unload.
  -- Otherwise, stop the unloading and carry on immediately.
  local inspect_res, front_item = t.inspect()
  
  if not inspect_res or front_item.name ~= "minecraft:chest" then
	  return "turnAround"
  end

  _unloadItems(false)
  
  return "turnAround"
end

--[[
  Plants a tree behind the turtle.
  Has no effect if it has no sapling in its inventory.
  @param string direction: Where the tree should be planted:
    - 'front' to plant it in front of the turtle (Default vlaue).
    - 'behind' to plant it behind the turtle.
    - 'below' to plant it below the turtle.
    Optional.
]]
function _plantTree(where)
  if not _in_array(where, {'front', 'behind', 'below'}) then
    behind = 'front'
  end

  local sapling_slot = TBotAPI.searchForItemsSlot(sapling_types)

  if sapling_slot ~= nil then
    t.select(sapling_slot)
  
    if where == 'front' then
      t.place()
    elseif where == 'behind' then
      _turnAround()
      t.place()
      _turnAround()
    elseif where == 'below' then
      t.placeDown()
    end
  end
end

--[[
  Unloads the turtle by throwing items down.
]]
function _unloadDown()
  _unloadItems(true)
end

--[[
  Unloads the turtle by throwing items.
  @param bool dropDown: Whether resources should be dropped down or not.
    If true, drops down. If false, drops in front of it.
    Optional. Defaults to false.
]]
function _unloadItems(dropDown)
  -- Drop all logs and apples.
  _drop_all_items(wood_types, dropDown)
  _drop_all_items({"minecraft:apple"}, dropDown)
  
  return "turnAround"
end

--[[
  Unloads all items of given types from the turtle.
  @param array item_types: List of item types to drop. Ex: {"minecraft:apple", "minecraft:sapling"}.
  @param bool dropDown: Whether resources should be dropped down or not.
    If true, drops down. If false, drops in front of it.
    Optional. Defaults to false.
]]
function _drop_all_items(item_types, dropDown)
  if dropDown == nil then
    dropDown = false
  end

  local item_slot_num = TBotAPI.searchForItemsSlot(item_types)
  while item_slot_num ~= nil do
    t.select(item_slot_num)
    local drop_res = nil
    
    if dropDown then
      drop_res = t.dropDown()
    else
      drop_res = t.drop()
    end
    
    if not drop_res then
      break
    end
    
    item_slot_num = TBotAPI.searchForItemsSlot(item_types)
  end
end

--[[
  Moves the turtle forward and sucks everything in its way.
  @param num_moves: Number of moves forward.
    Optional. Defaults to 1.
    If you set it to 0, the turtle will suck resources in front of
    it without moving forward.
]]
function _suckAndMoveF(num_moves)
  local remaining_moves = num_moves
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
function _refuelIfNeeded(target_num_fuel_units)
  print("Fuel level: " .. t.getFuelLevel())
  if target_num_fuel_units == nil then
    target_num_fuel_units = target_fuel
  end
  
  -- Check whether or not we need to try refueling, based on last fuel check level.
  if last_fuel_check_level ~= "unlimited" and (last_fuel_check_level == nil or last_fuel_check_level <= fuel_check_window or (last_fuel_check_level - t.getFuelLevel()) >= fuel_check_window) then
    local refuel_res = TBotAPI.checkAndRefuel(target_num_fuel_units, refuel_items_to_ignore)
    last_fuel_check_level = t.getFuelLevel()
    
    return refuel_res
  else
    return true
  end
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

--[[
  Tries retrieving its position from the GPS.
  Warning: Takes time when no signal is found.
  @param int timeout: The time to wait for a GPS signal before timeing out (in seconds).
    Optional. Defaults to 2 seconds.
  @return vector: The turtle's position as an X, Y, Z vector. Nil if getting its position failed.
]]
function _get_gps_position(timeout)
  if not timeout then
    timeout = 2
  end
  
  local x, y, z = gps.locate(timeout)
  if not x then
    return nil
  else
    return vector.new(x, y, z)
  end
end

--[[
  Saves current turtle's position, by retrieving its GPS position.
  If it fails, returns false.
  @return bool: True if saving the checkpoint succeeded. False otherwise.
]]
function _save_gps_checkpoint()
  local gps_pos = _get_gps_position()
  
  if gps_pos ~= nil then
    TBotAPI.writePersistentData("checkpoint_x", var)
    TBotAPI.writePersistentData("checkpoint_y", var)
    TBotAPI.writePersistentData("checkpoint_z", var)
  end
end

--[[
  Persists a variable to disk.
  @param string name: Variable name. Must be filename compliant.
  @param value: The value to store.
]]
function _write_persistent_data(name, value)
  TBotAPI.writePersistentData("LumberJack." .. name, value)
end

--[[
  Reads a variable from disk.
  @param string name: Variable name. Must be filename compliant.
  @return value: The sought value.
]]
function _read_persistent_data(name)
  return TBotAPI.readPersistentData("LumberJack." .. name)
end




-- MAIN --

-- Check if there is fuel first.
local initial_refuel = _refuelIfNeeded(init_target_fuel)
if not initial_refuel then
  print("The turtle needs at least " .. init_target_fuel .. " units of fuel to start.")
  print("It currently has " .. t.getFuelLevel() .. " units of fuel.")
  print("Please add more fuel items to it and restart the program.")
  return
end

-- Confirm launch.
print()
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

while runCycle() do
  -- Well... nothing to do here, waiting for the cycle to complete.
end
