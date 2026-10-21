[rarsql]
sql01=drop table if exists game_endtime;
sql02=create table game_endtime(bak_flag varchar(30) not null,end_time datetime not null);
sql03=insert into game_endtime(bak_flag,end_time)values('%s',now());