class_name Skins
extends RefCounted
## Gnome skins: looks only, never gameplay. Price in coins; -1 means only
## from a skin pack (PurchaseService, M5).

const CATALOG := [
	{"id": "classic", "name": "Klassiek", "body": Color(0.2, 0.35, 0.85), "hat": Color(0.9, 0.15, 0.15), "price": 0},
	{"id": "forest", "name": "Bosgroen", "body": Color(0.2, 0.5, 0.25), "hat": Color(0.55, 0.35, 0.15), "price": 150},
	{"id": "sunny", "name": "Zonnegeel", "body": Color(1.0, 0.8, 0.2), "hat": Color(1.0, 0.45, 0.1), "price": 250},
	{"id": "night", "name": "Nachtblauw", "body": Color(0.12, 0.15, 0.4), "hat": Color(0.85, 0.85, 1.0), "price": 400},
	{"id": "candy", "name": "Snoeproze", "body": Color(1.0, 0.55, 0.75), "hat": Color(0.55, 0.85, 1.0), "price": 600},
	{"id": "gold", "name": "Goud", "body": Color(0.95, 0.75, 0.2), "hat": Color(1.0, 0.95, 0.6), "price": 1500},
	{"id": "pirate", "name": "Piraat", "body": Color(0.15, 0.15, 0.15), "hat": Color(0.85, 0.1, 0.1), "price": -1},
	{"id": "christmas", "name": "Kerst", "body": Color(0.1, 0.55, 0.2), "hat": Color(0.95, 0.95, 0.95), "price": -1},
]


## Unknown ids fall back to the classic skin.
static func get_skin(id: String) -> Dictionary:
	for skin in CATALOG:
		if skin.id == id:
			return skin
	return CATALOG[0]
