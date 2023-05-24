--LINDAS FIRST TWO TABLES
--LINDA TABLE 1
--8,881,165 on 5/23/23
DROP TABLE IF EXISTS LOCAL.VS_titlprint_ct_1; 
CREATE TABLE local.VS_titlprint_ct_1 AS
SELECT DISTINCT 
       sm.instance_hrid,
    sm.instance_id,
    sm.field,
    substring(sm."content", 7, 2) AS "format_type",
    ie.discovery_suppress,
    ie.record_created_date::date AS date_created
    FROM srs_marctab sm 
    LEFT JOIN folio_reporting.instance_ext AS ie ON sm.instance_id = ie.instance_id::uuid
    LEFT JOIN srs_records sr ON sm.srs_id = sr.id::uuid
    WHERE sm.field LIKE '000'
    AND (ie.discovery_suppress = 'FALSE' OR ie.discovery_suppress IS NULL)
    AND sr.state  = 'ACTUAL'
;


--LINDA TABLE 2
/*Query 2: Adds holdings information and removes records with formats, locations and statuses not 
 * wanted, including microforms and remote e-resources. Holdings records must be unsuppressed.*/

--6,121,047 on 5/23/23
DROP TABLE IF EXISTS local.VS_titlprint_ct_2; 
CREATE TABLE local.VS_titlprint_ct_2 AS 
SELECT DISTINCT 
    tc1.instance_id,
    tc1.instance_hrid,
    tc1."format_type",
    h.holdings_hrid,
    h.holdings_id,
    h.permanent_location_name,
    h.call_number,
    --h.call_number_prefix,
    h.discovery_suppress,
    tc1.date_created
    FROM  local.VS_titlprint_ct_1 AS tc1
    LEFT JOIN  folio_reporting.holdings_ext AS h ON tc1.instance_id=h.instance_id::uuid
    WHERE h.permanent_location_name NOT ilike 'serv,remo'
    AND h.permanent_location_name NOT ilike '%LTS%'
    AND h.permanent_location_name NOT ilike 'Agricultural Engineering'
    AND h.permanent_location_name NOT ilike 'Bindery Circulation'
    AND h.permanent_location_name NOT ilike 'Biochem Reading Room'
    AND h.permanent_location_name NOT iLIKE 'Borrow Direct'
    AND h.permanent_location_name NOT ilike 'CISER'
    AND h.permanent_location_name NOT ilike 'cons,opt'
    AND h.permanent_location_name NOT ilike 'Engineering'
    AND h.permanent_location_name NOT ilike 'Engineering Reference'
    AND h.permanent_location_name NOT ilike 'Engr,wpe'
    AND h.permanent_location_name NOT ilike 'Entomology'
    AND h.permanent_location_name NOT ilike 'Food Science'
    AND h.permanent_location_name NOT ilike 'Law Technical Services'
    AND h.permanent_location_name NOT ilike 'LTS Review Shelves'
    AND h.permanent_location_name NOT ilike 'LTS E-Resources & Serials'
    AND h.permanent_location_name NOT ilike 'Mann Gateway'
    AND h.permanent_location_name NOT ilike 'Mann Hortorium'
    AND h.permanent_location_name NOT ilike 'Mann Hortorium Reference'
    AND h.permanent_location_name NOT ilike 'Mann Technical Services'
    AND h.permanent_location_name NOT ilike 'Iron Mountain'
    AND h.permanent_location_name NOT ilike 'Interlibrary Loan%'
    AND h.permanent_location_name NOT ilike 'Phys Sci'
    AND h.permanent_location_name NOT ilike 'RMC Technical Services'
    AND h.permanent_location_name NOT ilike 'No Library'
    AND h.permanent_location_name NOT ilike 'x-test'
    AND h.permanent_location_name NOT ilike 'z-test location'
    AND h.call_number !~~* 'on order%'
    AND h.call_number !~~* 'in process%'
    AND h.call_number !~~* 'Available for the library to purchase'
    AND h.call_number !~~* 'On selector%'
    AND h.call_number !~~* '%film%' 
       AND h.call_number !~~* '%fiche%' 
       AND h.call_number !~~* '%micro%' 
       AND h.call_number !~~* '%vault%'
    AND (h.discovery_suppress = 'FALSE' 
    OR h.discovery_suppress IS NULL )
;


--VANDANA'S FIRST TWO TABLES (IN ONE QUERY)
--VANDANA TABLE 1
--6,035,325 on 5/23/23 IF I exclude micro in call number prefix and suffix.
--6,121,047 if I do not do so. Makes no sense becacuse there are only 655 instances with micro in suffix or prefix

DROP TABLE IF EXISTS LOCAL.vsl_hlds;
CREATE TABLE local.vsl_hlds AS

WITH
 			
marc_formats AS
	(SELECT 
 		DISTINCT sm.instance_id,
       	substring(sm."content", 7, 2) AS "leader0607"
       	 		 
    	FROM srs_marctab AS sm  
    	LEFT JOIN folio_reporting.instance_ext ie ON sm.instance_id = ie.instance_id ::uuid	
    	WHERE  sm.field = '000')
    
SELECT DISTINCT
   	he.holdings_id,
   	he.instance_id,
   	he.permanent_location_id,
   	he.permanent_location_name AS holdings_permanent_location_name,
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
'RMC Technical Services', 'No Library','x-test', 'z-test location' ])) --OR he.permanent_location_name IS NULL)

--exclude the following materials as they are not available for discovery
AND he.call_number NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%', '%film%','%fiche%', '%micro%', '%vault%']) --added film fische micro vault this on to compare with Linda's
 /*AND he.call_number_suffix NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%', '%film%','%fiche%', '%micro%', '%vault%'])
AND he.call_number_prefix NOT ILIKE ALL(ARRAY['on order%', 'in process%', 'Available for the library to purchase', 
 'On selector%', '%film%','%fiche%', '%micro%', '%vault%'])*/
AND (he.discovery_suppress IS NOT TRUE OR he.discovery_suppress IS NULL OR he.discovery_suppress ='FALSE')
AND he.permanent_location_name IS NOT NULL
AND (ie.discovery_suppress IS NOT TRUE OR ie.discovery_suppress IS NULL OR ie.discovery_suppress = 'FALSE');



/* LINDA'S TABLE 3 To make title count unique again.*/
-- 5,718,461 ON 5/23/23

DROP TABLE IF EXISTS local.VS_titlprint_ct_3; 
CREATE TABLE local.VS_titlprint_ct_3 AS 
SELECT DISTINCT
       ft."format_type",
       ft.instance_hrid
FROM local.VS_titlprint_ct_2 AS ft
;

--VANDANA'S TABLE 3 version in case my count so far in the first table is not distinct
--5,634,903 ON 5/23/23 without the micros in suffix ad prefix
--5,718,461 not excluding them
DROP TABLE IF EXISTS LOCAL.vsl_hlds2;
CREATE TABLE LOCAL.vsl_hlds2 AS
SELECT DISTINCT ft.instance_id,
ft.leader0607
FROM LOCAL.vsl_hlds AS ft
;

--LINDA'S FINAL TABLE: TABLE 4 Groups and counts titles in titlprint_ct_3 by format, adding format translation. Also removes
--known unpurchased PDA/DDA items through a subquery.
--VS NOTE: VS changed the bib format display table to the recent folio format table.
--This creates 5,321,304 bokks (unique instances) and 217,637 serials. 
DROP TABLE IF EXISTS local.VS_titlprint_ct_4;
CREATE TABLE local.VS_titlprint_ct_4 AS

WITH title_unpurch AS 
(SELECT DISTINCT 
    sm.instance_hrid,
    sm.instance_id,
    sm.field,
    sm."content",
    ie.discovery_suppress
    FROM srs_marctab AS sm 
    LEFT JOIN folio_reporting.instance_ext AS ie ON sm.instance_id = ie.instance_id::uuid
    LEFT JOIN srs_records sr ON sm.srs_id = sr.id::uuid
    WHERE sm.field LIKE '899'
    AND sm.sf LIKE 'a'
    AND sm."content" ILIKE 'Couttspdbappr'
    AND (ie.discovery_suppress = 'FALSE' OR ie.discovery_suppress IS NULL)
    AND sr.state  = 'ACTUAL' --I added this back ON 6/23/22
)
SELECT DISTINCT
tc3."format_type" AS "Bib Format",
bft.folio_format_type_adc_groups AS adc_formats,
count(tc3.instance_hrid) AS "Total"
FROM local.VS_titlprint_ct_3 AS tc3
LEFT JOIN local_core.vs_folio_physical_material_formats AS bft ON tc3."format_type" = bft.leader0607
LEFT JOIN title_unpurch ON tc3.instance_hrid = title_unpurch.instance_hrid
WHERE title_unpurch.instance_id IS NULL
GROUP BY tc3."format_type", bft.folio_format_type_adc_groups
ORDER BY bft.folio_format_type_adc_groups
;

--VS FINAL TABLE
--5,239,663 books excluding micro in prefix and suffix
--5,321,313 books without excluding
DROP TABLE IF EXISTS LOCAL.vsl_hlds3;
CREATE TABLE LOCAL.vsl_hlds3 AS
SELECT COUNT (v2.instance_id),
v2.leader0607,
fmg.leader0607description,
fmg.folio_format_type,
fmg.folio_format_type_adc_groups, 
fmg.folio_format_type_acrl_nces_groups

FROM LOCAL.vsl_hlds2 AS v2
INNER JOIN local_core.vs_folio_physical_material_formats AS fmg ON v2.leader0607=fmg.leader0607
GROUP BY v2.leader0607,
fmg.leader0607description,
fmg.folio_format_type,
fmg.folio_format_type_adc_groups, 
fmg.folio_format_type_acrl_nces_groups

ORDER BY fmg.folio_format_type_adc_groups
