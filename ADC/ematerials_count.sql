WITH
marc_formats AS
	(SELECT 
 	sm.instance_id,
       	 substring(sm."content", 7, 2) AS "leader0607"
       	  FROM srs_marctab AS sm  
       	  LEFT JOIN folio_reporting.holdings_ext he ON sm.instance_id = he.instance_id::uuid
    	 WHERE  sm.field = '000'
    	 AND he.permanent_location_name LIKE 'serv,remo'
    	 AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL OR he.discovery_suppress ='FALSE')
    	 ),

--Pre-Folio identification of ematerial type by 948 field   
--only 9 e-images	 
field_format AS
	(SELECT 
	 sm.instance_id,
	sm."content" AS ematerial_type_by_948
	 FROM srs_marctab AS sm  
	 WHERE sm.field = '948' AND sm.sf = 'f' AND sm.content IN ('fd','webfeatdb','imagedb','ebk','j','evideo','eaudio','escore','ewb','emap','emisc')),
	 
--Post-Folio identification of ematerial type by stat code	
--Zero images 
statcode_format AS 
	(SELECT
	 sm.instance_id,
	 string_agg(DISTINCT isc.statistical_code, ', ') AS ematerial_type_by_stat_code
	FROM srs_marctab AS sm  
	LEFT JOIN folio_reporting.instance_statistical_codes AS isc ON sm.instance_id = isc.instance_id ::uuid
	WHERE isc.statistical_code IN ('fd','webfeatdb','imagedb','ebk','j','evideo','eaudio','escore','ewb','emap','emisc')
	GROUP BY sm.instance_id	
	ORDER BY string_agg(DISTINCT isc.statistical_code, ', ')
	),
	
--FLAGGING UNPURCHASED
unpurch AS
	(SELECT 
     DISTINCT sm.instance_id,
     sm."content"  AS "unpurchased"
      FROM srs_marctab AS sm  
       WHERE sm.field LIKE '899'
    AND sm.sf LIKE 'a'
    AND sm."content" ILIKE 'Couttspdbappr'
   ),

format_merge AS	
	(SELECT 
 	mf.instance_id,
 	up.unpurchased,
 	fmg.leader0607description,
 	ff.ematerial_type_by_948,
 	sf.ematerial_type_by_stat_code,
 	 	
 	CASE 
 	WHEN ff.ematerial_type_by_948 ='ebk' OR sf.ematerial_type_by_stat_code ='ebk' THEN 'e-book'
 	WHEN ff.ematerial_type_by_948 IN ('fd','webfeatdb', 'ewb') OR sf.ematerial_type_by_stat_code IN ('fd','webfeatdb', 'ewb') THEN 'e-database'
 	WHEN ff.ematerial_type_by_948 ='imagedb' OR sf.ematerial_type_by_stat_code ='imagedb' THEN 'e-image'
 	WHEN ff.ematerial_type_by_948 ='j' OR sf.ematerial_type_by_stat_code ='j' THEN 'e-journal'
 	WHEN ff.ematerial_type_by_948 ='evideo' OR sf.ematerial_type_by_stat_code ='evideo' THEN 'e-video'
 	WHEN ff.ematerial_type_by_948 ='eaudio' OR sf.ematerial_type_by_stat_code ='eaudio' THEN 'e-audio'
 	WHEN ff.ematerial_type_by_948 ='escore' OR sf.ematerial_type_by_stat_code ='escore' THEN 'e-score'
 	WHEN ff.ematerial_type_by_948 ='emap' OR sf.ematerial_type_by_stat_code ='emap' THEN 'e-map'
 	WHEN ff.ematerial_type_by_948 ='emisc' OR sf.ematerial_type_by_stat_code ='emisc' THEN 'e-misc'
 	ELSE 'unknown' END AS ematerial_format,
 	
 	CASE 
 	WHEN ff.ematerial_type_by_948 IS NULL AND  sf.ematerial_type_by_stat_code IS NULL THEN 'No'
 	ELSE 'Yes' END AS ematerial
 		
 	FROM 
marc_formats AS mf
LEFT JOIN field_format AS ff ON mf.instance_id = ff.instance_id
LEFT JOIN statcode_format AS sf ON mf.instance_id = sf.instance_id
LEFT JOIN local_core.vs_folio_physical_material_formats AS fmg ON mf.leader0607=fmg.leader0607
LEFT JOIN unpurch AS up ON up.instance_id=mf.instance_id),


merge2 AS
(SELECT DISTINCT fm.instance_id,
fm.leader0607description,
fm.ematerial_type_by_948,
fm.ematerial_type_by_stat_code,
fm.ematerial_format,
fm.unpurchased
FROM format_merge AS fm
)

SELECT COUNT (DISTINCT mm.instance_id),
mm.leader0607description,
mm.ematerial_type_by_948,
mm.ematerial_type_by_stat_code,
mm.ematerial_format

FROM merge2 AS mm


GROUP BY 
mm.leader0607description,
mm.ematerial_type_by_948,
mm.ematerial_type_by_stat_code,
mm.ematerial_format,
mm.unpurchased



;
