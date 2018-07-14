-- BatteryMeter script.
-- lists the batteries on th network and displays their status




--[[

- somme de la capacité totale des batteries branchées (qui retournent "getEUCapacity" et "getEUStored"
- somme capacité restante
- % restant
- gérer les couleurs de texte (pour le %: rouge, jaune, vert)



]]



--[[
getEUStored()
getEUCapacity()
peripheral.getNames()
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

function newLine(mon, mon_height)
  mon.scroll(1)
  mon.setCursorPos(1,mon_height)
end


while true do
  peripherals_names = peripheral.getNames()
  total_capacity = 0
  total_stored = 0
  percent = 0
  network_error = 0
  monitor = false

  for key, peripheral_name in ipairs(peripherals_names) do
    if _in_array("getEUCapacity", peripheral.getMethods(peripheral_name)) then
      tmp = peripheral.wrap(peripheral_name)
      if pcall(function () tmp_data = tmp.getEUCapacity() end) then 
        total_capacity = total_capacity + tmp_data
      else 
        network_error = 1
      end
      
      
      if pcall(function () tmp_data = tmp.getEUStored() end) then 
        total_stored = total_stored + tmp_data
      else 
        network_error = 1
      end
      
      -- total_capacity = total_capacity + tmp.getEUCapacity()
      -- total_stored = total_stored + tmp.getEUStored()
    end
    if _in_array("clearLine", peripheral.getMethods(peripheral_name)) then
      -- print("monitor found"..peripheral_name)
      monitor = peripheral.wrap(peripheral_name)
    end
    
  end
  if total_capacity>0 then
    percent = round((total_stored/total_capacity)*10000)/100
  end
  
  print("total capacity : "..total_capacity)
  print("total stored   : "..total_stored)
  print("percent        : "..percent.."%")
  
  if 1 == network_error then
    print("probable network error")
  end
  
  if monitor then
    print("monitor found")
    
    battery_data_color = 2
    if percent>80 then
      battery_data_color = 32
    end
    if percent<20 then
      battery_data_color = 16384
    end
    
    
    monitor.setTextScale(2) -- 1-5
    monitor_width, monitor_height = monitor.getSize() -- tied to TextScale!
    
    --[[
    if string.len(txt[i]) > X then
      print("\nTexte trop long !\nNe doit pas dépasser : "..X.."\nBloc concerné : "..txt[i].."\n")
      check = false
    end
    ]]
    
    monitor.setBackgroundColor(32768)
    monitor.clear()
    -- monitor.setTextScale(2)
    newLine(monitor, monitor_height)
    monitor.setTextColor(1)
    monitor.write("total capacity : ")
    -- monitor.setTextColor(battery_data_color)
    monitor.write(total_capacity)
    
    newLine(monitor, monitor_height)
    monitor.setTextColor(1)
    monitor.write("total stored   : ")
    monitor.setTextColor(battery_data_color)    
    monitor.write(total_stored)
    newLine(monitor, monitor_height)
    monitor.setTextColor(1)
    monitor.write("percent        : ")
    monitor.setTextColor(battery_data_color)
    monitor.write(percent)
    monitor.setTextColor(1)
    monitor.write("%")
    newLine(monitor, monitor_height)
    
    if 1 == network_error then
      monitor.setTextColor(16384)
      monitor.setBackgroundColor(128)
      monitor.write("probable network error")
    end
    
  end
  
  os.sleep(10)
  
end
