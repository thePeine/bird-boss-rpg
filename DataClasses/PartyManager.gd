extends Node

var _party: Dictionary = {
    "p1": PlayerBattleStats.new(),
    "p2": PlayerBattleStats.new(),
}

func get_party_member(name: String) -> PlayerBattleStats:
    return _party.get(name)
