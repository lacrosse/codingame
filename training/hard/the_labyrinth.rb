require "set"

class Graph
  def initialize
    @adjs = Hash.new { |h, k| h[k] = Set[] }
  end

  def connect(src, dst)
    [[src, dst], [dst, src]].each { |a, b| @adjs[a] << b }
  end

  def bfs(start)
    v = Set[]
    q = [start]
    t = []

    while current = q.shift
      if v.add?(current)
        t << current
        q.push(*@adjs[current])
      end
    end

    t
  end

  def path(src, dst)
    paths(src, [dst])[dst]
  end

  def paths(src, dsts)
    vertices = @adjs.keys.to_set

    distances = Hash.new(Float::INFINITY).merge(src => 0)
    previouses = Hash.new(nil)
    dsts_left = Set.new(dsts)

    until vertices.empty?
      nearest_vertex = vertices.min_by { |vert| distances[vert] }
      vertices.delete(nearest_vertex)

      (@adjs[nearest_vertex] & vertices).each do |neighbor|
        alt = distances[nearest_vertex] + 1

        if alt < distances[neighbor]
          distances[neighbor] = alt
          previouses[neighbor] = nearest_vertex
        end
      end

      break if dsts_left.delete(nearest_vertex).empty?
    end

    get_paths(previouses, src, dsts)
  end

  private

  def get_paths(previouses, src, dsts)
    dsts.map { |dst| [dst, get_path_recursively(previouses, src, dst)] }.to_h
  end

  def get_path_recursively(previouses, src, dst)
    if src == dst
      [src]
    elsif !(prev = previouses[dst])
      []
    else
      get_path_recursively(previouses, src, prev) + [dst]
    end
  end
end

class Maze
  attr_reader :kirk, :control_room

  class << self
    def not_a_wall?(c)
      ".TC"[c]
    end

    def mysterious?(c)
      ?? == c
    end
  end

  def initialize(kirk, grid)
    @kirk = kirk
    grid_hash = grid.zip(0..).flat_map { |l, y| l.chars.zip(0..).map { |c, x| [[x, y], c] } }.to_h
    @graph = Graph.new
    @start = @control_room = nil
    grid_hash.select { |_, c| self.class.not_a_wall?(c) }.each do |cs, c|
      x, y = cs
      neighbors = [x - 1, x + 1].product([y]) + [x].product([y - 1, y + 1])
      fs = neighbors.select { |n_x, n_y| (0...grid[0].size) === n_x && (0...grid.size) === n_y }
      fs.select { |n_cs| self.class.not_a_wall?(grid_hash[n_cs]) }.each { |n_cs| @graph.connect([x, y], n_cs) }
      if c == "T"
        @start = [x, y]
      elsif c == "C"
        @control_room = [x, y]
      end
    end
    @mysteries = grid_hash.select { |_, c| self.class.mysterious?(c) }.map(&:first).to_set
  end

  def path(triggered, alarm)
    if triggered
      @graph.path(kirk, @start)
    elsif @control_room && (paths = @graph.paths(control_room, [@kirk, @start])) && !paths[@kirk].empty? && paths[@start].size - 1 <= alarm
      paths[@kirk].reverse
    elsif point_of_interest = @graph.bfs(@kirk).select { |point| @mysteries.any? { |mystery| dist(mystery, point) == 1 } }[0]
      @graph.path(@kirk, point_of_interest)
    else
      raise "My life no longer has meaning."
    end
  end

  private

  def dist(a, b)
    (a[0] - b[0]).abs + (a[1] - b[1]).abs
  end
end

class Game
  def initialize(alarm)
    @triggered = false
    @fuel = 1200
    @alarm = alarm
    @maze = nil
  end

  def update_and_go!(new_maze)
    @maze = new_maze

    @triggered |= @maze.kirk == @maze.control_room
    @fuel -= 1

    cur, step, *_ = path
    cur_x, cur_y = cur
    step_x, step_y = step

    command = if cur_x < step_x
        "RIGHT"
      elsif cur_x > step_x
        "LEFT"
      elsif cur_y < step_y
        "DOWN"
      elsif cur_y > step_y
        "UP"
      end

    puts command
  end

  private

  def path
    @maze.path(@triggered, @alarm)
  end
end

STDOUT.sync = true

rows, _, alarm = gets.split.map &:to_i

game = Game.new(alarm)

loop { game.update_and_go!(Maze.new(gets.split.map(&:to_i).reverse, rows.times.map { gets.chomp })) }
