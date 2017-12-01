# Node rebalancing

## Game Node

This is the master node and will push out zones to all of the nodes running only the `World` application. The game node also contains the `World` application and will run zones.

```bash
cd apps/game
iex --sname game -S mix
```

After starting up the game node will contain 7 zone processes.

## World Nodes

These nodes will contain processes spawned by the game server (zones). A `ZoneController` is on each node locally registered that the `ZoneMaster` communicates with.

```bash
cd apps/world
iex --sname world-1 -S mix
iex --sname world-2 -S mix
```

## Connect nodes

From the game node connect up to the world nodes. Shortly after connecting nodes you'll see the zones rebalance. Replace `localhost` with the hostname of your computer. From each world server run:

```elixir
Node.connect(:"game@localhost")
```

As each node connects the game node will rebalance zones on to the node.

## Rebalancing

When new nodes come online or go offline, the game node will try rebalancing nodes.
