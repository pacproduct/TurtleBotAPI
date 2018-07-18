-- TurtleBot API
--
-- Usage:
-- os.loadAPI("TBotAPI.lua");


-- test aymeric

-- #### CONSTANTS & Global variables ####

-- Debugging purpose variable only.
local DEBUG = false

-- Path to the persistent data directory:
local PERSISTENT_DATA_DIR_PATH = "/TBotData"




-- #### Aliases ####

local t = turtle
local v = vector




-- #### Utility functions ####

-- Rounds a Number to the closest integer.
-- @return int: Given number rounded up to the closest integer.
function round(num)
  return math.floor(num + 0.5)
end

-- Clones a variable to make a copy of it. Usefull to duplicate a table
-- instead of just referencing it. Note: Recursive function.
-- @param mixed var: Variable to clone.
-- @return a new instance copy of the passed in variable.
function clone(var)
  local orig_type = type(var)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, var, nil do
      copy[clone(orig_key)] = clone(orig_value)
    end
    setmetatable(copy, clone(getmetatable(var)))
  else -- number, string, boolean, etc
    copy = var
  end
  return copy
end

-- Returns a default num of tries to use in our API functions below.
-- This variable is used by plenty functions in this API: its purpose is to
-- tell the system how many times the turtle should try an action again on each
-- block before giving up if something is preventing it from completing the
-- task. A negative value would make the turtle try for ever.
-- @param int num_tries: Num of tries initially  passed to the parent function.
--        If that variable is not nil, it will be rounded up.
-- @param int default: Default value to use if first variable is nil. If not
--        given, defaults to 1 so that the turtle retries only once.
-- @return int: The number of tries to use.
function default_num_tries(num_tries, default)
  local nnum_tries = clone(num_tries)
  local default = clone(default)

  if default == nil then
    default = 1
  end

  if num_tries == nil then
    return default
  else
    return round(num_tries)
  end
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




-- #### File API utility functions ####

-- Retrieves path to the persistent data directory. If it does not exist yet,
-- this function creates it before returning the path.
function getDataDirPath()
  if not fs.exists(PERSISTENT_DATA_DIR_PATH) or not fs.isDir(PERSISTENT_DATA_DIR_PATH) then
    -- If path the persistent data dir wasn't found, or isn't a directory,
    -- create it:
    fs.makeDir(PERSISTENT_DATA_DIR_PATH)
  end
  
  return PERSISTENT_DATA_DIR_PATH
end

-- Saves a variable in the persistent data directory.
-- Note: This function creates files based on variables' names.
-- Hence, you should make sure you use names that can be used as file names.
-- @param string name: Variable's name to save. Must be a valid file name.
--        If nil, this function has no effect.
-- @param string value: Variable's value to save. If nil, this variable will
--        be deleted.
-- @param bool overwrite: Whether the data to write should be appened to the
--        value if any, or if it should overwrite it. Defaults to TRUE to
--        overwrite any existing value.
function writePersistentData(name, value, overwrite)
  if overwrite == nil then
    overwrite = true
  end
  
  local file_path = nil
  
  if name ~= nil then
    file_path = getDataDirPath() .. "/" .. name
  else
    -- Given name is nil: There's nothing we can do with it...
    return
  end
  
  if value == nil then
    -- Given value is nil: Delete this variable.
    fs.delete(file_path)
    return
  end
  
  -- Save data:
  local write_mode = "a"
  if overwrite then
    write_mode = "w"
  end
  local fh = fs.open(file_path, write_mode)
  
  if fh ~= nil then
    fh.write(value)
    fh.close()
  end
end

-- Returns the value of a persistent variable.
function readPersistentData(name)
  local file_path = nil
  
  if name ~= nil then
    file_path = getDataDirPath() .. "/" .. name
  else
    -- Given name is nil: There's nothing we can do with it...
    return nil
  end
  
  -- Retrieve data:
  local fh = fs.open(file_path, "r")
  
  if fh ~= nil then
    local value = fh.readAll()
    fh.close()
    
    return value
  else
    -- Something wrong happened when reading the file, return nil:
    return nil
  end
end




-- #### Persistent DATA getter/setter functions ####

-- Returns the current direction of the turtle.
-- Important note: This value is accurate only if the turtle was
-- initialiazed with its actual coordinates!
-- @return vector: Current direction: 0, 1, 2, 3.
--         If not data was found, will return 0 by default.
function getDir()
  local dir = readPersistentData("dir")
  
  if dir == nil then
    dir = 0
  end
  
  return tonumber(dir)
end

function setDir(dir)
  writePersistentData("dir", dir % 4)
end

function addToDir(var)
  local dir = getDir()
  setDir(dir + var)
end

-- Returns the current position of the turtle.
-- Important note: This value is accurate only if the turtle was
-- initialiazed with its actual coordinates!
-- @return vector: Current position.
--         If not data was found, will return (0, 0, 0) by default.
function getPos()
  local pos = v.new(
    readPersistentData("pos_x", 0),
    readPersistentData("pos_y", 0),
    readPersistentData("pos_z", 0)
  )

  return pos
end

function setPosX(var)
  writePersistentData("pos_x", var)
end

function setPosY(var)
  writePersistentData("pos_y", var)
end

function setPosZ(var)
  writePersistentData("pos_z", var)
end

function setPos(pos)
  setPosX(pos.x)
  setPosY(pos.y)
  setPosZ(pos.z)
end

function addToPosX(var)
  local pos = getPos()
  setPosX(pos.x + var)
end

function addToPosY(var)
  local pos = getPos()
  setPosY(pos.y + var)
end

function addToPosZ(var)
  local pos = getPos()
  setPosZ(pos.z + var)
end

-- Sets the tracking status.
-- @param bool status: true to enable tracking, false otherwise.
function setTrackerStatus(status)
  if status then
    writePersistentData("tracker_status", "1")
  else
    writePersistentData("tracker_status", "0")
  end
end

-- Returns whether tracking is enabled or not.
-- @return bool: true if enabled, false otherwise.
function getTrackerStatus()
  local ts = readPersistentData("tracker_status")
  
  if ts == nil or ts == "0" then
    return false
  else
    return true
  end
end

-- Tracks a turtle position.
-- NOTE: Does not do anything if tracking was no enabled via setTrackerStatus(true).
function track()
  if not getTrackerStatus() then
    return
  end
  
  local pos = getPos()
  writePersistentData("tracker", pos.x .. "," .. pos.y .. "," .. pos.z .. "\n", false)
end

function clearTracker()
  writePersistentData("tracker", nil)
  -- The tracker should always contain the current position as the first one:
  track()
end




-- #### API wrapping functions ####
-- Functions wrapping CC APIs to track changes ourselves (like
-- position and direction for instance). Only these functions should use
-- turtle's API! The rest of the program should use functions below instead.

-- Simply wraps turtle.turnLeft().
function turnL()
  t.turnLeft()
  addToDir(-1)
end

-- Simply wraps turtle.turnRight().
function turnR()
  t.turnRight()
  addToDir(1)
end

-- Simply wraps turtle.forward().
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function moveF(num_tries)
  -- Duplicate parameters so we don't modify them:
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local result = t.forward()
  while not result and num_tries ~= 0 do
    num_tries = num_tries - 1
    sleep(0.1)
    result = t.forward()
  end
  
  if result then
    -- The move was successfull, update position:
    local dir = getDir()
    if dir == 0 then
      addToPosZ(-1)
    elseif dir == 1 then
      addToPosX(1)
    elseif dir == 2 then
      addToPosZ(1)
    else
      addToPosX(-1)
    end
    
    -- Track movement:
    track()
  end
  
  return result
end

-- Moves to the next cell on the Y axis (Up).
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function movePlusY(num_tries)
  -- Duplicate parameters so we don't modify them:
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local result = t.up()
  while not result and num_tries ~= 0 do
    num_tries = num_tries - 1
    sleep(0.1)
    result = t.up()
  end
  
  if result then
    addToPosY(1)
    
    -- Track movement:
    track()
  end
  
  return result
end

-- Moves to the previous cell on the Y axis (Down).
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function moveMinusY(num_tries)
  -- Duplicate parameters so we don't modify them:
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local result = t.down()
  while not result and num_tries ~= 0 do
    num_tries = num_tries - 1
    sleep(0.1)
    result = t.down()
  end
  
  if result then
    addToPosY(-1)
    
    -- Track movement:
    track()
  end
  
  return result
end

-- Simply wraps turtle.dig().
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function dig(num_tries)
  -- Duplicate parameters so we don't modify them:
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local result = t.dig()
  while not result and num_tries ~= 0 do
    num_tries = num_tries - 1
    sleep(0.1)
    result = t.dig()
  end
  
  return result
end

-- Simply wraps turtle.digUp().
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function digU(num_tries)
  -- Duplicate parameters so we don't modify them:
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local result = t.digUp()
  while not result and num_tries ~= 0 do
    num_tries = num_tries - 1
    sleep(0.1)
    result = t.digUp()
  end
  
  return result
end

-- Simply wraps turtle.digDown().
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function digD(num_tries)
  -- Duplicate parameters so we don't modify them:
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local result = t.digDown()
  while not result and num_tries ~= 0 do
    num_tries = num_tries - 1
    sleep(0.1)
    result = t.digDown()
  end
  
  return result
end




-- #### Positionning functions ####

-- Moves to the next cell on the X axis (East).
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function movePlusX(num_tries)
  face(1)
  return moveF(num_tries)
end

-- Moves to the previous cell on the X axis (West).
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function moveMinusX(num_tries)
  face(3)
  return moveF(num_tries)
end

-- Moves to the next cell on the Z axis (South).
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function movePlusZ(num_tries)
  face(2)
  return moveF(num_tries)
end

-- Moves to the previous cell on the Z axis (North).
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if success. Else false.
function moveMinusZ(num_tries)
  face(0)
  return moveF(num_tries)
end

-- Turns to face given direction.
-- @param int dir: Direction to face: 0, 1, 2, 3.
function face(dir)
  -- Duplicate parameters so we don't modify them:
  local dir = round(clone(dir))
  -- --

  -- Compute actions to make:
  local actions = dir - getDir()

  -- Make sure we take the most efficient way (ex: do -1 instead of +3):
  if actions > 2 then
    actions = actions - 4
  elseif actions < -2 then
    actions = actions + 4
  end

  -- Apply actions:
  while actions ~= 0 do
    if actions > 0 then
      turnR()
      actions = actions - 1
    else
      turnL()
      actions = actions + 1
    end
  end
end

-- Travels "dist" distance, on the X axis.
-- @param int dist: Distance to travel. Will go East if positive. Else West.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the move was successful. Else false.
function moveX(dist, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dist = round(clone(dist))
  -- --
  
  local move_sign = 1
  if dist < 0 then
    move_sign = -1
  end
  
  dist = math.abs(dist)
  
  local successful_move = false
  while dist > 0 do
    if move_sign == 1 then
      successful_move = movePlusX(num_tries)
    else
      successful_move = moveMinusX(num_tries)
    end
    
    if not successful_move then
      return false
    end

    dist = dist - 1
  end
  
  return true
end

-- Travels "dist" distance, on the Y axis (height).
-- @param int dist: Distance to travel. Will go Up if positive. Else Down.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the move was successful. Else false.
function moveY(dist, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dist = round(clone(dist))
  -- --

  dist = round(dist)
  
  local move_sign = 1
  if dist < 0 then
    move_sign = -1
  end
  
  dist = math.abs(dist)
  
  local successful_move = false
  while dist > 0 do
    if move_sign == 1 then
      successful_move = movePlusY(num_tries)
    else
      successful_move = moveMinusY(num_tries)
    end
    
    if not successful_move then
      return false
    end

    dist = dist - 1
  end
  
  return true
end

-- Travels "dist" distance, on the Z axis.
-- @param int dist: Distance to travel. Will go South if positive. Else North.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the move was successful. Else false.
function moveZ(dist, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dist = round(clone(dist))
  -- --

  local move_sign = 1
  if dist < 0 then
    move_sign = -1
  end
  
  dist = math.abs(dist)
  
  local successful_move = false
  while dist > 0 do
    if move_sign == 1 then
      successful_move = movePlusZ(num_tries)
    else
      successful_move = moveMinusZ(num_tries)
    end
    
    if not successful_move then
      return false
    end

    dist = dist - 1
  end
  
  return true
end

-- Moves on X, Y and Z axes, in line with given vector.
-- @param vect: Relative movement vector to follow.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the move was successful. Else false.
function move(vect, num_tries)
  -- Duplicate parameters so we don't modify them:
  local vect = clone(vect)
  -- --
  
  local result = false

  -- Make sure positions are integers:
  vect.x = round(vect.x)
  vect.y = round(vect.y)
  vect.z = round(vect.z)
  
  -- Move on X:
  result = moveX(vect.x, num_tries)
  if result then
    -- Move on Y if previous move was successful:
    result = moveY(vect.y, num_tries)
    if result then
      -- Move on Z if previous move was successful:
      result = moveZ(vect.z, num_tries)
    end
  end
  
  return result
end

-- Goes to given destination position.
-- @param vector dest: Absolute position X, Y, Z to reach.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the move was successful. Else false.
function moveTo(dest, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dest = clone(dest)
  -- --
  
  -- Make sure positions are integers:
  dest.x = round(dest.x)
  dest.y = round(dest.y)
  dest.z = round(dest.z)
  
  -- Compute relative movement vector to apply:
  local vect = v.new(dest.x, dest.y, dest.z) - getPos()
  
  -- Go:
  return move(vect, num_tries)
end

-- Attempts to go back to the origin point when turtle's movements are
-- being tracked.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
function getBack(num_tries)
  -- Retrieve the list of positions:
  local tracker = readPersistentData('tracker')
  
  -- If the tracker is empty, there is nothing to do:
  if tracker == nil then
    return
  end
  
  -- Retrieve all positions and create a list of vectors:
  local positions = {}
  for line in tracker:gmatch("[^\r\n]+") do
    -- Extract coordinates X, Y, Z:
    local coordinates = {}
    for value in line:gmatch("[^,]+") do
      table.insert(coordinates, value)
    end
    
    if #coordinates >= 3 then
      -- Insert new position at the begining of the array so it lists
      -- all positions from the last to the first:
      table.insert(
        positions,
        1,
        v.new(
          coordinates[1],
          coordinates[2],
          coordinates[3]
        )
      )
    end
  end
  
  -- Follow thread back to its origin:
  for i, v in ipairs(positions) do
    moveTo(v, num_tries)
  end
  
  -- Clear tracker:
  clearTracker()
end




-- #### Escavating functions ####

-- Excavates a line on the X axis, of given length.
-- Important note: The turtle will start digging as if its position was PART of
-- the line to dig: its position is the first cell to dig (i.e. already dug).
-- @param int dist: Length of the line to excavate. A positive number will
--        excavate towards East. Else West.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the operation was successful. Else false.
function excavateX(dist, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dist = round(clone(dist))
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local cur_num_tries = clone(num_tries)
  
  local move_sign = 1
  if dist < 0 then
    move_sign = -1
  end
  
  dist = math.abs(dist) - 1
  face(move_sign)
  
  local successful_move = false
  while dist > 0 do
    -- Dig:
    dig(1)
    -- And move forward:
    successful_move = moveF(1)

    if successful_move then
      dist = dist - 1
      -- Restore the maximum num of tries for next move:
      cur_num_tries = num_tries
    else
      cur_num_tries = cur_num_tries - 1
      if cur_num_tries == 0 then
        return false
      end
    end
  end
  
  return true
end

-- Excavates a line on the Y axis, of given length.
-- Important note: The turtle will start digging as if its position was PART of
-- the line to dig: its position is the first cell to dig (i.e. already dug).
-- @param int dist: Length of the line to excavate. A positive number will
--        excavate Up. Else Down.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the operation was successful. Else false.
function excavateY(dist, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dist = round(clone(dist))
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local cur_num_tries = clone(num_tries)
  
  local move_sign = 1
  if dist < 0 then
    move_sign = -1
  end
  
  dist = math.abs(dist) - 1
  
  local successful_move = false
  while dist > 0 do
    if move_sign == 1 then
      -- Dig Up:
      digU(1)
      -- And move Up:
      successful_move = movePlusY(1)
    else
      -- Dig Down:
      digD(1)
      -- And move Down:
      successful_move = moveMinusY(1)
    end

    if successful_move then
      dist = dist - 1
      -- Restore the maximum num of tries for next move:
      cur_num_tries = num_tries
    else
      cur_num_tries = cur_num_tries - 1
      if cur_num_tries == 0 then
        return false
      end
    end
  end
  
  return true
end

-- Excavates a line on the Z axis, of given length.
-- Important note: The turtle will start digging as if its position was PART of
-- the line to dig: its position is the first cell to dig (i.e. already dug).
-- @param int dist: Length of the line to excavate. A positive number will
--        excavate towards South. Else North.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the operation was successful. Else false.
function excavateZ(dist, num_tries)
  -- Duplicate parameters so we don't modify them:
  local dist = round(clone(dist))
  local num_tries = default_num_tries(num_tries)
  -- --
  
  local cur_num_tries = clone(num_tries)

  local move_sign = 1
  if dist < 0 then
    move_sign = -1
  end
  
  dist = math.abs(dist) - 1
  face(move_sign + 1)
  
  local successful_move = false
  while dist > 0 do
    -- Dig:
    dig(1)
    -- And move forward:
    successful_move = moveF(1)

    if successful_move then
      dist = dist - 1
      -- Restore the maximum num of tries for next move:
      cur_num_tries = num_tries
    else
      cur_num_tries = cur_num_tries - 1
      if cur_num_tries == 0 then
        return false
      end
    end
  end
  
  return true
end

-- Excavates a plan (X, Z) of given coordinates.
-- Important note: The turtle will start digging as if its position was PART of
-- the plan to dig: its position is the first cell to dig (i.e. already dug).
-- @param int x: Length on the X axis. May be negative.
-- @param int z: Length on the Z axis. May be negative.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the operation was successful. Else false.
function excavatePlan(x, z, num_tries)
  -- Duplicate parameters so we don't modify them:
  local x = round(clone(x))
  local z = round(clone(z))
  -- --

  local move_x_sign = 1
  
  local move_z_sign = 1
  if z < 0 then
    move_z_sign = -1
  end
  
  z = math.abs(z)
  
  local current_z_row = 0
  local exc_result = false
  while current_z_row < z do
    -- Excavate a X line:
    exc_result = excavateX(x * move_x_sign, num_tries)
    
    if not exc_result then
      return false
    end
    
    -- Move to next line (if we did not reach the last already):
    if current_z_row < z - 1 then
      exc_result = excavateZ(2 * move_z_sign, num_tries)
      
      if not exc_result then
        return false
      end
    end
    
    -- Go to next Z row:
    current_z_row = current_z_row + 1
    -- Flip the x move sign:
    move_x_sign = move_x_sign * -1
  end
  
  return true
end

-- Excavates a volume of given vector coordinates.
-- Important note: The turtle will start digging as if its position was PART of
-- the volume to dig: its position is the first cell to dig (i.e. already dug).
-- @param vector volume: X, Y and Z coordinates of the volume size to dig.
-- @param bool go_back: Whether the turtle should go back to start position we
--                      the job is done. If true, it will attempt to get back
--                      even if the excavation failed.
-- @param int num_tries: Num of time to try the operation on each block before
--        giving up. See default_num_tries() for further details.
-- @return bool: true if the excavation was successful. Else false.
--               Note that if excavating succeeded but returning to start
--               position failed, it would return true nevertheless.
function excavate(volume, go_back, num_tries)
  -- Duplicate parameters so we don't modify them:
  local volume = clone(volume)
  local go_back = clone(go_back)
  -- --
  
  volume.x = round(volume.x)
  volume.y = round(volume.y)
  volume.z = round(volume.z)
  
  -- Save current position:
  local start_pos = getPos()

  local move_y_sign = 1
  if volume.y < 0 then
    move_y_sign = -1
  end
  
  volume.y = math.abs(volume.y)
  
  local current_plan_num = 0
  local exc_result = false
  while current_plan_num < volume.y do
    -- Compute directions to apply to the next plan excavation:
    local move_plan_sign_x = 1
    local move_plan_sign_z = 1
    local cur_pos = getPos()
    if start_pos.x ~= cur_pos.x then
      move_plan_sign_x = -1
    end
    if start_pos.z ~= cur_pos.z then
      move_plan_sign_z = -1
    end
      
    -- Excavate a plan on current level:
    exc_result = excavatePlan(
      volume.x * move_plan_sign_x,
      volume.z * move_plan_sign_z,
      num_tries
    )
    
    if not exc_result then
      -- Exit loop as excavation failed:
      break
    end
    
    -- Move to next level (if we did not reach the last already):
    if current_plan_num < volume.y - 1 then
      exc_result = excavateY(2 * move_y_sign, num_tries)
      
      if not exc_result then
        -- Exit loop as excavation failed:
        break
      end
    end
    
    -- Go to next level:
    current_plan_num = current_plan_num + 1
  end
  
  -- Get back to initial position if asked to do so:
  if go_back then
    local end_pos = getPos()
    
    -- First go back to Y position:
    moveY(start_pos.y - end_pos.y, num_tries)
    
    -- Then go back to starting point:
    moveTo(start_pos, num_tries)
  end
  
  return exc_result
end



-- #### Fuel functions ####

-- Refuels the turtle if needed, by looking for an item
-- suitable for fueling it.
-- @param int target_minimum: Minimum amount of fuel that should be available in the turtle.
--   If it contains less than than, refueling will be attempted. Otherwise, this
--   will return true without doing anything else.
-- @param array types_to_ignore: List of item types that should NOT be eaten up by the turtle
--   for refueling (i.e. items you want to keep). Ex: {"minecraft:log", "minecraft:sapling"}.
--   Optional. Defaults to none (empty array).
-- @return bool: Whether fueling succeeded. Returns false if refuel was needed but could not
--   occur, most likely because not suitable resource was found within the turtle.
--   Also returns false if fuel was found, but not enough to reach the target minimum.
--   Returns true if fueling succeeded, or if fueling was not needed.
function checkAndRefuel(target_minimum, types_to_ignore)
  if types_to_ignore == nil then
    types_to_ignore = {}
  end
  
  -- If turtles need no refuel, do nothing.
  if t.getFuelLevel() == "unlimited" then
    return true
  end
  
  -- If asked quantity is above the allowed maximum, cap it.
  if target_minimum > t.getFuelLimit() then
    target_minimum = t.getFuelLimit()
  end
  
  -- If fuel level is already high enough, do nothing.
  if t.getFuelLevel() >= target_minimum then
    return true
  end
  
  -- Loop over item slots and consume them until the target minimum is reached.
  for i = 1, 16 do
    local data = t.getItemDetail(i)
    local cur_resource_type = nil
    
    if data ~= nil then
      cur_resource_type = data.name
    end
    
    -- Test whether current slot contains an item valid for refueling, that is not
    -- to be ignored.
    -- Select current slot that we'll consume if not empty.
    t.select(i)
    if not _in_array(cur_resource_type, types_to_ignore) and t.refuel(0) then
      -- Consume items from the stack until the target minimum is reached, or until the stack is empty.
      while t.getItemCount() > 0 and t.getFuelLevel() < target_minimum do
        t.refuel(1)
      end
      
      -- If minimum target got reached, stop here.
      if t.getFuelLevel() >= target_minimum then
        return true
      end
    end
  end
  
  -- If we reach this line, it means not enough fuel was found.
  return false
end




-- #### Inventory functions ####

-- Search the first slot containing a specific kind of item.
-- @param array: Technical names of sought items.
--   If looking for a specific kind of item, provide a single entry array.
--   For instance: {"minecraft:log"} for a wood block.
--   If you provide multiple technical names, then the first one matching what's
--   in a slot will return (i.e. other technical names will get ignored).
-- @return int|nil: Slot number where the resource can be found (Starting from 1).
--   Nil if it was not found.
function searchForItemsSlot(item_technical_names)
  -- Loop over technical names until one is found.
  for key, item_technical_name in ipairs(item_technical_names) do
    -- Loop over item slots and search for the item.
    for i = 1, 16 do
      -- Get details about current slot.
      local data = t.getItemDetail(i)
      
      if data ~= nil and data.name == item_technical_name then
        return i
      end
    end
  end

  -- If we reach this line, it means no maching item was not found.
  return nil
end

-- Groups together same resources potentially scattered in the turtle's
-- inventory, optimizing the free space it has.
function groupInventoryResources()
  -- Loop over item slots and try grouping them.
  for i = 1, 15 do
    -- Get details about current slot.
    local data = t.getItemDetail(i)
    
    -- Act on slots that contain stuff only.
    if data ~= nil then
      local spare_space = t.getItemSpace(i)
      -- If current stack is not full, try completing it.
      if spare_space > 0 then
        -- Loop over remaining slots in search of the same resource as the
        -- current one, that we select here just for that.
        t.select(i)
        for j = (i + 1), 16 do
          local found_same_res = t.compareTo(j)
          
          -- The same resource was found, try grouping it.
          if found_same_res then
            t.select(j)
            t.transferTo(i)
            -- Restore selection to i for next loop.
            t.select(i)
          end
          
          -- No more space in current slot? Skip to next slot.
          if t.getItemSpace(i) <= 0 then
            break
          end
        end
      end
    end
  end
end

-- Counts the total number of items of given types the turtle contains.
-- @param array: Technical names of the item type to count intances.
--   If counting a specific kind of item, provide a single entry array.
--   For instance: {"minecraft:log"} for counting wood blocks.
function getTotalNumResources(item_technical_names)
  local total_count = 0

  -- Loop over item slots and count.
  for i = 1, 16 do
    -- Get details about current slot.
    local data = t.getItemDetail(i)
    
    -- Act on slots that contain stuff only.
    if data ~= nil and _in_array(data.name, item_technical_names) then
      total_count = total_count + t.getItemCount(i)
    end
  end
  
  return total_count
end




-- #### MAIN ####