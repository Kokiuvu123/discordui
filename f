local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local UILibrary = {}

-- Function to create our UI
local function CreateCenteredUI()
    -- Check if a previous UI exists and remove it
    local existingUI = CoreGui:FindFirstChild("CenteredUI")
    if existingUI then
        existingUI:Destroy()
    end
    
    -- Remove any existing blur effects from Lighting
    for _, effect in pairs(game:GetService("Lighting"):GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") then
            if effect:GetAttribute("UIBlur") then
                effect:Destroy()
            end
        end
    end
    
    -- Create the main UI frame
    local mainUI = Instance.new("ScreenGui")
    mainUI.Name = "CenteredUI"
    mainUI.ResetOnSpawn = false
    mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create the main frame that will be centered
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10) -- Cambiado de 30,30,30 a un color casi negro
    frame.BackgroundTransparency = 0.5-- Menos transparencia para un aspecto más oscuro
    frame.BorderSizePixel = 0

    -- Add blur script
    local blurScript = Instance.new("LocalScript")
    blurScript.Name = "BlurEffect"
    blurScript.Parent = frame

    blurScript.Source = [[
        --// Not original source / Modified by biggaboy212
        --// Add under any frame to apply

        --// User Graphics quality must be greater than or equal to 8 (Depending on your system possibly 7)

        local RunService = game:GetService('RunService')
        local HS = game:GetService('HttpService')
        local camera = workspace.CurrentCamera
        local MTREL = "SmoothPlastic"
        local binds = {}
        local root = Instance.new('Folder', camera)
        local wedgeguid = HS:GenerateGUID(true)
        root.Name = HS:GenerateGUID(true)

        -- Usar directamente el frame padre en lugar de crear uno nuevo
        local frame = script.Parent

        do
            local function IsNotNaN(x)
                return x == x
            end
            local continue = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
            while not continue do
                RunService.RenderStepped:wait()
                continue = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
            end
        end

        local DrawQuad; do
            local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
            local sz = 0.2

            function DrawTriangle(v1, v2, v3, p0, p1)
                local s1 = (v1 - v2).magnitude
                local s2 = (v2 - v3).magnitude
                local s3 = (v3 - v1).magnitude
                local smax = max(s1, s2, s3)
                local A, B, C
                if s1 == smax then
                    A, B, C = v1, v2, v3
                elseif s2 == smax then
                    A, B, C = v2, v3, v1
                elseif s3 == smax then
                    A, B, C = v3, v1, v2
                end

                local para = ( (B-A).x*(C-A).x + (B-A).y*(C-A).y + (B-A).z*(C-A).z ) / (A-B).magnitude
                local perp = sqrt((C-A).magnitude^2 - para*para)
                local dif_para = (A - B).magnitude - para

                local st = CFrame.new(B, A)
                local za = CFrame.Angles(pi/2,0,0)

                local cf0 = st

                local Top_Look = (cf0 * za).lookVector
                local Mid_Point = A + CFrame.new(A, B).lookVector * para
                local Needed_Look = CFrame.new(Mid_Point, C).lookVector
                local dot = Top_Look.x*Needed_Look.x + Top_Look.y*Needed_Look.y + Top_Look.z*Needed_Look.z

                local ac = CFrame.Angles(0, 0, acos(dot))

                cf0 = cf0 * ac
                if ((cf0 * za).lookVector - Needed_Look).magnitude > 0.01 then
                    cf0 = cf0 * CFrame.Angles(0, 0, -2*acos(dot))
                end
                cf0 = cf0 * CFrame.new(0, perp/2, -(dif_para + para/2))

                local cf1 = st * ac * CFrame.Angles(0, pi, 0)
                if ((cf1 * za).lookVector - Needed_Look).magnitude > 0.01 then
                    cf1 = cf1 * CFrame.Angles(0, 0, 2*acos(dot))
                end
                cf1 = cf1 * CFrame.new(0, perp/2, dif_para/2)

                if not p0 then
                    p0 = Instance.new('Part')
                    p0.FormFactor = 'Custom'
                    p0.TopSurface = 0
                    p0.BottomSurface = 0
                    p0.Anchored = true
                    p0.CanCollide = false
                    p0.CastShadow = false
                    p0.Material = MTREL
                    p0.Size = Vector3.new(sz, sz, sz)
                    p0.Name = HS:GenerateGUID(true)
                    local mesh = Instance.new('SpecialMesh', p0)
                    mesh.MeshType = 2
                    mesh.Name = wedgeguid
                end
                p0[wedgeguid].Scale = Vector3.new(0, perp/sz, para/sz)
                p0.CFrame = cf0

                if not p1 then
                    p1 = p0:clone()
                end
                p1[wedgeguid].Scale = Vector3.new(0, perp/sz, dif_para/sz)
                p1.CFrame = cf1

                return p0, p1
            end

            function DrawQuad(v1, v2, v3, v4, parts)
                parts[1], parts[2] = DrawTriangle(v1, v2, v3, parts[1], parts[2])
                parts[3], parts[4] = DrawTriangle(v3, v2, v4, parts[3], parts[4])
            end
        end

        if binds[frame] then
            return binds[frame].parts
        end

        local parts = {}
        local f = Instance.new('Folder', root)
        f.Name = HS:GenerateGUID(true)

        local parents = {}
        do
            local function add(child)
                if child and child:IsA('GuiObject') then
                    parents[#parents + 1] = child
                    add(child.Parent)
                end
            end
            add(frame)
        end

        local function IsVisible(instance)
            while instance do
                if instance:IsA("GuiObject") then
                    if not instance.Visible then
                        return false
                    end
                elseif instance:IsA("ScreenGui") then
                    if not instance.Enabled then
                        return false
                    end
                    break
                end
                instance = instance.Parent
            end
            return true
        end

        local function UpdateOrientation(fetchProps)
            if not IsVisible(frame) then
                for _, pt in pairs(parts) do
                    pt.Parent = nil
                end
                return
            end

            local properties = {
                Transparency = 0.98,
                BrickColor = BrickColor.new('Institutional white'),
                Reflectance = 0.2
            }
            local zIndex = 1 - 0.05*frame.ZIndex

            local tl, br = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
            local tr, bl = Vector2.new(br.x, tl.y), Vector2.new(tl.x, br.y)
            do
                local rot = 0;
                for _, v in ipairs(parents) do
                    rot = rot + v.Rotation
                end
                if rot ~= 0 and rot%180 ~= 0 then
                    local mid = tl:lerp(br, 0.5)
                    local s, c = math.sin(math.rad(rot)), math.cos(math.rad(rot))
                    local vec = tl
                    tl = Vector2.new(c*(tl.x - mid.x) - s*(tl.y - mid.y), s*(tl.x - mid.x) + c*(tl.y - mid.y)) + mid
                    tr = Vector2.new(c*(tr.x - mid.x) - s*(tr.y - mid.y), s*(tr.x - mid.x) + c*(tr.y - mid.y)) + mid
                    bl = Vector2.new(c*(bl.x - mid.x) - s*(bl.y - mid.y), s*(bl.x - mid.x) + c*(bl.y - mid.y)) + mid
                    br = Vector2.new(c*(br.x - mid.x) - s*(br.y - mid.y), s*(br.x - mid.x) + c*(br.y - mid.y)) + mid
                end
            end
            DrawQuad(
                camera:ScreenPointToRay(tl.x, tl.y, zIndex).Origin, 
                camera:ScreenPointToRay(tr.x, tr.y, zIndex).Origin, 
                camera:ScreenPointToRay(bl.x, bl.y, zIndex).Origin, 
                camera:ScreenPointToRay(br.x, br.y, zIndex).Origin, 
                parts
            )
            if fetchProps then
                for _, pt in pairs(parts) do
                    pt.Parent = f
                end
                for propName, propValue in pairs(properties) do
                    for _, pt in pairs(parts) do
                        pt[propName] = propValue
                    end
                end
            end
        end

        UpdateOrientation(true)
        RunService:BindToRenderStep(HS:GenerateGUID(true), 2000, UpdateOrientation)
    ]]
    
    -- Crear un efecto de blur local para la UI
    local blurFrame = Instance.new("Frame")
    blurFrame.Name = "BlurBackground"
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.Position = UDim2.new(0, 0, 0, 0)
    blurFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5) -- Cambiado a un color casi negro
    blurFrame.BackgroundTransparency = 0.25-- Ajustado para mantener algo de transparencia
    blurFrame.BorderSizePixel = 0
    blurFrame.ZIndex = -1
    blurFrame.Parent = frame
    
    -- Añadir un efecto de gradiente para simular blur
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0.05),
        NumberSequenceKeypoint.new(1, 0.1)
    })
    uiGradient.Parent = blurFrame
    
    -- Añadir esquinas redondeadas al fondo de blur
    local blurCorner = Instance.new("UICorner")
    blurCorner.CornerRadius = UDim.new(0, 8)
    blurCorner.Parent = blurFrame
    
    -- Add some rounded corners to main frame
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = frame
    
    -- Add a title to the UI
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Centered UI"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.Parent = frame
    
    -- Make the frame draggable with smooth animation
    local isDragging = false
    local isResizing = false
    local resizeType = nil
    local dragInput
    local dragStart
    local startPos
    local startSize
    local currentTween
    
    -- Animation settings
    local tweenInfo = TweenInfo.new(
        0.1,                    -- Time (seconds)
        Enum.EasingStyle.Quad,  -- Easing style
        Enum.EasingDirection.Out -- Easing direction
    )
    
    local resizeHandleSize = 10

    

    local function createResizeHandle(name, position, size)
        local handle = Instance.new("TextButton")
        handle.Name = name
        handle.Position = position
        handle.Size = size
        handle.BackgroundTransparency = 1
        handle.Text = ""
        handle.ZIndex = 10
        handle.Parent = frame
        return handle
    end

    local rightHandle = createResizeHandle("RightHandle", UDim2.new(1, -resizeHandleSize, 0, resizeHandleSize), UDim2.new(0, resizeHandleSize, 1, -resizeHandleSize*2))
    local leftHandle = createResizeHandle("LeftHandle", UDim2.new(0, 0, 0, resizeHandleSize), UDim2.new(0, resizeHandleSize, 1, -resizeHandleSize*2))
    local topHandle = createResizeHandle("TopHandle", UDim2.new(0, resizeHandleSize, 0, 0), UDim2.new(1, -resizeHandleSize*2, 0, resizeHandleSize))
    local bottomHandle = createResizeHandle("BottomHandle", UDim2.new(0, resizeHandleSize, 1, -resizeHandleSize), UDim2.new(1, -resizeHandleSize*2, 0, resizeHandleSize))

    local topLeftHandle = createResizeHandle("TopLeftHandle", UDim2.new(0, 0, 0, 0), UDim2.new(0, resizeHandleSize, 0, resizeHandleSize))
    local topRightHandle = createResizeHandle("TopRightHandle", UDim2.new(1, -resizeHandleSize, 0, 0), UDim2.new(0, resizeHandleSize, 0, resizeHandleSize))
    local bottomLeftHandle = createResizeHandle("BottomLeftHandle", UDim2.new(0, 0, 1, -resizeHandleSize), UDim2.new(0, resizeHandleSize, 0, resizeHandleSize))
    local bottomRightHandle = createResizeHandle("BottomRightHandle", UDim2.new(1, -resizeHandleSize, 1, -resizeHandleSize), UDim2.new(0, resizeHandleSize, 0, resizeHandleSize))
    
    local function updateResizeHandles()
        rightHandle.Position = UDim2.new(1, -resizeHandleSize, 0, resizeHandleSize)
        leftHandle.Position = UDim2.new(0, 0, 0, resizeHandleSize)
        topHandle.Position = UDim2.new(0, resizeHandleSize, 0, 0)
        bottomHandle.Position = UDim2.new(0, resizeHandleSize, 1, -resizeHandleSize)
        
        topLeftHandle.Position = UDim2.new(0, 0, 0, 0)
        topRightHandle.Position = UDim2.new(1, -resizeHandleSize, 0, 0)
        bottomLeftHandle.Position = UDim2.new(0, 0, 1, -resizeHandleSize)
        bottomRightHandle.Position = UDim2.new(1, -resizeHandleSize, 1, -resizeHandleSize)
    end

    local function updateCursor(handle, cursorType)
        handle.MouseEnter:Connect(function()
            UserInputService.MouseIcon = cursorType
        end)
        
        handle.MouseLeave:Connect(function()
            if not isResizing then
                UserInputService.MouseIcon = ""
            end
        end)
    end

    
    updateCursor(rightHandle, "rbxasset://SystemCursors/SizeEW")
    updateCursor(leftHandle, "rbxasset://SystemCursors/SizeEW")
    updateCursor(topHandle, "rbxasset://SystemCursors/SizeNS")
    updateCursor(bottomHandle, "rbxasset://SystemCursors/SizeNS")
    updateCursor(topLeftHandle, "rbxasset://SystemCursors/SizeNWSE")
    updateCursor(bottomRightHandle, "rbxasset://SystemCursors/SizeNWSE")
    updateCursor(topRightHandle, "rbxasset://SystemCursors/SizeNESW")
    updateCursor(bottomLeftHandle, "rbxasset://SystemCursors/SizeNESW")

    -- Ahora que todos los handles están creados, podemos llamar a updateResizeHandles
    updateResizeHandles()

    local function updateDrag(input)
        if not isDragging then return end
        
        local delta = input.Position - dragStart
        local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        -- Cancel any existing tween
        if currentTween then
            currentTween:Cancel()
        end
        
        -- Create and play the tween
        currentTween = TweenService:Create(frame, tweenInfo, {Position = targetPosition})
        currentTween:Play()
        
        -- Actualizar inmediatamente la posición de los handles sin esperar a que termine el tween
        frame.Position = targetPosition
        updateResizeHandles()
    end

    local function updateResize(input)
        if not isResizing then return end

        local delta = input.Position - dragStart
        local newSize = startSize
        local newPosition = startPos
        
        -- Minimum size constraints
        local minWidth = 300
        local minHeight = 200
        
        if resizeType == "right" then
            newSize = UDim2.new(0, math.max(minWidth, startSize.X.Offset + delta.X), startSize.Y.Scale, startSize.Y.Offset)
        elseif resizeType == "left" then
            local widthChange = math.min(startSize.X.Offset - minWidth, delta.X)
            newSize = UDim2.new(0, startSize.X.Offset - widthChange, startSize.Y.Scale, startSize.Y.Offset)
            newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + widthChange, startPos.Y.Scale, startPos.Y.Offset)
        elseif resizeType == "top" then
            local heightChange = math.min(startSize.Y.Offset - minHeight, delta.Y)
            newSize = UDim2.new(startSize.X.Scale, startSize.X.Offset, 0, startSize.Y.Offset - heightChange)
            newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + heightChange)
        elseif resizeType == "bottom" then
            newSize = UDim2.new(startSize.X.Scale, startSize.X.Offset, 0, math.max(minHeight, startSize.Y.Offset + delta.Y))
        elseif resizeType == "topLeft" then
            local widthChange = math.min(startSize.X.Offset - minWidth, delta.X)
            local heightChange = math.min(startSize.Y.Offset - minHeight, delta.Y)
            newSize = UDim2.new(0, startSize.X.Offset - widthChange, 0, startSize.Y.Offset - heightChange)
            newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + widthChange, startPos.Y.Scale, startPos.Y.Offset + heightChange)
        elseif resizeType == "topRight" then
            local heightChange = math.min(startSize.Y.Offset - minHeight, delta.Y)
            newSize = UDim2.new(0, math.max(minWidth, startSize.X.Offset + delta.X), 0, startSize.Y.Offset - heightChange)
            newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + heightChange)
        elseif resizeType == "bottomLeft" then
            local widthChange = math.min(startSize.X.Offset - minWidth, delta.X)
            newSize = UDim2.new(0, startSize.X.Offset - widthChange, 0, math.max(minHeight, startSize.Y.Offset + delta.Y))
            newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + widthChange, startPos.Y.Scale, startPos.Y.Offset)
        elseif resizeType == "bottomRight" then
            newSize = UDim2.new(0, math.max(minWidth, startSize.X.Offset + delta.X), 0, math.max(minHeight, startSize.Y.Offset + delta.Y))
        end
        
        -- Cancel any existing tween
        if currentTween then
            currentTween:Cancel()
        end
        
        -- Create and play the tween for size and position
        currentTween = TweenService:Create(frame, tweenInfo, {Size = newSize, Position = newPosition})
        currentTween:Play()

        currentTween.Completed:Connect(function()
            updateResizeHandles()
        end)
    end

    local function setupResizeHandler(handle, resizeDir)
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = true
                resizeType = resizeDir
                dragStart = input.Position
                startSize = frame.Size
                startPos = frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isResizing = false
                        resizeType = nil
                        UserInputService.MouseIcon = ""
                        
                        -- Actualizar startSize y startPos después de redimensionar
                        startSize = frame.Size
                        startPos = frame.Position
                        
                        -- Actualizar las posiciones de las manijas después del redimensionamiento
                        updateResizeHandles()
                    end
                end)
            end
        end)
    end

    setupResizeHandler(rightHandle, "right")
    setupResizeHandler(leftHandle, "left")
    setupResizeHandler(topHandle, "top")
    setupResizeHandler(bottomHandle, "bottom")
    setupResizeHandler(topLeftHandle, "topLeft")
    setupResizeHandler(topRightHandle, "topRight")
    setupResizeHandler(bottomLeftHandle, "bottomLeft")
    setupResizeHandler(bottomRightHandle, "bottomRight")
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Simplified approach: Only start dragging if we're clicking on the title area
            -- This avoids the need to check for specific targets
            local mouseY = input.Position.Y - frame.AbsolutePosition.Y
            
            -- Only allow dragging when clicking in the title bar area (top 40 pixels)
            if mouseY <= 40 then
                isDragging = true
                dragStart = input.Position
                startPos = frame.Position
                startSize = frame.Size
                
                -- Guardar el tamaño actual en lugar de usar valores fijos
                local currentSize = frame.Size
                
                -- Modificar el efecto "pickup" para usar el tamaño actual + un pequeño incremento
                local pickupTween = TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Size = UDim2.new(0, currentSize.X.Offset + 5, 0, currentSize.Y.Offset + 5)})
                pickupTween:Play()
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                        
                        -- Actualizar startSize y startPos después de soltar
                        startSize = frame.Size
                        startPos = frame.Position
                        
                        -- Actualizar las posiciones de las manijas después del arrastre
                        updateResizeHandles()
                        
                        -- Importante: Reiniciar el estado de arrastre y redimensionamiento
                        isDragging = false
                        isResizing = false
                        resizeType = nil
                        dragInput = nil
                    end
                end)
            end
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            updateDrag(input)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and isResizing then
            updateResize(input)
        end
    end)

    -- Asegurarse de que los handles se actualicen cuando la ventana cambie de tamaño o posición
    frame:GetPropertyChangedSignal("Size"):Connect(updateResizeHandles)
    frame:GetPropertyChangedSignal("Position"):Connect(updateResizeHandles)
    
    -- Add a shadow effect for better visual appeal
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4) -- Slight offset
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.ZIndex = -2
    shadow.Image = "rbxassetid://1316045217" -- Shadow image
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = frame
    
    -- Parent the frame to the ScreenGui
    frame.Parent = mainUI
    
    -- Parent the ScreenGui to CoreGui
    mainUI.Parent = CoreGui
    
    -- Crear un efecto de blur local para la UI usando capas
    for i = 1, 3 do
        local blurLayer = Instance.new("Frame")
        blurLayer.Name = "BlurLayer" .. i
        blurLayer.Size = UDim2.new(1, 0, 1, 0)
        blurLayer.Position = UDim2.new(0, 0, 0, 0)
        blurLayer.BackgroundTransparency = 0.7 + (i * 0.05) -- Transparencia progresiva para efecto de profundidad
        blurLayer.BackgroundColor3 = Color3.fromRGB(5, 5, 5) -- Color casi negro
        blurLayer.ZIndex = -i - 2
        blurLayer.BorderSizePixel = 0
        
        local layerCorner = Instance.new("UICorner")
        layerCorner.CornerRadius = UDim.new(0, 8)
        layerCorner.Parent = blurLayer
        
        blurLayer.Parent = frame
    end
    
    return mainUI
end

function UILibrary.CreateWindow(options)
    options = options or {}
    local title = options.Title or "UI Library"
    local size = options.Size or UDim2.new(0, 500, 0, 350)
    local kavoStyle = options.KavoStyle ~= nil and options.KavoStyle or true -- Default to Kavo style (tabs on left)
    
    local Window = {}
    local ui = CreateCenteredUI()
    
    -- Modify the main frame
    local mainFrame = ui:FindFirstChild("MainFrame")
    mainFrame.Size = size
    mainFrame:FindFirstChild("TitleLabel").Text = title
    
    
    -- Create tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.BackgroundTransparency = 0.9
    tabsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = mainFrame
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame

    local function updateUILayout()
        if kavoStyle then
            -- Kavo style (tabs on left)
            tabsContainer.Size = UDim2.new(0.25, 0, 1, -40) -- Leave space for title
            tabsContainer.Position = UDim2.new(0, 0, 0, 40)
            
            contentContainer.Size = UDim2.new(0.75, 0, 1, -40)
            contentContainer.Position = UDim2.new(0.25, 0, 0, 40)
        else
            -- Tabs on top
            tabsContainer.Size = UDim2.new(1, 0, 0, 30)
            tabsContainer.Position = UDim2.new(0, 0, 0, 40)
            
            contentContainer.Size = UDim2.new(1, 0, 1, -70)
            contentContainer.Position = UDim2.new(0, 0, 0, 70)
        end
    end
    
    updateUILayout()

    -- Create tab buttons container
    local tabButtonsContainer = Instance.new("ScrollingFrame")
    tabButtonsContainer.Name = "TabButtonsContainer"
    tabButtonsContainer.Size = UDim2.new(1, 0, 1, 0)
    tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabButtonsContainer.BackgroundTransparency = 1
    tabButtonsContainer.BorderSizePixel = 0
    tabButtonsContainer.ScrollBarThickness = 4
    tabButtonsContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    tabButtonsContainer.ScrollBarImageTransparency = 0.5
    tabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabButtonsContainer.Parent = tabsContainer
    
    -- Create UI list layout for tab buttons
    local tabButtonsLayout = Instance.new("UIListLayout")
    tabButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabButtonsLayout.Padding = UDim.new(0, 5)
    tabButtonsLayout.Parent = tabButtonsContainer

    local function updateTabButtonsLayout()
        if kavoStyle then
            -- Vertical layout for Kavo style
            tabButtonsLayout.FillDirection = Enum.FillDirection.Vertical
            tabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
            tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            -- Horizontal layout for tabs on top
            tabButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
            tabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
            tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        end
    end

    updateTabButtonsLayout()
    
    -- Create padding for tab buttons
    local tabButtonsPadding = Instance.new("UIPadding")
    tabButtonsPadding.PaddingTop = UDim.new(0, 5)
    tabButtonsPadding.PaddingLeft = UDim.new(0, 5)
    tabButtonsPadding.PaddingRight = UDim.new(0, 5)
    tabButtonsPadding.Parent = tabButtonsContainer
    
    -- Store tabs
    local tabs = {}
    local activeTab = nil
    
    -- Function to create a new tab
    function Window:AddTab(options)
        options = options or {}
        local tabTitle = options.Title or "Tab"
        
        -- Create tab button
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabTitle .. "Button"
        tabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tabButton.BackgroundTransparency = 0.5
        tabButton.Text = tabTitle
        tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButton.Font = Enum.Font.GothamSemibold
        tabButton.TextSize = 14
        tabButton.BorderSizePixel = 0
        tabButton.Parent = tabButtonsContainer
        
        -- Update tab button size based on style
        if kavoStyle then
            tabButton.Size = UDim2.new(1, 0, 0, 30)
        else
            tabButton.Size = UDim2.new(0, 100, 1, 0)
            tabButton.AutomaticSize = Enum.AutomaticSize.X
        end
        
        -- Add rounded corners to tab button
        local tabButtonCorner = Instance.new("UICorner")
        tabButtonCorner.CornerRadius = UDim.new(0, 6)
        tabButtonCorner.Parent = tabButton
        
        -- Create tab content frame
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabTitle .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        tabContent.ScrollBarImageTransparency = 0.5
        tabContent.Visible = false
        tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.Parent = contentContainer
        
        -- Create UI list layout for tab content
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 10)
        contentLayout.Parent = tabContent
        
        -- Create padding for tab content
        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingTop = UDim.new(0, 10)
        contentPadding.PaddingLeft = UDim.new(0, 10)
        contentPadding.PaddingRight = UDim.new(0, 10)
        contentPadding.PaddingBottom = UDim.new(0, 10)
        contentPadding.Parent = tabContent
        
        -- Tab object
        local Tab = {}
        
        -- Function to add a paragraph
        function Tab:AddParagraph(options)
            options = options or {}
            local title = options.Title or "Paragraph"
            local content = options.Content or ""
            
            -- Create paragraph frame
            local paragraphFrame = Instance.new("Frame")
            paragraphFrame.Name = "ParagraphFrame"
            paragraphFrame.Size = UDim2.new(1, 0, 0, 0)
            paragraphFrame.AutomaticSize = Enum.AutomaticSize.Y
            paragraphFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            paragraphFrame.BackgroundTransparency = 0.5
            paragraphFrame.BorderSizePixel = 0
            paragraphFrame.Parent = tabContent
            
            -- Add rounded corners
            local paragraphCorner = Instance.new("UICorner")
            paragraphCorner.CornerRadius = UDim.new(0, 6)
            paragraphCorner.Parent = paragraphFrame
            
            -- Create title label
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Name = "TitleLabel"
            titleLabel.Size = UDim2.new(1, 0, 0, 25)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 14
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = paragraphFrame
            
            -- Create content label
            local contentLabel = Instance.new("TextLabel")
            contentLabel.Name = "ContentLabel"
            contentLabel.Size = UDim2.new(1, 0, 0, 0)
            contentLabel.Position = UDim2.new(0, 0, 0, 25)
            contentLabel.BackgroundTransparency = 1
            contentLabel.Text = content
            contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            contentLabel.Font = Enum.Font.Gotham
            contentLabel.TextSize = 12
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextYAlignment = Enum.TextYAlignment.Top
            contentLabel.TextWrapped = true
            contentLabel.AutomaticSize = Enum.AutomaticSize.Y
            contentLabel.Parent = paragraphFrame
            
            -- Add padding
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 5)
            padding.PaddingLeft = UDim.new(0, 10)
            padding.PaddingRight = UDim.new(0, 10)
            padding.PaddingBottom = UDim.new(0, 10)
            padding.Parent = paragraphFrame
            
            return paragraphFrame
        end
        
        -- Function to add a button
        function Tab:AddButton(options)
            options = options or {}
            local title = options.Title or "Button"
            local description = options.Description or ""
            local callback = options.Callback or function() end
            
            -- Create button frame
            local buttonFrame = Instance.new("Frame")
            buttonFrame.Name = "ButtonFrame"
            buttonFrame.Size = UDim2.new(1, 0, 0, 0)
            buttonFrame.AutomaticSize = Enum.AutomaticSize.Y
            buttonFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            buttonFrame.BackgroundTransparency = 0.5
            buttonFrame.BorderSizePixel = 0
            buttonFrame.Parent = tabContent
            
            -- Add rounded corners
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 6)
            buttonCorner.Parent = buttonFrame
            
            -- Create title label
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Name = "TitleLabel"
            titleLabel.Size = UDim2.new(1, -110, 0, 25)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 14
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = buttonFrame
            
            -- Create description label
            local descriptionLabel = Instance.new("TextLabel")
            descriptionLabel.Name = "DescriptionLabel"
            descriptionLabel.Size = UDim2.new(1, -110, 0, 0)
            descriptionLabel.Position = UDim2.new(0, 0, 0, 25)
            descriptionLabel.BackgroundTransparency = 1
            descriptionLabel.Text = description
            descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            descriptionLabel.Font = Enum.Font.Gotham
            descriptionLabel.TextSize = 12
            descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
            descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
            descriptionLabel.TextWrapped = true
            descriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
            descriptionLabel.Parent = buttonFrame
            
            -- Create button
            local button = Instance.new("TextButton")
            button.Name = "Button"
            button.Size = UDim2.new(0, 100, 0, 30)
            button.Position = UDim2.new(1, -105, 0, 10)
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            button.BackgroundTransparency = 0.3
            button.BorderSizePixel = 0
            button.Text = "Execute"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamSemibold
            button.TextSize = 12
            button.Parent = buttonFrame
            
            -- Add rounded corners to button
            local buttonElementCorner = Instance.new("UICorner")
            buttonElementCorner.CornerRadius = UDim.new(0, 4)
            buttonElementCorner.Parent = button
            
            -- Add padding
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 5)
            padding.PaddingLeft = UDim.new(0, 10)
            padding.PaddingRight = UDim.new(0, 10)
            padding.PaddingBottom = UDim.new(0, 10)
            padding.Parent = buttonFrame
            
            -- Button click event
            button.MouseButton1Click:Connect(function()
                callback()
            end)
            
            -- Hover effect
            button.MouseEnter:Connect(function()
                game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end)
            
            button.MouseLeave:Connect(function()
                game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
            end)
            
            return buttonFrame
        end
        
        -- Add tab to tabs table
        tabs[tabTitle] = {
            Button = tabButton,
            Content = tabContent,
            Object = Tab
        }
        
        -- Tab button click event
        tabButton.MouseButton1Click:Connect(function()
            -- Hide all tab contents
            for _, tab in pairs(tabs) do
                tab.Content.Visible = false
                game:GetService("TweenService"):Create(tab.Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    TextColor3 = Color3.fromRGB(200, 200, 200)
                }):Play()
            end
            
            -- Show selected tab content
            tabContent.Visible = true
            game:GetService("TweenService"):Create(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            
            activeTab = tabTitle
        end)
        
        -- If this is the first tab, make it active
        if activeTab == nil then
            activeTab = tabTitle
            tabContent.Visible = true
            game:GetService("TweenService"):Create(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end
        
        return Tab
    end

    function Window:ToggleStyle()
        kavoStyle = not kavoStyle
        
        -- Update UI layout
        updateUILayout()
        updateTabButtonsLayout()
        
        -- Update all tab buttons size
        for _, tab in pairs(tabs) do
            if kavoStyle then
                tab.Button.Size = UDim2.new(1, 0, 0, 30)
                tab.Button.AutomaticSize = Enum.AutomaticSize.None
            else
                tab.Button.Size = UDim2.new(0, 100, 1, 0)
                tab.Button.AutomaticSize = Enum.AutomaticSize.X
            end
        end
        
        return kavoStyle
    end
    
    function Window:GetStyle()
        return kavoStyle
    end

    function Window:AddSettingsTab()
        local settingsTab = self:AddTab({Title = "Settings"})
        
        -- Add style toggle
        local styleToggleFrame = Instance.new("Frame")
        styleToggleFrame.Name = "StyleToggleFrame"
        styleToggleFrame.Size = UDim2.new(1, 0, 0, 40)
        styleToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        styleToggleFrame.BackgroundTransparency = 0.5
        styleToggleFrame.BorderSizePixel = 0
        -- Fix: Use the correct path to the tab content
        styleToggleFrame.Parent = tabs["Settings"].Content
        
        -- Add rounded corners
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = styleToggleFrame
        
        -- Create label
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "ToggleLabel"
        toggleLabel.Size = UDim2.new(0, 200, 1, 0)
        toggleLabel.Position = UDim2.new(0, 10, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Text = "Kavo Style (Tabs on Left)"
        toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleLabel.Font = Enum.Font.GothamSemibold
        toggleLabel.TextSize = 14
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = styleToggleFrame
        
        -- Create toggle button
        local toggleButton = Instance.new("Frame")
        toggleButton.Name = "ToggleButton"
        toggleButton.Size = UDim2.new(0, 40, 0, 20)
        toggleButton.Position = UDim2.new(1, -50, 0.5, 0)
        toggleButton.AnchorPoint = Vector2.new(0, 0.5)
        toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        toggleButton.BorderSizePixel = 0
        toggleButton.Parent = styleToggleFrame
        
        -- Add rounded corners to toggle button
        local toggleButtonCorner = Instance.new("UICorner")
        toggleButtonCorner.CornerRadius = UDim.new(1, 0)
        toggleButtonCorner.Parent = toggleButton
        
        -- Create toggle indicator
        local toggleIndicator = Instance.new("Frame")
        toggleIndicator.Name = "Indicator"
        toggleIndicator.Size = UDim2.new(0, 16, 0, 16)
        toggleIndicator.Position = UDim2.new(kavoStyle and 1 or 0, kavoStyle and -18 or 2, 0.5, 0)
        toggleIndicator.AnchorPoint = Vector2.new(0, 0.5)
        toggleIndicator.BackgroundColor3 = kavoStyle and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
        toggleIndicator.BorderSizePixel = 0
        toggleIndicator.Parent = toggleButton
        
        -- Add rounded corners to indicator
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(1, 0)
        indicatorCorner.Parent = toggleIndicator
        
        -- Update toggle appearance
        local function updateToggle()
            toggleLabel.Text = kavoStyle and "Kavo Style (Tabs on Left)" or "Tabs on Top"
            
            -- Animate the toggle
            game:GetService("TweenService"):Create(toggleIndicator, TweenInfo.new(0.2), {
                Position = UDim2.new(kavoStyle and 1 or 0, kavoStyle and -18 or 2, 0.5, 0),
                BackgroundColor3 = kavoStyle and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
            }):Play()
            
            game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(0.2), {
                BackgroundColor3 = kavoStyle and Color3.fromRGB(0, 120, 180) or Color3.fromRGB(40, 40, 40)
            }):Play()
        end
        
        -- Make toggle clickable
        toggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:ToggleStyle()
                updateToggle()
            end
        end)
        
        -- Also make label clickable
        toggleLabel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:ToggleStyle()
                updateToggle()
            end
        end)
        
        -- Make the entire frame clickable
        styleToggleFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:ToggleStyle()
                updateToggle()
            end
        end)
        
        return settingsTab
    end

    

    -- Function to create a dialog
    function Window:Dialog(options)
        options = options or {}
        local title = options.Title or "Dialog"
        local content = options.Content or ""
        local buttons = options.Buttons or {}
        
        -- Create dialog background (overlay)
        local dialogBackground = Instance.new("Frame")
        dialogBackground.Name = "DialogBackground"
        dialogBackground.Size = UDim2.new(1, 0, 1, 0)
        dialogBackground.Position = UDim2.new(0, 0, 0, 0)
        dialogBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        dialogBackground.BackgroundTransparency = 0.5
        dialogBackground.BorderSizePixel = 0
        dialogBackground.ZIndex = 10
        dialogBackground.Parent = ui
        
        -- Create dialog frame
        local dialogFrame = Instance.new("Frame")
        dialogFrame.Name = "DialogFrame"
        dialogFrame.Size = UDim2.new(0, 300, 0, 0)
        dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        dialogFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        dialogFrame.BackgroundTransparency = 0.1
        dialogFrame.BorderSizePixel = 0
        dialogFrame.ZIndex = 11
        dialogFrame.AutomaticSize = Enum.AutomaticSize.Y
        dialogFrame.Parent = dialogBackground
        
        -- Add rounded corners
        local dialogCorner = Instance.new("UICorner")
        dialogCorner.CornerRadius = UDim.new(0, 8)
        dialogCorner.Parent = dialogFrame
        
        -- Create title label
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "TitleLabel"
        titleLabel.Size = UDim2.new(1, 0, 0, 40)
        titleLabel.BackgroundTransparency = 0.8
        titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 16
        titleLabel.ZIndex = 12
        titleLabel.Parent = dialogFrame
        
        -- Add rounded corners to title
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = titleLabel
        
        -- Create content label
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Name = "ContentLabel"
        contentLabel.Size = UDim2.new(1, -20, 0, 0)
        contentLabel.Position = UDim2.new(0, 10, 0, 50)
        contentLabel.BackgroundTransparency = 1
        contentLabel.Text = content
        contentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        contentLabel.Font = Enum.Font.Gotham
        contentLabel.TextSize = 14
        contentLabel.TextWrapped = true
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.ZIndex = 12
        contentLabel.AutomaticSize = Enum.AutomaticSize.Y
        contentLabel.Parent = dialogFrame
        
        -- Create buttons container
        local buttonsContainer = Instance.new("Frame")
        buttonsContainer.Name = "ButtonsContainer"
        buttonsContainer.Size = UDim2.new(1, 0, 0, 50)
        buttonsContainer.Position = UDim2.new(0, 0, 0, contentLabel.Position.Y.Offset + contentLabel.TextBounds.Y + 20)
        buttonsContainer.BackgroundTransparency = 1
        buttonsContainer.ZIndex = 12
        buttonsContainer.Parent = dialogFrame
        
        -- Create buttons
        local buttonWidth = 100
        local buttonSpacing = 10
        local totalWidth = (#buttons * buttonWidth) + ((#buttons - 1) * buttonSpacing)
        local startX = (300 - totalWidth) / 2
        
        for i, buttonInfo in ipairs(buttons) do
            local button = Instance.new("TextButton")
            button.Name = buttonInfo.Title .. "Button"
            button.Size = UDim2.new(0, buttonWidth, 0, 30)
            button.Position = UDim2.new(0, startX + (i-1) * (buttonWidth + buttonSpacing), 0, 10)
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            button.BackgroundTransparency = 0.3
            button.BorderSizePixel = 0
            button.Text = buttonInfo.Title
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamSemibold
            button.TextSize = 14
            button.ZIndex = 13
            button.Parent = buttonsContainer
            
            -- Add rounded corners
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 4)
            buttonCorner.Parent = button
            
            -- Button click event
            button.MouseButton1Click:Connect(function()
                dialogBackground:Destroy()
                if buttonInfo.Callback then
                    buttonInfo.Callback()
                end
            end)
            
            -- Hover effect
            button.MouseEnter:Connect(function()
                game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end)
            
            button.MouseLeave:Connect(function()
                game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
            end)
        end
        
        -- Animation
        dialogFrame.Size = UDim2.new(0, 300, 0, 0)
        dialogFrame.BackgroundTransparency = 1
        dialogBackground.BackgroundTransparency = 1
        
        -- Animate in
        game:GetService("TweenService"):Create(dialogBackground, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
        game:GetService("TweenService"):Create(dialogFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, buttonsContainer.Position.Y.Offset + 50),
            BackgroundTransparency = 0.1
        }):Play()
    end
    
    return Window
end

-- Create the UI when the script runs
local ui = CreateCenteredUI()

-- You can call CreateCenteredUI() again anytime you want to recreate the UI
-- This will automatically remove any existing UI with the same name

return UILibrary
