local Modules = script.Parent.Modules
require(Modules.Economy)
require(Modules.EnemyManager)
local TowerManager = require(Modules.TowerManager)
local WaveManager = require(Modules.WaveManager)

TowerManager.Start()
WaveManager.Start()
