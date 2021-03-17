/*trying to create a table with library id and all associated service point ids*/

WITH LSP AS (
SELECT
    library_id,
        json_extract_path_text(il.data, 'servicePointIds') AS servicePointIds
    FROM
    public.inventory_locations AS il
   )
     SELECT
  	library_id,
 	STRING_AGG(distinct lsp.servicePointIds, '|'::TEXT) AS service_point_ID
 FROM LSP
 GROUP BY library_id
   ;