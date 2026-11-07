# roblox tower defense

tower defense game i made in roblox studio

2 towers (archer, sword), 2 enemies (zombie, brute), 15 waves on easy. you get cash from kills and waves, can upgrade towers to lvl 3 or sell them. 3 lives, game restarts by itself when you win or lose

## folders

same layout as in studio

- `ServerScriptService` - server stuff, waves, enemies, towers, cash
- `ReplicatedStorage/Modules` - stats, wave data, path and placement checks (client + server both use these)
- `StarterPlayer/StarterPlayerScripts` - rendering, vfx, placing towers, ui

## how enemies work

server doesnt make any parts for enemies, it just saves when they spawned and how fast they are. position is `(time - spawnTime) * speed` along the path so the client can draw them from that and nothing has to get sent every frame

towers check the same math on the server for hits

## setup
for trying the game, please use the rbxl.
