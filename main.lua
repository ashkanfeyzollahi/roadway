local buttonClickSound
local carCrashSound
local carEngineLoopSound

local otherCarImage
local playerCarImage

local explosionFrames = {}
local otherCarFrames = {}
local playerCarFrames = {}

local otherCar = {love.math.random(2), -100, love.math.random(40, 80)}
local playerCar = {1, 500}

local numCarFrames = 12
local numExplosionFrames = 8

local carWidth = 100
local carHeight = 80

local carSpeed = 80

local frame = 0
local framePerSecond = 8

local roadImage

local roadHeight
local roadOffset
local roadWidth

local shouldQuit = false

local collided = false
local explosionStart = os.clock()

local paused = false

local function detect_collision()
    return (playerCar[1] == otherCar[1]) and (otherCar[2] > playerCar[2] - 80) and (otherCar[2] < playerCar[2] + 40)
end

local function draw_explosion(n)
    love.graphics.draw(explosionFrames[n], ({295, 415})[playerCar[1]], playerCar[2] - 20, 0, 3, 3)
end

local function draw_other_car(x, y)
    love.graphics.draw(otherCarImage, otherCarFrames[math.floor(frame) + 1], x, y)
end

local function draw_player_car(x, y)
    love.graphics.draw(playerCarImage, playerCarFrames[math.floor(frame) + 1], x, y)
end

local function draw_road()
    local width, height = love.graphics.getDimensions()
    love.graphics.draw(roadImage, 0, roadOffset, 0, width / roadWidth, height * 4 / roadHeight)
end

local function load_car(filename, car_table)
    local carImage = love.graphics.newImage(filename)
    for j = 0, numCarFrames - 1 do
        table.insert(
            car_table,
            love.graphics.newQuad(j * carWidth + j * 508, 0, carWidth, carHeight, carImage:getDimensions())
        )
    end
    return carImage
end

local function load_explosion_frames()
    for i = 1, numExplosionFrames do
        table.insert(explosionFrames, love.graphics.newImage(string.format("assets/explosion%d.png", i)))
    end
end

function love.conf(t)
    t.version = "11.5"
end

function love.draw()
    draw_road()
    draw_other_car(({295, 415})[otherCar[1]], otherCar[2])
    draw_player_car(({295, 415})[playerCar[1]], playerCar[2])

    if collided then
        draw_explosion(math.floor(math.min(frame, 7)) + 1)
    end
end

function love.keypressed(key, scancode, isrepeat)
    buttonClickSound:play()
    if collided or shouldQuit or paused then
        return
    end
    if key == "escape" or key == "q" then
        shouldQuit = true
    elseif key == "p" then
        paused = not paused
    elseif key == "left" or key == "a" then
        playerCar[1] = 1
    elseif key == "right" or key == "d" then
        playerCar[1] = 2
    end
end

function love.load()
    love.window.setTitle("Roadway — A fast-paced 2-lane dodging game made with LÖVE2D.")

    love.math.setRandomSeed(os.time())

    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)

    buttonClickSound = love.audio.newSource("assets/button-click.mp3", "stream")
    carCrashSound = love.audio.newSource("assets/car-crash-sound-effect.mp3", "stream")
    carEngineLoopSound = love.audio.newSource("assets/Car_Engine_Loop.ogg", "stream")

    roadImage = love.graphics.newImage("assets/road.png")
    roadImage:setFilter("nearest", "nearest")

    otherCarImage = load_car("assets/other_car.png", otherCarFrames)
    playerCarImage = load_car("assets/player_car.png", playerCarFrames)

    load_explosion_frames()

    roadHeight = roadImage:getHeight()
    roadOffset = -roadHeight * 3
    roadWidth = roadImage:getWidth()
end

function love.update(dt)
    if paused then
        return
    end

    frame = (frame + framePerSecond * dt) % 12

    roadOffset = roadOffset + 200 * framePerSecond * dt

    if roadOffset > 0 then
        roadOffset = -roadHeight * 3
    end

    carEngineLoopSound:play()

    if collided then
        otherCar[2] = otherCar[2] + carSpeed * framePerSecond * dt
        playerCar[2] = playerCar[2] + carSpeed * framePerSecond * dt
        if (os.time() - explosionStart) >= 1 then
            shouldQuit = true
            collided = false
        end
    elseif not shouldQuit then
        otherCar[2] = otherCar[2] + (otherCar[3] + carSpeed) * framePerSecond * dt

        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            playerCar[2] = math.max(playerCar[2] - 40 * framePerSecond * dt, 0)
        elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            playerCar[2] = math.min(playerCar[2] + 40 * framePerSecond * dt, 500)
        end

        if otherCar[2] > 600 then
            otherCar[1] = love.math.random(2)
            otherCar[2] = -100
            otherCar[3] = love.math.random(40, 80)
        end

        if detect_collision() then
            carCrashSound:play()
            collided = true
            explosionStart = os.time()
            frame = 0
        end
    else
        print("Gameover!")
        love.event.quit()
    end
end
