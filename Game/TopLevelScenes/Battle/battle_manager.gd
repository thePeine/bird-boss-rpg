extends Node

var overworld_scene: Node2D
var current_battle: BattleScene

const BATTLE_SCENE =          preload("res://TopLevelScenes/Battle/BattleScene.tscn")

# Make the existing tree invisible, and insert a new battle node.  Note: the pre-battle scene 
# is kept in the scene graph, so I can switch back when the battle is complete
func battle_manager_start_battle(background_texture: Texture2D, player_party_data: Array[PlayerBattleStats.PlayerType], enemy_party_data: Array[PlayerBattleStats.PlayerType]) -> void:
    overworld_scene = get_tree().current_scene
    overworld_scene.process_mode = PROCESS_MODE_DISABLED # Freezes scripts & physics
    overworld_scene.visible = false 
    
    current_battle = BATTLE_SCENE.instantiate() as BattleScene
    get_tree().root.add_child(current_battle)
    if not current_battle.is_node_ready():
        await current_battle.ready
    current_battle.setup_battle(background_texture, player_party_data, enemy_party_data)
    
func battle_manager_end_battle() -> void:
    pass
