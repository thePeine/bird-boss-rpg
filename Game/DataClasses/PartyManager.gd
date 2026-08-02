extends Node

const player_punch_attack_name: String = "PlayerPunchAttack"
const player_use_item_name: String = "PlayerUseItem"
const player_bro_attack_name: String = "PlayerBroAttack"
const bird_boss_attack_name: String = "BirdBossAttack"

static func create_player_punch_attack() -> BattleAttackData:
    return BattleAttackData.new(player_punch_attack_name,  "Player Punch Attack", load("res://DataClasses/boxUIpunch.png") as Texture2D, 0, 10)
static func create_player_use_item() -> BattleAttackData:
    return BattleAttackData.new(player_use_item_name, "Use Item", load("res://DataClasses/boxUIitems.png") as Texture2D, 0, 10)
static func create_player_bro_attack() -> BattleAttackData:
    return BattleAttackData.new(player_bro_attack_name, "Bro Attack", load("res://DataClasses/boxUIbroattacks.png") as Texture2D, 0, 10)
static func create_bird_boss_attack() -> BattleAttackData:
    return BattleAttackData.new(bird_boss_attack_name,"Bird Boss Attack", load("res://DataClasses/boxUIpunch.png") as Texture2D, 0, 10)

const P1_Name = "p1"
const P2_Name = "p2"
const BirdBoss_Name = "birdboss"

var _party: Dictionary = {
    P1_Name: PlayerBattleStats.new(100, 100, 50, 50, 1, [create_player_punch_attack(),create_player_use_item(),create_player_bro_attack() ], PlayerBattleStats.PlayerType.P1),
    P2_Name: PlayerBattleStats.new(100, 100, 50, 50, 1, [create_player_punch_attack(),create_player_use_item(),create_player_bro_attack() ], PlayerBattleStats.PlayerType.P2),
    BirdBoss_Name: PlayerBattleStats.new(200, 200, 15, 15, 3, [create_bird_boss_attack(),create_player_use_item()], PlayerBattleStats.PlayerType.BirdBoss)
}

func get_party_member(name: String) -> PlayerBattleStats:
    return _party.get(name)
