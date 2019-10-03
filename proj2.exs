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
    neighbours = set_neighbours()


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


end
Proj2.main()
