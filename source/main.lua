-- Playdate SDK
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
-- import "CoreLibs/animator"
-- import "CoreLibs/easing"
-- import "CoreLibs/keyboard"

-- Shooty
import "Global"
import "BulletManager"


local gfx <const> = playdate.graphics
local vec2 <const> = playdate.geometry.vector2D



-- Images
local buffer = gfx.image.new(400, 240, gfx.kColorClear)

local screenCenterOffset = vec2.new(200, 120)
local cameraPosition = screenCenterOffset
-- playdate.graphics.setDrawOffset(x, y) -- can use this?


Player = {}
Player.__index = Player

function Player.new(pos, size)
	local a = {
		pos = vec2.new(pos.x, pos.y),
		size = size,
		collectorOffset = 128,
		collectorSize = 32,
	}
	setmetatable(a, Player)

	return a
end


function Player:update()
	local dir = vec2.new(0, 0)
	if playdate.buttonIsPressed(playdate.kButtonLeft) then dir.x -= 1
	elseif playdate.buttonIsPressed(playdate.kButtonRight) then dir.x += 1 end
	if playdate.buttonIsPressed(playdate.kButtonUp) then dir.y -= 1
	elseif playdate.buttonIsPressed(playdate.kButtonDown) then dir.y += 1 end
	
	if dir.x ~= 0 and dir.y ~= 0 then
		dir:normalize()
	end

	local speed = 100.0
	self.pos += dir * (speed * deltaTimeSeconds)

	local fire = playdate.buttonJustPressed(playdate.kButtonB)
	if fire then
		shootBullets(self.pos.x, self.pos.y, 200, 1)
	end
end


-- expects to just draw into a locked background
-- TODO: probably best to draw using sprites?
function Player:draw()
	local halfSize = self.size * 0.5
	gfx.drawRect(self.pos.x - halfSize, self.pos.y - halfSize, self.size, self.size)

	-- draw collector
	local crankAngle = playdate.getCrankPosition() * (math.pi / 180.0)
	local crankDir = vec2.new(math.sin(crankAngle), -math.cos(crankAngle))
	local collectorPos = self.pos + crankDir * self.collectorOffset
	gfx.drawCircleAtPoint(collectorPos.x, collectorPos.y, self.collectorSize)
end


local player = Player.new(screenCenterOffset, 16)
local bulletManager = BulletManager.new(2400)
bulletManager.bulletImage = gfx.image.new("images/shot_8px")
bulletManager:enableSpacePartition()

function shootBullets(x, y, speed, count)
	local angleInc = (2 * math.pi) / count
	local angle = 0.0

	for i = 1, count do
		local bullet = bulletManager:getInactiveBullet()
		if bullet ~= nil then
			local vx = math.cos(angle) * speed
			local vy = math.sin(angle) * speed
			bullet:init(x, y, vx, vy, 3.0)
			angle += angleInc
		else
			break
		end
	end
end



function draw(target)
	target:clear(gfx.kColorWhite)
	gfx.lockFocus(target)

	player:draw()
	bulletManager:draw()

	gfx.unlockFocus()
end


-------------------------------------------------------------------------------
-- MAIN -----------------------------------------------------------------------
-------------------------------------------------------------------------------
function playdate.update()
	totalTimeSeconds += deltaTimeSeconds

	-- update
	player:update()
	bulletManager:update()

	-- collide collector with bullets
	local crankAngle = playdate.getCrankPosition() * (math.pi / 180.0)
	local crankDir = vec2.new(math.sin(crankAngle), -math.cos(crankAngle))
	local collectorPos = player.pos + crankDir * player.collectorOffset
	local hits = bulletManager:collideCircle(collectorPos.x, collectorPos.y, player.collectorSize)
	-- if hits > 0 then
	-- 	print(string.format("Hits: %d", hits))
	-- end

	-- test space partition is working
	local bullet = bulletManager.bullets[bulletManager.maxBullets]
	if bulletManager.spacePartition ~= nil and bullet.lifetime > 0.0 then
		local x, y = bullet.x, bullet.y
		local i = bulletManager.spacePartition:getIndex(x, y)
		print(string.format("(%.2f, %.2f) --> [%d]  (lifetime = %.2f)", x, y, i, bullet.lifetime))
	end

	-- draw
	draw(buffer)
	gfx.sprite.redrawBackground()

	gfx.sprite.update()
	playdate.timer.updateTimers()
end


function init()
	buffer:clear(gfx.kColorBlack)

	gfx.sprite.setBackgroundDrawingCallback(
		function(x, y, width, height)
			gfx.setClipRect(x, y, width, height)
			buffer:draw(0, 0)
			gfx.clearClipRect()
		end
	)
end

init()
