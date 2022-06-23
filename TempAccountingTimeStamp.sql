USE Puritan_Test
GO

DROP TABLE IF EXISTS [dbo].[TempAccountingTimeStamp]
GO

CREATE TABLE [dbo].[TempAccountingTimeStamp]
    (
        [CurrentTime] [DATETIME] NOT NULL ,
        CONSTRAINT [PK_TempAccountingTimeStamp]
            PRIMARY KEY CLUSTERED ( [CurrentTime] ASC )
            WITH ( PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [FG1]
    ) ON [FG1]
GO