
Table "user_info" {
  "user_idx" "bigint IDENTITY(10000001,1)" [pk, not null]
  "user_name" nvarchar(20) [unique, not null]
  "country_code" char(3) [not null, default: 'zz']
  "device_name" nvarchar(50) [not null, default: 'zz']
  "os_version" nvarchar(50) [not null, default: 'zz']
  "last_login_date" datetime [not null, default: `getdate()`]
  "user_status" tinyint [not null, default: 0]
  "is_guest" tinyint [not null, default: 0]
  "created_date" DATETIME [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]
}

Table "login_info" {
  "user_idx" bigint
  "platform_type" tinyint
  "access_token" nvarchar(300)
  "refresh_token" nvarchar(300)
  "token_expired_date" datetime
  "created_date" datetime [default: `getdate()`]
  "updated_date" datetime [default: `getdate()`]

  Indexes {
    (user_idx, platform_type) [pk, name: "pk_login_user_platform"]
  }
}

Table "block_user_list" {
  "user_idx" bigint [pk]
  "block_reason" tinyint
  "block_detail_reason" nvarchar(500)
  "blocked_by" nvarchar(30)
  "is_active" tinyint [default: 1]
  "block_start_date" datetime [default: '2000-01-01']
  "block_end_date" datetime [default: '2000-01-01']
}

Table "user_report" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "target_idx" bigint
  "report_reason" tinyint
  "report_detail" nvarchar(500)
  "status" tinyint [default: 0]
  "created_date" datetime [default: `getdate()`]

  Indexes {
    (target_idx, status) [name: "ix_user_report_target"]
  }
}

Table "billing" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "user_idx" bigint
  "platform_type" tinyint
  "status" tinyint
  "product_id" int
  "country_code" char(3) [not null, default: 'zz']
  "amount" decimal(10,2)
  "currency" nvarchar(5) [default: 'zz']
  "receipt" nvarchar(300)
  "bill_tx_id" nvarchar(300)
  "fail_reason" nvarchar(300)
  "bill_start_date" datetime [default: `getdate()`]
  "bill_updated_date" datetime
  "bill_end_date" datetime

  Indexes {
    user_idx [name: "ix_billing_user_idx"]
  }
}

Table "Notice" {
  "seq_key" "bigint IDENTITY(1,1)" [pk]
  "notice_type" int [default: 0]
  "contents" text [default: '']
  "is_active" tinyint [default: 0]
  "notice_start_date" datetime [default: '2000-01-01']
  "notice_end_date" datetime [default: '2000-01-01']
  "created_date" datetime [default: `getdate()`]
}


Ref: "user_info"."user_idx" < "billing"."user_idx"

Ref: "user_info"."user_idx" < "login_info"."user_idx"

Ref: "user_info"."user_idx" < "user_report"."user_idx"

Ref: "user_info"."user_idx" < "block_user_list"."user_idx"