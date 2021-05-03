--REP-152
/*FILTERS: date range, location */

/* Change the lines below to adjust the date and location filters */
WITH parameters AS (
    SELECT
        '2000-01-01'::DATE AS start_date,
        '2022-01-01'::DATE AS end_date,
              ---- Fill out one location or service point filter, leave others blank ----
        ''::varchar AS item_permanent_location_filter, -- 'Main Library'
''::varchar AS item_temporary_location_filter, -- 'Annex'
''::varchar AS holdings_permanent_location_filter, -- 'Main Library'
''::varchar AS holdings_temporary_location_filter, -- 'Main Library'
''::varchar AS effective_location_filter, -- 'Main Library'
),
---------- SUB-QUERIES/TABLES ----------
ranked_loans AS (
    SELECT
        item_id,
        id AS loan_id,
        return_date AS loan_return_date,
        item_status,
        rank() OVER (PARTITION BY item_id ORDER BY return_date DESC) AS return_date_ranked
FROM
    public.circulation_loans
    ),
/* This should be pulling the latest loan for each item. Will want to test again with real data. */
latest_loan AS (
    SELECT
        item_id,
        loan_id,
        item_status,
        loan_return_date 
    FROM
        ranked_loans
    WHERE
        ranked_loans.return_date_ranked = 1
),
item_notes_list AS (
    SELECT
        item_id,
        string_agg(DISTINCT note, '|'::text) AS notes_list
    FROM
        folio_reporting.item_notes
    GROUP BY
        item_id
),
publication_dates_list AS (
    SELECT
        instance_id,
        string_agg(DISTINCT date_of_publication, '|'::text) AS publication_dates_list
    FROM
        folio_reporting.instance_publication
    GROUP BY
        instance_id)
    ---------- MAIN QUERY ----------
    SELECT
        (
            SELECT
                start_date::VARCHAR
            FROM
                parameters) || ' to '::VARCHAR || (
            SELECT
                end_date::VARCHAR
            FROM
                parameters) AS date_range,
        it.item_id,
        ie.title,
        he.shelving_title,
        it.status_name AS item_status,
        it.status_date AS item_status_date,
        ll.loan_return_date AS last_loan_return_date,
        li.checkout_service_point_name,
        li.checkin_service_point_name,
        it.barcode,
        it.call_number,
        it.enumeration,
        it.chronology,
        it.copy_number,
        it.volume,
        he.permanent_location_name AS holdings_permanent_location_name,
        he.temporary_location_name AS holdings_temporary_location_name,
        li.current_item_permanent_location_name,
        li.current_item_temporary_location_name,
        li.current_item_effective_location_name,
        ie.cataloged_date,
        pd.publication_dates_list,
        nl.notes_list,
        li.material_type_name,
        lc.num_loans,
        lc.num_renewals
    FROM
        folio_reporting.item_ext as it
    	left join folio_reporting.loans_items AS li on it.item_id=li.item_id 
        INNER JOIN latest_loan AS ll ON li.loan_id = ll.loan_id
        LEFT JOIN item_notes_list AS nl ON li.item_id = nl.item_id
        LEFT JOIN folio_reporting.holdings_ext AS he ON li.holdings_record_id = he.holdings_id
        LEFT JOIN folio_reporting.instance_ext AS ie ON he.instance_id = ie.instance_id
        LEFT JOIN folio_reporting.instance_publication AS ip ON ie.instance_id = ip.instance_id
        LEFT JOIN publication_dates_list AS pd ON ie.instance_id = pd.instance_id
        LEFT JOIN folio_reporting.loans_renewal_count AS lc ON li.item_id = lc.item_id
    WHERE it.status_name = 'Checked out'
        AND it.status_date >= (SELECT start_date FROM parameters)
        AND it.status_date < (SELECT end_date FROM parameters)
        AND   (li.current_item_permanent_location_name = (
            SELECT
                item_permanent_location_filter
            FROM
                parameters)
            OR (
                SELECT
                    item_permanent_location_filter
                FROM
                    parameters) = '')
        AND (li.current_item_temporary_location_name = (
                SELECT
                    item_temporary_location_filter
                FROM
                    parameters)
                OR (
                    SELECT
                        item_temporary_location_filter
                    FROM
                        parameters) = '')
            AND (he.permanent_location_name = (
                    SELECT
                        holdings_permanent_location_filter
                    FROM
                        parameters)
                    OR (
                        SELECT
                            holdings_permanent_location_filter
                        FROM
                            parameters) = '')
                AND (he.temporary_location_name = (
                        SELECT
                            holdings_temporary_location_filter
                        FROM
                            parameters)
                        OR (
                            SELECT
                                holdings_temporary_location_filter
                            FROM
                                parameters) = '')
                    AND (current_item_effective_location_name = (
                            SELECT
                                effective_location_filter
                            FROM
                                parameters)
                            OR (
                                SELECT
                                    effective_location_filter
                                FROM
                                    parameters) = '')
                      ;
