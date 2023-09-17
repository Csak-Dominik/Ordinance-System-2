--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)
        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        -- simulator:setInputBool(31, simulator:getIsClicked(1))     -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        -- simulator:setInputNumber(31, simulator:getSlider(1))      -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsClicked(1))     -- make button 2 a toggle, for input.getBool(32)
        -- simulator:setInputNumber(32, simulator:getSlider(2) * 50) -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!


-- Valid Instruction Codes:
-- 0 - NOP: no operation -> nothing
-- 1 - PING (data: pylon_id): pings a pylon -> bool32: response
INSTR_PING = 1
-- 2 - DROP (data: pylon_id): drops a pylon -> nothing
INSTR_DROP = 2
-- 3 - FIRE (data: pylon_id): fires a pylon -> nothing
INSTR_FIRE = 3
-- 4 - FIRE-AD (data: pylon_id): fires a pylon and drops if ammo is 0 -> nothing
INSTR_FIRE_AD = 4
-- 5 - SEEK-ON (data: pylon_id): turns on radar of missle (if missle support dynamic radar) -> nothing
INSTR_SEEK_ON = 5
-- 6 - SEEK-OFF (data: pylon_id): turns off radar of missle (if missle support dynamic radar) -> nothing
INSTR_SEEK_OFF = 6
-- 7 - TARGET (data: pylon_id): returns the primary target of the radar -> bool32: response, bool1: found, num1: dist, num2: azim, num3: elev, num4: time_since
INSTR_TARGET = 7
-- 8 - M-Z-OFF (data: pylon_id): asks the missle how far the radar is from the pylon center -> bool32: response, num1: dist
INSTR_M_Z_OFF = 8
-- 9 - P-XYZ-OFF (data: pylon_id): asks the pylon the x, y and z offset from the player's head -> bool32: response, num1: x, num2: y, num3: z
INSTR_P_XYZ_OFF = 9


-- Valid States:
-- IDLE: waiting for a command
ST_IDLE = "IDLE"
-- INIT: initialize the pylons
ST_INIT = "INIT"
-- PING_WAIT: waiting for a ping response
ST_INIT_PING_WAIT = "INIT_PING_WAIT"


counters = {
    -- wait 5 seconds for pylon response (1 sec is 60 ticks)
    pylon_wait_max = 300,
    pylon_wait_counter = 0,
}

state_machine = {
    state = ST_INIT,

    max_pylon_index = 0,
    current_pylon = 1,
}

dead_pylons = {}

function onTick()
    --print("State: " .. state_machine.state)
    if state_machine.state == ST_INIT or state_machine.state == ST_INIT_PING_WAIT then
        init()
        return
    end
end

function onDraw()
end

function init()
    if state_machine.state == ST_INIT then
        -- ping a pylon
        instruction(INSTR_PING, {state_machine.current_pylon})
        -- set the state to wait for a response
        state_machine.state = ST_INIT_PING_WAIT

        counters.pylon_wait_counter = 0
    elseif state_machine.state == ST_INIT_PING_WAIT then
        -- check for response (bool32)
        if input.getBool(32) then
            state_machine.state = ST_INIT

            -- increment the max pylon index and current pylon
            state_machine.max_pylon_index = state_machine.current_pylon
            state_machine.current_pylon = state_machine.current_pylon + 1
        end

        -- if no pylon is responding, then the pylon doesn't exist
        -- this means we have found all pylons
        if counters.pylon_wait_counter >= counters.pylon_wait_max then
            state_machine.state = ST_IDLE
            return
        end

        counters.pylon_wait_counter = counters.pylon_wait_counter + 1
    end
end

function instruction(code, data)
    output.setNumber(1, code)

    for index, value in ipairs(data) do
        output.setNumber(index + 1, value)
    end
end
