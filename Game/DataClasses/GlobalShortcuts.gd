class_name GS
extends Node

static var KnownAttacks: AttackDatabase:
    get:
        return GlobalAttackDatabaseDummy as AttackDatabase
