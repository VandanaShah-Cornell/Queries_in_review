WITH
marc_formats AS
	(SELECT 
 	sm.instance_id,
       	 substring(sm."content", 7, 2) AS "leader0607"
       	  FROM srs_marctab AS sm  
    	 WHERE  sm.field = '000'),

--Pre-Folio identification of ematerial type by 948 field   	 
field_format AS
	(SELECT 
	sm.instance_id,
	sm."content" AS ematerial_type_by_948,
	sm.sf
	 FROM srs_marctab AS sm  
	 WHERE sm.field = '948' AND sm.sf = 'f' AND sm.content IN ('fd','webfeatdb','imagedb','ebk','j','evideo','eaudio','escore','ewb','emap','emisc')),
	 
--Post-Folio identification of ematerial type by stat code	 
statcode_format AS 
	(SELECT
	sm.instance_id,
	 string_agg(DISTINCT isc.statistical_code, ', ') AS ematerial_type_by_stat_code
	FROM srs_marctab AS sm  
	LEFT JOIN folio_reporting.instance_statistical_codes AS isc ON sm.instance_id = isc.instance_id ::uuid
	WHERE isc.statistical_code IN ('fd','webfeatdb','imagedb','ebk','j','evideo','eaudio','escore','ewb','emap','emisc')
	GROUP BY sm.instance_id	
	),
	
format_merge AS	
	(SELECT 
 	mf.instance_id,
 	mf.leader0607,
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
LEFT JOIN statcode_format AS sf ON mf.instance_id = sf.instance_id)



SELECT count(DISTINCT fm.instance_id) AS CountDistinctInstanceID,
fm.leader0607,
fm.ematerial_type_by_948,
fm.ematerial_type_by_stat_code,
fm.ematerial_format
FROM format_merge AS fm
WHERE ematerial='Yes'

GROUP BY 
fm.leader0607,
fm.ematerial_type_by_948,
fm.ematerial_type_by_stat_code,
fm.ematerial_format
;
