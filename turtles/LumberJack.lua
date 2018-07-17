-- LumberJack script.
-- This program requires the TBotAPI software.

local version = "1.2.5"
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




os.loadAPI("TBotAPI/init.lua")
local TBotAPI = init
local t = turtle




-- Runs through a cycle.
-- @param String|nil start_step: The starting step to run with.
--   If nil, runs the cycle from the start.
function runCycle(start_step)
  local step = "findNextTask"
  
  if start_step ~= nil then
    step = start_step
  end
  
  while step ~= "done" do
    print("Step '" .. step .. "'...")
    _write_persistent_data("current_step", step)
    
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
  -- Organize inventory to ensure there's space for wood.
  TBotAPI.groupInventoryResources()
  
  -- Dig tree.
  TBotAPI.dig()
  TBotAPI.moveF()
  
  _harvestTreeUpAndGetBackDown()
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
  
  -- Add a checkpoint!
  _save_checkpoint_and_start_tracking()

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

-- Specifically used by the resume feature, as stopping the server while
-- a turtle was harvesting a tree needs a special behavior.
-- @return String: What the next step should be.
function _resumeHarvestingTree()
  -- Wood in front? Back to normal process.
  local inspect_res, item = t.inspect()
  if inspect_res and _in_array(item.name, wood_types) then
    return "harvestTree"
  end

  -- Organize inventory to ensure there's space for wood.
  TBotAPI.groupInventoryResources()
  
  -- Wood above? Harvest it.
  local inspect_res, item_up = t.inspectUp()
  if inspect_res and _in_array(item_up.name, wood_types) then
    _harvestTreeUpAndGetBackDown()
    return "collectAndPlant"
  end
  
  -- Go up.
  TBotAPI.movePlusY()
  
  -- Wood above? Harvest it.
  local inspect_res, item_up = t.inspectUp()
  if inspect_res and _in_array(item_up.name, wood_types) then
    _harvestTreeUpAndGetBackDown()
    return "collectAndPlant"
  end
  
  -- No wood found? We probably were done harvesting it.
  -- Get back down and carry on.
  _goDownToTheGround()
  return "collectAndPlant"
end

-- Harvests the tree up the turtle.
-- Then gets back down.
function _harvestTreeUpAndGetBackDown()
  local inspect_res, up_item = t.inspectUp()
  while inspect_res and _in_array(up_item.name, wood_types) do
    TBotAPI.digU()
    TBotAPI.movePlusY()
    
    inspect_res, up_item = t.inspectUp()
  end

  -- Get back down.
  _goDownToTheGround()
end

-- Go down until something is detected below the turtle.
function _goDownToTheGround()
  local inspect_res, down_item = t.inspectDown()
  while not inspect_res do
    TBotAPI.moveMinusY()
    
    inspect_res, down_item = t.inspectDown()
  end
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
  Restarts tracking turtle's movements and initial direction.
  Saved data is useful for resuming a job after a server restart.
]]
function _save_checkpoint_and_start_tracking()
  -- Enable tracking.
  TBotAPI.setTrackerStatus(true)
  -- Clear tracking.
  TBotAPI.clearTracker()
  
  -- Save current direction.
  _write_persistent_data("checkpoint_direction", TBotAPI.getDir())
end

--[[
  Moves the turtle back to its last checkpoint, following its trail back.
  Puts it in its initial direction too.
]]
function _get_back_to_last_checkpoint()
  TBotAPI.getBack()
  local dir = _read_persistent_data("checkpoint_direction")
  
  if dir then
    TBotAPI.face(dir)
  end
end

--[[
  Clears out any persistent data this turtle had written to disk.
]]
function _clear_persistent_data()
  _write_persistent_data("checkpoint_direction", nil)
  _write_persistent_data("current_step", nil)
end

--[[
  Persists a variable to disk.
  @param string name: Variable name. Must be filename compliant.
  @param value: The value to store. Nil to delete it.
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

--[[
  Tries receiving GPS position.
  If it succeeds, tries to find out direction.
  If everything succeeds, initialize de TBotAPI with these.
  @return bool: True if everything went well.
]]
function _gps_initialization()
  local gps_pos = _get_gps_position()
  local gps_pos2 = nil
  
  if gps_pos == nil then
    return false
  end
  
  -- Persist position.
  TBotAPI.setPos(gps_pos)
  
  -- Tries finding out direction.
  local turns = 0
  
  -- Tries all 4 directions before giving up.
  for i=1,4 do
    local move_res = turtle.forward()
    
    if move_res then
      gps_pos2 = _get_gps_position()
      turtle.back()
      break
    end

    turtle.turnRight()
    turns = turns + 1
  end
  
  -- Restore origin direction.
  local restore_turns = turns
  if restore_turns > 0 and restore_turns < 4 then
    while restore_turns > 0 do
      turtle.turnLeft()
      restore_turns = restore_turns - 1
    end
  end
  
  -- Did we get a second position?
  -- If not, bail.
  if gps_pos2 == nil then
    return false
  end
  
  -- Second position found. Yay. Deduct direction.
  local move_vector = gps_pos2 - gps_pos
  local final_direction = nil
  if move_vector.z == -1 then
    -- north
    final_direction = 0
  elseif move_vector.z == 1 then
    -- south
    final_direction = 2
  elseif move_vector.x == -1 then
    -- west
    final_direction = 3
  elseif move_vector.x == 1 then
    -- east
    final_direction = 1
  end
  
  -- Compute direction based on var "turns".
  final_direction = (final_direction - turns) % 4
  -- Persist direction.
  TBotAPI.setDir(final_direction)
  
  return true
end

-- Resume activitie.
-- @return String|nil: Name of the next step to run.
--   Returns nil if the next cycle should start from the begining.
function _resumeActivities()
  local last_step = _read_persistent_data("current_step")
  local next_step = nil
  if last_step == "harvestTree" then
    next_step = _resumeHarvestingTree()
  end
  
  -- Tries initializing GPS.
  local gps_init_res = _gps_initialization()
  
  -- No fix? Issue a warning.
  if not gps_init_res then
    print("WARNING: Could not get a GPS fix!")
    print("The turtle might be out of sync.")
  end
  
  -- We have no next step for carrying on.
  -- We need to get back to latest checkpoint.
  if not next_step then
    -- Whether we got the GPS fix or not, try getting back to last checkpoint.
    -- With no GPS fix, the potential problem is that the TBotAPI might
    -- be out of sync with the turtle's real position if the server shut down
    -- exactly in between the turtle's movement and saving its new position to disk...
    _get_back_to_last_checkpoint()
  end
    
  -- Return next step.
  return next_step
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

-- Initial inventory sorting.
print("Initial inventory sorting...")
TBotAPI.groupInventoryResources()
print("Done.")

-- Resume operations.
local start_step = _resumeActivities()
runCycle(start_step)

while runCycle() do
  -- Well... nothing to do here, waiting for the cycle to complete.
end
