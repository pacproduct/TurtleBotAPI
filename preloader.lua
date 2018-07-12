-- update pastebin at https://pastebin.com/zfVbYhca to load into the turtle
-- load with "pastebin get zfVbYhca"

if not http then
    print("Sorry, I need access to the interwebs to download stuffs.")
    return
end
 
 
 
-- Change this to "dev" if you want to download the last development snapshot.
-- Note that these versions may screw over your state files and be buggy, or at
-- least not was well tested as the release versions.
local default_branch = "master"
local branch = default_branch

local arg = {...}


if arg and arg[1] and not "update" == arg[1] then
  branch = arg[1]
  print("loading from branch "..branch.." instead of "..default_branch)
else
  print("loading from default branch "..default_branch)
end

local program_name = shell.getRunningProgram()
local url = "https://raw.githubusercontent.com/pacproduct/TurtleBotAPI/"..branch.."/install.lua"

print("updating loader")
print("from '" .. url .. "'...")

local request = http.get(url)
if request then
    local response = request.getResponseCode()
    if response == 200 then
        local script = request.readAll()
        local f = fs.open(program_name, "w")
        f.write(script)
        f.close()
        print("loader updated, bye")
    else
        print("Oh dear, something went wrong (bad HTTP response code " .. response .. ").")
        print("Please try again later; sorry for the inconvenience!")
        os.sleep(0.1)
    end
else
    print("Oh dear, something went wrong (did not get a request handle).")
    print("Please try again later; sorry for the inconvenience!")
    os.sleep(0.1)
end