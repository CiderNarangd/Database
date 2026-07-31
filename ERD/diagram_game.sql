
Table "user_game_info" {
  "user_idx" bigint [pk]
  "user_name" nvarchar(20) [unique]
  "level" int [default: 1]
  "exp" int [default: 0]
  "free_goods" int [default: 0]
  "paid_goods" int [default: 0]
  "skill_points" int [default: 0]
  "score" int
  "guild_idx" bigint [default: 0]
  "guild_name" nvarchar(20) [not null, default: '']
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]
}

Table "equip_inven" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "item_type" int
  "item_id" int
  "option1_id" int [default: 0]
  "option1_value" int [default: 0]
  "option2_id" int [default: 0]
  "option2_value" int [default: 0]
  "option3_id" int [default: 0]
  "option3_value" int [default: 0]
  "is_equipped" tinyint [default: 0]
  "item_expiration_date" datetime [default: '2050-01-01']
  "updated_date" datetime
  "created_date" datetime [default: `getdate()`]

  Indexes {
    user_idx [name: "ix_equip_inven_user_idx"]
  }
}

Table "equip_item" {
  "user_idx" bigint
  "slot_type" int
  "inven_index" bigint [default: 0]
  "equipped_time" datetime [default: `getdate()`]

  Indexes {
    (user_idx, slot_type) [pk, name: "pk_equip_item"]
  }
}

Table "consumable_inven" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "item_type" int
  "item_id" int
  "quantity" int
  "item_expiration_date" datetime [default: '2050-01-01']
  "updated_date" datetime
  "created_date" datetime [default: `getdate()`]

  Indexes {
    user_idx [name: "ix_consumable_inven_user_idx"]
  }
}

Table "Mail" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "title" nvarchar(50) [default: '']
  "contents" nvarchar(300) [default: '']
  "is_read" tinyint [default: 0]
  "item_type" int [default: 0]
  "item_id" int [default: 0]
  "send_time" datetime [default: `getdate()`]
  "expired_date" datetime [default: '2050-01-01']
  "is_deleted" tinyint [default: 0]

  Indexes {
    user_idx [name: "ix_mail_user_idx"]
    (is_deleted, expired_date) [name: "ix_mail_expired"]
  }
}

Table "user_quest" {
  "user_idx" bigint
  "quest_id" int
  "quest_status" int [default: 0]
  "quest_progress" int [default: 0]
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]

  Indexes {
    (user_idx, quest_id) [pk, name: "pk_user_quest"]
  }
}

Table "user_achievement" {
  "user_idx" bigint
  "achievement_id" int
  "achievement_cate" int
  "achievement_progress" int
  "achievement_goal" int
  "achievement_status" int
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]

  Indexes {
    (user_idx, achievement_id) [pk, name: "pk_user_achievement"]
  }
}

Table "user_skill" {
  "user_idx" bigint
  "skill_id" int
  "skill_level" int
  "created_date" datetime [default: `getdate()`]

  Indexes {
    (user_idx, skill_id) [pk, name: "pk_user_skill"]
  }
}

Table "friend" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "friend_idx" bigint
  "created_date" datetime [default: `getdate()`]

  Indexes {
    user_idx [name: "ix_friend_user_idx"]
  }
}

Table "friend_request" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "request_user_idx" bigint
  "status" tinyint [default: 0]
  "created_date" datetime [default: `getdate()`]
  "responded_time" datetime

  Indexes {
    user_idx [name: "ix_fr_user_idx"]
    request_user_idx [name: "ix_fr_requester_idx"]
    created_date [name: "ix_created_date"]
  }
}

Table "match_history" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "match_idx" bigint
  "user_idx" bigint
  "opponent_user_idx" bigint
  "result" tinyint
  "score" int
  "opponent_score" int
  "user_info_list" nvarchar(300)
  "opponent_info_list" nvarchar(300)
  "match_time" int
  "match_start_date" datetime
  "match_end_date" datetime

  Indexes {
    (user_idx, seq_key) [name: "ix_match_history_user_idx"]
    match_end_date [name: "ix_match_history_end_date"]
  }
}

Table "daily_ranking" {
  "rank" "int IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "user_name" nvarchar(20)
  "score" int
}

Table "leader_board" {
  "season_idx" int
  "user_idx" bigint
  "score" int [default: 0]
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]

  Indexes {
    (season_idx, user_idx) [pk, name: "pk_season_useridx"]
    (season_idx, score) [name: "ix_leader_board_score"]
  }
}


Ref: friend.user_idx > user_game_info.user_idx
Ref: friend.friend_idx > user_game_info.user_idx
Ref: friend_request.user_idx > user_game_info.user_idx



Ref: "user_game_info"."user_idx" < "user_achievement"."user_idx"

Ref: "user_game_info"."user_idx" < "user_quest"."user_idx"

Ref: "user_game_info"."user_idx" < "equip_inven"."user_idx"

Ref: "user_game_info"."user_idx" < "consumable_inven"."user_idx"

Ref: "user_game_info"."user_idx" < "Mail"."user_idx"

Ref: "user_game_info"."user_idx" < "user_skill"."user_idx"

Ref: "equip_inven"."item_type" < "equip_item"."user_idx"

Ref: "equip_inven"."seq_key" < "equip_item"."inven_index"

Ref: "user_game_info"."user_idx" < "match_history"."opponent_user_idx"

Ref: "user_game_info"."user_idx" < "match_history"."user_idx"

Ref: "user_game_info"."user_idx" < "leader_board"."user_idx"