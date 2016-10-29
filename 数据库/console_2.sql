USE sql作业数据;
# ALTER TABLE 学生表 ADD FOREIGN KEY (班长学号) REFERENCES 学生表(学号);
# SHOW CREATE TABLE 学生表;
# ALTER TABLE 学生表 DROP FOREIGN KEY 学生表_ibfk_1;
# ALTER TABLE 学生表 ADD FOREIGN KEY (系号) REFERENCES 系表(系号);
# ALTER TABLE 学生表 MODIFY COLUMN 年龄 INTEGER;
# ALTER TABLE 学生表 MODIFY COLUMN 入学年份 CHAR(50);
# ALTER TABLE 系表 MODIFY COLUMN 系号 INTEGER;
# ALTER TABLE 学生表 MODIFY COLUMN 系号 INTEGER;
# ALTER TABLE 选课表 MODIFY 成绩 INTEGER;
# ALTER TABLE 学生表 ADD COLUMN 手机号 CHAR(50) UNIQUE ;
# ALTER TABLE 课程表 ADD UNIQUE (课程名);
# ALTER TABLE 学生表 ADD CONSTRAINT CK_sex CHECK (性别='男' OR 性别='女');

#1
# CREATE TABLE `系表` (
#   `系号` CHAR(3) PRIMARY KEY ,
#   `系名` CHAR(100) UNIQUE ,
#   `系主任` CHAR(40)
# );
#
# CREATE TABLE `学生表` (
#   `学号` CHAR(10) PRIMARY KEY ,
#   `姓名` CHAR(40),
#   `性别` CHAR(5) CHECK (`性别` IN('男','女')),
#   `年龄` INT CHECK (`年龄`>=10 AND `年龄`<=50),
#   `入学年份` CHAR(2),
#   `籍贯` CHAR(40),
#   `系号` CHAR(3),
#   `班长学号` CHAR(10),
#   FOREIGN KEY (`系号`) REFERENCES `系表`(`系号`),
#   FOREIGN KEY (`班长学号`) REFERENCES `学生表`(`学号`)
# );
#
# CREATE TABLE `课程表`(
#   `课程号` CHAR(10) PRIMARY KEY ,
#   `课程名` CHAR(40) UNIQUE ,
#   `先修课` CHAR(10),
#   `学分` INT CHECK (`学分`>0 AND `学分`<5),
#   FOREIGN KEY (`先修课`) REFERENCES `课程表`(`课程号`)
# );
#
# CREATE TABLE `选课表` (
#   `学号` CHAR(10),
#   `课程号` CHAR(10),
#   `成绩` DOUBLE CHECK (`成绩`>=0 AND `成绩`<=100),
#   PRIMARY KEY (`学号`,`课程号`),
#   FOREIGN KEY (`学号`) REFERENCES `学生表`(`学号`),
#   FOREIGN KEY (`课程号`) REFERENCES `课程表`(`课程号`)
# );
#
# CREATE TABLE `学分计算表` (
#   `最低成绩` INT,
#   `最高成绩` INT,
#   `计算比率` DOUBLE
# );

#3
# INSERT INTO 学生表(学号, 姓名, 性别, 年龄, 入学年份, 籍贯, 班长学号, 手机号)
#     VALUES  (26, '李四', '女', 20, 2008, '广东', 10, 10010001000)

#4
# DELETE FROM 学生表
# WHERE 学号=26

#5
# ALTER TABLE 学生表 MODIFY 姓名 CHAR(18)

#6
# ALTER TABLE 学生表 ADD COLUMN 电子邮件 CHAR(20);

#7
# ALTER TABLE 课程表 ADD CONSTRAINT CK_score CHECK (0 <= 学分 AND 学分 <= 6);

#8
# ALTER TABLE 学生表 ADD INDEX cluster('学号');

#9
# CREATE VIEW 每门课的最高分 AS SELECT 课程表.课程号, MAX(成绩) FROM 课程表, 选课表 WHERE 课程表.课程号=选课表.课程号 GROUP BY 课程表.课程号;

#10
# SELECT 学生表.学号, 姓名, SUM(成绩) FROM 学生表, 选课表 WHERE 学生表.学号=选课表.学号 GROUP BY 学生表.学号;

#11
# UPDATE 学生表
# INNER JOIN (
#     SELECT AVG(年龄) 7系平均年龄 FROM 学生表 WHERE 系号 = '07'
# ) AS B
# SET 年龄 = B.7系平均年龄 WHERE 系号 = '06';

#12
# UPDATE 选课表
# SET 成绩=67 WHERE 学生表.姓名='曹洪'

#13
# SELECT 姓名, 入学年份, 籍贯 FROM 学生表;

#14
# SELECT * FROM 学生表 WHERE 籍贯='山东'

#15
# SELECT 学号, 姓名 FROM 学生表 WHERE 年龄=(SELECT MIN(年龄) FROM 学生表);

#16
# SELECT DISTINCT 学生表.学号 FROM 学生表 INNER JOIN 课程表 INNER JOIN 选课表 WHERE 课程名='数据库';

#17
# SELECT DISTINCT 学生表.学号, 学生表.姓名 FROM 学生表 INNER JOIN 选课表 INNER JOIN 课程表 WHERE 课程名='编译技术' AND 性别='女';

#18
# SELECT DISTINCT 课程表.课程号 FROM 学生表 INNER JOIN 选课表 INNER JOIN 课程表 WHERE 学生表.学号=(SELECT 班长学号 FROM 学生表 WHERE 姓名='典韦');

#19
# SELECT DISTINCT 学号, 姓名, 系名 FROM 学生表 INNER JOIN 系表 WHERE 姓名 LIKE '%侯_';

#20
# SELECT DISTINCT 课程名 FROM 课程表 WHERE 课程名 LIKE 'P%L__';

#21
# SELECT DISTINCT SUM(成绩) FROM 学生表 INNER JOIN 选课表 WHERE 姓名='甘宁';

#22
# SELECT DISTINCT 学号, 姓名 FROM 成绩表
# WHERE EXISTS(SELECT * FROM 成绩表 X WHERE X.学号 = 学号 AND 课程名= '数据库')
# AND EXISTS(SELECT * FROM 成绩表 Y WHERE Y.学号 = 学号 AND 课程名= '操作系统');

#23
# SELECT DISTINCT 学号, 姓名 FROM 成绩表 A
# WHERE 学号 NOT IN (SELECT 学号 FROM 成绩表 WHERE '数据库' IN (SELECT 课程名 FROM 成绩表 X WHERE X.学号 = A.学号));

#24
# CREATE VIEW 成绩表 AS SELECT 学生表.学号, 姓名, 课程名, 成绩 FROM ((学生表 INNER JOIN 选课表 ON 学生表.学号 = 选课表.学号) INNER JOIN 课程表 ON 选课表.课程号 = 课程表.课程号) ;
# SELECT DISTINCT 学号, 姓名 FROM 成绩表 A
# WHERE exists(SELECT * FROM 成绩表 X WHERE A.学号=X.学号 AND 课程名='数据库' AND 成绩>=60)
#       AND exists(SELECT * FROM 成绩表 Y WHERE A.学号=Y.学号 AND 课程名='编译技术' AND 成绩<60)

#25
# SELECT 学号, 姓名 FROM 成绩表 WHERE 课程名='数据库' AND 成绩 < (SELECT AVG(成绩) FROM 成绩表 WHERE 课程名='数据库');

#26
CREATE VIEW 貂蝉的课号 AS SELECT DISTINCT 课程号 FROM (学生表 INNER JOIN 选课表 ON 学生表.学号 = 选课表.学号 AND 姓名='貂蝉');
SELECT 学号,姓名 FROM 学生表 学生表OUT
  WHERE NOT EXISTS(       #不存在课程此学生选了但"貂蝉"没选,反之亦然
    SELECT 课程号 FROM 选课表
      WHERE (课程号 IN (   #此学生选了但"貂蝉"没选
        SELECT 课程号 FROM 选课表
          WHERE 学号 = 学生表OUT.学号
      ) AND 课程号 NOT IN (
        SELECT * FROM 貂蝉的课号
    ) OR (课程号 NOT IN (  #或此学生没选但"貂蝉"选了
        SELECT 课程号 FROM 选课表
          WHERE 学号 = 学生表OUT.学号
      ) AND 课程号 IN (
        SELECT * FROM 貂蝉的课号
      )
  )));

#27
# SELECT 学号,姓名 FROM 学生表 学生表OUT
#   WHERE EXISTS(#此学生选了但"貂蝉"没选
#     SELECT 课程号 FROM 选课表
#       WHERE 课程号 IN (
#         SELECT 课程号 FROM 选课表
#           WHERE 选课表.学号 = 学生表OUT.学号
#       ) AND 课程号 NOT IN (
#         SELECT 课程号 FROM 选课表,学生表 学生表IN
#           WHERE 选课表.学号 = 学生表IN.学号 AND
#                 学生表IN.姓名 = "貂蝉"
#     )) AND
#   NOT EXISTS( #或此学生没选但"貂蝉"选了
#     SELECT 课程号 FROM 选课表
#       WHERE 课程号 NOT IN (
#           SELECT 课程号 FROM 选课表
#             WHERE 选课表.学号 = 学生表OUT.学号
#         ) AND 课程号 IN (
#           SELECT 课程号 FROM 选课表,学生表 学生表IN
#             WHERE 选课表.学号 = 学生表IN.学号 AND
#                   学生表IN.姓名 = "貂蝉"
#         )
#   );


#28
# CREATE VIEW 高等数学学生成绩表 AS
#   SELECT 学生表.学号, 学生表.姓名, 系表.系名, 选课表.成绩, 课程表.课程名 FROM
#     ((((学生表
#     INNER JOIN 选课表 ON 学生表.学号 = 选课表.学号)
#     INNER JOIN 系表 ON 学生表.系号 = 系表.系号)
#     INNER JOIN 课程表 ON 选课表.课程号 = 课程表.课程号));
# (SELECT 系名, MAX(平均成绩) FROM (SELECT 系名, AVG(成绩) 平均成绩 FROM 高等数学学生成绩表 WHERE 课程名 = '数学' GROUP BY 系名) as 学) ;

#29
# CREATE VIEW 籍贯课程 AS SELECT 籍贯, 课程名 FROM ((学生表 INNER JOIN 选课表 ON 学生表.学号 = 选课表.学号) INNER JOIN 课程表 ON 选课表.课程号 = 课程表.课程号);
# SELECT DISTINCT 课程名 FROM 籍贯课程 WHERE 籍贯课程.籍贯 = '四川'

#30
CREATE FUNCTION getCredit(Sno CHAR(10),Cno CHAR(10)) RETURNS DOUBLE
  BEGIN
    DECLARE score INT;
    DECLARE Ccredit INT;
    DECLARE ratio DOUBLE;
    SELECT 成绩 INTO score FROM 选课表
      WHERE 学号=Sno AND 课程号 = Cno;
    SELECT 学分 INTO Ccredit FROM 课程表
      WHERE 课程号 = Cno;
    SELECT 计算比率 INTO ratio FROM 学分计算表
      WHERE 最低成绩 <= score AND 最高成绩 >= score;
    SET @result = Ccredit*ratio;
    RETURN @result;
  END;

# 31
CREATE PROCEDURE info(id CHAR(10))
  BEGIN
    DECLARE Dno CHAR(10);
    DECLARE StudentCount INT;
    DECLARE CourseCount DOUBLE;
    DECLARE AvgScore DOUBLE;
    DECLARE Srank INT;
    SELECT 系号 INTO Dno FROM 学生表 WHERE 学号=id;
    SELECT COUNT(*) INTO StudentCount FROM 学生表
      WHERE 系号 = Dno;
    SELECT COUNT(*) INTO CourseCount FROM
      选课表 INNER JOIN 学生表 ON 选课表.学号 = 学生表.学号
      WHERE 系号 = Dno;
    SELECT AVG(成绩) INTO AvgScore FROM
      选课表 INNER JOIN 学生表 ON 选课表.学号 = 学生表.学号
      WHERE 系号 = Dno;
    SELECT 排名 INTO Srank FROM (
      SELECT 学号, @rank:=@rank+1 排名 FROM(
        SELECT 学生表.学号, AVG(成绩) 平均成绩 FROM
          选课表 INNER JOIN 学生表 ON 选课表.学号 = 学生表.学号
          WHERE 系号 = Dno
          GROUP BY 学生表.学号
          ORDER BY 平均成绩 DESC
      ) AS temp1,(SELECT @rank := 0) AS temp2
    ) AS 排名表
      WHERE 学号 = id;
    SELECT StudentCount 学生人数,CourseCount/StudentCount 平均选课门数,
      AvgScore 平均成绩, Srank 排名;
  END;