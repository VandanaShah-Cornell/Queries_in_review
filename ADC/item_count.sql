WITH
 			
marc_formats AS
	(SELECT 
 		DISTINCT sm.instance_id,
       	substring(sm."content", 7, 2) AS "leader0607"
       	  FROM srs_marctab AS sm  
         LEFT JOIN folio_reporting.instance_ext ie ON sm.instance_id = ie.instance_id ::uuid	
    	 WHERE  sm.field = '000'
    	 AND (ie.discovery_suppress = 'FALSE' OR ie.discovery_suppress IS NULL OR ie.discovery_suppress IS NOT TRUE)
    	
    	 ),

 
--bring in holdings details in order to exclude some locations
    	 
holdings AS
    (SELECT 
   	he.holdings_id,
   	he.instance_id,
   	he.permanent_location_id,
   	he.permanent_location_name AS holdings_permanent_location_name
 
	   	   	   	
   	FROM folio_reporting.holdings_ext AS he
  
   	LEFT JOIN folio_reporting.instance_ext AS ii ON he.instance_id=ii.instance_id
 
 --exclude materials from the following locations, as these locations are sub-sets of main locations, and including them would result in double counts
 --also exclude serv,remo which are all e-materials and are counted in a separate query
   	WHERE 
   (he.permanent_location_name NOT ILIKE ALL(ARRAY['serv,remo', '%LTS%','Agricultural Engineering','Bindery Circulation',
'Biochem Reading Room', 'Borrow Direct', 'CISER', 'cons,opt', 'Engineering', 'Engineering Reference', 'Engr,wpe',
'Entomology', 'Food Science', 'Law Technical Services', 'LTS Review Shelves', 'LTS E-Resources & Serials','Mann Gateway',
'Mann Hortorium', 'Mann Hortorium Reference', 'Mann Technical Services', 'Iron Mountain', 'Interlibrary Loan%', 'Phys Sci',
'RMC Technical Services', 'No Library','x-test', 'z-test location' ])) 

AND he.call_number NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%', '%film%','%fiche%', '%micro%', '%vault%']) 
AND ii.title NOT ILIKE '%microform%' 

--exclude the following materials as they are not available for discovery

AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL OR he.discovery_suppress ='FALSE')
AND he.permanent_location_name IS NOT NULL
ORDER BY he.instance_id, he.holdings_id
),


--bring in item details 
items AS
(SELECT 
DISTINCT ie.item_id, 
ie.holdings_record_id AS holdings_id,
ie.created_date::DATE AS item_record_created_date,
ie.permanent_location_id,
ie.permanent_location_name AS item_permanent_location_name,
date_part ('month',ie.created_date::DATE) as month_record_created,
date_part ('year',ie.created_date::DATE)::VARCHAR as record_created,
        
CASE WHEN 
                date_part ('month',ie.created_date::DATE) >'6' 
                THEN concat ('FY ', date_part ('year',ie.created_date::DATE) + 1) 
                ELSE concat ('FY ', date_part ('year',ie.created_date::DATE))
                END as record_created_fiscal_year

FROM folio_reporting.item_ext as ie 

--exclude materials labeled as 'bound with' as they are a subset of an item
WHERE concat_ws (' ',ie.effective_call_number_prefix,ie.effective_call_number,ie.effective_call_number_suffix,ie.enumeration,ie.chronology) NOT ILIKE '%bound%with%'

),

--combine holdings and instances subqueries and include format descriptors from the translation table 'local_core.vs_folio_physical_material_formats'
combined AS   
(SELECT DISTINCT
  	hh.instance_id,
   	hh.holdings_id,
    hh.holdings_permanent_location_name,
   	ite.item_id,
   	ite.record_created_fiscal_year,
   	adc2.adc_loc_translation AS holdings_adc_loc_translation,
   	ll.discovery_display_name,
   	ll.library_name AS holdings_library_name,
   	lz.library_name AS items_library_name,
   	fm.leader0607,
  	fmg.leader0607description,
  	fmg.folio_format_type,
   	fmg.folio_format_type_adc_groups, 
    fmg.folio_format_type_acrl_nces_groups
    
   	
  	FROM marc_formats AS fm
  	LEFT JOIN holdings AS hh ON hh.instance_id ::uuid = fm.instance_id
  	LEFT JOIN items AS ite ON ite.holdings_id=hh.holdings_id
	LEFT JOIN folio_reporting.locations_libraries AS ll ON hh.permanent_location_id = ll.location_id  
	LEFT JOIN folio_reporting.locations_libraries AS lz ON ite.permanent_location_id = lz.location_id  
   	LEFT JOIN local_core.vs_folio_physical_material_formats AS fmg ON fmg.leader0607 = fm.leader0607
    LEFT JOIN local_core.lm_adc_loc_translation AS adc2 ON 	hh.holdings_permanent_location_name=adc2.permanent_location_name)
    
    
   SELECT 
    count(DISTINCT cc.item_id) AS counDistinct_itemID,
   	cc.record_created_fiscal_year,
   	cc.holdings_permanent_location_name,
   	cc.holdings_adc_loc_translation,
   	cc.holdings_library_name,
   	cc.leader0607,
  	cc.leader0607description,
  	cc.folio_format_type,
	cc.folio_format_type_adc_groups, 
	cc.folio_format_type_acrl_nces_groups
       FROM combined AS cc
    
   
    GROUP BY
           
   	cc.record_created_fiscal_year,
   	cc.holdings_permanent_location_name,
   	cc.holdings_adc_loc_translation,
   	cc.holdings_library_name,
   	cc.leader0607,
  	cc.leader0607description,
  	cc.folio_format_type,
	cc.folio_format_type_adc_groups, 
	cc.folio_format_type_acrl_nces_groups
	;
