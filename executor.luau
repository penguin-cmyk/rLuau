--!nocheck
local last_content = ""
while task.wait() do 
    if isfile("rLuau/output.luau") then 
        local content = readfile("rLuau/output.luau")
        if content ~= last_content then 
            local success,err = pcall(function()
                loadstring(content)()
            end)
            if not success then 
                print(err)
            end 
            last_content = content
        end 
    end 
end 
