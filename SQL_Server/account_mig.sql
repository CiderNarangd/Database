/*
 유저 이관
  https://learn.microsoft.com/ko-kr/troubleshoot/sql/database-engine/security/transfer-logins-passwords-between-instances
  해당 페이지에 쿼리사용후 
  exec sp_help_revlogin 
  해당 sp를 사용하여 로그인 정보 생성하는 쿼리 생성 가능

  System 및 정책상 생성되는 로컬 계정들을 제외한
  유저 로그인만 생성

  계정 생성후 하단에 계정 맵핑 쿼리 사용

*/


/* Login [bckadmusr] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'bckadmusr'
    )
BEGIN
	CREATE LOGIN [bckadmusr]
    WITH PASSWORD = 0x0100E50F4B33A62FFFD01F8381956E99CD9D2517EF143FB03F0A HASHED
        ,SID = 0x7E45A91185A43645B42A743EDEF801E5
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [english]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END


/* Login [bi_duck] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'bi_duck'
    )
BEGIN
	CREATE LOGIN [bi_duck]
    WITH PASSWORD = 0x01004840F193FC6F478DE261620F1E50934BE75A6F3A2E212F00 HASHED
        ,SID = 0x3BA0D8AB0FCC3E4094CB691C27E209D1
        ,DEFAULT_DATABASE = [DSS_DM]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END



/* Login [bi_riscky] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'bi_riscky'
    )
BEGIN
	CREATE LOGIN [bi_riscky]
    WITH PASSWORD = 0x01003381A740ECBC576335FD4B58415044FA6E2D743D3CB2E9A8 HASHED
        ,SID = 0xDAB601899893714AB9B092F850D5627D
        ,DEFAULT_DATABASE = [DSS_DM]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END



/* Login [bi_ydh0612] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'bi_ydh0612'
    )
BEGIN
	CREATE LOGIN [bi_ydh0612]
    WITH PASSWORD = 0x01006DB6017E1079A96BEB43528B4CBAB690D920F1EBB7859E05 HASHED
        ,SID = 0x22C51A51A7BA7D459403ACA0BCF771FE
        ,DEFAULT_DATABASE = [DSS_DM]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END
 
/* Login [dbcrtracc] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'dbcrtracc'
    )
BEGIN
	CREATE LOGIN [dbcrtracc]
    WITH PASSWORD = 0x0100AA0A6DA85D087CF0C77C951BAD4B48C47DFCFFDA964DBA3B HASHED
        ,SID = 0xB1536CB4D2B3C148AB37108EB48B8042
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [english]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF

	
	EXEC [master].dbo.sp_addsrvrolemember @loginame = N'dbcrtracc', @rolename = N'dbcreator'
END
 


 /* Login [ddous] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'ddous'
    )
BEGIN
	CREATE LOGIN [ddous]
    WITH PASSWORD = 0x0100FF15E3E902E1B31437E3F4BB56FA24D35E22C60516021D6D HASHED
        ,SID = 0x23B79DA144CA4444A9A8DC746C1AFC2F
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = ON

	
	EXEC [master].dbo.sp_addsrvrolemember @loginame = N'ddous', @rolename = N'sysadmin'
END



 
/* Login [dsswebacc] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'dsswebacc'
    )
BEGIN
	CREATE LOGIN [dsswebacc]
    WITH PASSWORD = 0x01004BD129FB9E6032A0B7F53DBCE459FB91088B1621054D2270 HASHED
        ,SID = 0x2D8B12D85E0D4C41B2AA9463262C4717
        ,DEFAULT_DATABASE = [DSS_DM]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END
 

/* Login [joy_user_jej] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'joy_user_jej'
    )
BEGIN
	CREATE LOGIN [joy_user_jej]
    WITH PASSWORD = 0x010078DB5EF33F5E1E7DBCE755DCE9279C8B241FE0599A7B319C HASHED
        ,SID = 0x56409C9A8837A5429A9097276298D96F
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = ON

	
	EXEC [master].dbo.sp_addsrvrolemember @loginame = N'joy_user_jej', @rolename = N'sysadmin'
END


/* Login [joyjm] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'joyjm'
    )
BEGIN
	CREATE LOGIN [joyjm]
    WITH PASSWORD = 0x0100B5009C59FCEF37F333C43E82F45A83170DB50ECF23B7C96F HASHED
        ,SID = 0xAD9E06DC9B46714AB06B6E5963D9E73F
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = ON

	
	EXEC [master].dbo.sp_addsrvrolemember @loginame = N'joyjm', @rolename = N'sysadmin'
END


/* Login [sadmusr] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'sadmusr'
    )
BEGIN
	CREATE LOGIN [sadmusr]
    WITH PASSWORD = 0x01007033470C647C79EAA26E3364C9EE6C99903ED11EAB2E956C HASHED
        ,SID = 0x2EFF23E465C2AD488BC04CC2446A9DBC
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF

	
	EXEC [master].dbo.sp_addsrvrolemember @loginame = N'sadmusr', @rolename = N'sysadmin'
END


/* Login [telegraf] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'telegraf'
    )
BEGIN
	CREATE LOGIN [telegraf]
    WITH PASSWORD = 0x0100162BBDEDA9BEC018287A826ECEEDF707213395AB2BCC8437 HASHED
        ,SID = 0xF9E863637DEB0644BC0863B7D1658273
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [한국어]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END

--/* Login [ssrssvcacc] */ --> 안스는거같다 생성X
--IF NOT EXISTS (
--    SELECT 1
--    FROM sys.server_principals
--    WHERE [name] = N'ssrssvcacc'
--    )
--BEGIN
--	CREATE LOGIN [ssrssvcacc]
--    WITH PASSWORD = 0x0100C681E59C51D5D8BD36ABFFBC94DCC660081E1B9869064130 HASHED
--        ,SID = 0x954357FF4BF4C84EA30FD027C7D976E5
--        ,DEFAULT_DATABASE = [KOR_DM]
--        ,DEFAULT_LANGUAGE = [한국어]
--        ,CHECK_POLICY = ON
--        ,CHECK_EXPIRATION = OFF
--END


-- 계정 생성후 기존 데이터베이스 계정에 맵핑

--EX)
use [DSS_DM]
exec sp_change_users_login 'Update_One','bckadmusr','bckadmusr'
exec sp_change_users_login 'Update_One','bi_duck','bi_duck'
exec sp_change_users_login 'Update_One','bi_riscky','bi_riscky'
exec sp_change_users_login 'Update_One','bi_ydh0612','bi_ydh0612'
exec sp_change_users_login 'Update_One','dsswebacc','dsswebacc'

use [WorkDB]
exec sp_change_users_login 'Update_One','bckadmusr','bckadmusr'
exec sp_change_users_login 'Update_One','bi_duck','bi_duck'
exec sp_change_users_login 'Update_One','bi_riscky','bi_riscky'
exec sp_change_users_login 'Update_One','bi_ydh0612','bi_ydh0612'

use [WorkDB]
exec sp_change_users_login 'Update_One','bckadmusr','bckadmusr'


-- Or 아래 쿼리 사용해도 무방

USE [DSS_DM]
GO
ALTER USER bckadmusr WITH LOGIN = bckadmusr
