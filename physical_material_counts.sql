--physical_material_counts.sql
--date: 5-8-23

--This query takes about 10 mins to run. If you want to export the results to EXCEL, it will run all over again, so 
--another way to do that is to select all the code, right-click, select execute, and then choose Export from Query. 
--Then follow steps to export as an EXCEL file. 

--Bring in marc format codes from the marctab table
WITH
marc_formats1 AS 
    (SELECT 
    sm.instance_id,
       	 substring(sm."content", 7, 1) AS "leader06"
       		FROM srs_marctab AS sm   
 			WHERE  sm.field = '000'),
 			
marc_formats2 AS
	(SELECT 
 sm.instance_id,
       	 substring(sm."content", 8, 1) AS "leader07"
       	 FROM srs_marctab AS sm   
    	 WHERE  sm.field = '000'),	
 			
marc_formats3 AS
	(SELECT 
 sm.instance_id,
       	 substring(sm."content", 7, 2) AS "leader0607"
       	  FROM srs_marctab AS sm  
    	 WHERE  sm.field = '000'),
    	 
	
format_merge AS
	(SELECT 
 	mf1.instance_id,
 	mf1.leader06,
 	mf2.leader07,
 	mf3.leader0607
 	 	
 	FROM 
marc_formats1 AS mf1
LEFT JOIN marc_formats2 AS mf2 ON mf1.instance_id = mf2.instance_id
LEFT JOIN marc_formats3 AS mf3 ON mf1.instance_id = mf3.instance_id


GROUP BY mf1.instance_id, 
	mf1.leader06,
 	mf2.leader07,
 	mf3.leader0607
	
	
ORDER BY instance_id),


--bring in item details
items AS
(SELECT 
ie.item_id, 
ie.holdings_record_id,
ie.created_date::DATE AS item_record_created_date,
ie.material_type_name AS item_material_type_name,
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
ORDER BY ie.item_id
),

--bring in holdings details
holdings AS
    (SELECT 
   	he.holdings_id,
   	he.instance_id,
   	he.permanent_location_id,
   	he.type_name AS holdings_type,
   	he.permanent_location_name AS holdings_permanent_location_name,
   
   	--identifying micro items via call number and title
   	CASE 
	WHEN ((concat_ws (' ',he.call_number_prefix,he.call_number,he.call_number_suffix) iLIKE '%film%'OR ii.title ilike '%[film%]%'))  THEN 'film'
  	WHEN ((concat_ws (' ',he.call_number_prefix,he.call_number,he.call_number_suffix) ILIKE '%fiche%' OR ii.title ilike '%[fiche%]%'))  THEN 'fiche' 
   	WHEN ((concat_ws (' ',he.call_number_prefix,he.call_number,he.call_number_suffix) iLIKE '%micro%'OR ii.title ilike '%[micro%]%'))   THEN 'micro' 
   	ELSE 'Not micro' END AS micro_from_callNum_title,
   	
	CASE
   	WHEN ((concat_ws (' ',he.call_number_prefix,he.call_number,he.call_number_suffix) iLIKE '%vault%'OR ii.title ilike '%[vault%]%'))  THEN 'vault'
   	ELSE 'Not vault' END AS vault_from_callNum_title
   	   	   	
   	FROM folio_reporting.holdings_ext AS he
  
   	LEFT JOIN folio_reporting.instance_ext AS ii ON he.instance_id=ii.instance_id
 
 --exclude materials from the following locations, as these locations are sub-sets of main locations, and including them would result in double counts
 --also exclude serv,remo which are all e-materials and are counted in a separate query
   	WHERE 
   (he.permanent_location_name NOT ILIKE ALL(ARRAY['serv,remo', '%LTS%','Agricultural Engineering','Bindery Circulation',
'Biochem Reading Room', 'Borrow Direct', 'CISER', 'cons,opt', 'Engineering', 'Engineering Reference', 'Engr,wpe',
'Entomology', 'Food Science', 'Law Technical Services', 'LTS Review Shelves', 'LTS E-Resources & Serials','Mann Gateway',
'Mann Hortorium', 'Mann Hortorium Reference', 'Mann Technical Services', 'Iron Mountain', 'Interlibrary Loan%', 'Phys Sci',
'RMC Technical Services', 'No Library','x-test', 'z-test location' ]) OR he.permanent_location_name IS NULL)

--exclude the following materials as they are not available for discovery
AND trim(concat (he.call_number_prefix,' ',he.call_number,' ',he.call_number_suffix)) NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%'])
AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL)
ORDER BY he.instance_id, he.holdings_id
)
--combine all subqueries and include format descriptors from the translation table 'local_core.vs_folio_physical_material_formats'
   SELECT 
   	
   	ite.record_created_fiscal_year,
   	ite.item_material_type_name,
   	hh.holdings_type,
   	hh.holdings_permanent_location_name,
   	ite.item_permanent_location_name,
   	adc1.adc_loc_translation AS item_adc_loc_translation,
   	adc2.adc_loc_translation AS holdings_adc_loc_translation,
   	--ll.location_name,
   	ll.discovery_display_name,
   	ll.library_name AS holdings_library_name,
   	lz.library_name AS items_library_name,
  	fm.leader06,
  	fm.leader07,
  	fm.leader0607,
  	fmg.leader06description,
  	fmg.leader07description,
  	fmg.folio_format_type,
    fmg.folio_format_type_adc_groups, 
    fmg.folio_format_type_acrl_nces_groups,
  	count(DISTINCT hh.instance_id) AS countDistinct_instanceID,
   	count(hh.instance_id) AS count_instanceID,
   	count(ite.item_id) AS count_itemID,
   	count(hh.holdings_id) AS count_holdings_ID,
    hh.micro_from_callNum_title,
   	hh.vault_from_callNum_title,
   	CASE WHEN hh.micro_from_callNum_title IN ('film', 'fiche', 'micro' ) THEN 'Yes'
   	ELSE 'No' END AS micro_material
   	
  	FROM items AS ite
   	LEFT JOIN holdings AS hh ON ite.holdings_record_id = hh.holdings_id 
    LEFT JOIN format_merge AS fm ON hh.instance_id ::uuid = fm.instance_id
    LEFT JOIN folio_reporting.locations_libraries AS ll ON hh.permanent_location_id = ll.location_id  
    LEFT JOIN folio_reporting.locations_libraries AS lz ON ite.permanent_location_id = lz.location_id  
    LEFT JOIN local_core.vs_folio_physical_material_formats AS fmg ON fmg.leader06=fm.leader06 AND fmg.leader07=fm.leader07 
    LEFT JOIN local_core.lm_adc_loc_translation AS adc1 ON 	hh.holdings_permanent_location_name=adc1.permanent_location_name
    LEFT JOIN local_core.lm_adc_loc_translation AS adc2 ON ite.item_permanent_location_name=adc2.permanent_location_name
    
   
     GROUP BY  	
    ite.record_created_fiscal_year,
   	ite.item_material_type_name,
   	micro_material,
   	hh.holdings_type,
   	hh.holdings_permanent_location_name,
   	ite.item_permanent_location_name,
   	adc1.adc_loc_translation,
   	adc2.adc_loc_translation,
   	--ll.location_name,
   	ll.discovery_display_name,
   	ll.library_name,
   	lz.library_name,
  	fm.leader06,
  	fm.leader07,
  	fm.leader0607,
  	fmg.leader06description,
  	fmg.leader07description,
  	fmg.folio_format_type,
    fmg.folio_format_type_adc_groups, 
    fmg.folio_format_type_acrl_nces_groups,
  	hh.micro_from_callNum_title,
   	hh.vault_from_callNum_title
    ;
