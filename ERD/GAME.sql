use GAME;
--시간값은 기본적으로 서버에서 받아오는것을 원칙으로 한다.
-- 재화, 아이템, 컨텐츠 관련 테이블들.

create table user_game_info(
	user_idx bigint not null primary key,								-- 유저 고유값
	[user_name] nvarchar(20) not null unique,							-- 유저 이름
	[level] int not null default 1,										-- 유저 레벨
	[exp] int not null default 0,										-- 경험치
	free_goods int not null default 0,									-- 무료 재화
	paid_goods int not null default 0,									-- 유료 재화
	skill_points int not null default 0,								-- 스킬 포인트
	score int not null,													-- 점수
	guild_idx bigint not null default 0,								-- 유저가 가입중인 길드 고유값
	guild_name nvarchar(20) NOT NULL default '',						-- 유저가 가입중인 길드이름
	created_date datetime not null default getdate(),					-- 해당 테이블 삽입 시간
	updated_date datetime not null default getdate()					-- 유저 정보 마지막 변경 시간
);

-- user_idx pk지정시 페이지 스플릿이 심할것으로 예상되어, 대체키 사용
-- user_idx 세컨더리 인덱스 지정해서 사용.
-- 인벤토리 테이블은 유저수가 많아지고 플레이어블 캐릭터가 늘어나고 캐릭터별 인벤토리를 갖게되면 무한정 늘어난다.
-- 차후 압축하여 로우수 줄이는것도 고려 필요.( )
create table equip_inven(		
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null,											-- 유저 고유값
	item_type int not null,												-- 부위	
	item_id int not null,												-- 아이템id
	option1_id int not null default 0,									-- 아이템 옵션 id
	option1_value int not null default 0,								-- 아이템 옵션 value
	option2_id int not null default 0,
	option2_value int not null default 0,
	option3_id int not null default 0,
	option3_value int not null default 0,
	is_equipped tinyint not null default 0,								-- 장착 여부 // 장착x-0, 장착o -1
	item_expiration_date datetime not null default '2050-01-01',		-- 아이템 만료일   // 배치작업보단 로그인시 지워줘도 문제 없을듯
	updated_date datetime not null,										-- 아이템 내역 변경일
	created_date datetime not null default getdate()					-- 아이템 획득일
);
CREATE INDEX ix_equip_inven_user_idx ON equip_inven(user_idx)


-- 장착 부위 갯수가 절대적으로 고정이면 컬럼을 늘려서 ROW를 줄이는 방식이겠지만, 
-- 정해진게 없으므로 ROW를 늘리는 방식으로
-- 캐릭터 생성 시점에 초기값들을 셋팅하여 로우를 넣어준다.
create table equip_item(
	user_idx bigint not null,											-- 
	slot_type int not null,												-- 0-무기, 1-머리, 2-가슴, 3-다리, 4-발 .... 
	inven_index	bigint not null default 0,								-- 인벤토리에 잇는 seq_key값, 0이면 장착x상태
	equipped_time datetime not null default getdate(),					-- 아이템 장착 시간.
	
	CONSTRAINT pk_equip_item PRIMARY KEY (user_idx, slot_type)
)

-- 개발편의 고려하여 인벤토리 테이블 분리.
-- 동일하게 아이템 종류 증가시 압축 고려필요.
create table consumable_inven(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null,											-- 유저 고유값
	item_type int not null,												-- 재료 / 물약 .. 
	item_id int not null,												-- 아이템id					
	quantity int not null,												-- 갯수
	item_expiration_date datetime not null default '2050-01-01',		-- 아이템 만료일
	updated_date datetime not null,										-- 아이템 내역 변경일
	created_date datetime not null default getdate(),					-- 아이템 획들일
)
CREATE INDEX ix_consumable_inven_user_idx ON consumable_inven(user_idx)


-- 만료메일은 배치처리 / 유저가 너무 많이 늘어나면 파티셔닝/샤딩 (다른 테이블 상황봐서)고려
create table Mail(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null,											-- 유저 고유값
	title nvarchar(50) not null default '',								-- 메일 제목
	contents nvarchar(300) not null default '',							-- 메일 내용
	is_read tinyint not null default 0,									-- 읽음 유무
	item_type int not null default 0,									-- 아이템이 첨부되어있으면, 없으면 0
	item_id int not null default 0,										-- 아이템이 첨부되어있으면, 없으면 0
	send_time datetime not null default getdate(),						-- 보낸 시간
	expired_date datetime not null default '2050-01-01',				-- 만료일
	is_deleted tinyint not null default 0								-- 삭제 여부 ( 0 - 삭제x , 1- 삭제o / 배치로 일괄 삭제시 값이 1인것만 삭제) 
)
CREATE INDEX ix_mail_user_idx ON Mail(user_idx)
CREATE INDEX ix_mail_expired ON Mail(is_deleted, expired_date)			-- 배치 일괄 삭제용 인덱스
																		-- 풀스캔 일어날것 같으니 나눠서 처리하는것도 고려


create table user_quest(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null ,											-- 유저 고유 값
	quest_id int not null,												-- 퀘스트 id
	quest_status int not null default 0,								-- 퀘스트 상태 0-퀘스트 받지 않음. 1-퀘스트 진행중 , 2-퀘스트 완료
	quest_progress int not null default 0,								-- 퀘스트 진행 상태
	created_date datetime not null default getdate(),					-- 퀘스트 최초 받은 시간
	updated_date datetime not null default getdate(),					-- 퀘스트 상태 변경 시간
	
)
create index ix_quest_user_idx ON user_quest(user_idx)	



create table user_achievement(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null ,											-- 유저 고유 값
	achievement_id int not null,										-- 업적 id
	achievement_cate int not null,										-- 업적 카테고리
	achievement_progress int not null,									-- 업적 진행상태
	achievement_goal int not null,										-- 업적 달성필요값
	achievement_status int not null,									-- 업적 상태		0-미달성, 1-달성
	created_date datetime not null default getdate(),					-- 업적 달성일
	updated_date datetime not null default getdate()					-- 업적 상태 변경일
)
create index ix_achiv_user_idx ON user_achievement(user_idx)	


-- 게임 최초 접속시 로우 preInsert
create table user_skill(
	user_idx bigint not null ,											-- 유저 고유 값
	skill_id int not null,												-- 스킬 id
	skill_level int not null default 1,									-- 스킬 level	
	created_date datetime not null default getdate(),					-- 스킬 획득일
	
	CONSTRAINT pk_user_skill PRIMARY KEY (user_idx, skill_id)
)

-- status( 접속중, 매치중 등 ...)등은 메모리db사용 고려
create table friend(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null, 											-- 유저 고유값
	friend_idx bigint not null,
	created_date datetime not null default getdate()					-- 친구 맺은날
)
create index ix_friend_user_idx ON friend(user_idx)
-- 중복체크는 insert이전에 select로 사전체크.

create table friend_request(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	user_idx bigint not null,											-- 요청 보낸 유저 고유 값
	request_user_idx bigint not null,									-- 요청 받은 유저 고유 값
	[status] tinyint not null default 0,								-- 0-신청중, 1-수락, 2-거절 
	created_date datetime not null default getdate(),					-- 신청 시간
	responded_time datetime null,										-- 응답 시간
)
create index ix_fr_user_idx ON friend_request(user_idx)					-- status 컬럼까지 묶어야 할수도.
create index ix_fr_requester_idx ON friend_request(request_user_idx)	-- 동일
create index ix_created_date ON friend_request(created_date)			-- 배치 삭제 용
-- 신청일기준으로 
-- 로그인 or 친구창 오픈시 확인하고 friend table에 Insert
-- 중복 신청은 insert전에 select로 사전체크


-- 게임이 거대해지고 정보가 많아지면 nvarchar(max)로 변경고려 필요.
-- 유저당 최대 10개까지 & 한달 보관한다고 가정 / 모든 매치기록들은 LogDB에 적재.
-- 개발편의상 한번의 매치후 두개의 로우가 Insert.
create table match_history
(
	seq_key bigint IDENTITY (1, 1) not null primary key,				-- 대체 키
	match_idx bigint not null,											-- 매치 고유값 / 서버단에서 고유값 / 발급 Redis Incr or snowflake_id 등을 사용한 티켓서버 
																		-- 한번의 매치에서 편의상 두개의 로우가 인서트 되기 때문에 db auto_incr등 사용 불가.
	user_idx bigint not null,											-- 유저 고유 값
	opponent_user_idx bigint not null,									-- 상대 유저 고유 값
	[result] tinyint not null,											-- 결과
	score int not null,													-- 획득 점수
	opponent_score int not null,										-- 상대편 획득 점수
	user_info_list	nvarchar(300) not null,								-- 내가 사용한 스킬, 아이템 리스트
	opponent_info_list nvarchar(300) not null,							-- 상대편이 사용한 스킬, 아이템 리스트
	match_time int not null,											-- 게임 시간
	match_start_date datetime not null,									-- 매치 시작 시간
	match_end_date datetime not null									-- 매치 종료 시간
)
create index ix_match_history_user_idx ON match_history(user_idx, seq_key desc)  -- 최신 10개만 조회하기 위해
create index ix_match_history_end_date ON match_history(match_end_date)			 -- 배치삭제용

 
-- 인게임에서 보여지는 상위 n명 테이블
-- 일단위로 정산후 최신화 (아래 leader_board 테이블에서 스냅샷처리 후 해당 테이블에 insert)
-- 실시간 랭킹필요하면 레디스 사용 고려 필요
-- 서버에서 해당 테이블을 전체 캐싱해서 클라이언트들한테 보여준다.
create table daily_ranking(
	[rank] int IDENTITY (1, 1) not null primary key,					-- 순위
	user_idx bigint not null,											-- 유저 고유값
	[user_name] nvarchar(20) not null,									-- 유저이름	
	score	int not null												-- 점수
)

-- 시즌 단위로 현재 게임중인 유저들의 점수 저장하는 리더보드
-- 아카이빙 처리 필요할수도
-- or 시즌별로 테이블 새로 생성해서 하는 방법
create table leader_board(
	season_idx int not null,											-- 시즌인덱스
	user_idx bigint not null,											-- 유저 고유값
	score int not null default 0,										-- 해당 시즌 점수
	created_date datetime not null default getdate(),					-- 시즌 진입일
	updated_date datetime not null default getdate(),					-- 점수 변동일
	CONSTRAINT pk_season_useridx primary key (season_idx, user_idx)	
)
create index ix_leader_board_score on leader_board(season_idx,score desc) -- 일일 랭킹 산정용 인덱스

