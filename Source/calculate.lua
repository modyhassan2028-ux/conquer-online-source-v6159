Version = "1.8"
----------------------------Begin 主函数主体------------------------------------------
function calculate()
	file:write(os.date().."\r\n------------------货币类型:"..NationSymbol.."\r\n")
	file:write(os.date().."\r\n------------------货币名称:"..NationSymbolName.."\r\n")	
	
	--兼容旧版本数据结构
	if IsMainSymbol then
		if Is91dd ~= true then
			sql = "UPDATE `m_DataMonitor` SET `nationsymbol`= "..NationSymbol.." WHERE `nationsymbol` IS NULL"
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))
			
			sql = "UPDATE `m_DataMonitorBak` SET `nationsymbol`= "..NationSymbol.." WHERE `nationsymbol` IS NULL"
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))

			sql = "UPDATE `emoneybak` SET `nationsymbol`= "..NationSymbol.." WHERE `nationsymbol` IS NULL"
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))
		else
			sql = "UPDATE `m_DataMonitor` SET `nationsymbol`= `InnerType` WHERE `nationsymbol` IS NULL"
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))
			
			sql = "UPDATE `m_DataMonitorBak` SET `nationsymbol`= `InnerType` WHERE `nationsymbol` IS NULL"
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))

			sql = "UPDATE `emoneybak` SET `nationsymbol`=`DataType` WHERE `nationsymbol` IS NULL"
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))
		end
	end

	--判断这台服务器今天未运行过维护脚本
	sql = "SELECT IFNULL(Value,0) FROM `m_datamonitor` WHERE Type='RunFlag' AND TO_DAYS(now())-TO_DAYS(ExecDate)=0 AND `nationsymbol`="..NationSymbol
	cur = assert (con:execute(sql))
	if cur ~= nil then
		row = cur:fetch ({}, "n") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
		if row ~= nil then --如果为空那么两种情况1.新版本第一次使用 2.当日尚未运行
			if tonumber(row[1]) == 1 then
				file:write(os.date().."\r\n------------------\r\n今天已经运行过维护脚本了\r\n")
				print(NationSymbolName.. "已经运行过维护脚本了")
				return
			end
		
			if tonumber(row[1]) == 0 then
				--上次尚未运行成功
				sql = "DELETE FROM `m_DataMonitor` WHERE type NOT LIKE 'Old%' AND `nationsymbol`="..NationSymbol
				res = assert (con:execute(sql))
				file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			end
		end
	end
	
	--file:write(os.date().."\r\n------------------\r\n这台服务器今天未运行过维护脚本,继续执行\r\n")

	--开始初始化参数
	sql = "SELECT * FROM `m_datamonitor` WHERE `nationsymbol`="..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	cur = assert (con:execute(sql))
	row = cur:fetch ({}, "a") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
	
	i = 0;
	datas = {}
	while row do
	  --print(row.Type, row.Value)
	  if row.Type ~= nil then datas[row.Type] = row.Value end
	  row = cur:fetch (row, "a")	-- reusing the table of results
	end
	
	--准备一些旧的数据	
	OldCardMaxId = datas["CardMaxId"]
	if OldCardMaxId == nil then OldCardMaxId = 0 end
	
	OldCard2MaxId = datas["Card2MaxId"]
	if OldCard2MaxId == nil then OldCard2MaxId = 0 end

	OldEmoneyMaxId = datas["EmoneyMaxId"]
	if OldEmoneyMaxId == nil then 
		OldEmoneyMaxId = 0 
		IsFirstTimeEmoneyBak = true
	else
		IsFirstTimeEmoneyBak = false
	end
	
	--删除更旧的数据
	sql = "DELETE FROM `m_DataMonitor` WHERE type LIKE 'Old%' AND `nationsymbol`="..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	
	sql = "UPDATE `m_DataMonitor` SET type=CONCAT('Old',type) WHERE `nationsymbol`="..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	
	--记录运行标志
	sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) VALUES('RunFlag'," .. NationSymbol .. ",0,now()," .. NationSymbol .. ",'" ..Version.. "');"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")	
	res = assert (con:execute(sql))
	
	--记录卡表相关数据
	if IsMainSymbol then
		--是否包含USED字段
		if CarTableColumnUsed then
			usedstr = " WHERE used = 0 "
		else
			usedstr = ""
		end
		
		--记录卡表1库存
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardBalance',type,COUNT(*),now(),"..NationSymbol.. ",'" ..Version.."' FROM ".. Card_TableName .. usedstr.." GROUP BY type"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表1库存完成\r\n")
		print("记录卡表1库存完成")
		
		--记录卡表2库存
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardBalance',type,COUNT(*),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. Card2_TableName ..usedstr.." GROUP BY type"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表2库存完成\r\n")
		print("记录卡表2库存完成")
		
		--记录卡表1分类型最大Id
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardMaxId',0,IFNULL(MAX(id),0),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. Card_TableName
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表1分类型最大Id完成\r\n")
		print("记录卡表1分类型最大Id完成")
		
		--记录卡表2分类型最大Id
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'Card2MaxId',0,IFNULL(MAX(id),0),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. Card2_TableName
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表2分类型最大Id完成\r\n")
		print("记录卡表2分类型最大Id完成")
		
		--读取卡表1最大Id
		sql = "SELECT IFNULL(MAX(id),0) FROM "..Card_TableName
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		cur = assert (con:execute(sql))
		row = cur:fetch ({}, "n")
		CardMaxId = row[1]
		
		--读取卡表2最大Id
		sql = "SELECT IFNULL(MAX(id),0) FROM "..Card2_TableName
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		cur = assert (con:execute(sql))
		row = cur:fetch ({}, "n")
		Card2MaxId = row[1]
		
		--记录卡表1分类型进卡数
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardInCountByGroup',type,count(*),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. Card_TableName .. " WHERE id >" .. OldCardMaxId .. " and id<=" .. CardMaxId.. " GROUP BY type"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表1分类型进卡数完成\r\n")
		print("记录卡表1分类型进卡数完成")
		
		--记录卡表2分类型进卡数
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardInCountByGroup',type,count(*),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. Card2_TableName .. " WHERE id >" .. OldCard2MaxId .. " and id<=" .. Card2MaxId.. " GROUP BY type"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表2分类型进卡数完成\r\n")
		print("记录卡表2分类型进卡数完成")
	
		--读取Emoney表最大记录
		sql = "SELECT IFNULL(MAX(id),0) FROM "..EmoneyTableName
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		cur = assert (con:execute(sql))
		row = cur:fetch ({}, "n")
		EmoneyMaxId  = row[1]
		
		--记录卡表1分类型出卡数
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardOutCountByGroup',number,COUNT(*),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. EmoneyTableName.. " WHERE type=6 and id>"..OldEmoneyMaxId.." and id<="..EmoneyMaxId.." GROUP BY number "
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表1分类型出卡数完成\r\n")
		print("记录卡表1分类型出卡数完成")
		
		--记录卡表2分类型出卡数
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'CardOutCountByGroup',number,COUNT(*),now(),"..NationSymbol.. ",'" ..Version.."' FROM " .. EmoneyTableName.. " WHERE type=8 and id>"..OldEmoneyMaxId.." and id<="..EmoneyMaxId.." GROUP BY number "
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("记录卡表2分类型出卡数完成\r\n")
		print("记录卡表2分类型出卡数完成")
	end

	--记录Emoney表最大Id
	sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'EmoneyMaxId',"..NationSymbol..",IFNULL(MAX(id),0),now(),"..NationSymbol.. ",'" ..Version.."' FROM ".. EmoneyTableName
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	file:write("记录Emoney表最大Id完成\r\n")
	print("记录Emoney表最大Id完成")
	
	--记录当前用户总余额
	sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'UserEmoneySum',"..NationSymbol.. ",IFNULL(SUM(".. UserTableEmoneyColumnName.. "),0),now(),"..NationSymbol.. ",'" ..Version.."' FROM "..UserTableName
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	file:write("记录当前用户总余额\r\n")
	print("记录当前用户总余额")
	
	--记录当前已删除用户总余额
	i = 1;
	while DelUserTableName[i] do
	  	--print("记录当前已删除用户总余额")
	  	if i == 1 then
	  		index = "";
	  	else
	  		index = tostring(i)
	    end
		sql = "INSERT INTO `m_DataMonitor` (type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT 'DelUserEmoneySum"..index.."',0,IFNULL(SUM("..UserTableEmoneyColumnName.."),0),now(),"..NationSymbol.. ",'" ..Version.."' FROM "..DelUserTableName[i]
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = con:execute(sql)
		--res = assert (con:execute(sql))
	  	i = i + 1
	end
	file:write("记录当前已删除用户总余额完成\r\n")
	print("记录当前已删除用户总余额完成")

	--清空清空emoney备份表
	sql = "DELETE FROM `emoneybak` WHERE nationsymbol = "..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	file:write("清空清空emoney备份表完成\r\n")
	print("清空清空emoney备份表完成")	

	--截断获取emoney备份表
	IsEmoneybak = true
	if IsFirstTimeEmoneyBak then
		--判断是否要备份emonybak表
		if MaxEmoneyCount == nil then
			MaxEmoneyCount = 1000000;
		end
		sql = "SELECT count(*) FROM "..EmoneyTableName.." WHERE id > "..OldEmoneyMaxId
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		cur = assert (con:execute(sql))
		row = cur:fetch ({}, "n")
		if tonumber(row[1]) > MaxEmoneyCount then
			IsEmoneybak = false
			file:write("Emoney表需要抽取数据量大于"..MaxEmoneyCount.."条故不备份到emoneybak\r\n")
			print("Emoney表需要抽取数据量大于"..MaxEmoneyCount.."条故不备份到emoneybak表")
		else
			IsEmoneybak = true
		end
	end

	if IsEmoneybak then
		if Is91dd ~= true then
			sql = "INSERT INTO `emoneybak`(id,nationsymbol,number,type,id_source,id_target) SELECT id,"..NationSymbol..",number,`type`,id_source,id_target FROM "..EmoneyTableName.." WHERE id > "..OldEmoneyMaxId
		else
			sql = "INSERT INTO `emoneybak`(id,nationsymbol,number,type,id_source,id_target,DataType) SELECT id,"..NationSymbol..",number,`type`,id_source,id_target,"..NationSymbol.." FROM "..EmoneyTableName.." WHERE id > "..OldEmoneyMaxId
		end
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("备份emoney到emoneybak表完成\r\n")
		print("备份emoney到emoneybak表完成")
	end

	--更新运行标志
	sql = "UPDATE `m_DataMonitor` SET Value=1 WHERE type = 'RunFlag' AND nationsymbol = "..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")	
	res = assert (con:execute(sql))

	--备份到m_DataMonitorBak表
	sql = "INSERT INTO `m_DataMonitorBak`(Id,type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT Id,type,innertype,Value,ExecDate,`nationsymbol`,version FROM m_DataMonitor WHERE type NOT LIKE 'Old%' AND `nationsymbol`="..NationSymbol;
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))	
end
----------------------------End-------------------------------------------------------

function init()
	file:write(os.date().."\r\n------------------准备就绪\r\n")
	file:write(os.date().."\r\n------------------程序版本:"..Version.."\r\n")
	file:write(os.date().."\r\n------------------游戏名称:"..GameName.."\r\n")

	--先创建有可能不存在的表
	sql = "CREATE TABLE IF NOT EXISTS `m_DataMonitor` (`Id` int(11) NOT NULL auto_increment,`Type` varchar(255) default NULL,`Value` bigint(20) default NULL, `InnerType` int(11) default NULL,`ExecDate` datetime default NULL,`nationsymbol` int(4) NULL default 0,`version` varchar(50) default NULL, PRIMARY KEY  (`Id`)) ENGINE=MyISAM;"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	
	sql = "CREATE TABLE IF NOT EXISTS `m_DataMonitorBak` (`Id` int(11) NOT NULL , `Type` varchar(255) default NULL, `Value` bigint(20) default NULL, `InnerType` int(11) default NULL, `ExecDate` datetime default NULL,`nationsymbol` int(4) NULL default 0,`version` varchar(50) default NULL) ENGINE=MyISAM;"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")	
	res = assert (con:execute(sql))
	
	sql = "CREATE TABLE IF NOT EXISTS `emoneybak` (`Id` int(11) NOT NULL default 0,`nationsymbol` int(4) NULL default 0, `number` int(4) NULL default 0, `type` int(4) NULL default 0,`id_source` int(4) unsigned NULL default 0,`id_target` int(4) unsigned NULL default 0, KEY `type` (`type`,`id_target`)) ENGINE=MyISAM;"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	
	sql = "CREATE TABLE IF NOT EXISTS `emoneycount` (`number` int(4)  NULL default 0, `type` int(4)  NULL default 0, `id_target` int(4)  NULL default 0, KEY `type` (`type`,`id_target`)) ENGINE=MyISAM;"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
	
	--检测`m_DataMonitor`.nationsymbol表字段
	sql = "SHOW FIELDS FROM `m_DataMonitor`"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	cur = assert (con:execute(sql))
	row = cur:fetch ({}, "a") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
	
	i = 0;
	datas = {}
	while row do
	  --print(row.Field, row.Null)
	  if row.Field ~= nil then datas[row.Field] = row.Null end
	  row = cur:fetch (row, "a")	-- reusing the table of results
	end
	
	if datas["nationsymbol"] == nil then 
		sql = "ALTER TABLE `m_DataMonitor` ADD COLUMN `nationsymbol` int(4) NULL default NULL;"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		
		sql = "ALTER TABLE `m_DataMonitor` ADD COLUMN `version` varchar(50) default NULL;"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("m_DataMonitor表添加nationsymbol字段成功\r\n")
		print("m_DataMonitor表添加nationsymbol字段成功")
	end	
	
	--检测`m_DataMonitorBak`.nationsymbol表字段
	sql = "SHOW FIELDS FROM `m_DataMonitorBak`"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	cur = assert (con:execute(sql))
	row = cur:fetch ({}, "a") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
	
	i = 0;
	datas = {}
	while row do
	  --print(row.Field, row.Null)
	  if row.Field ~= nil then datas[row.Field] = row.Null end
	  row = cur:fetch (row, "a")	-- reusing the table of results
	end
	
	if datas["nationsymbol"] == nil then 
		sql = "ALTER TABLE `m_DataMonitorBak` ADD COLUMN `nationsymbol` int(4) NULL default NULL;"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		
		sql = "ALTER TABLE `m_DataMonitorBak` ADD COLUMN `version` varchar(50) default NULL;"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("m_DataMonitorBak表添加nationsymbol字段成功\r\n")
		print("m_DataMonitorBak表添加nationsymbol字段成功")
	end	
	
	--检测`emoneybak`表字段
	sql = "SHOW FIELDS FROM `emoneybak`"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	cur = assert (con:execute(sql))
	row = cur:fetch ({}, "a") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
	
	i = 0;
	datas = {}
	while row do
	  --print(row.Field, row.Null)
	  if row.Field ~= nil then datas[row.Field] = row.Null end
	  row = cur:fetch (row, "a")	-- reusing the table of results
	end
	
	if datas["Id"] == nil and datas["id"] == nil then 
		sql = "ALTER TABLE `emoneybak` ADD COLUMN `Id` int(11) NOT NULL default 0"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("emoneybak表添加Id字段成功\r\n")
		print("emoneybak表添加Id字段成功")
	end	
	
	if datas["id_source"] == nil then 
		sql = "ALTER TABLE `emoneybak` ADD COLUMN `id_source` int(4) NULL default 0"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("emoneybak表添加id_source字段成功\r\n")
		print("emoneybak表添加id_source字段成功")
	end
	
	if datas["nationsymbol"] == nil then 
		sql = "ALTER TABLE `emoneybak` ADD COLUMN `nationsymbol` int(4) NULL default NULL"
		file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
		res = assert (con:execute(sql))
		file:write("emoneybak表添加nationsymbol字段成功\r\n")
		print("emoneybak表添加nationsymbol字段成功")
	end	

	--删除`m_datamonitorbak`的主键否则一些游戏会有插入异常
	sql = "Alter table `m_datamonitorbak` drop primary key,change id id int(11)"
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = con:execute(sql)

	IsInit = true
end

function rollback()
	--清除已执行的数据
	sql = "delete from m_datamonitor where nationsymbol="..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."清除已执行的数据\r\n")
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))
    
	--清空emoneybak表
	sql = "delete from emoneybak where nationsymbol="..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."清空emoneybak表\r\n")
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	res = assert (con:execute(sql))

	--获取上次执行时间
	sql = "select date_format(max(execdate),'%y%m%d') from m_datamonitorbak where `nationsymbol`="..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."获取上次执行时间\r\n")
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
	cur = assert (con:execute(sql))
	row = cur:fetch ({}, "n") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
	if row ~= nil then
		CurDate = row[1]
		if CurDate ~= nil then
			--还原上次数据
			sql = "INSERT INTO `m_DataMonitor`(Id,type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT Id,type,innertype,Value,ExecDate,`nationsymbol`,version from m_datamonitorbak where date_format(execdate,'%y%m%d')='"..CurDate.."' and `nationsymbol`="..NationSymbol
			file:write(os.date().."\r\n------------------\r\n".."还原上次数据\r\n")
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			res = assert (con:execute(sql))
			--获取上上次执行时间
			sql = "select date_format(max(execdate),'%y%m%d') from m_datamonitorbak where date_format(execdate,'%y%m%d')<'"..CurDate.."' and `nationsymbol`="..NationSymbol
			file:write(os.date().."\r\n------------------\r\n".."获取上上次执行时间\r\n")
			file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
			cur = assert (con:execute(sql))
			row = cur:fetch ({}, "n") --此处 "n" 表示为数字为记录的下标，从1开始, 如果为 "a" 则表示以字段名做为记录的下标
			if row ~= nil then
				PreDate = row[1]
				if PreDate ~= nil then
					--还原上上次数据
					sql = "INSERT INTO `m_DataMonitor`(Id,type,innertype,Value,ExecDate,`nationsymbol`,version) SELECT Id,CONCAT('Old',type),innertype,Value,ExecDate,`nationsymbol`,version from m_datamonitorbak where date_format(execdate,'%y%m%d')='"..PreDate.."' and `nationsymbol`="..NationSymbol
					file:write(os.date().."\r\n------------------\r\n".."还原上上次数据\r\n")
					file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")
					res = assert (con:execute(sql))
				end
			end
		end
	end

	--更新运行标志回滚成功2
	sql = "UPDATE `m_DataMonitor` SET Value=2 WHERE type = 'RunFlag' AND nationsymbol = "..NationSymbol
	file:write(os.date().."\r\n------------------\r\n".."ExecuteSql:"..sql.."\r\n")	
	res = assert (con:execute(sql))
end

----------------------------Begin 调用主函数------------------------------------------
function foo()
	file = io.open(LogPath..os.date("%Y%m%d", os.time())..'.txt', 'a+')
	for i = 1, ReTryCount, 1
	do
		local status,err = pcall(dowork)
		if err~=nil then
			file:write(os.date().."\r\n------------------\r\n程序异常:"..err.."\r\n")
			print(os.date().."\r\n------------------\r\n程序异常:"..err.."\r\n")
			Sleep(ExceptionSleepSec)
		else
			break
		end
	end
	file:close()
end
----------------------------End-------------------------------------------------------


----------------------------Begin 调用主函数------------------------------------------
function dowork()
	require ("luamysql4") --加载luamysql库
	env = assert (luasql.mysql()) --初始化luamysql库
	con = assert (env:connect(Db_DataBaseName, Db_UserName, Db_Password, Db_Server, DB_Port)) --尝试连接数据库

	--表的创建及字段的扩展
	if not IsInit then
		init()
	end

	for i = 1, ReTryCount, 1
	do
		local status,err = pcall(calculate)
		if err==nil then
			file:write(os.date().."\r\n------------------\r\n".."操作成功\r\n")
			print(os.date().."\r\n------------------\r\n".."操作成功\r\n")
			LuaSqlRet="OK"
			break
		else
			file:write(os.date().."\r\n------------------\r\n".."第"..i.."次操作失败:"..err.."\r\n")
			print(os.date().."\r\n------------------\r\n".."第"..i.."次操作失败:"..err.."\r\n")
			LuaSqlRet="第"..i.."次操作失败:"..err

			--执行过程发生错误进行回滚
			file:write(os.date().."\r\n------------------\r\n".."操作失败开始回滚\r\n")
			print(os.date().."\r\n------------------\r\n".."操作失败开始回滚\r\n")
			local status,err = pcall(rollback)
			if err==nil then
				file:write(os.date().."\r\n------------------\r\n".."回滚成功\r\n")
				print(os.date().."\r\n------------------\r\n".."回滚成功\r\n")
			else
				file:write(os.date().."\r\n------------------\r\n".."回滚失败:"..err.."\r\n")
				print(os.date().."\r\n------------------\r\n".."回滚失败"..err.."\r\n")
			end
			Sleep(ExceptionSleepSec)
		end
	end

	--释放对应的资源
	cur:close()
	con:close()
	env:close()
end
----------------------------End-------------------------------------------------------
