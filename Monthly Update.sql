SET ANSI_WARNINGS OFF
SET DATEFIRST 1
SET NOCOUNT ON
--------------
DECLARE @Offset INT = -1
-------------------------
DECLARE @Max_Offset INT = -2
-------------------------------------|
WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
-------------------------------------|

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-----------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_Student]

 SELECT	@MonthYear as 'Month'
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.Organisation_Name IS NOT NULL THEN ph.Organisation_Name ELSE 'Other' END AS 'Provider Name'

		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'TotalReferrals'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS 'StudentReferralsTotal'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 THEN r.PathwayID ELSE NULL END) AS 'StudentReferrals1825'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 THEN r.PathwayID ELSE NULL END) AS 'StudentReferrals25Plus'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'TotalEnteringTreatment'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS 'StudentEnteringTreatmentTotal'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 THEN r.PathwayID ELSE NULL END) AS 'StudentEnteringTreatment1825'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 THEN r.PathwayID ELSE NULL END) AS 'StudentEnteringTreatment25Plus'

		, NULL AS 'Postcode'
		, NULL AS 'GridRef'
		, NULL AS 'Eastings'
		, NULL AS 'Northings'
		, NULL AS 'Lat'
		, NULL AS 'Long'
		, NULL AS 'City'

		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND Recovery_Flag = 'True' THEN r.PathwayID else NULL END) AS 'RecoveredTotal'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 THEN r.PathwayID ELSE NULL END) AS 'FinishingTreatmentTotal'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd and r.TreatmentCareContact_Count >= 2 AND NotCaseness_Flag = 'true' THEN r.PathwayID ELSE NULL END) AS 'NotCasenessTotal'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND EmployStatus = '03' AND Recovery_Flag = 'true' THEN r.PathwayID else NULL END) AS 'RecoveredStudent'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND EmployStatus = '03' AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'FinishingTreatmentStudent'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd and r.TreatmentCareContact_Count >= 2 AND NotCaseness_Flag = 'true' AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS 'NotCasenessStudent'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND ReliableImprovement_Flag = 'True' AND EmployStatus = '03' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement STUDENT'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
			
FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		-------------------------
		LEFT JOIN [mesh_IAPT].[IDS004empstatus] e ON r.RecordNumber = e.RecordNumber
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		-------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND UsePathway_Flag = 'True'  AND IsLatest = 1

GROUP BY CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END
		,CASE WHEN ph.Organisation_Name IS NOT NULL THEN ph.Organisation_Name ELSE 'Other' END 

------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Postcodes') IS NOT NULL DROP TABLE #Postcodes

SELECT	[SiteCode]
		,[Postcode1]
		,[Grid Reference]
		,[X (easting)]
		,[Y (northing)]
		,[Latitude]
		,[Longitude]
		,[Address4]

INTO #Postcodes FROM [MHDInternal].[ODS_All_Sites]

-- ------------------------------------------------------------------------------

UPDATE [MHDInternal].[DASHBOARD_TTAD_Student]

SET		Postcode = b.Postcode1,
		GridRef = b.[Grid Reference],
		Eastings = b.[X (easting)],
		Northings = b.[Y (northing)],
		Lat = b.Latitude,
		Long = b.Longitude,
		City = b.Address4

FROM	[MHDInternal].[DASHBOARD_TTAD_Student] a
		LEFT JOIN #Postcodes b

ON		a.[Provider Code]= b.SiteCode

------------------------------|
SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT CHAR(10) + 'Updated - [MHDInternal].[DASHBOARD_TTAD_Student]'