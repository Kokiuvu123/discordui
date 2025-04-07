local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local UILibrary = {}


-- Function to create our UI
local function CreateCenteredUI()
    -- First, clean up ALL blur effects and parts regardless of whether a UI exists
    -- Clean up blur effects in Lighting
    for _, effect in pairs(game:GetService("Lighting"):GetChildren()) do
        if (effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect")) then
            effect:Destroy()
        end
    end
    
    -- Clean up any blur parts in the workspace camera
    if workspace.CurrentCamera then
        for _, child in pairs(workspace.CurrentCamera:GetChildren()) do
            if child:IsA("Part") then
                child:Destroy()
            end
        end
    end
    

    
    -- Now check if a previous UI exists and remove it
    local existingUI = CoreGui:FindFirstChild("CenteredUI")
    if existingUI then
        existingUI:Destroy()
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
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.7  -- Change this value to adjust transparency (0 = opaque, 1 = fully transparent)
frame.BorderSizePixel = 0
frame:SetAttribute("BlurIntensity", 0.98)

    local BLUR_OBJ = Instance.new("DepthOfFieldEffect")
    BLUR_OBJ.FarIntensity = 0
    BLUR_OBJ.NearIntensity = frame:GetAttribute("BlurIntensity")
    BLUR_OBJ.FocusDistance = 0.25
    BLUR_OBJ.InFocusRadius = 0
    BLUR_OBJ:SetAttribute("UIBlur", true)
    BLUR_OBJ.Parent = game:GetService("Lighting")

    -- Inicializar variables para el sistema de blur
    local PartsList = {}
    local BlursList = {}
    local BlurObjects = {}
    local BlurredGui = {}
    BlurredGui.__index = BlurredGui

    -- Funciones para el sistema de blur
    local function rayPlaneIntersect(planePos, planeNormal, rayOrigin, rayDirection)
        local n = planeNormal
        local d = rayDirection
        local v = rayOrigin - planePos
        local num = n.x * v.x + n.y * v.y + n.z * v.z
        local den = n.x * d.x + n.y * d.y + n.z * d.z
        local a = -num / den
        return rayOrigin + a * rayDirection, a
    end

    local function rebuildPartsList()
        PartsList = {}
        BlursList = {}
        for blurObj, part in pairs(BlurObjects) do
            table.insert(PartsList, part)
            table.insert(BlursList, blurObj)
        end
    end

    function BlurredGui.new(frame, shape)
        local blurPart = Instance.new("Part")
        blurPart.Size = Vector3.new(1, 1, 1) * 0.01
        blurPart.Anchored = true
        blurPart.CanCollide = false
        blurPart.CanTouch = false
        blurPart.Material = Enum.Material.Glass
        blurPart.Transparency = 1 - 1e-7
        blurPart.Parent = workspace.CurrentCamera

        local mesh
        if shape == "Rectangle" then
            mesh = Instance.new("BlockMesh")
            mesh.Parent = blurPart
        elseif shape == "Oval" then
            mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Sphere
            mesh.Parent = blurPart
        end
        
        local ignoreInset = false
        local currentObj = frame
        while true do
            currentObj = currentObj.Parent
            if currentObj and currentObj:IsA("ScreenGui") then
                ignoreInset = currentObj.IgnoreGuiInset
                break
            elseif currentObj == nil then
                break
            end
        end

        local new = setmetatable({
            Frame = frame;
            Part = blurPart;
            Mesh = mesh;
            IgnoreGuiInset = ignoreInset;
        }, BlurredGui)

        BlurObjects[new] = blurPart
        rebuildPartsList()

        -- Enlazar la actualización con cada frame
        game:GetService("RunService"):BindToRenderStep("BlurUpdate_" .. tostring(new), Enum.RenderPriority.Camera.Value + 10, function()
            local cam = workspace.CurrentCamera
            if cam and blurPart and blurPart.Parent then
                blurPart.CFrame = cam.CFrame * CFrame.new(0, 0, -0.1)
                BlurredGui.updateAll()
            end
        end)
        
        return new
    end

    local function updateGui(blurObj)
        local cam = workspace.CurrentCamera
        
        if not blurObj.Frame.Visible then
            blurObj.Part.Transparency = 1
            return
        end
        
        local frame = blurObj.Frame
        local part = blurObj.Part
        local mesh = blurObj.Mesh
        
        part.Transparency = 1 - 1e-7
        part.CFrame = cam.CFrame * CFrame.new(0, 0, -0.1)
        
        local BLUR_SIZE = Vector2.new(10, 10)
        local corner0 = frame.AbsolutePosition + BLUR_SIZE
        local corner1 = corner0 + frame.AbsoluteSize - BLUR_SIZE * 2
        local ray0, ray1

        if blurObj.IgnoreGuiInset then
            ray0 = cam:ViewportPointToRay(corner0.X, corner0.Y, 1)
            ray1 = cam:ViewportPointToRay(corner1.X, corner1.Y, 1)
        else
            ray0 = cam:ScreenPointToRay(corner0.X, corner0.Y, 1)
            ray1 = cam:ScreenPointToRay(corner1.X, corner1.Y, 1)
        end

        local planeOrigin = cam.CFrame.Position + cam.CFrame.LookVector * (0.05 - cam.NearPlaneZ)
        local planeNormal = cam.CFrame.LookVector
        local pos0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
        local pos1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

        pos0 = cam.CFrame:PointToObjectSpace(pos0)
        pos1 = cam.CFrame:PointToObjectSpace(pos1)

        local size = pos1 - pos0
        local center = (pos0 + pos1) / 2

        mesh.Offset = center
        mesh.Scale = size / 0.01
    end

    function BlurredGui.updateAll()
        local cam = workspace.CurrentCamera
        BLUR_OBJ.NearIntensity = tonumber(frame:GetAttribute("BlurIntensity"))
        
        for i = 1, #BlursList do
            updateGui(BlursList[i])
        end

        local cframes = table.create(#BlursList, cam.CFrame)
        workspace:BulkMoveTo(PartsList, cframes, Enum.BulkMoveMode.FireCFrameChanged)

        BLUR_OBJ.FocusDistance = 0.25 - cam.NearPlaneZ
    end

    function BlurredGui:Destroy()
        game:GetService("RunService"):UnbindFromRenderStep("BlurUpdate_" .. tostring(self))
        self.Part:Destroy()
        BlurObjects[self] = nil
        rebuildPartsList()
    end

    -- Eliminar el blurFrame simulado y usar el sistema de blur real
    if frame:FindFirstChild("BlurBackground") then
        frame:FindFirstChild("BlurBackground"):Destroy()
    end
    
    -- Eliminar las capas de blur simuladas
    for i = 1, 3 do
        if frame:FindFirstChild("BlurLayer" .. i) then
            frame:FindFirstChild("BlurLayer" .. i):Destroy()
        end
    end

    -- Crear el efecto de blur real para el frame
    BlurredGui.new(frame, "Rectangle")
    BlurredGui.updateAll()

    

    

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- Añadir esquinas redondeadas con radio más grande
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10) -- Radio más grande
    corner.Parent = frame
    
    -- Añadir borde sutil
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    -- Crear un efecto de blur local para la UI
    local blurFrame = Instance.new("Frame")
    blurFrame.Name = "BlurBackground"
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.Position = UDim2.new(0, 0, 0, 0)
    blurFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5) -- Mantener color oscuro
    blurFrame.BackgroundTransparency = 0.55-- Reducir transparencia para que sea más visible
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
        blurLayer.BackgroundTransparency = 0.5 + (i * 0.1) -- Transparencia progresiva
        blurLayer.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        blurLayer.ZIndex = -i - 1
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
    local kavoStyle = options.KavoStyle ~= nil and options.KavoStyle or true
    local animationStyle = options.AnimationStyle or 1 -- Default animation style
    
    local Window = {}
    local ui = CreateCenteredUI()

    

    local mainFrame = ui:FindFirstChild("MainFrame")
    mainFrame.Size = size
    mainFrame:FindFirstChild("TitleLabel").Text = title
    
    -- Añadir animación de entrada
    mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0) -- Comienza fuera de la pantalla
    mainFrame.BackgroundTransparency = 1
    mainFrame.Size = UDim2.new(0, size.X.Offset * 0.8, 0, size.Y.Offset * 0.8) -- Start smaller

    local backdrop = Instance.new("Frame")
    backdrop.Name = "AnimationBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.ZIndex = 0
    backdrop.Parent = ui
    
    -- Animar la entrada
    TweenService:Create(backdrop, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()

    task.delay(0.1, function()
        -- First animation: move up with bounce
        local tween1 = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, 0, 0.5, -10)}
        )
        
        -- Second animation: settle into final position and size
        local tween2 = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = size,
                BackgroundTransparency = 0.70
            }
        )
        
        tween1:Play()
        
        tween1.Completed:Connect(function()
            tween2:Play()
            
            -- Fade out backdrop
            TweenService:Create(backdrop, TweenInfo.new(0.5), {
                BackgroundTransparency = 1
            }):Play()
            
            -- Remove backdrop after animation
            task.delay(0.5, function()
                backdrop:Destroy()
            end)
        end)
    end)
    
    
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
        -- En lugar de eliminar y recrear, simplemente actualiza las propiedades
        if tabButtonsContainer:FindFirstChildOfClass("UIListLayout") then
            local existingLayout = tabButtonsContainer:FindFirstChildOfClass("UIListLayout")
            
            -- Actualizar propiedades en lugar de eliminar
            if kavoStyle then
                existingLayout.FillDirection = Enum.FillDirection.Vertical
                tabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
            else
                existingLayout.FillDirection = Enum.FillDirection.Horizontal
                tabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
            end
        else
            -- Crear nuevo layout si no existe
            local newLayout = Instance.new("UIListLayout")
            newLayout.SortOrder = Enum.SortOrder.LayoutOrder
            newLayout.Padding = UDim.new(0, 5)
            
            if kavoStyle then
                newLayout.FillDirection = Enum.FillDirection.Vertical
            else
                newLayout.FillDirection = Enum.FillDirection.Horizontal
            end
            
            newLayout.Parent = tabButtonsContainer
            tabButtonsLayout = newLayout
        end
        
        -- Let the layout update
        task.wait()
        
        -- Get all tab buttons
        local tabButtons = {}
        for _, child in pairs(tabButtonsContainer:GetChildren()) do
            if child:IsA("TextButton") then
                table.insert(tabButtons, child)
            end
        end
        
        -- Sort by LayoutOrder
        table.sort(tabButtons, function(a, b)
            return a.LayoutOrder < b.LayoutOrder
        end)
        
        -- Calculate exact positions for each button and animate
        for i, button in ipairs(tabButtons) do
            local targetPosition
            if kavoStyle then
                -- Para estilo vertical, posicionar precisamente
                targetPosition = UDim2.new(0, 5, 0, (i-1) * (button.AbsoluteSize.Y + 5) + 5)
            else
                -- Para estilo horizontal, calcular posición X acumulativa precisa
                local xOffset = 5 -- Empezar con el padding
                for j = 1, i-1 do
                    if tabButtons[j] then
                        xOffset = xOffset + tabButtons[j].AbsoluteSize.X + 5
                    end
                end
                targetPosition = UDim2.new(0, xOffset, 0, 5)
            end
            
            -- Animate to target position with delay
            TweenService:Create(
                button,
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, i * 0.08),
                {Position = targetPosition}
            ):Play()
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
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabTitle .. "Button"
        tabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tabButton.BackgroundTransparency = 0.5
        tabButton.Text = tabTitle
        tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButton.Font = Enum.Font.GothamSemibold
        tabButton.TextSize = 14
        tabButton.BorderSizePixel = 0
        
        -- Set LayoutOrder based on number of existing tabs for consistent animation
        if options.LayoutOrder then
            tabButton.LayoutOrder = options.LayoutOrder
        else
            -- Find the highest LayoutOrder and add 1
            local maxOrder = 0
            for _, tab in pairs(tabs) do
                if tab.Button.LayoutOrder > maxOrder then
                    maxOrder = tab.Button.LayoutOrder
                end
            end
            tabButton.LayoutOrder = maxOrder + 1
        end
        
        -- Set exact size based on current style before parenting
        if kavoStyle then
            tabButton.Size = UDim2.new(1, 0, 0, 30)
            tabButton.AutomaticSize = Enum.AutomaticSize.None
        else
            -- For horizontal tabs, set a fixed height but allow width to adjust to text
            tabButton.Size = UDim2.new(0, 100, 0, 30)
            tabButton.AutomaticSize = Enum.AutomaticSize.X
        end
        
        -- Now parent the button
        tabButton.Parent = tabButtonsContainer
        
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

        function Window:Close()
            -- First clean up all blur effects
            for _, effect in pairs(game:GetService("Lighting"):GetChildren()) do
                if (effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect")) then
                    effect:Destroy()
                end
            end
            
            -- Clean up any blur parts in the workspace camera
            if workspace.CurrentCamera then
                for _, child in pairs(workspace.CurrentCamera:GetChildren()) do
                    if child:IsA("Part") then
                        child:Destroy()
                    end
                end
            end
            
            -- Remove the problematic code that tries to use GetConnections
            -- Instead, we'll use a different approach to clean up connections
            
            -- If you have stored your connections in a table, you can disconnect them here
            if Window.BlurConnections then
                for _, connection in pairs(Window.BlurConnections) do
                    connection:Disconnect()
                end
                Window.BlurConnections = {}
            end
            
            -- Now animate and destroy the UI
            TweenService:Create(
                mainFrame,
                TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                {Position = UDim2.new(0.5, 0, 1.5, 0), BackgroundTransparency = 1}
            ):Play()
            
            task.delay(0.5, function()
                ui:Destroy()
            end)
        end
        
        -- Añadir botón de cierre
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 24, 0, 24)
        closeButton.Position = UDim2.new(1, -30, 0, 8)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "✕"
        closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 16
        closeButton.Parent = mainFrame
        
        -- Efecto hover para el botón de cierre
        closeButton.MouseEnter:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            Window:Close()
        end)

        
        
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
    contentLabel.Size = UDim2.new(1, -80, 0, 0)
    contentLabel.Position = UDim2.new(0, 50, 0, 35)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content
    contentLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 14
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    contentLabel.ZIndex = 3
    contentLabel.Parent = dialogFrame -- Cambiar de contentContainer a dialogFrame
            
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

            local buttonRipple = Instance.new("Frame")
    buttonRipple.Name = "ButtonRipple"
    buttonRipple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buttonRipple.BackgroundTransparency = 1
    buttonRipple.BorderSizePixel = 0
    buttonRipple.Size = UDim2.new(1, 0, 1, 0)
    buttonRipple.ZIndex = button.ZIndex - 1
    buttonRipple.Parent = button
    
    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = UDim.new(0, 4)
    rippleCorner.Parent = buttonRipple
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        -- Create hover glow effect
        local hoverGlow = Instance.new("ImageLabel")
        hoverGlow.Name = "HoverGlow"
        hoverGlow.BackgroundTransparency = 1
        hoverGlow.Image = "rbxassetid://1316045217"
        hoverGlow.ImageColor3 = Color3.fromRGB(255, 255, 255)
        hoverGlow.ImageTransparency = 0.9
        hoverGlow.Size = UDim2.new(1, 10, 1, 10)
        hoverGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
        hoverGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        hoverGlow.ZIndex = button.ZIndex - 1
        hoverGlow.Parent = button
        
        -- Animate button and glow
        TweenService:Create(button, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(70, 70, 70),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        
        TweenService:Create(hoverGlow, TweenInfo.new(0.5), {
            ImageTransparency = 0.7,
            Size = UDim2.new(1, 20, 1, 20)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        -- Remove glow and reset button
        local hoverGlow = button:FindFirstChild("HoverGlow")
        if hoverGlow then
            TweenService:Create(hoverGlow, TweenInfo.new(0.3), {
                ImageTransparency = 1,
                Size = UDim2.new(1, 10, 1, 10)
            }):Play()
            
            task.delay(0.3, function()
                if hoverGlow and hoverGlow.Parent then
                    hoverGlow:Destroy()
                end
            end)
        end
        
        TweenService:Create(button, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    -- Click effect
    button.MouseButton1Down:Connect(function()
        -- Crear efecto de onda con animación mejorada
        buttonRipple.BackgroundTransparency = 0.7
        buttonRipple.Size = UDim2.new(0, 0, 0, 0)
        buttonRipple.Position = UDim2.new(0.5, 0, 0.5, 0)
        buttonRipple.AnchorPoint = Vector2.new(0.5, 0.5)
        
        -- Animación de onda mejorada con curva de aceleración
        TweenService:Create(buttonRipple, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            Size = UDim2.new(2, 0, 2, 0)
        }):Play()
        
        -- Efecto de presión con rebote suave
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 95, 0, 28),
            Position = UDim2.new(1, -102.5, 0, 11)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        -- Animación de liberación con rebote
        TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 100, 0, 30),
            Position = UDim2.new(1, -105, 0, 10)
        }):Play()
    end)
            
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
            -- Crear efecto de onda para el botón seleccionado
            local ripple = Instance.new("Frame")
            ripple.Name = "SelectionRipple"
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
            ripple.AnchorPoint = Vector2.new(0.5, 0.5)
            ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ripple.BackgroundTransparency = 0.8
            ripple.BorderSizePixel = 0
            ripple.ZIndex = tabButton.ZIndex - 1
            ripple.Parent = tabButton

            local tabIndicator = tabsContainer:FindFirstChild("TabIndicator")
            if not tabIndicator then
                tabIndicator = Instance.new("Frame")
                tabIndicator.Name = "TabIndicator"
                tabIndicator.Size = UDim2.new(0, 3, 0, 20)
                tabIndicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                tabIndicator.BorderSizePixel = 0
                tabIndicator.ZIndex = 5
                
                local indicatorCorner = Instance.new("UICorner")
                indicatorCorner.CornerRadius = UDim.new(0, 2)
                indicatorCorner.Parent = tabIndicator
                
                tabIndicator.Parent = tabsContainer
            end
            
            -- Position the indicator based on layout style
            if kavoStyle then
                -- Vertical tabs (Kavo style)
                tabIndicator.Size = UDim2.new(0, 3, 0, 20)
                TweenService:Create(tabIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(0, 0, 0, tabButton.AbsolutePosition.Y - tabsContainer.AbsolutePosition.Y + 5),
                    Size = UDim2.new(0, 3, 0, tabButton.AbsoluteSize.Y - 10)
                }):Play()
            else
                -- Horizontal tabs
                tabIndicator.Size = UDim2.new(0, 20, 0, 3)
                TweenService:Create(tabIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(0, tabButton.AbsolutePosition.X - tabsContainer.AbsolutePosition.X + 10, 0, tabButton.AbsoluteSize.Y - 3),
                    Size = UDim2.new(0, tabButton.AbsoluteSize.X - 20, 0, 3)
                }):Play()
            end
            
            -- Añadir esquinas redondeadas al efecto
            local rippleCorner = Instance.new("UICorner")
            rippleCorner.CornerRadius = UDim.new(0, 4)
            rippleCorner.Parent = ripple
            
            -- Animar el efecto de onda
            TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(1.5, 0, 1.5, 0),
                BackgroundTransparency = 1
            }):Play()
            
            -- Eliminar el efecto después de la animación
            task.delay(0.5, function()
                ripple:Destroy()
            end)
            
            -- Hide all tab contents with fade out animation
            for tabName, tab in pairs(tabs) do
                if tabName ~= tabTitle and tab.Content.Visible then
                    -- Fade out animation for previous tab
                    TweenService:Create(tab.Content, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0.05, 0, 0, 0),
                        BackgroundTransparency = tab.Content.BackgroundTransparency + 0.5
                    }):Play()
                    
                    -- Create fade effect for all children
                    for _, child in pairs(tab.Content:GetChildren()) do
                        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                            TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                                BackgroundTransparency = child.BackgroundTransparency + 0.5
                            }):Play()
                        end
                    end
                    
                    -- Reset button appearance with smooth transition
                    TweenService:Create(tab.Button, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        TextColor3 = Color3.fromRGB(200, 200, 200)
                    }):Play()
                    
                    -- Hide after animation completes
                    task.delay(0.2, function()
                        tab.Content.Visible = false
                        tab.Content.Position = UDim2.new(0, 0, 0, 0)
                        -- Restore original transparency
                        tab.Content.BackgroundTransparency = tab.Content.BackgroundTransparency - 0.5
                    end)
                end
            end
            
           -- Show selected tab content with fade in animation
           tabContent.Position = UDim2.new(-0.05, 0, 0, 0)
            local originalTransparency = tabContent.BackgroundTransparency
            tabContent.BackgroundTransparency = originalTransparency + 0.5
            tabContent.Visible = true
            
            -- Fade in animation for content and its children
            TweenService:Create(tabContent, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = originalTransparency
            }):Play()
            
            -- Animate children with staggered delay
            local children = tabContent:GetChildren()
            for i, child in pairs(children) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child.BackgroundTransparency = child.BackgroundTransparency + 0.5
                    child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset - 20, child.Position.Y.Scale, child.Position.Y.Offset)
                    
                    -- Staggered animation
                    TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, i * 0.05), {
                        BackgroundTransparency = child.BackgroundTransparency - 0.5,
                        Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset + 20, child.Position.Y.Scale, child.Position.Y.Offset)
                    }):Play()
                end
            end
            
            -- Fade in animation
            TweenService:Create(tabContent, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
                -- No modificar la transparencia del fondo aquí
                -- BackgroundTransparency = 0
            }):Play()
            
            -- Highlight selected tab button with smooth transition
            TweenService:Create(tabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
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
        
        -- First update the containers with animation
        if kavoStyle then
            -- Kavo style (tabs on left)
            TweenService:Create(
                tabsContainer, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(0.25, 0, 1, -40),
                    Position = UDim2.new(0, 0, 0, 40)
                }
            ):Play()
            
            TweenService:Create(
                contentContainer,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(0.75, 0, 1, -40),
                    Position = UDim2.new(0.25, 0, 0, 40)
                }
            ):Play()
        else
            -- Tabs on top
            TweenService:Create(
                tabsContainer, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(1, 0, 0, 40),
                    Position = UDim2.new(0, 0, 0, 40)
                }
            ):Play()
            
            TweenService:Create(
                contentContainer,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(1, 0, 1, -80),
                    Position = UDim2.new(0, 0, 0, 80)
                }
            ):Play()
        end
        
        -- SOLUCIÓN DEFINITIVA: Eliminar completamente el ScrollingFrame y crear uno nuevo
        
        -- Capturar todos los datos de los tabs
        local tabData = {}
        
        -- Usar un índice numérico para preservar el orden exacto y manejar duplicados
        local tabIndex = 1
        for tabName, tab in pairs(tabs) do
            table.insert(tabData, {
                title = tabName,
                button = tab.Button,
                content = tab.Content,
                object = tab.Object,
                isActive = (activeTab == tabName),
                layoutOrder = tab.Button.LayoutOrder,
                uniqueId = tabIndex  -- Añadir un ID único para cada tab
            })
            tabIndex = tabIndex + 1
        end
        
        -- Ordenar por LayoutOrder explícitamente
        table.sort(tabData, function(a, b)
            if a.layoutOrder ~= b.layoutOrder then
                return a.layoutOrder < b.layoutOrder
            else
                -- Si tienen el mismo LayoutOrder, usar el uniqueId para mantener el orden original
                return a.uniqueId < b.uniqueId
            end
        end)
        
        -- Eliminar el contenedor de tabs actual
        tabButtonsContainer:Destroy()
        
        -- Crear un nuevo contenedor (Frame en lugar de ScrollingFrame)
        local newTabButtonsContainer = Instance.new("Frame")
        newTabButtonsContainer.Name = "TabButtonsContainer"
        newTabButtonsContainer.Size = UDim2.new(1, 0, 1, 0)
        newTabButtonsContainer.BackgroundTransparency = 1
        newTabButtonsContainer.BorderSizePixel = 0
        newTabButtonsContainer.ClipsDescendants = true
        newTabButtonsContainer.Parent = tabsContainer
        
        -- Crear animación de entrada para los nuevos botones
        for i, data in ipairs(tabData) do
            -- Crear un nuevo botón
            local newButton = Instance.new("TextButton")
            newButton.Name = data.title .. "Button" .. data.uniqueId  -- Usar ID único en el nombre
            newButton.Text = data.title
            newButton.Font = data.button.Font
            newButton.TextSize = data.button.TextSize
            newButton.TextColor3 = data.isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            newButton.BackgroundColor3 = data.isActive and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(30, 30, 30)
            newButton.BackgroundTransparency = 0.5
            newButton.BorderSizePixel = 0
            newButton.LayoutOrder = data.layoutOrder  -- Mantener el LayoutOrder original
            newButton.ZIndex = 5
            
            -- Añadir esquinas redondeadas
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = newButton
            
            -- Calcular tamaño según el estilo
            if kavoStyle then
                -- Estilo Kavo (vertical)
                newButton.Size = UDim2.new(1, -10, 0, 30)
                
                -- Posición inicial para animación (fuera de la pantalla)
                newButton.Position = UDim2.new(-1, 0, 0, 5 + (i-1) * 35)
                
                -- Posición final
                local finalPos = UDim2.new(0, 5, 0, 5 + (i-1) * 35)
                
                -- Animar entrada
                TweenService:Create(
                    newButton,
                    TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, i * 0.08),
                    {Position = finalPos}
                ):Play()
            else
                -- Estilo horizontal
                local textSize = game:GetService("TextService"):GetTextSize(
                    data.title,
                    data.button.TextSize,
                    data.button.Font,
                    Vector2.new(1000, 30)
                )
                newButton.Size = UDim2.new(0, textSize.X + 30, 0, 30)
                
                -- Calcular posición X acumulativa
                local xOffset = 5
                for j = 1, i-1 do
                    if tabData[j] then
                        local prevTextSize = game:GetService("TextService"):GetTextSize(
                            tabData[j].title,
                            tabData[j].button.TextSize,
                            tabData[j].button.Font,
                            Vector2.new(1000, 30)
                        )
                        xOffset = xOffset + prevTextSize.X + 35 -- 30 para el texto + 5 de padding
                    end
                end
                
                -- Posición inicial para animación (fuera de la pantalla)
                newButton.Position = UDim2.new(0, xOffset, -1, 0)
                
                -- Posición final
                local finalPos = UDim2.new(0, xOffset, 0, 5)
                
                -- Animar entrada
                TweenService:Create(
                    newButton,
                    TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, i * 0.08),
                    {Position = finalPos}
                ):Play()
            end
            
            -- Actualizar la referencia en la tabla de tabs
            tabs[data.title].Button = newButton
    
    -- Recrear evento de clic
    newButton.MouseButton1Click:Connect(function()
        -- Efecto de onda
        local ripple = Instance.new("Frame")
        ripple.Name = "SelectionRipple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.8
        ripple.BorderSizePixel = 0
        ripple.ZIndex = newButton.ZIndex - 1
        ripple.Parent = newButton
                
                -- Añadir esquinas redondeadas
                local rippleCorner = Instance.new("UICorner")
                rippleCorner.CornerRadius = UDim.new(0, 4)
                rippleCorner.Parent = ripple
                
                -- Animar el efecto de onda
                TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1.5, 0, 1.5, 0),
                    BackgroundTransparency = 1
                }):Play()
                
                -- Eliminar después de la animación
                task.delay(0.5, function()
                    ripple:Destroy()
                end)
                
                -- Ocultar todos los contenidos de tabs
                for tabName, tab in pairs(tabs) do
                    if tabName ~= data.title and tab.Content.Visible then
                        -- Animación de desvanecimiento
                        TweenService:Create(tab.Content, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0.05, 0, 0, 0),
                            BackgroundTransparency = 1
                        }):Play()
                        
                        -- Restablecer apariencia del botón
                        TweenService:Create(tab.Button, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                            TextColor3 = Color3.fromRGB(200, 200, 200)
                        }):Play()
                        
                        -- Ocultar después de la animación
                        task.delay(0.2, function()
                            tab.Content.Visible = false
                            tab.Content.Position = UDim2.new(0, 0, 0, 0)
                            tab.Content.BackgroundTransparency = 0
                        end)
                    end
                end
                
                -- Mostrar el contenido del tab seleccionado
                data.content.Position = UDim2.new(0.05, 0, 0, 0)
                data.content.BackgroundTransparency = 0.5
                data.content.Visible = true
                
                -- Animación de aparición
                TweenService:Create(data.content, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 0
                }):Play()
                
                -- Resaltar el botón seleccionado
                TweenService:Create(newButton, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
                
                activeTab = data.title
            end)
            
            -- Añadir al nuevo contenedor
    newButton.Parent = newTabButtonsContainer
    
    -- Asegurarse de que el contenido del tab también tenga la referencia actualizada
    tabs[data.title].Content = data.content
        end
        
        -- Actualizar la referencia global
        tabButtonsContainer = newTabButtonsContainer
        
        return kavoStyle
    end

-- ... existing code ...
    
    function Window:GetStyle()
        return kavoStyle
    end

    local function CreateSettingsTab()
        local settingsTab = Window:AddTab({Title = "Settings"})
        
        -- Add style toggle
        local styleToggleFrame = Instance.new("Frame")
        styleToggleFrame.Name = "StyleToggleFrame"
        styleToggleFrame.Size = UDim2.new(1, 0, 0, 40)
        styleToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        styleToggleFrame.BackgroundTransparency = 0.5
        styleToggleFrame.BorderSizePixel = 0
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

        local toggleClickDetector = Instance.new("TextButton")
        toggleClickDetector.Name = "ToggleClickDetector"
        toggleClickDetector.Size = UDim2.new(1, 0, 1, 0)
        toggleClickDetector.Position = UDim2.new(0, 0, 0, 0)
        toggleClickDetector.BackgroundTransparency = 1
        toggleClickDetector.Text = ""
        toggleClickDetector.Parent = toggleButton
        
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

        toggleClickDetector.MouseButton1Click:Connect(function()
            Window:ToggleStyle()
            updateToggle()
        end)
        
        -- Make toggle clickable
        toggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Window:ToggleStyle()
                updateToggle()
            end
        end)
        
        -- Also make label clickable
        toggleLabel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Window:ToggleStyle()
                updateToggle()
            end
        end)
        
        return settingsTab
    end

    CreateSettingsTab()


    

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
        contentLabel.Size = UDim2.new(1, -80, 0, 0)
        contentLabel.Position = UDim2.new(0, 50, 0, 35)
        contentLabel.BackgroundTransparency = 1
        contentLabel.Text = content
        contentLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
        contentLabel.Font = Enum.Font.Gotham
        contentLabel.TextSize = 14
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.TextWrapped = true
        contentLabel.AutomaticSize = Enum.AutomaticSize.Y
        contentLabel.ZIndex = 3
        contentLabel.Parent = contentContainer
        
        -- Create close button
        local closeButton = Instance.new("TextButton")
        
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
    
    -- Animate background with subtle fade
    TweenService:Create(dialogBackground, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), {
        BackgroundTransparency = 0.5
    }):Play()
    
    -- Animate dialog with bounce effect
    local sizeTween = TweenService:Create(dialogFrame, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0), {
        Size = UDim2.new(0, 300, 0, buttonsContainer.Position.Y.Offset + 50),
        BackgroundTransparency = 0.1
    })
    
    -- Add subtle scale effect
    dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dialogFrame.Size = UDim2.new(0, 280, 0, 0) -- Start slightly smaller
    
    -- Sequence the animations
    TweenService:Create(dialogFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 320, 0, 10), -- Overshoot slightly
        BackgroundTransparency = 0.5
    }):Play()
    
    task.delay(0.2, function()
        sizeTween:Play()
    end)
    
    -- Add subtle shadow animation
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DialogShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 25, 1, 25)
    shadow.ZIndex = 10
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 1
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = dialogFrame
    
    -- Animate shadow
    TweenService:Create(shadow, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
        ImageTransparency = 0.6,
        Size = UDim2.new(1, 35, 1, 35)
    }):Play()
        
        -- Animate in
        game:GetService("TweenService"):Create(dialogBackground, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
        game:GetService("TweenService"):Create(dialogFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, buttonsContainer.Position.Y.Offset + 50),
            BackgroundTransparency = 0.1
        }):Play()
    end

    function Window:Notify(options)
        options = options or {}
        local title = options.Title or "Notification"
        local content = options.Content or ""
        local duration = options.Duration or 3
        local type = options.Type or "Info" -- Info, Success, Warning, Error
        
        -- Create notification container if it doesn't exist
        local notifContainer = ui:FindFirstChild("NotificationContainer")
        if not notifContainer then
            notifContainer = Instance.new("Frame")
            notifContainer.Name = "NotificationContainer"
            notifContainer.Size = UDim2.new(0, 320, 1, 0)
            notifContainer.Position = UDim2.new(1, -320, 0, 0)
            notifContainer.BackgroundTransparency = 1
            notifContainer.Parent = ui
            
            -- Create layout for stacking notifications
            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 10)
            listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = notifContainer
            
            -- Add padding at the bottom
            local padding = Instance.new("UIPadding")
            padding.PaddingBottom = UDim.new(0, 20)
            padding.Parent = notifContainer
        end
        
        -- Color mapping for different notification types
        local typeColors = {
            Info = Color3.fromRGB(0, 120, 255),
            Success = Color3.fromRGB(0, 180, 100),
            Warning = Color3.fromRGB(255, 150, 0),
            Error = Color3.fromRGB(255, 60, 60)
        }
        
        -- Icon mapping for different notification types
        local typeIcons = {
            Info = "rbxassetid://9072944922",
            Success = "rbxassetid://9073052584",
            Warning = "rbxassetid://9072448788",
            Error = "rbxassetid://9072464246"
        }
        
        -- Create notification frame
        local notifFrame = Instance.new("Frame")
notifFrame.Name = "NotificationFrame"
notifFrame.Size = UDim2.new(0, 300, 0, 80) -- Set a fixed minimum height instead of using MinSize
notifFrame.AutomaticSize = Enum.AutomaticSize.Y  -- Still allow it to grow taller if needed
notifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
notifFrame.BackgroundTransparency = 0.1
notifFrame.BorderSizePixel = 0
notifFrame.ClipsDescendants = true
notifFrame.LayoutOrder = tick() -- Use timestamp for ordering
notifFrame.Parent = notifContainer
        
        -- Add glass effect with gradient
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
        })
        gradient.Rotation = 45
        gradient.Parent = notifFrame
        
        -- Rounded corners
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 10)
        notifCorner.Parent = notifFrame
        
        -- Add subtle glow effect
        local stroke = Instance.new("UIStroke")
        stroke.Color = typeColors[type] or typeColors.Info
        stroke.Thickness = 1.5
        stroke.Transparency = 0.7
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = notifFrame
        
        -- Add shadow
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.BackgroundTransparency = 1
        shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
        shadow.Size = UDim2.new(1, 15, 1, 15)
        shadow.ZIndex = -1
        shadow.Image = "rbxassetid://1316045217"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.6
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(10, 10, 118, 118)
        shadow.Parent = notifFrame
        
        -- Create content container (to separate from accent bar)
        local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, 0, 1, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.Parent = notifFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 25) -- Ensure enough space for progress bar
padding.Parent = contentContainer

        -- Create accent bar
        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 4, 1, 0)
        accentBar.Position = UDim2.new(0, 0, 0, 0)
        accentBar.BackgroundColor3 = typeColors[type] or typeColors.Info
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 2
        accentBar.Parent = notifFrame
        
        -- Create icon
        local icon = Instance.new("ImageLabel")
        icon.Name = "TypeIcon"
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 15, 0, 15)
        icon.BackgroundTransparency = 1
        icon.Image = typeIcons[type] or typeIcons.Info
        icon.ImageColor3 = typeColors[type] or typeColors.Info
        icon.ZIndex = 3
        icon.Parent = contentContainer
        
        -- Add glow to icon
        local iconGlow = Instance.new("ImageLabel")
        iconGlow.Name = "IconGlow"
        iconGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
        iconGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        iconGlow.BackgroundTransparency = 1
        iconGlow.Image = "rbxassetid://1316045217"
        iconGlow.ImageColor3 = typeColors[type] or typeColors.Info
        iconGlow.ImageTransparency = 0.7
        iconGlow.ZIndex = 2
        iconGlow.Parent = icon
        
                -- Create title
                local titleLabel = Instance.new("TextLabel")
                titleLabel.Name = "TitleLabel"
                titleLabel.Size = UDim2.new(1, -80, 0, 25)
                titleLabel.Position = UDim2.new(0, 50, 0, 10)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = title
                titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                titleLabel.Font = Enum.Font.GothamBold
                titleLabel.TextSize = 16
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.ZIndex = 3
                titleLabel.Parent = contentContainer
                
                -- Create content
                local contentLabel = Instance.new("TextLabel")
                contentLabel.Name = "ContentLabel"
                contentLabel.Size = UDim2.new(1, -80, 0, 0)
                contentLabel.Position = UDim2.new(0, 50, 0, 35)
                contentLabel.BackgroundTransparency = 1
                contentLabel.Text = content
                contentLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                contentLabel.Font = Enum.Font.Gotham
                contentLabel.TextSize = 14
                contentLabel.TextXAlignment = Enum.TextXAlignment.Left
                contentLabel.TextYAlignment = Enum.TextYAlignment.Top
                contentLabel.TextWrapped = true
                contentLabel.AutomaticSize = Enum.AutomaticSize.Y
                contentLabel.ZIndex = 3
                contentLabel.Parent = contentContainer
                
                -- Create close button
                local closeButton = Instance.new("TextButton")
                closeButton.Name = "CloseButton"
                closeButton.Size = UDim2.new(0, 24, 0, 24)
                closeButton.Position = UDim2.new(1, -30, 0, 15)
                closeButton.BackgroundTransparency = 1
                closeButton.Text = "✕"
                closeButton.TextColor3 = Color3.fromRGB(180, 180, 180)
                closeButton.Font = Enum.Font.GothamBold
                closeButton.TextSize = 14
                closeButton.ZIndex = 3
                closeButton.Parent = contentContainer
        
        -- Create progress bar container
        local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -20, 0, 4)
    progressContainer.Position = UDim2.new(0, 10, 1, -10) -- Ajustado de -15 a -10 para mejor posicionamiento
    progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressContainer.BackgroundTransparency = 0.5
    progressContainer.BorderSizePixel = 0
    progressContainer.ZIndex = 3
    progressContainer.Parent = notifFrame
        
        -- Rounded corners for progress container
        local progressContainerCorner = Instance.new("UICorner")
        progressContainerCorner.CornerRadius = UDim.new(0, 2)
        progressContainerCorner.Parent = progressContainer
        
        -- Create progress bar
        local progressBar = Instance.new("Frame")
        progressBar.Name = "ProgressBar"
        progressBar.Size = UDim2.new(1, 0, 1, 0)
        progressBar.BackgroundColor3 = typeColors[type] or typeColors.Info
        progressBar.BorderSizePixel = 0
        progressBar.ZIndex = 4
        progressBar.Parent = progressContainer
        
        -- Rounded corners for progress bar
        local progressBarCorner = Instance.new("UICorner")
        progressBarCorner.CornerRadius = UDim.new(0, 2)
        progressBarCorner.Parent = progressBar
        
        -- Hover effect for close button
        closeButton.MouseEnter:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(180, 180, 180)}):Play()
        end)
        
        -- Function to close notification
        local function closeNotification()
            -- Cancel any running tweens
            for _, tween in pairs(notifFrame:GetChildren()) do
                if tween:IsA("Tween") then
                    tween:Cancel()
                end
            end
            
            -- Animate out with rotation and scaling for more dynamic effect
            local exitTween = TweenService:Create(
                notifFrame,
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {
                    Position = UDim2.new(1.2, 0, 0, 0), 
                    BackgroundTransparency = 1,
                    Rotation = 5,
                    Size = UDim2.new(0, 300, 0, notifFrame.AbsoluteSize.Y * 0.8)
                }
            )
            exitTween:Play()
            
            -- Destroy after animation
            task.delay(0.5, function()
                notifFrame:Destroy()
            end)
        end
        
        -- Close button click event
        closeButton.MouseButton1Click:Connect(closeNotification)
        
        -- Animate in
        notifFrame.Position = UDim2.new(1.2, 0, 0, 0) -- Start further off-screen
        notifFrame.Rotation = 2 -- Slight rotation for dynamic effect
        
        -- Entrance animation
        local entranceTween1 = TweenService:Create(
        notifFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.05, 0, 0, 0), Rotation = -1}
    )
    
    local entranceTween2 = TweenService:Create(
        notifFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0), Rotation = 0}
    )
    
    entranceTween1:Play()

    entranceTween1.Completed:Connect(function()
        entranceTween2:Play()
    end)
        
        -- Progress bar animation
        local progressTween = TweenService:Create(
            progressBar,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {Size = UDim2.new(0, 0, 1, 0)}
        )
        progressTween:Play()
        
        -- Auto-close after duration
        task.delay(duration, function()
            if notifFrame.Parent then
                closeNotification()
            end
        end)
        
        -- Add hover effect to pause timer
        local isPaused = false
        local timeLeft = duration
        local startTime = tick()
        
        notifFrame.MouseEnter:Connect(function()
            if not isPaused then
                isPaused = true
                progressTween:Pause()
                
                -- Calculate time left
                timeLeft = duration - (tick() - startTime)
                
                -- Highlight effect
                TweenService:Create(notifFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
                TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.3}):Play()
            end
        end)
        
        notifFrame.MouseLeave:Connect(function()
            if isPaused then
                isPaused = false
                
                -- Update start time
                startTime = tick() - (duration - timeLeft)
                
                -- Resume progress bar
                progressTween:Cancel()
                progressTween = TweenService:Create(
                    progressBar,
                    TweenInfo.new(timeLeft, Enum.EasingStyle.Linear),
                    {Size = UDim2.new(0, 0, 1, 0)}
                )
                progressTween:Play()
                
                -- Remove highlight effect
                TweenService:Create(notifFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
                TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.7}):Play()
            end
        end)
        
        -- Make entire notification clickable
        local clickDetector = Instance.new("TextButton")
        clickDetector.Name = "ClickDetector"
        clickDetector.Size = UDim2.new(1, 0, 1, 0)
        clickDetector.Position = UDim2.new(0, 0, 0, 0)
        clickDetector.BackgroundTransparency = 1
        clickDetector.Text = ""
        clickDetector.ZIndex = 1
        clickDetector.Parent = notifFrame
        
        return notifFrame
    end
    
    
    return Window
end



-- Create the UI when the script runs
local ui = CreateCenteredUI()

local function createKeySystem()
    local keyUI = Instance.new("ScreenGui")
    keyUI.Name = "KeySystemUI"
    keyUI.Parent = game:GetService("CoreGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = keyUI
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.ZIndex = -1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = mainFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Key System"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.Parent = mainFrame
    
    -- Key input
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(0.8, 0, 0, 40)
    keyInput.Position = UDim2.new(0.5, 0, 0.5, -20)
    keyInput.AnchorPoint = Vector2.new(0.5, 0.5)
    keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    keyInput.BackgroundTransparency = 0.5
    keyInput.BorderSizePixel = 0
    keyInput.PlaceholderText = "Enter Key..."
    keyInput.Text = ""
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.Font = Enum.Font.Gotham
    keyInput.TextSize = 14
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = mainFrame
    
    -- Add rounded corners to input
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = keyInput
    
    -- Submit button
    local submitButton = Instance.new("TextButton")
    submitButton.Name = "SubmitButton"
    submitButton.Size = UDim2.new(0.5, 0, 0, 35)
    submitButton.Position = UDim2.new(0.5, 0, 0.5, 40)
    submitButton.AnchorPoint = Vector2.new(0.5, 0.5)
    submitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    submitButton.BackgroundTransparency = 0.2
    submitButton.BorderSizePixel = 0
    submitButton.Text = "Submit"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.Font = Enum.Font.GothamSemibold
    submitButton.TextSize = 14
    submitButton.Parent = mainFrame
    
    -- Add rounded corners to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = submitButton
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 1, -40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.Parent = mainFrame
    
    -- Animation for initial appearance
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    
    local TweenService = game:GetService("TweenService")
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 200),
        BackgroundTransparency = 0.1
    }):Play()
    
    -- Button hover effect
    submitButton.MouseEnter:Connect(function()
        TweenService:Create(submitButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(0, 140, 255),
            Size = UDim2.new(0.52, 0, 0, 37)
        }):Play()
    end)
    
    submitButton.MouseLeave:Connect(function()
        TweenService:Create(submitButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(0, 120, 255),
            Size = UDim2.new(0.5, 0, 0, 35)
        }):Play()
    end)
    
    -- Key validation
    local function validateKey()
        local key = keyInput.Text
        
        if key == "admin" then
            -- Success animation
            statusLabel.Text = "Key Accepted!"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            
            TweenService:Create(mainFrame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            
            -- Remove key system and show main UI
            wait(0.6)
            keyUI:Destroy()

            local ui = CreateCenteredUI()
            
            -- Create the main UI only after successful key validation
            local window = UILibrary.CreateWindow({
                Title = "Mi Ventana",
                Size = UDim2.new(0, 600, 0, 400)
            })
            
            -- Create a tab for testing
            local mainTab = window:AddTab({Title = "Principal"})
            mainTab:AddParagraph({
                Title = "Bienvenido",
                Content = "Esta es una demostración de la UI Library"
            })
            
            -- Show notifications
            window:Notify({
                Title = "¡Éxito!",
                Content = "La operación se completó correctamente",
                Duration = 5,
                Type = "Info"
            })
            
            window:Notify({
                Title = "¡Éxito!",
                Content = "La operación se completó correctamente",
                Duration = 5,
                Type = "Success"
            })
            
            window:Notify({
                Title = "¡Éxito!",
                Content = "La operación se completó correctamente",
                Duration = 5,
                Type = "Warning"
            })
            
            window:Notify({
                Title = "¡Éxito!",
                Content = "La operación se completó correctamente",
                Duration = 5,
                Type = "Error"
            })
            
            mainTab:AddButton({
                Title = "Botón de Prueba",
                Description = "Haz clic para ver una alerta",
                Callback = function()
                    window:Dialog({
                        Title = "Alerta",
                        Content = "Has hecho clic en el botón de prueba",
                        Buttons = {
                            {
                                Text = "Aceptar",
                                Callback = function() end
                            }
                        }
                    })
                end
            })
        else
            -- Error animation
            statusLabel.Text = "Invalid Key!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            -- Shake effect
            local originalPosition = mainFrame.Position
            local shake = 10
            
            for i = 1, 5 do
                TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                    Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset + (i % 2 == 0 and shake or -shake), 
                                         originalPosition.Y.Scale, originalPosition.Y.Offset)
                }):Play()
                wait(0.05)
            end
            
            TweenService:Create(mainFrame, TweenInfo.new(0.1), {
                Position = originalPosition
            }):Play()
            
            -- Clear input
            keyInput.Text = ""
        end
    end
    
    -- Connect events
    submitButton.MouseButton1Click:Connect(validateKey)
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            validateKey()
        end
    end)
    
    return keyUI
end

local keySystem = createKeySystem()


return UILibrary
