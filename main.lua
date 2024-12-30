Board = {
  w=0, h=0, mines=0,
  state = {}, -- 0 = safe, 1 = mine
  info = {} -- '-' = hidden, # = revealed, 'F' = flag
}
Startzone = 1 -- empty space around starting tile to prevent single-tile starts

function Board:new(x, y, m)
  local b = {w=x, h=y, mines=m}
  setmetatable(b, self)
  self.__index = self
  for r=1,y do
    b.state[r] = {}
    b.info[r] = {}
    for c=1,x do
      b.state[r][c] = 0
      b.info[r][c] = '-'
    end
  end
  return b
end

function Board:display()
  local row_spc = Digits(self.w)
  local col_spc = Digits(self.h)
  for r=1,self.h do
    local line = string.rep(" ", col_spc-Digits(r)) .. r .. ": "
    for c=1,self.w do
      line = line .. self.info[r][c] .. string.rep(" ", row_spc)
    end
    print(line)
  end
  local numRow = string.rep(" ", col_spc + 2)
  for r=1,self.w do
    numRow = numRow .. r .. string.rep(" ", row_spc+1-Digits(r))
  end
  print(numRow)
end
function Digits(n) return string.len(n) end

function Board:generateMines(sr, sc)
  self.mines = math.min(self.mines, self.w*self.h - (Startzone*2+1)*(Startzone*2+1))
  for i=1,self.mines do
    local r, c
    repeat
      r = math.random(self.h)
      c = math.random(self.w)
    until self.state[r][c] ~= 1 and (r < sr-Startzone or r > sr+Startzone or c < sc-Startzone or c > sc+Startzone)
    self.state[r][c] = 1
  end
end

function Board:applyAdj(r, c, op)
  local val = 0
  for i=r-1,r+1 do
    for j=c-1,c+1 do
      if (i ~= r or j ~= c) and i > 0 and i <= self.h and j > 0 and j <= self.w then
        local t = op(i, j)
        if t then val = val + t end
      end
    end
  end
  return val
end

function Board:adjMines(r, c)
  return self:applyAdj(r, c, function (i, j)
    return self.state[i][j]
  end)
end

function Board:revealTile(r, c)
  if self.info[r][c] ~= '-' then return end
  if self.state[r][c] == 1 then
    self.info[r][c] = 'X'
    return
  end
  self.info[r][c] = self:adjMines(r, c)
  if self.info[r][c] == 0 then
    self:applyAdj(r, c, function (i, j) self:revealTile(i, j) end)
  end
end

function Board:revealAll()
  for r=1,self.h do
    for c=1,self.w do
      self.info[r][c] = '-'
      self:revealTile(r, c)
    end
  end
end

function Board:updateOutcome() -- checks for win/loss
  local outcome = 1
  for r=1,self.h do
    for c=1,self.w do
      if self.info[r][c] == 'X' then return 2 end
      if self.state[r][c] == 0 and (self.info[r][c] == '-' or self.info[r][c] == 'F') then outcome = 0 end
    end
  end
  return outcome
end

function Rungame()
  print("Input the board width, height, and number of mines, separated by a space:")
  local w,h,m = io.read("*n","*n","*n")
  while w < 1 or h < 1 or m < 1 do
    print("Invalid input, please try again!")
    w,h,m = io.read("*n","*n","*n")
  end
  local board = Board:new(w, h, m)

  print("\nInput format: cmd row col\n cmd can be 1 to reveal a tile or 2 to flag\n row and col are the coordinates of the check/flag\n if there are enough flags around a revealed tile, you can check it to reveal all adjacent unflagged tiles")

  local outcome = 0 -- 0 = ongoing, 1 = win, 2 = lose
  local turn = 0
  local makeMines = true
  while outcome == 0 do
    turn = turn + 1
    print("\nRound " .. turn)
    board:display()
    local cmd,r,c = io.read("*n","*n","*n") -- cmd: 1 for check, 2 for flag
    if r < 1 or r > board.h or c < 1 or c > board.w then
      print("Invalid input!"); turn = turn - 1
    elseif cmd == 1 then
      if makeMines then board:generateMines(r, c); makeMines = false end
      if board.info[r][c] == '-' then board:revealTile(r, c)
      elseif board.info[r][c] == 'F' then print("That tile is flagged!"); turn = turn - 1
      else
        -- quality of life feature, if there are n flags around a tile that displays the number n, then reveal all unflagged tiles around it
        local fcount = board:applyAdj(r, c, function (i, j)
          if board.info[i][j] == 'F' then return 1 else return 0 end
        end)
        local adjm = board:adjMines(r, c)
        if fcount == adjm then board:applyAdj(r, c, function (i, j) board:revealTile(i, j) end)
        elseif fcount > adjm then print("There are too many flags around that tile!")
        else print("There are not enough flags around that tile!") end
      end
    elseif cmd == 2 then
      if board.info[r][c] == '-' then board.info[r][c] = 'F'
      elseif board.info[r][c] == 'F' then board.info[r][c] = '-'
      else print("That tile has already been revealed!"); turn = turn - 1 end
    else print("Invalid input!"); turn = turn - 1 end
    outcome = board:updateOutcome()
  end

  print("\nRound " .. turn)
  board:display()
  if outcome == 1 then print("\nYou won!") else print("\nYou lost!") end
  print("This was the full board:")
  board:revealAll()
  board:display()
end


math.randomseed(os.time())

repeat
  Rungame()
  print("\nPlay again? (y/n)")
  io.read()
  local again = io.read()
  while again ~= 'y' and again ~= 'n' do
    print("Invalid input!")
    again = io.read()
  end
until again == 'n'

return