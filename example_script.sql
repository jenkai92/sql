/*
    Daily Company Example Performance Aggregated at Creative Level (using plain event names)
*/


        SELECT
            TO_CHAR(date(date_action),'YYYY-MM-DD') AS date
            ,campaign_name AS campaign_name
            ,dim_campaign.campaign_id AS id
            ,f.creative_id
            ,f.country_code_a2 AS country
            ,dim_creative.creative_name
            ,dim_creative.creative_format
            ,dim_creative.creative_type
            ,platform AS os
            ,DATE_PART('month', date_action) AS "month"
            ,TO_CHAR(SUM(number_click) * client_cost, '999D99') AS "cost gross €"
            ,TO_CHAR(client_cost, '0D999') AS cpc
            ,SUM(number_impression) AS impressions
            ,SUM(number_click) AS clicks
            ,SUM(number_reopen) AS reopenings
            ,COALESCE(mailcontact_kauf,0) AS mailcontact_kauf
            ,COALESCE(mailcontact_miete,0) AS mailcontact_miete
            ,COALESCE(phonecontact_miete,0) AS phonecontact_miete
            ,COALESCE (phonecontact_kauf,0) AS phonecontact_kauf
        FROM fact_campaign_insights f
        LEFT OUTER JOIN dim_campaign
            ON f.campaign_id = dim_campaign.campaign_id
        LEFT OUTER JOIN dim_creative
            ON f.creative_id = dim_creative.creative_id
        LEFT OUTER JOIN dim_bundle_identifier
            ON f.bundle_id = dim_bundle_identifier.bundle_id
        LEFT OUTER JOIN (
            SELECT 
                CASE WHEN e13_bundle_identifier = 'example_client'
                    THEN 337
                    ELSE 370
                END AS bundle
                ,partition_date AS "date"
                ,e13_campaign_id AS campaign
                ,e13_creative_format_id AS creative
                ,SUM(
                    CASE WHEN e15_custom_action IN ('mailcontact_miete')
                              THEN 1
                        ELSE 0
                    END) AS mailcontact_miete
                ,SUM(
                    CASE WHEN e15_custom_action IN ('phonecontact_miete')
                        THEN 1
                        ELSE 0
                    END) AS phonecontact_miete
                ,SUM(
                    CASE WHEN e15_custom_action IN ('phonecontact_kauf')
                        THEN 1
                        ELSE 0
                    END) AS phonecontact_kauf
                ,SUM(
                    CASE WHEN e15_custom_action IN ('mailcontact_kauf')
                        THEN 1
                        ELSE 0
                    END) AS mailcontact_kauf
                FROM marketed_custom_action
                WHERE partition_date >= DATE_TRUNC('month', DATEADD(MONTH, -1, current_date))
                    AND e13_bundle_identifier IN ('example_client', 'example_client_android')
                GROUP BY e13_bundle_identifier
                        ,partition_date
                        ,e13_campaign_id
                        ,e13_creative_format_id
        ) AS actions 
            ON f.bundle_id = actions.bundle
                AND f.date_action = actions.date
                AND f.campaign_id = actions.campaign
                AND f.creative_id = actions.creative
  
        LEFT OUTER JOIN dim_client_cost 
            ON f.campaign_id = dim_client_cost.campaign_id 
                AND f.date_action BETWEEN dim_client_cost.start_date AND DATEADD(DAY, -1, dim_client_cost.end_date)

        WHERE f.bundle_id IN (337, 370)
            AND date_action >= DATE_TRUNC('month', DATEADD(MONTH, -1, current_date))
            AND date_action <= DATEADD(DAY, -1, current_date)
            AND f.channel = 'DSP'

        GROUP BY campaign_name
                ,dim_campaign.campaign_id
                ,f.creative_id
                ,f.country_code_a2
                ,dim_creative.creative_name
                ,dim_creative.creative_format
                ,dim_creative.creative_type
                ,date_action
                ,platform
                ,client_cost
                ,mailcontact_miete
                ,phonecontact_miete
                ,phonecontact_kauf
                ,mailcontact_kauf
        ORDER BY date_action
                ,campaign_name

