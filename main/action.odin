package main

Action :: struct {
  actor:    EntityId,
  type:     ActionType,
  data:     ActionData,
  duration: f32,
}

ActionType :: enum {
  None,
  Move,
  MoveUpStairs,
  MoveDownStairs,
  Attack,
  Wait,
  Activate,
  Deactivate,
}

ActionData :: union {
  MoveActionData,
  AttackActionData,
}

MoveActionData :: struct {
  to: GridPos,
}

AttackActionData :: struct {
  target: EntityId,
}

activate_action :: proc(actor: EntityId, duration: f32) -> Action {
  return Action{actor = actor, type = .Activate, data = {}, duration = duration}
}

deactivate_action :: proc(actor: EntityId, duration: f32) -> Action {
  return Action{actor = actor, type = .Deactivate, data = {}, duration = duration}
}

attack_action :: proc(actor, target: EntityId, duration: f32) -> Action {
  return Action{actor = actor, type = .Attack, data = AttackActionData{target = target}, duration = duration}
}

move_action :: proc(actor: EntityId, to: GridPos, duration: f32) -> Action {
  return Action{actor = actor, type = .Move, data = MoveActionData{to = to}, duration = duration}
}

wait_action :: proc(actor: EntityId, duration: f32) -> Action {
  return Action{actor = actor, type = .Wait, data = {}, duration = duration}
}

handle_enemy_action :: proc(game: ^Game, action: Action) -> (ok: bool) {
  enemy_ok, enemy := entity_manager_get(&game.entity_manager, action.actor)
  if !enemy_ok {
    return false
  }
  switch action.type {
  case .None:
    {
      unreachable()
    }
  case .Move:
    {
      data := action.data.(MoveActionData)
      entity_manager_set_pos(&game.entity_manager, enemy.id, data.to)
    }
  case .MoveUpStairs:
    {
      unreachable()
    }
  case .MoveDownStairs:
    {
      unreachable()
    }
  case .Attack:
    {
      data := action.data.(AttackActionData)
      attack(game, enemy.id, data.target)
    }
  case .Wait:
    {
      // NOOP
    }
  case .Activate:
    {
      entity_manager_set_status(&game.entity_manager, enemy.id, .ACTIVE)
    }
  case .Deactivate:
    {
      entity_manager_set_status(&game.entity_manager, enemy.id, .INACTIVE)
    }
  }
  return true
}
