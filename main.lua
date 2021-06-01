-- NEEDS OPTIMIZATIONS
local angle = 0
local relativeGap = 0.5
local relativeMarker = 0.1
local relativeWidth = 0.08
local rows, cols, circles, curves, markerSize, gap
local opacity = 0.3
local constants = {
  circleRadius = 20,
  speed = 1,
  drawLines = false,
  colors = true,
  drawMarkers = true,
  drawCircles = true,
  drawTable = true
}

function HSV(h, s, v, a)
  if s <= 0 then return v,v,v end
  h, s, v = h/256*6, s/255, v/255
  local c = v*s
  local x = (1-math.abs((h%2)-1))*c
  local m,r,g,b = (v-c), 0,0,0
  if h < 1     then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else              r,g,b = c,0,x
  end return (r+m),(g+m),(b+m), a or 1
end

function addColors(h1, h2)
  local r1, g1, b1, a1 = HSV(h2, 255, 255)
  local r2, g2, b2, a2 = HSV(h1, 255, 255)
  return (r1+r2)/2, (g1+g2)/2, (b1+b2)/2, (a1+a2)/2
end

local function distance(x1,y1,x2,y2)
  return ((x1-x2)^2 + (y1-y2)^2)^0.5
end

function Curve()
  local self = {}
  self._points = {}
  self.draw = function(self)
    if #self._points >= 4 then
      love.graphics.line(self._points)
    end
  end
  self.addPoint = function(self, x, y)
    table.insert(self._points, x)
    table.insert(self._points, y)
  end
  self.clear = function(self)
    self._points = {}
  end
  return self
end

function genTable(default, N)
  local t = {}
  for i=0, N-1 do
    if type(default) == "function" then
      t[i] = default()
    else
      t[i] = default
    end
  end
  return t
end

function roundDown(X)
  return X - (X / 10)
end

function recalc(w, h)
  local realSize = (relativeGap + 1) * constants.circleRadius
  local rows = roundDown(w  / realSize)
  local cols = roundDown(h / realSize)
  circles = genTable(angle, math.max(rows, cols))
  curves = {}
  for i=0, rows-1 do
    curves[i] = genTable(Curve, cols)
  end
end

function love.load(args, unfilteredArgs)
  for i=1,#args do
    for name in pairs(constants) do
      if "-"..name == args[i] then
        if type(constants[name]) == "boolean" then
          constants[name] = args[i+1] == "true"
        elseif type(constants[name]) == "number" then
          constants[name] = tonumber(args[i+1])
        end
        i = i + 1
        break
      end
    end
  end

  markerSize = constants.circleRadius*relativeMarker
  gap = constants.circleRadius*(1+relativeGap)

  recalc(love.graphics.getDimensions())
end

function love.update(dt)
  angle = angle + constants.speed * dt
  for i in pairs(circles) do
    circles[i] = angle * (i+1)
  end
  if angle > math.pi*2 then
    angle = angle % math.pi*2
    for _, j in pairs(curves) do
      for _, curve in pairs(j) do
        curve:clear()
      end
    end
  end
end

function setColor(r,g,b,a)
  if constants.colors then
    love.graphics.setColor(r,g,b,a)
  else
    love.graphics.setColor(1, 1, 1, a)
  end
end

function drawMarker(x, y)
  if constants.drawMarkers then
    love.graphics.circle("fill", x, y, markerSize)
  end
end

function drawCircle(x, y)
  if constants.drawCircles then
    love.graphics.circle("line", x, y, constants.circleRadius)
  end
end

function love.draw()
  local w,h = love.graphics.getDimensions()

  love.graphics.setLineJoin("none")
  love.graphics.setLineStyle("smooth")
  -- Circles and lines
  for i, circleAngle in pairs(circles) do
    local dist = constants.circleRadius + (i+1) * gap*2
    local p = i/#circles

    -- X-axis
    if dist+gap < w then
      local x = dist + constants.circleRadius * math.cos(circleAngle-math.pi/2)
      local y = gap  + constants.circleRadius * math.sin(circleAngle-math.pi/2)
      setColor(HSV(p*511, 255, 255))
      love.graphics.setLineWidth(constants.circleRadius * relativeWidth)
      drawMarker(x, y)
      drawCircle(dist, gap)

      if constants.drawLines then
        setColor(HSV(p*511, 255, 255, opacity))
        love.graphics.line(x, 0, x, h)
      end
    end
    -- Y-axis
    if dist+gap < h then
      local x = gap  + constants.circleRadius * math.cos(circleAngle-math.pi/2)
      local y = dist + constants.circleRadius * math.sin(circleAngle-math.pi/2)
      setColor(HSV(p*511, 255, 255))
      love.graphics.setLineWidth(constants.circleRadius * relativeWidth)
      drawMarker(x, y)
      drawCircle(gap, dist)

      if constants.drawLines then
        setColor(HSV(p*511, 255, 255, opacity))
        love.graphics.line(0, y, w, y)
      end
    end
  end

  -- Draw intersection point
  for i, circleAngle1 in pairs(circles) do
    for j, circleAngle2 in pairs(circles) do
      local distX = (constants.circleRadius + (i+1) * gap*2)
      local distY = (constants.circleRadius + (j+1) * gap*2)
      if distX+gap < w and distY+gap < h then
        local x = constants.circleRadius * math.cos(circleAngle1-math.pi/2) + distX
        local y = constants.circleRadius * math.sin(circleAngle2-math.pi/2) + distY
        
        setColor(addColors(i/#circles*511, j/#circles*511))
        drawMarker(x, y)
        curves[i][j]:addPoint(x, y)
      end
    end
  end

  -- Draw curves
  if constants.drawTable then
    for n1, j in pairs(curves) do
      for n2, curve in pairs(j) do
        setColor(addColors(n1/#circles*511, n2/#circles*511))
        curve:draw()
      end
    end
  end
end

function love.resize(w, h)
  angle = 0
  recalc(w,h)
end
