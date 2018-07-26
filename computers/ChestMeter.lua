-- BatteryMeter script.
-- lists the batteries on th network and displays their status

-- pastebin get PHKiVJCB test

-- save launch command for autoreboot
local arg = {...}

local program_name = shell.getRunningProgram()

local autoload_string = "shell.run(\""..program_name.." "..table.concat(arg, " ").."\")"

local f = fs.open("startup", "w")
f.write(autoload_string)
f.close()


--[[

- somme de la capacité totale des batteries branchées (qui retournent "getEUCapacity" et "getEUStored"
- somme capacité restante
- % restant
- gérer les couleurs de texte (pour le %: rouge, jaune, vert)

- centrer le texte


]]


local tmp
local peripherals_names

local total_capacity
local total_stored
local percent

local network_error

local tmp_data

local monitor
local monitor_width, monitor_height
local pos_y
local battery_data_color





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

-- Rounds a Number to the closest integer.
-- @return int: Given number rounded up to the closest integer.
function round(num)
  return math.floor(num + 0.5)
end

function newLine(mon, pos_y)
  mon.scroll(1)
  mon.setCursorPos(1, pos_y)
end


while true do
  peripherals_names = peripheral.getNames()
  total_capacity = 0
  total_stored = 0
  percent = 0
  network_error = 0
  chest = false
  monitor = false
  

  for key, peripheral_name in ipairs(peripherals_names) do
    local tmp = peripheral.wrap(peripheral_name)
    
    if  _in_array("getMetadata", peripheral.getMethods(peripheral_name)) and "minecraft:chest" == tmp.getMetadata().name then
      chest = tmp
    end
    if _in_array("clearLine", peripheral.getMethods(peripheral_name)) then
      monitor = tmp
    end
  end
  
   
  if monitor then
    if chest then
      local total_slots = chest.size()
      local total_items = 0
      local total_filled_slots = 0
      for key, value in pairs(chest.list()) do
       --[[ 
        
        for key1, value1 in ipairs(value) do
        
        print(key1.."|"..value1)
        end]]
        
        -- print(key)
        -- print(value.count)
        total_filled_slots = total_filled_slots + 1
        total_items = total_items + value.count
      end
      
      local percent = round(total_items/(total_slots*64)*10000)/100
    
      local data_color = 2 -- orange
      if percent>50 then
        data_color = 32 -- vert
      end
      if percent<20 then
        data_color = 16384 -- rouge
      end
      
      
      monitor.setTextColor(battery_data_color)    
      --[[
      monitor.clear()
      newLine(monitor,5)
      monitor.write(round(total_filled_slots).." used")
      newLine(monitor,5)
      monitor.write("slots")
      newLine(monitor,5)
      monitor.write(total_items.." on")
      newLine(monitor,5)
      monitor.write(tostring(round(total_slots*64)))
      newLine(monitor,5)]]
      monitor.write(percent.."%")
      
    
    end
  else
    
  end
  
  --[[
  
  if monitor then
    print("monitor found")
    
    battery_data_color = 2 -- orange
    if percent>50 then
      battery_data_color = 32 -- vert
    end
    if percent<20 then
      battery_data_color = 16384 -- rouge
    end
    
    local scale_not_found = true
    local monitor_scale = 5
    
    while scale_not_found and monitor_scale>1 do
      monitor.setTextScale(monitor_scale) -- 1-5
      monitor_width, monitor_height = monitor.getSize() -- tied to TextScale!
      --print("width: "..monitor_width.." | height"..monitor_height)
      if monitor_height<4 or monitor_width<string.len("total capacity : "..total_capacity) then
        -- print(monitor_scale.." too high")
        monitor_scale = monitor_scale - 1
      else
        -- print(monitor_scale.." ok")
        scale_not_found = false
      end
      
    end
    monitor.setTextScale(monitor_scale)
    monitor_width, monitor_height = monitor.getSize()
    
    
    pos_y = monitor_height-(monitor_height-4)/2
        
    monitor.setBackgroundColor(32768)
    monitor.clear()
    newLine(monitor, pos_y)
    monitor.setTextColor(1)
    monitor.write("Total capacity : ")
    monitor.write(total_capacity)
    
    newLine(monitor, pos_y)
    monitor.setTextColor(1)
    monitor.write("Total stored   : ")
    monitor.setTextColor(battery_data_color)    
    monitor.write(total_stored)
    newLine(monitor, pos_y)
    monitor.setTextColor(1)
    monitor.write("Percent        : ")
    monitor.setTextColor(battery_data_color)
    monitor.write(percent)
    monitor.setTextColor(1)
    monitor.write("%")
    newLine(monitor, pos_y)
    
    if 1 == network_error then
      monitor.setTextColor(16384)
      monitor.setBackgroundColor(128)
      monitor.write("probable network error")
    end
    
  end
  ]]
  os.sleep(1)
  
end
