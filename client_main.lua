Camera = {
    tick = getTickCount();
    accelerationTick = getTickCount();
    rotation = 0;
    maxRotationUnit = 15;
    defaultCameraY = -6;
    currentCameraY = -6;
    standartCameraY = -6;
    maxCameraY = -7;
    Enabled = true;
    snake = 0;
};

addEventHandler("onClientKey", root, function(key, state)
    if not localPlayer.vehicle then return end;

    if ( localPlayer:getControlState("vehicle_left") ) or ( localPlayer:getControlState("vehicle_right") ) then
        Camera.tick = getTickCount();
    end
    if ( localPlayer:getControlState("accelerate") ) or ( localPlayer:getControlState("brake_reverse") ) then
        Camera.accelerationTick = getTickCount();
    end
    if key == "F5" and state then
        local newState = not Camera.Enabled;
        fadeCamera(false, 0.5)
        if isTimer(timer) then
            killTimer(timer)
        end
        timer = setTimer(function()
            if not newState then
                setCameraTarget(localPlayer);
            end
            Camera.Enabled = newState
            fadeCamera(true, 0.5)
        end, 500, 1)
    end
end)

function Camera:Render()
    if ( localPlayer.vehicle ) and ( self.tick ~= nil ) and ( self.accelerationTick ~= nil ) then

        self.pVehicle = localPlayer.vehicle;

        if not self.object or not isElement(self.object) then
            self.object = Object(902, 0, 0, 0);
            self.parent = Object(902, 0, 0, 0);
            self.parent:attach(self.pVehicle, 0, 0, 2);
            self.object:attach(self.parent, 0, -5, 1);

            self.object.alpha = 0; self.parent.alpha = 0;
            self.object.collisions = false; self.parent.collisions = false;
        end

        local _,_,_,_,_,vecCurrentRotation = self.parent:getAttachedOffsets();
        if ( localPlayer:getControlState("vehicle_left") ) or ( localPlayer:getControlState("vehicle_right") ) then
            local newValue;

            if ( localPlayer:getControlState("vehicle_left") ) then
                if self.rotation > -(self.maxRotationUnit) then
                    newValue = self.rotation - 1;
                else
                    newValue = -(self.maxRotationUnit);
                end
            else
                if self.rotation < self.maxRotationUnit then
                    newValue = self.rotation + 1;
                else
                    newValue = (self.maxRotationUnit);
                end
            end

            if ( self.rotation <= -self.maxRotationUnit ) or ( self.rotation >= self.maxRotationUnit ) then
                if self.rotation <= -self.maxRotationUnit then
                    self.rotation = -self.maxRotationUnit;
                else
                    self.rotation = self.maxRotationUnit;
                end
            end

            self.rotation = interpolateBetween(self.rotation, 0, 0, newValue, 0, 0,(getTickCount() - self.tick) / 3000, "InQuad")
        else
            self.rotation = interpolateBetween(self.rotation, 0, 0,  0, 0, 0,(getTickCount() - self.tick) / 2000, "InQuad")
        end

        if ( localPlayer:getControlState("accelerate") ) or ( localPlayer:getControlState("brake_reverse") ) then
            if math.abs(self.currentCameraY) <= math.abs(self.maxCameraY) then
                self.defaultCameraY = math.abs(self.defaultCameraY) + 0.05;
                self.defaultCameraY = -(self.defaultCameraY);
            end
        else
            self.defaultCameraY = self.standartCameraY;
        end

        if (self.defaultCameraY > self.maxCameraY) then
            self.defaultCameraY = self.maxCameraY;
        end

        self.currentCameraY = interpolateBetween(self.currentCameraY, 0, 0, self.defaultCameraY, 0, 0, (getTickCount() - self.accelerationTick)/2000, "InQuad");



        if self.parent then
            self.parent:setAttachedOffsets(0, 0, 1, -(Vector3(self.pVehicle.rotation).x), -(Vector3(self.pVehicle.rotation).y), self.rotation)
           self.object:setAttachedOffsets(0, self.currentCameraY, 1, (Vector3(self.pVehicle.rotation).x), -(Vector3(self.pVehicle.rotation).y))

            local vecPlayerVehicle      = Vector3(self.parent.position);
            local vecObject             = Vector3(self.object.position);

            setCameraMatrix(vecObject.x, vecObject.y, vecObject.z, vecPlayerVehicle.x, vecPlayerVehicle.y, vecPlayerVehicle.z);

            if (getElementSpeed(self.pVehicle, 1) > 1) and (getElementSpeed(self.pVehicle, 1) < 15) and (localPlayer:getControlState("accelerate")) and not (localPlayer:getControlState("handbrake")) then
                self.snake = interpolateBetween(self.snake, 0, 0, 255, 0, 0, (getTickCount() - self.accelerationTick) / 1500, "InQuad");
                
            else
                self.snake = interpolateBetween(self.snake, 0, 0, 0.0, 0, 0, (getTickCount() - self.accelerationTick) / 10000, "InQuad");
            end

            setCameraShakeLevel(self.snake)
            
        end

        self.customCamera = true;
    else
        if self.customCamera then
            setCameraTarget(localPlayer);
            self.customCamera = false;
            
            self.parent:destroy(); self.parent = nil;
            self.object:destroy(); self.object = nil;
        end
    end
end

local timer;

addEventHandler("onClientPreRender", root, function()
    if Camera.Enabled then
        Camera:Render();
    end
end)

function getElementSpeed(theElement, unit)
    -- Check arguments for errors
    assert(isElement(theElement), "Bad argument 1 @ getElementSpeed (element expected, got " .. type(theElement) .. ")")
    local elementType = getElementType(theElement)
    assert(elementType == "player" or elementType == "ped" or elementType == "object" or elementType == "vehicle" or elementType == "projectile", "Invalid element type @ getElementSpeed (player/ped/object/vehicle/projectile expected, got " .. elementType .. ")")
    assert((unit == nil or type(unit) == "string" or type(unit) == "number") and (unit == nil or (tonumber(unit) and (tonumber(unit) == 0 or tonumber(unit) == 1 or tonumber(unit) == 2)) or unit == "m/s" or unit == "km/h" or unit == "mph"), "Bad argument 2 @ getElementSpeed (invalid speed unit)")
    -- Default to m/s if no unit specified and 'ignore' argument type if the string contains a number
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    -- Setup our multiplier to convert the velocity to the specified unit
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    -- Return the speed by calculating the length of the velocity vector, after converting the velocity to the specified unit
    return (Vector3(getElementVelocity(theElement)) * mult).length
end