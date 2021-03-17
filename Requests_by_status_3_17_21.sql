WITH parameters AS (
    SELECT
        /* Choose a start and end date for the requests period */
        '2000-01-01'::date AS start_date,
        '2022-01-01'::date AS end_date,
        /*Choose as many request types as needed below*/
        ''::VARCHAR AS request_status_filter1,-- Closed - Filled
        'Open - In transit'::VARCHAR AS request_status_filter2, --Open - In transit
		'Open - Not yet filled'::VARCHAR AS request_status_filter3, --Open - Not yet filled
		''::VARCHAR AS request_status_filter4 --Any other request status
)
    --MAIN QUERY
    SELECT
        (
            SELECT
                start_date::varchar
            FROM
                parameters) || ' to '::varchar || (
        SELECT
            end_date::varchar
        FROM
            parameters) AS date_range,
    cr.id AS request_id,
    cr.request_date,
    cr.request_type,
    cr.status AS request_status,
    cr.pickup_service_point_id,
    isp.discovery_display_name AS pickup_service_point_name,
    il.name AS library_name,
    cr.item_id,
    cr.fulfilment_preference,
    ie.call_number,
    ie.barcode,
    ie.material_type_name,
    ie.permanent_location_name,
    ie.effective_location_name,
    he.holdings_id,
    he.shelving_title,
    cr.requester_id,
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
LEFT JOIN public.inventory_locations as il
	ON isp.id=il.primary_service_point
WHERE 
status IN (SELECT request_status_filter1 FROM parameters) 
OR status IN (SELECT request_status_filter2 FROM parameters)
OR status IN (SELECT request_status_filter3 FROM parameters)
OR status IN (SELECT request_status_filter4 FROM parameters)
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
	