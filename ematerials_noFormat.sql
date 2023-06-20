WITH
marc_formats AS
       (SELECT 
       sm.instance_hrid,
       substring(sm."content", 7, 2) AS leader0607
       FROM srs_marctab AS sm  
           
       WHERE  sm.field = '000'
),

field_format AS
       (SELECT 
       sm.instance_hrid,
       sm."content" AS ematerial_type_by_948
       FROM srs_marctab AS sm  
       
       WHERE sm.field = '948' 
       AND sm.sf = 'f' 
       AND sm.content IN ('fd','webfeatdb','imagedb','ebk','j','evideo','eaudio','escore','ewb','emap','emisc')
),
       
statcode_format AS 
       (SELECT
       isc.instance_hrid,
       string_agg(DISTINCT isc.statistical_code, ', ') AS ematerial_type_by_stat_code
       
       FROM folio_reporting.instance_statistical_codes AS isc 
       
       WHERE isc.statistical_code IN ('fd','webfeatdb','imagedb','ebk','j','evideo','eaudio','escore','ewb','emap','emisc')
       
       GROUP BY isc.instance_hrid   
),

/*Flagging unpurchased materials*/
unpurch AS
                                (SELECT DISTINCT 
                                sm.instance_hrid,
                                sm."content"  AS "unpurchased"
                                      
                                FROM srs_marctab AS sm  
                                
                                WHERE sm.field = '899'
                                    AND sm.sf LIKE 'a'
                                    AND sm.CONTENT ILIKE ANY (ARRAY['DDA_pqecebks', 'PDA_casaliniebkmu']) 
),

format_merge AS
                (SELECT 
                mf.instance_hrid,
                mf.leader0607,
                up.unpurchased,
                fmg.leader0607description,
                ff.ematerial_type_by_948,
                sf.ematerial_type_by_stat_code,
                COALESCE (ff.ematerial_type_by_948, sf.ematerial_type_by_stat_code) AS ematerial

FROM marc_formats AS mf
                LEFT JOIN field_format AS ff ON mf.instance_hrid = ff.instance_hrid
                LEFT JOIN statcode_format AS sf ON mf.instance_hrid = sf.instance_hrid
                LEFT JOIN local_core.vs_folio_physical_material_formats AS fmg ON mf.leader0607 = fmg.leader0607
                LEFT JOIN unpurch AS up ON up.instance_hrid = mf.instance_hrid
),
                
format_final AS  
(SELECT DISTINCT
                format_merge.instance_hrid,
                ii.title,
                format_merge.leader0607,
                format_merge.leader0607description,
                format_merge.unpurchased,
                format_merge.ematerial_type_by_948,
                format_merge.ematerial_type_by_stat_code,
                format_merge.ematerial,
                he.permanent_location_name,
                CASE          
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['ebk'])   THEN 'e-book'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['fd','webfeatdb', 'ewb']) THEN 'e-database'
                    WHEN format_merge.ematerial ='imagedb' THEN 'e-image'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['j']) THEN 'e-journal'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['evideo'])  THEN 'e-video'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['eaudio']) THEN 'e-audio'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['escore']) THEN 'e-score'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['emap']) THEN 'e-map'
                    WHEN format_merge.ematerial ILIKE ANY (ARRAY['emisc']) THEN 'e-misc' 
                    
                    ELSE  'unknown' END AS ematerial_format
                
                FROM format_merge
                                LEFT JOIN inventory_instances AS ii 
                                ON ii.hrid = format_merge.instance_hrid 
                                
                                LEFT JOIN folio_reporting.holdings_ext AS he 
                                ON ii.id = he.instance_id 
                
                WHERE (ii.discovery_suppress = 'False' OR ii.discovery_suppress IS NULL OR ii.discovery_suppress IS NOT TRUE) 
                AND (he.discovery_suppress = 'False' OR he.discovery_suppress IS NULL OR he.discovery_suppress IS NOT TRUE) 
                AND he.permanent_location_name = 'serv,remo'
)

SELECT
DISTINCT format_final.instance_hrid,
format_final.leader0607description,
format_final.ematerial_type_by_948,
format_final.ematerial_type_by_stat_code,
format_final.unpurchased,
format_final.ematerial,
format_final.ematerial_format,
format_final.permanent_location_name


FROM format_final
WHERE format_final.ematerial_format='unknown'
  
GROUP BY
		format_final.instance_hrid,
                format_final.leader0607description,
                format_final.ematerial_type_by_948,
                format_final.ematerial_type_by_stat_code,
                format_final.unpurchased,
                format_final.ematerial,
                format_final.ematerial_format,
                format_final.permanent_location_name
                
                
              
                
                
;
