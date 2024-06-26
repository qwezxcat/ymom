USE [U8211394]
GO
/****** Object:  StoredProcedure [dbo].[getNORR]    Script Date: 05/13/2024 20:13:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Создание хранимой процедуры --
ALTER PROCEDURE [dbo].[getNORR](
@id INT,
@norr INT OUTPUT
)
AS
-- Определяет количество подчиненных строк по идентификатору инженера
-- Входной параметр @id нужен для поиска инженера
-- Выходной параметр @norr будет содержать количество подчиненных строк
-- Процедура возвращает код –100, если значение идентификатора 
-- в таблице engineers отсутствует 

SET NOCOUNT ON;
SELECT @norr=COUNT(bus_id)
FROM buses
WHERE engineer_id=@id;
SELECT engineer_id 
FROM engineers
WHERE engineer_id=@id;
IF @@ROWCOUNT=0
	RETURN -100;
ELSE
	RETURN 0;



--Проверка хранимой процедуры
Declare @Qty int,
        @RetCode int; 
-- RetCode = 0 --
EXEC @RetCode = getNORR 10, @Qty OUTPUT;
SELECT @RetCode, @Qty;

-- RetCode = -100 --
EXEC @RetCode = getNORR 5, @Qty OUTPUT;
SELECT @RetCode, @Qty;


USE [U8211394]
GO
/****** Object:  StoredProcedure [dbo].[addNORR]    Script Date: 05/13/2024 20:10:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Создание процедуры на увеличение числа подчиненных строк --
ALTER PROCEDURE [dbo].[addNORR](
@Id  INT
) 
AS
-- Прибавляет 1 к числу подчиненных строк в таблице engineers
-- Входной параметр @Id задает индентификатор инженера
-- Процедура возвращает код –100, если инженер с 
-- идентификатором @Id отсутствует 
SET NOCOUNT ON;
UPDATE engineers SET NORR = NORR + 1
  WHERE engineer_id = @Id;
IF @@RowCount=0
   RETURN -100;
RETURN;


USE [U8211394]
GO
/****** Object:  StoredProcedure [dbo].[addBuses]    Script Date: 05/13/2024 21:17:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Создание процедуры на добавление строки в таблицу buses --
ALTER PROCEDURE [dbo].[addBuses](
@Model nchar(20),
@Capacity float,
@DriverID int,
@EngineerID int
)
AS
-- Добавляет строку  в таблицу Buses
--и корректирует общее количество подчиненных строк с помощью триггера
SET NOCOUNT ON;
INSERT INTO buses(model, capacity, driver_id, engineer_id)
		VALUES(@Model, @Capacity, @DriverID, @EngineerID)
RETURN;


-- Тестирование процедуры addbuses --
Declare @Qty int,
        @RetCode int; 

EXEC @RetCode = getNORR 5, @Qty OUTPUT;
SELECT @RetCode, @Qty;

EXEC @RetCode = addBuses 'A', 200, 3, 5;
SELECT @RetCode;

EXEC @RetCode = getNORR 5, @Qty OUTPUT;
SELECT @RetCode, @Qty;


USE [U8211394]
GO
/****** Object:  StoredProcedure [dbo].[subNORR]    Script Date: 05/13/2024 20:36:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Создание процедуры на уменьшение числа подчиненных строк --
ALTER PROCEDURE [dbo].[subNORR]( 
@Id  INT
) 
AS
-- Вычитает 1 из числа подчиненных строк в таблице engineers
-- Входной параметр @Id задает индентификатор инженера
-- Процедура возвращает код –100, если инженер с 
-- идентификатором @Id отсутствует 
SET NOCOUNT ON;
UPDATE engineers SET NORR = NORR - 1
  WHERE engineer_id = @Id;
IF @@RowCount=0
   RETURN -100;
RETURN;



-- Создание процедуры на удаление строки из таблицы Buses --
CREATE PROCEDURE removeBuses(
@Id  INT,
@EngineerId INT
) 
AS
-- Удаляет строку из таблицы buses и корректирует общее количество подчиненных строк
-- Входной параметр @Id задает индентификатор автобуса
-- Входной параметр @UserId задает индентификатор инженера
-- Процедура возвращает код –100, если инженер с 
-- идентификатором @EngineerId отсутствует 
-- Процедура возвращает код –101, если автобус с 
-- идентификатором @Id отсутствует 
SET NOCOUNT ON;
Declare @RetCode int; 

DELETE FROM buses
   WHERE (bus_id = @Id)
IF @@RowCount=0
   RETURN -101;
EXEC @RetCode = subNORR @EngineerId;
IF @RetCode<>0
   RETURN @RetCode;
RETURN;



-- Тестирование процедуры removebuses --
Declare @Qty int,
        @RetCode int; 

EXEC @RetCode = getNORR 5, @Qty OUTPUT;
SELECT @RetCode, @Qty;

EXEC @RetCode = removeBuses 11,5;
SELECT @RetCode;

EXEC @RetCode = getNORR 5, @Qty OUTPUT;
SELECT @RetCode, @Qty;



-- Создание триггера afterInsert --
CREATE TRIGGER ai_buses_trig ON buses
AFTER Insert
AS
SET NOCOUNT ON
Declare @RetCode int,
@Inserted INT;
SELECT TOP 1 @Inserted = [engineer_id] FROM inserted;
EXEC @RetCode = addNORR @Inserted;


-- Создание триггера afterDelete --
CREATE TRIGGER ad_buses_trig ON buses
AFTER Delete
AS
SET NOCOUNT ON
Declare @RetCode int,
@Inserted INT;
SELECT TOP 1 @Inserted = [engineer_id] FROM deleted;
EXEC @RetCode = subNORR @Inserted;
