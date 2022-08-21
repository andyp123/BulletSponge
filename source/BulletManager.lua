-- Playdate SDK
import "CoreLibs/object"
import "CoreLibs/graphics"

-- Shooty
import "Global"

local gfx <const> = playdate.graphics


BulletManager = {}
BulletManager.__index = BulletManager

BulletManager.bounds = playdate.geometry.rect.new(0, 0, 400, 240)
BulletManager.unpackBounds = function()
	local b = BulletManager.bounds
	return b.x, b.y, b.x + b.width, b.y + b.height
end

function BulletManager.new(maxBullets)
	local bullets = table.create(maxBullets)
	local inactiveBulletStack = table.create(maxBullets)
	for i = 1, maxBullets do
		local bullet = Bullet.new()
		bullets[i] = bullet
		inactiveBulletStack[i] = bullet
	end

	local a = {
		maxBullets = maxBullets,
		bullets = bullets,
		inactiveBulletStack = inactiveBulletStack,
		inactiveBulletStackIndex = maxBullets,
		bulletImage = nil,
	}
	setmetatable(a, BulletManager)

	return a
end


function BulletManager:update()
	local bullets = self.bullets
	local deltaTime = deltaTimeSeconds

	local xMin, yMin, xMax, yMax = BulletManager.unpackBounds()

	for i = 1, self.maxBullets do
		local bullet = bullets[i]

		if bullet.lifetime > 0.0 then
			bullet.x += bullet.vx * deltaTime
			bullet.y += bullet.vy * deltaTime
			bullet.lifetime -= deltaTime

			-- bounds check
			local x, y = bullet.x, bullet.y
			if x < xMin or x > xMax or y < yMin or y > yMax then
				bullet.lifetime = 0.0
			end

			-- return to inactive stack
			if bullet.lifetime <= 0.0 then
				self.inactiveBulletStackIndex += 1
				self.inactiveBulletStack[self.inactiveBulletStackIndex] = bullet
			end
		end
	end
end


function BulletManager:collideRect(px, py, w, h)

end


function BulletManager:collideCircle(px, py, r)
	local bullets = self.bullets
	local collisionCount = 0

	for i = 1, self.maxBullets do
		local bullet = bullets[i]
		local x, y = bullet.x, bullet.y
		if bullet.lifetime > 0.0 and (x-px)*(x-px) + (y-py)*(y-py) < r*r then
			bullet.lifetime = 0.0
			collisionCount += 1
			self.inactiveBulletStackIndex += 1
			self.inactiveBulletStack[self.inactiveBulletStackIndex] = bullet
		end
	end

	return collisionCount
end


function BulletManager:getInactiveBullet()
	local idx = self.inactiveBulletStackIndex

	if idx > 0 then
		local bullet = self.inactiveBulletStack[idx]
		self.inactiveBulletStack[idx] = nil
		self.inactiveBulletStackIndex -= 1
		return bullet
	end

	return nil
end


function BulletManager:draw()
	local bullets = self.bullets
	local bulletImage = self.bulletImage

	for i = 1, self.maxBullets do
		local bullet = bullets[i]

		if bullet.lifetime > 0.0 then
			--gfx.fillRect(bullet.x - 2, bullet.y - 2, 4, 4)
			bulletImage:drawCentered(bullet.x, bullet.y)
		end
	end
end




Bullet = {}
Bullet.__index = Bullet

function Bullet.new()
	local a = {
		x = 0.0,
		y = 0.0,
		vx = 0.0,
		vy = 0.0,
		lifetime = 0.0, -- lifetime > 0 means active
	}
	setmetatable(a, Bullet)

	return a
end


function Bullet:init(x, y, vx, vy, lifetime)
	self.x = x
	self.y = y
	self.vx = vx
	self.vy = vy
	self.lifetime = lifetime
end