WITH parameters AS (
	SELECT
/*Select a date range when the previously lost items were checked-in*/
'2021-01-01'::DATE as start_date,
'2022-01-01'::DATE as end_date,
/*Select a date range for when the item was declared lost*/
'2020-01-01'::DATE as lost_start_date,
'2022-01-01'::DATE as lost_end_date
),
lost_items AS (
	SELECT 
occurred_date_time as check_in_date_time,
item_id,
service_point_id,
item_status_prior_to_check_in
FROM public.circulation_check_ins 
	WHERE 
		item_status_prior_to_check_in='Declared lost'
			OR 
				item_status_prior_to_check_in= 'Aged to lost'
),
ranked_loans AS (
    SELECT
        item_id,
        id AS loan_id,
        declared_lost_date,
        item_status,
        rank() OVER (PARTITION BY item_id ORDER BY declared_lost_date DESC) AS lost_date_ranked
FROM
    public.circulation_loans
    WHERE
        item_status = 'Lost and paid'
            AND declared_lost_date::DATE >= (
                SELECT
                    lost_start_date
                FROM
                    parameters)
                AND declared_lost_date::DATE < (
                    SELECT
                        lost_end_date
                    FROM
                        parameters)
),
/* This should be pulling the latest loan for each item. Will want to test again with real data. */
latest_loan AS (
    SELECT
        item_id,
        loan_id,
        item_status,
        declared_lost_date
    FROM
        ranked_loans
    WHERE
        ranked_loans.lost_date_ranked = 1
)
/*MAIN QUERY*/
SELECT
        (
            SELECT
                start_date::VARCHAR
            FROM
                parameters) || ' to '::VARCHAR || (
            SELECT
                end_date::VARCHAR
            FROM
                parameters) AS lost_items_returned_date_range,
        cc.occurred_date_time as lost_item_returned_date,
        cl.declared_lost_date,
        cc.item_status_prior_to_check_in,
        li.item_id,
        li.loan_id,
        li.user_id, 
        ug.group_name AS patron_group_name,
        ug.user_first_name,
        ug.user_last_name,
        ug.user_middle_name,
        ug.user_email,
        he.shelving_title, 
        it.barcode AS item_barcode, 
        it.call_number,
        li.item_status AS loan_status_action
      FROM
        folio_reporting.loans_items AS li
        INNER JOIN latest_loan AS ll ON li.loan_id = ll.loan_id        
        LEFT JOIN folio_reporting.item_ext AS it ON li.item_id = it.item_id
        LEFT JOIN public.circulation_check_ins AS cc on li.item_id=cc.item_id
        LEFT JOIN public.circulation_loans AS cl ON li.loan_id=cl.id 
        LEFT JOIN folio_reporting.holdings_ext AS he ON li.holdings_record_id = he.holdings_id
		LEFT JOIN folio_reporting.users_groups AS ug ON li.user_id=ug.user_id
WHERE 
	cc.occurred_date_time >= (SELECT start_date FROM parameters)
    AND cc.occurred_date_time < (SELECT end_date FROM parameters)
    ;
