WITH marc_formats AS
	(SELECT 
 		DISTINCT sm.instance_id,
       	substring(sm."content", 7, 2) AS "leader0607"
     	FROM srs_marctab AS sm  
    	WHERE  sm.field = '000'),
    	
candidates AS 
(SELECT DISTINCT sm.instance_id

                FROM srs_marctab AS sm
                LEFT JOIN folio_reporting.holdings_ext he ON sm.instance_id = he.instance_id::uuid
                LEFT JOIN inventory_instances as ii ON ii.id::uuid=sm.instance_id
                WHERE  sm.field = '007'  AND substring (sm."content",1,1) = 'h'
                OR (he.call_number similar to '%(Film|Fiche|Micro|film|fiche|micro)%')
       			OR (ii.title ilike '%[microform]%')
                AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL OR he.discovery_suppress ='FALSE')
                AND
 --exclude materials from the following locations, as these locations are sub-sets of main locations, and including them would result in double counts
(he.permanent_location_name NOT ILIKE ALL(ARRAY['serv,remo', '%LTS%','Agricultural Engineering','Bindery Circulation',
'Biochem Reading Room', 'Borrow Direct', 'CISER', 'cons,opt', 'Engineering', 'Engineering Reference', 'Engr,wpe',
'Entomology', 'Food Science', 'Law Technical Services', 'LTS Review Shelves', 'LTS E-Resources & Serials','Mann Gateway',
'Mann Hortorium', 'Mann Hortorium Reference', 'Mann Technical Services', 'Iron Mountain', 'Interlibrary Loan%', 'Phys Sci',
'RMC Technical Services', 'No Library','x-test', 'z-test location' ]) OR he.permanent_location_name IS NULL)

--exclude the following materials as they are not available for discovery
AND trim(concat (he.call_number_prefix,' ',he.call_number,' ',he.call_number_suffix)) NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%'])
AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL)
AND (he.discovery_suppress is null or he.discovery_suppress = 'False')
)

        
  SELECT COUNT (DISTINCT cc.instance_id),
  	mfg.leader0607description,
 	mfg.folio_format_type,
	mfg.folio_format_type_adc_groups, 
	mfg.folio_format_type_acrl_nces_groups
  
  FROM candidates AS cc
  INNER JOIN marc_formats AS mf ON cc.instance_id=mf.instance_id
  INNER JOIN local_core.vs_folio_physical_material_formats AS mfg ON mf.leader0607=mfg.leader0607
       
   GROUP BY  
  	mfg.leader0607description,
   	mfg.folio_format_type,
	mfg.folio_format_type_adc_groups, 
	mfg.folio_format_type_acrl_nces_groups
  
