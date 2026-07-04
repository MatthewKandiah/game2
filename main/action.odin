package main

DEFAULT_ANIMATION_TIME_NANOS: i64 : 500_000_000

Action :: struct {
  type:           ActionType,
  data:           ActionData,
  duration:       f32,
  animation_time: i64,
}

ActionType :: enum {
  Move,
  Attack,
  Alerted,
  Snarl,
  Deactivate,
}

ActionData :: union {
  MoveActionData,
  AttackActionData,
}

MoveActionData :: struct {
  to: GridPos,
}
move_action :: proc(to: GridPos, duration: f32) -> Action {
  return {
    type = .Move,
    data = MoveActionData{to = to},
    duration = duration,
    animation_time = DEFAULT_ANIMATION_TIME_NANOS,
  }
}

AttackActionData :: struct {
  target_entity: EntityId,
}
attack_action :: proc(target: EntityId, duration: f32) -> Action {
  return {
    type = .Attack,
    data = AttackActionData{target_entity = target},
    duration = duration,
    animation_time = DEFAULT_ANIMATION_TIME_NANOS,
  }
}

alerted_action :: proc(duration: f32) -> Action {
  return {type = .Alerted, duration = duration, animation_time = DEFAULT_ANIMATION_TIME_NANOS}
}

snarl_action :: proc(duration: f32) -> Action {
  return {type = .Snarl, duration = duration, animation_time = DEFAULT_ANIMATION_TIME_NANOS}
}

deactivate_action :: proc(duration: f32) -> Action {
  return {type = .Deactivate, duration = duration, animation_time = DEFAULT_ANIMATION_TIME_NANOS}
}

handle_action :: proc(game: ^Game, action: Action) {
  game.time += action.duration

  switch action.type {
  case .Alerted:
    {
      entity_manager_set_status(&game.entity_manager, game.active_entity, .ACTIVE)
    }
  case .Attack:
    {
      data := action.data.(AttackActionData)
      attack(game, game.active_entity, data.target_entity)
    }
  case .Deactivate:
    {
      entity_manager_set_status(&game.entity_manager, game.active_entity, .INACTIVE)
    }
  case .Move:
    // TODO handle player action
    {
      data := action.data.(MoveActionData)
	entity_manager_set_pos(&game.entity_manager, game.active_entity, data.to)
    }
  case .Snarl:
    {
      // NOOP
    }
  }

  game.active_entity = NONE_ENTITY_ID
}
