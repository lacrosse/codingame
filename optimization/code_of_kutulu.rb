STDOUT.sync = true

require "set"

class Graph
  def initialize
    @adjs = Hash.new { |h, k| h[k] = Set[] }
  end

  def connect(src, dst)
    [[src, dst], [dst, src]].each { |a, b| @adjs[a] << b }
  end

  def bfs(starts)
    v = Set[]
    q = starts.dup
    t = []

    while current = q.shift
      if v.add?(current)
        t << current
        q.push(*@adjs[current])
      end
    end

    t
  end
end

width = gets.to_i
height = gets.to_i
grid = height.times.flat_map do |y|
  gets.chomp.chars.zip(0..).map { |c, x| [[x, y], c] }
end.to_h

def not_a_wall?(c)
  ".w"[c]
end

def dist(a, b)
  (a[0] - b[0]).abs + (a[1] - b[1]).abs
end

graph = Graph.new
grid.select { |_, c| not_a_wall?(c) }.each { |(x, y), _|
  neighbors = [x - 1, x + 1].product([y]) + [x].product([y - 1, y + 1])
  neighbors
    .select { |nb| grid[nb] }
    .select { |nb| not_a_wall?(grid[nb]) }
    .each { |nb| graph.connect([x, y], nb) }
}

spawns = grid.select { |_, c| c == ?w }.map(&:first)

# sanity_loss_lonely: how much sanity you lose every turn when alone, always 3 until wood 1
# sanity_loss_group: how much sanity you lose every turn when near another player, always 1 until wood 1
# wanderer_spawn_time: how many turns the wanderer take to spawn, always 3 until wood 1
# wanderer_life_time: how many turns the wanderer is on map after spawning, always 40 until wood 1
sanity_loss_lonely, sanity_loss_group, wanderer_spawn_time, wanderer_life_time = gets.split(" ").collect { |x| x.to_i }
plan = 2

loop do
  explorers = []
  wanderers = []
  effects = []
  gets.to_i.times do
    entity_type, *ints = gets.split

    id, x, y, param_0, param_1, param_2 = ints.map &:to_i

    common = { id: id, coords: [x, y] }

    case entity_type
    when "EXPLORER"
      explorers << common.merge(sanity: param_0, ignore_1: param_1, ignore_2: param_2)
    when "WANDERER"
      time = param_1 == 0 ? { time_to_spawn: param_0 } : { time_to_recall: param_0 }
      wanderers << common.merge(time).merge(state: param_1, target: param_2)
    when "EFFECT_PLAN"
      effects << { time_to_fade: param_0, author_id: param_1 }
    end
  end

  STDERR.puts "Explorers:"
  explorers.each { |exp| STDERR.puts exp.inspect }
  STDERR.puts "Wanderers:"
  wanderers.each { |w| STDERR.puts w.inspect }

  me = explorers[0]
  other_explorers = explorers[1..]

  my_wanderers = wanderers.reject { |w| w[:target] < 0 }.select { |w| explorers.find { |exp| exp[:id] == w[:target] }[:coords] == me[:coords] }

  threats = if wanderers.empty?
      spawns
    else
      my_wanderers.map { |w| w[:coords] }
    end

  bfs_from_threats = graph.bfs(threats)

  STDERR.puts "From threats"
  STDERR.puts bfs_from_threats.inspect

  safe = bfs_from_threats.select { |cs|
    !other_explorers.any? || other_explorers.any? { |exp| dist(exp[:coords], cs) <= 2 }
  }

  STDERR.puts "Safe"
  STDERR.puts safe.inspect

  # bfs_from_me = graph.bfs([me[:coords]])

  # bfs_from_me_up_to_threats = bfs_from_me.take_while { |cs| !my_wanderers.any? { |w| w[:coords] == cs } }

  # STDERR.puts "From me"
  # STDERR.puts bfs_from_me.inspect
  # STDERR.puts "Up to"
  # STDERR.puts bfs_from_me_up_to_threats.inspect

  # safer = safe & bfs_from_me_up_to_threats

  safest = safe.last

  if safest && safest != me[:coords]
    puts "MOVE %d %d" % safest
  else
    others_in_range = other_explorers.count { |exp| dist(exp[:coords], me[:coords]) <= 2 }

    if plan > 0 && others_in_range > 1
      plan -= 1
      puts "WAIT plan?"
    else
      puts "WAIT waiting to be disciplined"
    end
  end
end
