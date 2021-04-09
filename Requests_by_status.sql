/* Change the lines below to adjust the date, request status */
WITH parameters AS (
    SELECT
        /* Choose a start and end date for the requests period */
        '2000-01-01'::date AS start_date,
        '2022-01-01'::date AS end_date,
        'Closed - Filled'::VARCHAR AS request_status_filter1, --  'Open - Not yet filled', 'Open - Awaiting pickup','Open - In transit', ''Open, Awaiting delivery', 'Closed - Filled', 'Closed - Cancelled', 'Closed - Unfilled', 'Closed - Pickup expired'
		'Closed - Cancelled'::VARCHAR AS request_status_filter2, -- other request status to also include
		''::VARCHAR AS request_status_filter3, -- other request status to also include
		''::VARCHAR AS request_status_filter4 -- other request status to also include
         )
SELECT
        (SELECT start_date::varchar 
        FROM parameters) || ' to '::varchar || (
        SELECT end_date::varchar
        FROM parameters) AS date_range,
     cr.id,
    cr.request_date,
    cr.request_type,
    cr.requester_id,
    cr.status,
 --   cr.pickup_service_point_id,
 --   spe.service_point_discovery_display_name as pickup_service_point_name,
 --   spe.location_discovery_display_name as pickup_location_name,
    spe.library_name as pickup_library_name,
    cr.item_id,
    cr.fulfilment_preference,
    ie.item_id,
    he.call_number,
    ie.barcode,
    ie.material_type_name,
    ie.holdings_record_id,
    ie.permanent_location_name,
    ie.effective_location_name,
    he.holdings_id,
    he.shelving_title,
    ug.user_id,
    ug.group_name,
    ug.user_last_name,
    ug.user_first_name,
    ug.user_middle_name,
    ug.user_email
   FROM
    public.circulation_requests AS cr
LEFT JOIN folio_reporting.item_ext AS ie
	ON cr.item_id = ie.item_id
LEFT JOIN folio_reporting.holdings_ext AS he
	ON ie.holdings_record_id=he.holdings_id
LEFT JOIN folio_reporting.users_groups AS ug
	ON  cr.requester_id = ug.user_id
LEFT JOIN public.inventory_service_points as isp
	ON cr.pickup_service_point_id = isp.id	
left join local.service_points_ext as spe
	on cr.pickup_service_point_id =spe.service_point_id
where 
--How do I allow for multiple request_status_filter values?
(status  = (select request_status_filter1 from parameters)
or status =  (select request_status_filter2 from parameters)
or status =  (select request_status_filter3 from parameters)
or status =  (select request_status_filter4 from parameters)
 )
		AND request_date::DATE >= (
            SELECT
                start_date
           FROM
                parameters)
    	AND request_date::DATE < (
               SELECT
                 end_date
                    FROM
                        parameters)
                       ;
