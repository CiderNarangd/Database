
Table "guild_info" {
  "guild_idx" "bigint IDENTITY(10000001,1)" [pk, not null]
  "guild_name" nvarchar(20) [unique, not null]
  "guild_master_name" nvarchar(20)
  "guild_master_idx" bigint
  "level" int [default: 1]
  "exp" int [default: 0]
  "guild_points" int [default: 0]
  "guild_status" tinyint [not null, default: 0]
  "comment" nvarchar(300)
  "member_cnt" int [default: 1]
  "icon" int [default: 0]
  "is_alive" tinyint [default: 1]
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]
}

Table "guild_member" {
  "guild_idx" bigint
  "user_idx" bigint
  "user_name" nvarchar(20)
  "member_grade" int [default: 0]
  "contribution_point" int [default: 0]
  "created_date" datetime [default: `getdate()`]
  "last_login_date" datetime
  "update_date" datetime [default: `getdate()`]

  Indexes {
    (guild_idx, user_idx) [pk, name: "pk_guild_member"]
  }
}

Table "guild_join_request" {
  "seq_key" bigint [pk, increment]
  "guild_idx" bigint
  "user_idx" bigint
  "status" tinyint [default: 0]
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]

  Indexes {
    (guild_idx, status) [name: "IX_request_gidx"]
    (user_idx, status) [name: "IX_request_uidx"]
    (guild_idx, user_idx, status) [unique, name: "IX_request_guidx"]
  }
}

Table "guild_chat" {
  "seq_key" bigint [pk, increment]
  "guild_idx" bigint [not null]
  "user_idx" bigint [not null]
  "user_name" nvachar(20) [not null]
  "message" nvarchar(300) [not null]
  "created_date" datetime [not null, default: `getdate()`]

  Indexes {
    (guild_idx, seq_key) [name: "ix_guild_chat_guild_idx"]
  }
}


Ref: "guild_info"."guild_idx" < "guild_member"."guild_idx"

Ref: "guild_info"."guild_idx" < "guild_join_request"."guild_idx"

Ref: "guild_info"."guild_idx" < "guild_chat"."guild_idx"