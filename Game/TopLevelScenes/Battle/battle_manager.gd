extends Node

var overworld_scene: Node2D
var current_battle: BattleScene

const BATTLE_SCENE =          preload("res://TopLevelScenes/Battle/BattleScene.tscn")

func battle_manager_start_battle(background_texture: Texture2D, player_party_data: Array[PlayerBattleStats.PlayerType], enemy_party_data: Array[PlayerBattleStats.PlayerType]) -> void:
    # 1. Find and pause the active overworld scene
    overworld_scene = get_tree().current_scene
    overworld_scene.process_mode = PROCESS_MODE_DISABLED # Freezes scripts & physics
    overworld_scene.visible = false # Optional: hides overworld visually
    
    # 2. Load and instantiate the combat scene
    current_battle = BATTLE_SCENE.instantiate() as BattleScene
    # 3. Add battle directly to the tree root alongside the overworld
    get_tree().root.add_child(current_battle)
    if not current_battle.is_node_ready():
        await current_battle.ready
    current_battle.setup_battle(background_texture, player_party_data, enemy_party_data)
    
func battle_manager_end_battle() -> void:
    pass
