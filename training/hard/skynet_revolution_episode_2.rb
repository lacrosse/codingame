Edge = Struct.new(:dst, :length)

class Graph
  def initialize
    @adjs = Hash.new { |h, k| h[k] = [] }
  end

  def connect(src, dst)
    @adjs[src] << Edge.new(dst, 1)
    @adjs[dst] << Edge.new(src, 1)
  end

  def disconnect(src, dst)
    @adjs[src].reject! { |edge| edge.dst == dst }
    @adjs[dst].reject! { |edge| edge.dst == src }
  end

  def neighbors(vertex)
    @adjs[vertex].map(&:dst)
  end

  def filtered_neighbor_edges(vertices, vertex, sinks = nil)
    if sinks && sinks.include?(vertex)
      []
    else
      @adjs[vertex].select { |edge| vertices.include?(edge.dst) }
    end
  end

  def dijkstra(src, dst = nil, sinks = nil)
    vertices = @adjs.keys

    distances = vertices.map { |v| [v, Float::INFINITY] }.to_h
    previouses = vertices.map { |v| [v, nil] }.to_h

    distances[src] = 0

    until vertices.empty?
      nearest_vertex = vertices.reduce do |a, b|
        if distances[a] && (!distances[b] || distances[a] < distances[b])
          a
        else
          b
        end
      end

      break unless distances[nearest_vertex]

      filtered_neighbor_edges(vertices, nearest_vertex, sinks).each do |neighbor_edge|
        neighbor_vertex = neighbor_edge.dst
        alt = distances[nearest_vertex] + neighbor_edge.length

        if alt < distances[neighbor_vertex]
          distances[neighbor_vertex] = alt
          previouses[neighbor_vertex] = nearest_vertex
        end
      end
      vertices.delete nearest_vertex
    end

    paths = distances.map { |k, v| [k, get_path(previouses, src, k)] }.to_h

    { paths: paths, distances: distances }
  end

  private

  def get_path(previouses, src, dest)
    get_path_recursively(previouses, src, dest).reverse
  end

  # Unroll through previouses array until we get to source
  def get_path_recursively(previouses, src, dst)
    if src == dst
      [src]
    elsif !(prev = previouses[dst])
      []
    else
      [dst] + get_path_recursively(previouses, src, prev)
    end
  end
end

STDOUT.sync = true

graph = Graph.new
nodes_number, links_number, exits_number = gets.split.map(&:to_i)
links_number.times { graph.connect(*gets.split.map(&:to_i)) }
exits = exits_number.times.map { gets.to_i }

loop do
  agent = gets.to_i

  traversal = graph.dijkstra(agent, nil, exits)

  enter_nodes_with_duplicates = exits.flat_map { |exit| graph.neighbors(exit) }

  weakest_path =
    traversal[:paths]
      .values_at(*exits)
      .reject(&:empty?)
      .min_by { |path| [path.size - enter_nodes_with_duplicates.count { |enter| path.include?(enter) }, path.size] }

  weakest_link = weakest_path[-2..]

  graph.disconnect(*weakest_link)

  puts weakest_link * " "
end
