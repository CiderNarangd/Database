use [LOG]
-- 확장성 고려하여 추가컬럼 미리 생성해놓을수도 있음
-- 월단위 테이블 작성 or 파티셔닝하여 관리
create table login_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,
	user_idx bigint not null,
	login_date datetime not null,										-- 로그인 시간
	last_login_date datetime not null,									-- 지난 로그인 시간
	[login_type] tinyint not null,										-- 0 - Google, 1 - Apple Login, 2 - MS, 3 - 네이버.... , 99-게스트
	os_version nvarchar(50)	not null default'zz',						-- os 버전
	device_name nvarchar(50) not null default 'zz',						-- 기기명
	country_code char(3) not null default 'zz',							-- 국가코드
	created_date datetime not null default getdate()					-- 로그 삽입일
)

CREATE INDEX ix_login_created_date ON login_log(created_date)			-- 통계용 인덱스
CREATE INDEX ix_login_user_idx ON login_log(user_idx,created_date)		-- 특정 유저 조회용 인덱스

-- 결제가 정상적으로 완료된 로그만 삽입된다.
create table billing_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,
	user_idx bigint not null,											-- 유저 고유값
	login_date datetime not null,										-- 로그인 시간
	os_version nvarchar(50)	not null default'zz',						-- OS명
	device_name nvarchar(50) not null default 'zz',						-- 기기명
	market_type tinyint not null,										-- 0 - Google, 1 - AppStore ....
	product_id int not null,											-- 상품id
	amount decimal(10,2) not null,										-- 구매가격
	currency nvarchar(5) not null default 'zz',							-- 통화
	bill_start_date datetime not null,									-- 결제 시작 시간
	bill_end_date datetime not null,									-- 결제 완료 시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간
) 

CREATE INDEX ix_bill_created_date ON billing_log(created_date)			-- 통계용 인덱스
CREATE INDEX ix_bill_user_idx ON billing_log(user_idx,created_date)		-- 특정 유저 조회용 인덱스


create table quest_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,				
	user_idx bigint not null,											-- 유저 고유값
	login_date datetime not null,										-- 로그인 시간
 	quest_id int not null,												-- 퀘스트id
	completed_date  datetime not null,									-- 완료시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간
)

CREATE INDEX ix_quest_created_date ON quest_log(created_date)			-- 통계용 인덱스
CREATE INDEX ix_quest_user_idx ON quest_log(user_idx,created_date)		-- 특정 유저 조회용 인덱스

create table match_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	match_idx bigint not null,											-- 매치 고유값
	season_idx int not null,											-- 시즌 인덱스
	user1_idx bigint not null,											-- 유저1 고유값
	user2_idx bigint not null,											-- 유저2 고유값
	user1_score int not null,											-- 유저1 변동 점수
	user2_score int not null,											-- 유저2 변동 점수
	user1_before_score int not null,									-- 유저1 경기 이전 점수
	user2_before_score int not null,									-- 유저2 경기 이전 점수
	user1_after_score int not null,										-- 유저1 경기 이후 점수
	user2_after_score int not null,										-- 유저2 경기 이후 점수
	user1_info nvarchar(300) not null,									-- 유저1 장비, 스킬 정보
	user2_info nvarchar(300) not null,									-- 유저2 장비, 스킬 정보
	match_time int not null,											-- 게임 시간
	match_start_date datetime not null,									-- 게임 시작 시간
	match_end_date datetime not null,									-- 게임 종료 시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간
)

CREATE INDEX ix_match_created_date ON match_log(created_date)			-- 통계용 인덱스
CREATE INDEX ix_match_user1_idx ON match_log(user1_idx,created_date)	-- 특정 유저 조회용 인덱스
CREATE INDEX ix_match_user2_idx ON match_log(user2_idx,created_date)	
CREATE INDEX ix_match_match_idx ON match_log(match_idx)					-- 특정 매치 조회용 인덱스


create table equip_item_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,					
	user_idx bigint not null,											-- 유저 고유 값
	event_type tinyint not null,										-- 획득/사용 경로 ( 구매, 우편함, 기부, ....  )
	item_id int not null,												-- 아이템id
	item_cate tinyint not null,											-- 아이템 카테고리 ( 장비, 소모품 ....)
	quantity_change int not null,										-- 사용/획득 갯수
	before_quantity int not null,										-- 획득/사용 전 남은 갯수  (장비템은 0으로 처리)
	after_quantity int not null,										-- 획득/사용 후 남은 갯수  (장비템은 0으로 처리,)
	option1_id int not null,											-- 옵션1 id
	option1_value int not null,											-- 옵션1 value							
	option2_id int not null ,											-- 옵션2 id
	option2_value int not null,											-- 옵션2 value
	option3_id int not null,											-- 옵션3 id
	option3_value int not null,											-- 옵션3 value
	option4_id int not null,											-- 옵션4 id
	option4_value int not null,											-- 옵션4 value
	option5_id int not null,											-- 옵션5 id
	option5_value int not null,											-- 옵션5 value
	changed_date datetime not null,										-- 사용/획득 시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간
)

CREATE INDEX ix_equip_craete_date ON equip_item_log(created_date)			-- 통계용 인덱스
CREATE INDEX ix_equip_user_idx ON equip_item_log(user_idx,created_date)		-- 특정 유저 조회용 인덱스


create table goods_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,					
	user_idx bigint not null,											-- 유저 고유 값
	event_type tinyint not null,										-- 획득/사용 경로 ( 구매, 우편함, 기부, ....  )
	product_id int not null,											-- 재화 사용으로 획득한 아이템 id
	product_quantity int not null,										-- 획득한 아이템 갯수
	free_goods_change int not null,										-- 무료 재화 변화량		
	paid_goods_change int not null,										-- 유료 재화 변화량
	before_free_goods int not null,										-- 무료 재화 변동전 
	before_paid_goods int not null,										-- 유료 재화 변동전
	after_free_goods int not null,										-- 무료 재화 변동후
	after_paid_goods int not null,										-- 유료 재화 변동후
	changed_date datetime not null,										-- 이벤트 발생 시간
	created_date datetime not null default getdate()				    -- 로그 삽입 시간
)

CREATE INDEX ix_goodslog_created_date ON goods_log(created_date)		-- 통계용 인덱스
CREATE INDEX ix_goodslog_user_idx ON goods_log(user_idx,created_date)	-- 특정 유저 조회용 인덱스


create table guild_history_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,	
	guild_idx bigint not null,											-- 길드 고유값
	user_idx bigint not null,											-- 유저 고유값
	guild_master_idx bigint not null,									-- 길드장 고유값
	action_type tinyint not null,										-- 0-길드 생성, 1-길드 메시지 변경 , 3-길드 상태 변경, 4-길드 레벨업 ..., 5-길드 포인트 ,6- 폐쇄... 
	action_value tinyint not null,										-- 위 타입값에 종속된 행동값 // json등의 타입 고려해야할수도
	comment nvarchar(300) null,											-- 길드 메시지 (변경시 변경된 길드메시지)
	guild_level int not null default 1,									-- 길드 레벨
	guild_points int not null default 0,								-- 길드 포인트 값
	event_date datetime not null,										-- 이벤트 발생 시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간

)

CREATE INDEX ix_guild_history_created_date ON guild_history_log(created_date)		 -- 통계용 인덱스
CREATE INDEX ix_guild_history_user_idx ON guild_history_log(user_idx,created_date)	 -- 특정 유저 조회용 인덱스
CREATE INDEX ix_guild_history_guild_idx ON guild_history_log(guild_idx,created_date) -- 특정 길드 조회용 인덱스


create table guild_request_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,	
	user_idx bigint not null,											-- 유저 고유값
	guild_idx bigint not null,											-- 길드 고유값
	guild_master_idx bigint not null,									-- 길드장 고유값
	action_type tinyint not null,										-- 0-신청, 1-신청거절, 2-신청수락, 3-추방, 4-탈퇴
	event_date datetime not null,										-- 이벤트 발생 시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간

)

CREATE INDEX ix_guild_request_created_date ON guild_request_log(created_date)		 -- 통계용 인덱스
CREATE INDEX ix_guild_request_user_idx ON guild_request_log(user_idx,created_date)	 -- 특정 유저 조회용 인덱스
CREATE INDEX ix_guild_request_guild_idx ON guild_request_log(guild_idx,created_date) -- 특정 길드 조회용 인덱스


create table guild_member_history_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,	
	user_idx bigint not null,											-- 유저 고유값
	guild_idx bigint not null,											-- 길드 고유값
	guild_master_idx bigint not null,									-- 길드장 고유값
	action_type tinyint not null,										-- 행동 (0-가입 , 1- 탈퇴, 2- 기여 .....)
	action_value int not null,											-- 위 타입값에 종속된 행동값 // json등의 타입 고려해야할수도
	event_date datetime not null,										-- 이벤트 발생 시간
	created_date datetime not null default getdate()					-- 로그 삽입 시간
)

CREATE INDEX ix_guild_mem_history_created_date ON guild_member_history_log(created_date)		 -- 통계용 인덱스
CREATE INDEX ix_guild_mem_history_user_idx ON guild_member_history_log(user_idx,created_date)	 -- 특정 유저 조회용 인덱스
CREATE INDEX ix_guild_mem_history_guild_idx ON guild_member_history_log(guild_idx,created_date)  -- 특정 길드 조회용 인덱스

create table friend_event_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,	
	user_idx bigint not null,											-- 유저 고유값	
	friend_idx bigint not null,											-- 신청받은 친구 고유값
	action_type tinyint not null,										-- 0-신청, 1-거절, 2-신청수락, 3-친구삭제
	event_date datetime not null,										-- 이벤트 발생 시간
	created_date datetime not null default getdate(),					-- 로그 삽입 시간
)

CREATE INDEX ix_friend_created_date ON friend_event_log(created_date)		-- 통계용 인덱스
CREATE INDEX ix_friend_user_idx ON friend_event_log(user_idx,created_date)	-- 특정 유저 조회용 인덱스

create table mail_log(
	seq_key bigint IDENTITY (1, 1) not null primary key,	
	user_idx bigint not null,											-- 유저 고유값	
	title nvarchar(50) not null default '',								-- 메일 제목
	contents nvarchar(300) not null default '',							-- 메일 내용
	received_date datetime not null,									-- 메일 받은 시간
	read_date datetime null,											-- 메일 읽은 시간
	sender_idx bigint not null,											-- 발신자
	item_id	int not null,												-- 동봉된 아이템id (없으면 0)
	item_cnt int not null,												-- 아이템 갯수 
	created_date datetime not null default getdate(),					-- 로그 삽입 시간
)

CREATE INDEX ix_mail_created_date ON mail_log(created_date)				-- 통계용 인덱스
CREATE INDEX ix_mail_user_idx ON mail_log(user_idx,created_date)		-- 특정 유저 조회용 인덱스
