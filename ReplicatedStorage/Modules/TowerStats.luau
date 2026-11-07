local TowerStats = {
	["ArcherTower"] = {
		Name = "Archer Tower",
		PlaceCost = 120,
		SellRefund = 0.5,
		ProjectileSpeed = 60,
		ReleaseTime = 0.42,
		IdleAnim = "ArcherIdle",
		AttackAnim = "ArcherShoot",
		Levels = {
			[1] = {Damage = 9,Range = 15,Cooldown = 1.2},
			[2] = {Damage = 12,Range = 18,Cooldown = 1.0,Price = 150},
			[3] = {Damage = 25,Range = 22,Cooldown = 0.8,Price = 300},
		},
	},
	["SwordTower"] = {
		Name = "Sword Tower",
		PlaceCost = 90,
		SellRefund = 0.5,
		HitTime = 0.3,
		MaxHits = 3,
		IdleAnim = "KnightIdle",
		AttackAnim = "KnightSlash",
		Levels = {
			[1] = {Damage = 11,Range = 10,Cooldown = 0.85},
			[2] = {Damage = 15,Range = 11,Cooldown = 0.75,Price = 110},
			[3] = {Damage = 24,Range = 12,Cooldown = 0.65,Price = 220},
		},
	},
}

return TowerStats
