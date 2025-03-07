local Types = {
    ["number"] = {
        "i8",
        "u8",
        "i16",
        "u16",
        "i32",
        "u32",
        "f32",
        "i64",
        "u64",
        "f64",
        "isize",
        "usize"
    },

    -- Primitive types
    ["string"] = { "&str" },
    ["boolean"] = {"bool"},
    ["userdata"] = {"rUserdata"},
    
    -- Core Roblox types
    ["Instance"] = {"rInstance"},
    ["BasePart"] = {"rBasePart"},
    ["Part"] = {"rPart"},
    ["Model"] = {"rModel"},
    ["Tool"] = {"rTool"},
    ["Humanoid"] = {"rHumanoid"},
    ["Player"] = { "rPlayer" },
    ["Teams"] = {"rTeams"},
    ["Workspace"] = {"rWorkspace"},
    
    -- Scripting types
    ["RBXScriptConnection"] = {"rScriptConnection"},
    ["RemoteEvent"] = {"rRemoteEvent"},
    ["RemoteFunction"] = {"rRemoteFunction"},
    ["BindableEvent"] = {"rBindableEvent"},
    ["BindableFunction"] = {"rBindableFunction"},
    ["Script"] = {"rScript"},
    ["LocalScript"] = {"rLocalScript"},
    
    -- Math types
    ["Vector2"] = {"rVector2"},
    ["Vector3"] = {"rVector3"},
    ["CFrame"] = {"rCFrame"},
    ["UDim"] = {"rUDim"},
    ["UDim2"] = {"rUDim2"},
    ["Rect"] = {"rRect"},
    
    -- Utility types
    ["Color3"] = {"rColor3"},
    ["BrickColor"] = {"rBrickColor"},
    ["NumberRange"] = {"rNumberRange"},
    ["NumberSequence"] = {"rNumberSequence"},
    ["ColorSequence"] = {"rColorSequence"},
    ["Region3"] = {"rRegion3"},
    ["Faces"] = {"rFaces"},
    ["Axes"] = {"rAxes"},
    
    -- Physics/raycasting
    ["Ray"] = {"rRay"},
    ["RaycastResult"] = {"rRaycastResult"},
    ["PhysicalProperties"] = {"rPhysicalProperties"},
    
    -- UI types
    ["GuiObject"] = {"rGuiObject"},
    ["TextLabel"] = {"rTextLabel"},
    ["Frame"] = {"rFrame"},
    ["ScreenGui"] = {"rScreenGui"},
    
    -- Animation
    ["AnimationTrack"] = {"rAnimationTrack"},
    
    -- Networking
    ["NetworkPeer"] = {"rNetworkPeer"},
    
    -- Lighting/environment
    ["Lighting"] = {"rLighting"},
    ["Sky"] = {"rSky"},
    
    -- Data types
    ["IntConstrainedValue"] = {"rIntConstrainedValue"},
    ["DoubleConstrainedValue"] = {"rDoubleConstrainedValue"},
    
    -- Function types
    ["(...any) -> ...any"] = {"rFunction"},
    
    -- Enum types
    ["Enum"] = {"rEnum"},
    ["EnumItem"] = {"rEnumItem"}
}

local Replacements = {
    ["Vector3:"] = "Vector3.",
    ["Vector2:"] = "Vector2.",
    ["CFrame:"] = "CFrame.",
    ["Instance:new"] = "Instance.new",
    ["Color3:"] = "Color3.",
    ["UDim2:"] = "UDim2.",
    ["UDim:"] = "UDim.",
    ["TweenInfo:new"] = "TweenInfo.new",
    ["Enum:"] = "Enum.",
    ["Region3:"] = "Region3.",

    ["task:"] = "task.",
    ["bit32:"] = "bit32.",
    ["string:"] = "string.", 
    ["table:"] = "table.",

    ["env:"] = "env."
} 

return {
    get_type = function(input: string)
        for index, tab in pairs(Types) do 
            if table.find(tab, input) then 
                return index
            end 
        end 
        return "unknown"
    end,
    Replacements = Replacements,
}
