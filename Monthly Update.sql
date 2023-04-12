USE [NHSE_IAPT_v2]

DECLARE @Period_Start DATE
DECLARE @Period_End DATE 

SET @Period_Start = (SELECT DATEADD(MONTH,-1,MAX(ReportingPeriodStartDate)) FROM IDS000_Header)
SET @Period_End = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [dbo].[IDS000_Header])


PRINT @Period_Start
PRINT @Period_End


INSERT INTO [NHSE_Sandbox_MentalHealth].dbo.[IAPT_Dashboard_Student_AnalysisV1]

 SELECT DATENAME(m, @Period_Start) + ' ' + CAST(DATEPART(yyyy, @Period_Start) AS varchar) AS Month 
			,'Refresh' AS DataSource
			,'England' AS GroupType
			,CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END AS 'Provider Code'
			,CASE WHEN o1.Organisation_Name IS NOT NULL THEN o1.Organisation_Name ELSE 'Other' END AS 'Provider Name'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS TotalReferrals
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @Period_Start AND @Period_End AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS StudentReferralsTotal

			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @Period_Start AND @Period_End AND EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 THEN r.PathwayID ELSE NULL END) AS StudentReferrals1825
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @Period_Start AND @Period_End AND EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 THEN r.PathwayID ELSE NULL END) AS StudentReferrals25Plus
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS TotalEnteringTreatment
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @Period_Start AND @Period_End AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS StudentEnteringTreatmentTotal
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @Period_Start AND @Period_End AND EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 THEN r.PathwayID ELSE NULL END) AS StudentEnteringTreatment1825
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @Period_Start AND @Period_End AND EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 THEN r.PathwayID ELSE NULL END) AS StudentEnteringTreatment25Plus

			, NULL AS 'Postcode'
			, NULL AS 'GridRef'
			, NULL AS 'Eastings'
			, NULL AS 'Northings'
			, NULL AS 'Lat'
			, NULL AS 'Long'
			, NULL AS 'City'
			,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End AND Recovery_Flag = 'True' THEN r.PathwayID else NULL END) AS RecoveredTotal,

COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End AND r.TreatmentCareContact_Count >=2
THEN r.PathwayID ELSE NULL END) AS FinishingTreatmentTotal,
COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End and r.TreatmentCareContact_Count>=2 AND NotCaseness_Flag = 'true' 
THEN r.PathwayID ELSE NULL END) AS NotCasenessTotal
,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End AND r.TreatmentCareContact_Count >= 2 AND EmployStatus = '03' AND Recovery_Flag = 'true' 
THEN r.PathwayID else NULL END) AS RecoveredStudent
,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End AND r.TreatmentCareContact_Count >=2 AND EmployStatus = '03' AND CompletedTreatment_Flag = 'True'
THEN r.PathwayID ELSE NULL END) AS FinishingTreatmentStudent
,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End and r.TreatmentCareContact_Count>=2 AND NotCaseness_Flag = 'true' AND EmployStatus = '03'							
THEN r.PathwayID ELSE NULL END) AS NotCasenessStudent
,COUNT(DISTINCT CASE WHEN  TreatmentCareContact_Count >= 2 AND ServDischDate BETWEEN @Period_Start AND @Period_End 
AND  ReliableImprovement_Flag = 'True' AND EmployStatus = '03' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement STUDENT'
,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @Period_Start AND @Period_End AND r.TreatmentCareContact_Count >= 2 AND  ReliableImprovement_Flag = 'True' 
THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
			
		FROM [dbo].[IDS101_Referral] r

		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IDS000_Header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		LEFT JOIN [dbo].[IDS004_EmploymentStatus] e ON r.RecordNumber = e.RecordNumber
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		LEFT JOIN NHSE_Reference.dbo.tbl_Ref_ODS_Provider_Hierarchies o1 ON r.OrgID_Provider = o1.Organisation_Code

WHERE h.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @Period_Start) AND @Period_Start
		AND UsePathway_Flag = 'True'  AND IsLatest = 1



GROUP BY CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END
			,CASE WHEN o1.Organisation_Name IS NOT NULL THEN o1.Organisation_Name ELSE 'Other' END 

IF OBJECT_ID ('tempdb..#Postcodes') IS NOT NULL DROP TABLE #Postcodes
SELECT SiteCode, Postcode1,  [Grid Reference]
      ,[X (easting)]
      ,[Y (northing)]
      ,[Latitude]
      ,[Longitude]
	  ,Address4

INTO #Postcodes 
FROM [NHSE_Sandbox_MentalHealth].[dbo].[ODS_All_Sites]

UPDATE [NHSE_Sandbox_MentalHealth].dbo.[IAPT_Dashboard_Student_AnalysisV1]
SET Postcode = b.Postcode1,
GridRef = b.[Grid Reference],
Eastings = b.[X (easting)],
Northings = b.[Y (northing)],
Lat = b.Latitude,
Long = b.Longitude,
City = b.Address4
FROM 
 [NHSE_Sandbox_MentalHealth].dbo.[IAPT_Dashboard_Student_AnalysisV1] a
 LEFT JOIN #Postcodes b
ON a.[Provider Code]= b.SiteCode
