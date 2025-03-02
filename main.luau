local translator = require("./helpers/handler")

local stdio = require("@lune/stdio")
local fs = require("@lune/fs")

local current_file_name = "main.rs"

while true do 
    local choice: number = stdio.prompt("select", " Select",{
        "Change filename",
        "Reload code"
    })
    if choice == 2 then 
        if not fs.isFile(current_file_name) then 
            continue
        end 
        local translated = translator.translate(fs.readFile(current_file_name))
        fs.writeFile("output.luau","--!nocheck\n"..translated);
    elseif choice == 1 then 
        local new_file_name: string = stdio.prompt("text", " Please give a new filename")
        current_file_name = new_file_name
    end 
end 
