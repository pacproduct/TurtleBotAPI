-- update pastebin at https://pastebin.com/zfVbYhca to load into the turtle
-- loaded from the preloader (and replaces it)
-- update by calling the script with argument "update" (updates itself from git)

if not http then
    print("Sorry, I need access to the interwebs to download stuffs.")
    return
end
 
-- Change this to "dev" if you want to download the last development snapshot.
-- Note that these versions may screw over your state files and be buggy, or at
-- least not was well tested as the release versions.
local default_branch = "master"
local branch = default_branch

local version = "0.0.4c"

local arg = {...}

local program_name = shell.getRunningProgram()

print("version "..version)
os.sleep(0.1)
 
-- Utility function to grab user input.
local function selfUpdate(branch)
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
end



if arg and arg[1] then
  if "update" == arg[1] then
    selfUpdate(branch)
    return
  end

  branch = arg[1]
  print("loading from branch "..branch.." instead of "..default_branch)
  
  if arg[2] and "update" == arg[2] then
      selfUpdate(branch)
      return
  end
  
else
  print("loading from default branch "..default_branch)
end

-- The list of files we can fetch.
local files = {
    {
        folder = "TBotAPI",
        name = "init.lua",
        url = "https://raw.githubusercontent.com/pacproduct/TurtleBotAPI/"..branch.."/api/TBotAPI.lua",
        minify = false
    },
    {
        folder = "",
        name = "LJ",
--        info = "This is a utility application for managing the API's internal state from the shell.",
        url = "https://raw.githubusercontent.com/pacproduct/TurtleBotAPI/"..branch.."/turtles/LumberJack.lua",
        ask = false,
        default = true,
        minify= false
    }
--[[,
    {
        folder = "programs",
        name = "lama-example",
        info = "This is an small example application, demonstrating how to write a resumable program using the API.",
        url = "https://github.com/fnuecke/lama/raw/"..branch.."/programs/lama-example",
        ask = true,
        default = false
    },
    {
        folder = "apis",
        name = "lama-src",
        info = "This is the full, non-minified version of the API. You only need this if you're interested in the implementation details.",
        url = "https://github.com/fnuecke/lama/raw/"..branch.."/apis/lama",
        ask = true,
        default = false
    }
]]
}
 
-- Utility function to grab user input.
local function prompt(default)
    if default then
        print("> [Y/n]")
    else
        print("> [y/N]")
    end
    while true do
        local event, code = os.pullEvent("key")
        if code == keys.enter then
            return default
        elseif code == keys.y then
            return true
        elseif code == keys.n then
            return false
        end
    end
end
 
-- Utility function for shrinking the code.
function minify(code)
    local lines = {}
    local inMultilineComment = false
    for line in string.gmatch(code, "[^\n]+") do
        line = line
        :gsub("^%s*(.-)%s*$", "%1")
        :gsub("^%-%-[^%[]*$", "")
        local keep = not inMultilineComment
        if inMultilineComment then
            if line == "]]" then
                inMultilineComment = false
            end
        elseif line:match("^%-%-%[%[") then
            inMultilineComment = true
            keep = false
        end
        if keep and line ~= "" then
            table.insert(lines, line)
        end
    end
    return table.concat(lines, "\n")
end
 
-- Interactively download all files.
for _, file in ipairs(files) do
    (function()
        if file.ask then
            print("Do you wish to install '" .. file.name .. "'?")
            if file.info then
                print("  " .. file.info)
            end
            if not prompt(file.default) then
                print("Skipping.")
                return
            end
        end
        fs.makeDir(file.folder)
        local path = fs.combine(file.folder, file.name)
 
        if fs.exists(path) then
        print("Warning: file '" .. path .. "' already exists. Overwriten!")
--[[
            print("Warning: file '" .. path .. "' already exists. Overwrite?")
            if not prompt(true) then
                print("Skipping.")
                return
            end
]]
        end
        print("Fetching '" .. file.name .. "'...")
        local request = http.get(file.url)
        if request then
            local response = request.getResponseCode()
            if response == 200 then
                local script = request.readAll()
                if file.minify then
                    script = minify(script)
                end
                local f = fs.open(path, "w")
                f.write(script)
                f.close()
                print("Done.")
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
    end)()
    print()
end
 
-- Prevent last key entry to be entered in the shell.
os.sleep(0.1)