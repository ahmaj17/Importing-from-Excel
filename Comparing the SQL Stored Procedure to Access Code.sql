--*************************************************
--Comparing Access queries to SQL stored procedures

USE Puritan_Test
GO
--Tables that will change: dbo.OOIDABasicADDRecon, r?, AccountingEntries, OOIDABasicADD99_SumRecon(this is a query in Access, not sure about this)
--OOIDABasicADD99_SumRecon currently has 52 rows

SELECT * 
INTO   dbo.OOIDABasicADDRecon_Baseline
FROM   dbo.OOIDABasicADDRecon

SELECT *
INTO   dbo.AccountingEntries_Baseline
FROM   dbo.AccountingEntries


--Run the Access code then save the results in _access tables
--In Access:
--a. UpdateOOIDABasicADDRecon
--b. OOIDABasicADD1a Accounting....
--c. OOIDABasicAdd1b Accounting....


--Build tables with data from Access: 
SELECT * 
INTO   dbo.OOIDABasicADDRecon_Access
FROM   dbo.OOIDABasicADDRecon

SELECT *
INTO   dbo.AccountingEntries_Access
FROM   dbo.AccountingEntries

--3. Reset the baseline by copying 'Baseline" table back to its original 
DELETE dbo.OOIDABasicADDRecon

SET identity_insert dbo.OOIDABasicADDRecon on;

INSERT INTO dbo.OOIDABasicADDRecon(
				AccountNo,
				[Name],
				ActivePrior,
				AddCurrent,
				DelCurrent,
				TotalCurrent,
				ActivePriorAmt,
				AddCurrentAmt,
				DelCurrentAmt,
				TotalCurrentAmt,
				EffDate,
				Address1,
				Address2,
				City,
				[State],
				Zip,
				DOB,
				EntryDate,
				AddedToMaster,
				AMRPolNo,
				ID)
SELECT          AccountNo,
			    [Name],
				ActivePrior,
				AddCurrent,
				DelCurrent,
				TotalCurrent,
				ActivePriorAmt,
				AddCurrentAmt,
				DelCurrentAmt,
				TotalCurrentAmt,
				EffDate,
				Address1,
				Address2,
				City,
				[State],
				Zip,
				DOB,
				EntryDate,
				AddedToMaster,
				AMRPolNo,
				ID
FROM dbo.OOIDABasicADDRecon_Baseline

DELETE dbo.AccountingEntries

INSERT INTO dbo.AccountingEntries (DebitorCredit, Comp, Category, Account, Amt, RefNo, EmpID, EntryDate, Batch, SentToLedger, IssueCheck, PayeeName,
                                   PayeeAddr, PayeeAddr2, PayeeAddr3, PayeeCity, PayeeState, PayeeZip, PayeeForeignAddress, PayeeForeignLine1,
									 PayeeForeignLine2, PayeeForeignLine3, PayeeCountry, CheckNumber, CheckStubDes1, CheckStubDes2, CheckStubDes3, 
									 CheckStubDes4)
SELECT DebitorCredit,
	     Comp,
		 Category,
		 Account,
		 Amt, 
		 RefNo,
		 EmpID,
		 EntryDate,
		 Batch,
		 SentToLedger,
		 IssueCheck,
		 PayeeName,
		 PayeeAddr,
		 PayeeAddr2,
		 PayeeAddr3,
		 PayeeCity,
		 PayeeState,
		 PayeeZip,
		 PayeeForeignAddress,
		 PayeeForeignLine1,
		 PayeeForeignLine2,
		 PayeeForeignLine3,
		 PayeeCountry,
		 CheckNumber,
		 CheckStubDes1,
		 CheckStubDes2,
		 CheckStubDes3,
		 CheckStubDes4
FROM dbo.AccountingEntries_Baseline

--4. With the table back to its original state, run the new stored procedure 

EXEC dbo.uspUpdateOOIDABasicADDReconQueriesADDED
GO

--Now compare the base table to the Access version for differences in the columns that were updates

--*************************************************
--OOIDABasicADDRecon
SELECT   ooida.ActivePrior,
		 ooida.AccountNo,
		 ooida.AddCurrent,
		 ooida.DelCurrent,
		 ooida.TotalCurrent,
		 access.AccountNo,
		 access.ActivePrior,
		 access.AddCurrent,
		 access.DelCurrent,
		 access.TotalCurrent
FROM   dbo.OOIDABasicADDRecon ooida
       LEFT JOIN dbo.OOIDABasicADDRecon_Access access ON access.AccountNo = ooida.AccountNo 
	   AND ooida.TotalCurrent = access.TotalCurrent
	   AND access.EntryDate = ooida.EntryDate
WHERE     access.ActivePrior <> ooida.ActivePrior
       OR access.AddCurrent <> ooida.AddCurrent 
	   OR access.DelCurrent <> ooida.DelCurrent
       OR access.TotalCurrent <> ooida.TotalCurrent

--*************************************************
--Second Comparison Statement

SELECT   ooida.ActivePriorAmt,
		 ooida.AddCurrentAmt,
		 ooida.DelCurrentAmt,
		 ooida.TotalCurrentAmt,
		 ooida.AccountNo,
		 ooida.EntryDate,
		 access.EntryDate,
		 access.AccountNo,
		 access.ActivePriorAmt,
		 access.AddcurrentAmt,
		 access.DelCurrentAmt,
		 access.TotalCurrentAmt
FROM   dbo.OOIDABasicADDRecon ooida
       Left JOIN dbo.OOIDABasicADDRecon_Access access ON access.AccountNo = ooida.AccountNo
	   AND access.EntryDate = ooida.EntryDate
	   AND access.TotalCurrentAmt = ooida.TotalCurrentAmt
WHERE     ooida.ActivePriorAmt <> access.ActivePriorAmt
         OR ooida.AddCurrentAmt <> access.AddCurrentAmt
		 OR ooida.DelCurrentAmt <> access.DelCurrentAmt
		 OR ooida.TotalCurrentAmt <> access.TotalCurrentAmt


--*************************************************
--AccountingEntries
SELECT [sql].Amt, access.Amt,
	   [sql].DebitorCredit, access.DebitorCredit,
	   [sql].Comp, access.Comp,
	   [sql].PayeeName, access.PayeeName,
	   [sql].SystemCode, access.SystemCode,	
	   [sql].EntryDate, access.EntryDate,
	   [sql].IssueCheck, access.IssueCheck,
	   [sql].CheckNumber, access.CheckNumber,
	   [sql].OtherRefNo, access.OtherRefNo,
	   [sql].TaxYear, access.TaxYear,
	   [sql].TaxState, access.TaxState,
	   [sql].PayeeAddr, access.PayeeAddr,
	   [sql].SentToLedger, access.SentToLedger,
	   [sql].GLDescription, access.GLDescription
FROM   dbo.AccountingEntries [sql] 
	   LEFT JOIN dbo.AccountingEntries_Access access ON access.rowguid = [sql].rowguid
WHERE  [sql].Amt <> access.Amt
	   OR [sql].DebitorCredit <> access.DebitorCredit
	   OR [sql].Comp <> access.Comp
	   OR [sql].PayeeName <> access.PayeeName
	   OR [sql].SystemCode <> access.SystemCode
	   OR [sql].EntryDate <> access.EntryDate
	   OR [sql].IssueCheck <> access.IssueCheck
	   OR [sql].CheckNumber <> access.CheckNumber
	   OR [sql].OtherRefNo <> access.OtherRefNo
	   OR [sql].TaxYear <> access.TaxYear
	   OR [sql].TaxState <> access.TaxState
	   OR [sql].PayeeAddr <> access.PayeeAddr
	   OR [sql].SentToLedger <> access.SentToLedger
	   OR [sql].GLDescription <> access.GLDescription
	



