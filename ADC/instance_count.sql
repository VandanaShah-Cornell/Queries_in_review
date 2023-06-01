WITH
 			
marc_formats AS
	(SELECT 
 		DISTINCT sm.instance_id,
       	substring(sm."content", 7, 2) AS "leader0607"
     	FROM srs_marctab AS sm  
    	WHERE  sm.field = '000'),

holdings AS
(SELECT DISTINCT
    	he.instance_id,
     	mf.leader0607
   	
   	   	
   	FROM folio_reporting.holdings_ext AS he
  
   	INNER JOIN marc_formats AS mf ON he.instance_id ::uuid=mf.instance_id
   	INNER JOIN folio_reporting.instance_ext AS ie ON he.instance_id = ie.instance_id 
   
   	 
 --exclude materials from the following locations, as these locations are sub-sets of main locations, and including them would result in double counts
 --also exclude serv,remo which are all e-materials and are counted in a separate query
   	
 WHERE  (he.permanent_location_name NOT ILIKE ALL(ARRAY['serv,remo', '%LTS%','Agricultural Engineering','Bindery Circulation',
'Biochem Reading Room', 'Borrow Direct', 'CISER', 'cons,opt', 'Engineering', 'Engineering Reference', 'Engr,wpe',
'Entomology', 'Food Science', 'Law Technical Services', 'LTS Review Shelves', 'LTS E-Resources & Serials','Mann Gateway',
'Mann Hortorium', 'Mann Hortorium Reference', 'Mann Technical Services', 'Iron Mountain', 'Interlibrary Loan%', 'Phys Sci',
'RMC Technical Services', 'No Library','x-test', 'z-test location' ]))

--exclude the following materials as they are not available for discovery
AND he.call_number NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%', '%film%','%fiche%', '%micro%', '%vault%']) 

AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL OR he.discovery_suppress ='FALSE')
AND he.permanent_location_name IS NOT NULL
AND (ie.discovery_suppress IS NOT TRUE OR ie.discovery_suppress IS NULL OR ie.discovery_suppress = 'FALSE'))

SELECT COUNT (DISTINCT hh.instance_id) AS distinct_title_count,
hh.leader0607,
fmg.leader0607description,
fmg.folio_format_type,
fmg.folio_format_type_adc_groups, 
fmg.folio_format_type_acrl_nces_groups

FROM holdings AS hh
INNER JOIN local_core.vs_folio_physical_material_formats AS fmg ON hh.leader0607=fmg.leader0607
GROUP BY hh.leader0607,
fmg.leader0607description,
fmg.folio_format_type,
fmg.folio_format_type_adc_groups, 
fmg.folio_format_type_acrl_nces_groups
