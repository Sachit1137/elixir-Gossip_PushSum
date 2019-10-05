defmodule Proj2 do
  use GenServer

  def main do
    # Input of the nodes, Topology and Algorithm
    input = System.argv()
    [numNodes, topology, algorithm] = input
    numNodes = numNodes |> String.to_integer()
    startTime = System.monotonic_time(:millisecond)

    # Rounding of the values to the nearest square and cube
    numNodes =
      cond do
        topology == "torus" ->
          rowCountvalue = :math.pow(numNodes, 1 / 3) |> ceil
          rowCountvalue * rowCountvalue * rowCountvalue

        topology == "honeycomb" || topology == "randHoneycomb" || topology == "rand2D" ->
          row_count = :math.sqrt(numNodes) |> ceil
          row_count * row_count

        true ->
          numNodes
      end

    # Associating all nodes with their PID's
    allNodes =
      Enum.map(1..numNodes, fn x ->
        pid = start_node()
        updatePIDState(pid, x)
        pid
      end)

    # Indexing all the PID's with the nodes
    indexed_actors =
      Stream.with_index(allNodes, 1)
      |> Enum.reduce(%{}, fn {pids, nodeID}, acc -> Map.put(acc, nodeID, pids) end)

    # Setting the neighbors according to the chosen topology
    neighbours = set_neighbours(allNodes, indexed_actors, numNodes, topology)

    cond do
      algorithm == "gossip" ->
        IO.puts("Initiating Gossip Algorithm with #{topology} topology...")
        startGossip()

      algorithm == "push-sum" ->
        IO.puts("Initiating push-sum Algorithm with #{topology} topology...")
        startPushSum()

      true ->
        IO.puts("Invalid ALgorithm!")
    end
  end

  def init(:ok) do
    {:ok, {1, 1, [], 1}}
  end

  def start_node() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, [])
    pid
  end

  def updatePIDState(pid, nodeID) do
    GenServer.call(pid, {:UpdatePIDState, nodeID})
  end
  def startPushSum()
  end
  
  def startGossip()
  end
  
  def set_neighbours(actors, indexd_actors, numNodes, topology) do
    cond do
      topology == "line" ->
        Enum.reduce(1..numNodes, %{}, fn x, acc ->
          neighbors =
            cond do
              x == 1 -> [2]
              x == numNodes -> [numNodes - 1]
              true -> [x - 1, x + 1]
            end

          neighbor_pids =
            Enum.map(neighbors, fn i ->
              {:ok, n} = Map.fetch(indexd_actors, i)
              n
            end)

          {:ok, actor} = Map.fetch(indexd_actors, x)
          Map.put(acc, actor, neighbor_pids)
        end)
        
        topology == "full" ->
        Enum.reduce(1..numNodes, %{}, fn x, acc ->
          neighbors =
            cond do
              x == 1 -> Enum.to_list(2..numNodes)
              x == numNodes -> Enum.to_list(1..(numNodes - 1))
              true -> Enum.to_list(1..(x - 1)) ++ Enum.to_list((x + 1)..numNodes)
            end

          neighbor_pids =
            Enum.map(neighbors, fn i ->
              {:ok, n} = Map.fetch(indexd_actors, i)
              n
            end)

          {:ok, actor} = Map.fetch(indexd_actors, x)
          Map.put(acc, actor, neighbor_pids)
        end)

        topology == "honeycomb" ->
        common_honeycomb(numNodes, indexd_actors, topology)

        topology == "randHoneycomb" ->
        common_honeycomb(numNodes, indexd_actors, topology)

        
        topology == "rand2D" ->
        initial_map = %{}
        # creating a map with key = actor pid  and value = list of x and y coordinates
        actor_with_coordinates =
          Enum.map(actors, fn x ->
            Map.put(initial_map, x, [:rand.uniform()] ++ [:rand.uniform()])
          end)

        Enum.reduce(actor_with_coordinates, %{}, fn x, acc ->
          [actor_pid] = Map.keys(x)
          actor_coordinates = Map.values(x)

          list_of_neighbors =
            ([] ++
               Enum.map(actor_with_coordinates, fn x ->
                 if is_connected(actor_coordinates, Map.values(x)) do
                   Enum.at(Map.keys(x), 0)
                 end
               end))
            |> Enum.filter(&(&1 != nil))

          # one actor should not be its own neighbour
          updated_neighbors = list_of_neighbors -- [actor_pid]
          Map.put(acc, actor_pid, updated_neighbors)
        end)
        true-> IO.puts("Invalid topology!")
      end
    end
    
  # checks if 2 nodes are within 0.1 distance
  def is_connected(actor_cordinates, other_cordinates) do
    actor_cordinates = List.flatten(actor_cordinates)
    other_cordinates = List.flatten(other_cordinates)

    x1 = Enum.at(actor_cordinates, 0)
    x2 = Enum.at(other_cordinates, 0)
    y1 = Enum.at(actor_cordinates, 1)
    y2 = Enum.at(other_cordinates, 1)

    x_dist = :math.pow(x2 - x1, 2)
    y_dist = :math.pow(y2 - y1, 2)
    distance = round(:math.sqrt(x_dist + y_dist))

    cond do
      distance > 1 -> false
      distance <= 1 -> true
    end
  end
end
Proj2.main()
