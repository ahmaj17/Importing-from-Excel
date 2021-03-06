USE [Puritan_Test]
GO
/****** Object:  StoredProcedure [dbo].[uspUpdateOOIDABasicADDRecon]    Script Date: 6/22/2022 10:47:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC dbo.uspUpdateOOIDABasicADDRecon
--============================================================================
CREATE PROCEDURE [dbo].[uspUpdateOOIDABasicADDReconQueriesADDED]
AS
    BEGIN

        SET NOCOUNT ON;

        DECLARE @Tries AS SMALLINT ,
            @SqlReturnSts AS INT ,
            @TransactionDate AS DATETIME;

		-- Retry 3 times for deadlocks
        SET @Tries = 3;
        SET @SqlReturnSts = 0;
        SET @TransactionDate = GETDATE();
					
        DECLARE @procParametersTmp AS NVARCHAR(4000);
        SET @procParametersTmp = 'none';

        WHILE @Tries > 0
            AND @SqlReturnSts = 0
            BEGIN

                BEGIN TRY

                    BEGIN TRANSACTION;

                    UPDATE  dbo.OOIDABasicADDRecon
                    SET     AccountNo = RIGHT('000000000' + AccountNo, 7)
                    WHERE   LEN(AccountNo) <> 7;

                    UPDATE  dbo.OOIDABasicADDRecon
                    SET     AMRPolNo = '2' + RIGHT('000000000' + AccountNo, 7) + 'BA'
                    WHERE   AMRPolNo IS NULL;

                    UPDATE  r
                    SET     EffDate = a.EffDate ,
                            Address1 = a.Address1 ,
                            Address2 = a.Address2 ,
                            City = a.City ,
                            [State] = a.[State] ,
                            Zip = a.Zip ,
                            DOB = a.DOB
                    FROM    dbo.OOIDABasicADD a
                            INNER JOIN dbo.OOIDABasicADDRecon r ON a.AccountNo = r.AccountNo
					WHERE   r.EffDate IS NULL;


					--********************************************
					--[OOIDABasicADD99 SumRecon] is a query in Access, so need to use CTE to use in SQL
					
					WITH OOIDABasic_CTE  (EntryDate, 
										  PolCount, 
										  PriorAmt, 
										  AddCurrAmt, 
										  DelCurrAmt, 
										  TotalAmt)
					AS (SELECT   EntryDate,
							     SUM(IIF([totalcurrentamt]=0.06,1,0)),
							     ROUND(SUM(ActivePriorAmt),2) ,
							     ROUND(SUM(AddCurrentAmt),2) ,
							     ROUND(SUM(DelCurrentAmt),2) ,
							     ROUND(SUM(TotalCurrentAmt),2)
						FROM     OOIDABasicADDRecon
						GROUP BY EntryDate 
					    )
					SELECT * 
					INTO OOIDABasicADD99_SumRecon
					FROM OOIDABasic_CTE
					
					--SELECT * FROM OOIDABasicADD99_SumRecon ORDER BY EntryDate
					
					--********************************************
					--QUERY 1a: 
					--OOIDABasicAdd1a AccuontingEntry PremiumEntry
					INSERT INTO AccountingEntries 
							( SystemCode, 
							  Category, 
							  RefNo, 
							  Amt, 
							  DebitorCredit, 
							  EntryDate, 
							  Account, 
							  EmpID, 
							  Batch, 
							  GLDescription )
					SELECT    '00' AS Expr3, 
					          'OOIDABASIC Receipt' AS Expr13, 
							  'OOIDABASIC' AS Expr1, 
							  OOIDABasicADD99_SumRecon.TotalAmt, 
							  'D' AS Expr2, 
							  [TempAccountingTimeStamp].CurrentTime, 
							  '21100' AS Expr4, 
							  'OOIDABASIC' AS Expr5, 
							  'OOIDABASIC' & '-' & Format([CurrentTime],'yyyymmdd hh:nn:ss AM/PM') AS Expr6, 
							  'OOIDA BASIC for - ' & [EntryDate] AS Expr7
					FROM      [TempAccountingTimeStamp], 
					          OOIDABasicADD99_SumRecon, 
							  ValnDate
					WHERE     Format([EntryDate],'yyyymm')=Format([valn]-27,'yyyymm')

					
					--********************************************
					--Query 1b:
					--OOIDABasicAdd1b AccountingEntry Suspense
					INSERT INTO AccountingEntries 
							( SystemCode, 
							  Category, 
							  RefNo, 
							  Amt, 
							  DebitorCredit, 
							  EntryDate, 
							  Account, 
							  EmpID, 
							  Batch, 
							  GLDescription )
					SELECT    '00' AS Expr3, 
							  'OOIDABASIC Receipt' AS Expr13, 
							  'OOIDABASIC' AS Expr1, 
							  OOIDABasicADD99_SumRecon.TotalAmt, 
							  'D' AS Expr2, 
							  [TempAccountingTimeStamp].CurrentTime, 
							  '21100' AS Expr4, 
							  'OOIDABASIC' AS Expr5, 
							  'OOIDABASIC' & '-' & Format([CurrentTime],'yyyymmdd hh:nn:ss AM/PM') AS Expr6,
							  'OOIDA BASIC for - ' & [EntryDate] AS Expr7
					FROM      [TempAccountingTimeStamp],
					          OOIDABasicADD99_SumRecon, 
							  ValnDate
					WHERE    Format([EntryDate],'yyyymm') = Format([valn]-27,'yyyymm')


	
                    IF @@TRANCOUNT > 0
                        COMMIT TRANSACTION;

                    SET @SqlReturnSts = 0;

					-- break out of the loop if successful 
                    BREAK;
			
                END TRY
                BEGIN CATCH

					-- We want to retry if in a deadlock
                    IF ( ( ERROR_NUMBER() = 1205 )
                         AND ( @Tries > 0 )
                       )
                        BEGIN
                            SET @Tries = @Tries - 1;

                            IF @Tries = 0
                                SET @SqlReturnSts = -1;

                            IF @@TRANCOUNT > 0
                                BEGIN
                                    ROLLBACK TRANSACTION;
                                END;
							-- go back to the top of the loop
                            CONTINUE;
                        END;
                    ELSE
                        BEGIN
							-- if not a deadlock then bail out
                            SET @Tries = -1;
                            IF @@TRANCOUNT > 0
                                BEGIN
                                    ROLLBACK TRANSACTION;
                                END;

                            SET @SqlReturnSts = -1;
				
                            EXECUTE dbo.uspLogError @procParameters = @procParametersTmp, @userFriendly = 1;

                            BREAK;                         

                        END;

                END CATCH;

            END;

    END;






