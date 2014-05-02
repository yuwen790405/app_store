-- I'm taking the first date I found out about the opportunity as the date it entered the first stage I know of
-- velocity = date entered the stage - date when it was created
-- duration = last date it was in the stage - date entered stage
SELECT
    DATEDIFF(day, date_entered_stage, last_date_in_stage) AS stage_duration,
    DATEDIFF(day, o.CreatedDate, date_entered_stage) AS stage_velocity,
    o.AccountId AS account_id_id,
     o.OwnerId AS opp_owner_id_id,
     o.Id AS opportunity_id_id,
    pe.Product2Id AS product_id_id,
    o.StageName AS stage_id_id,
        TO_CHAR(o.CreatedDate, 'DD/MM/YYYY') as created_date,
        TO_CHAR(o.CloseDate, 'DD/MM/YYYY') as close_date

FROM (SELECT DISTINCT
    Id, Name, AccountId, OwnerId, CreatedDate, CloseDate,
    StageName,
    FIRST_VALUE(_INSERTED_AT) OVER (PARTITION BY Id, StageName ORDER BY _INSERTED_AT) AS date_entered_stage,
    FIRST_VALUE(_INSERTED_AT) OVER (PARTITION BY Id, StageName  ORDER BY _INSERTED_AT DESC) AS last_date_in_stage
    FROM  dss_Opportunity) o
    LEFT OUTER JOIN (SELECT * FROM dss_OpportunityLineItem WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_PricebookEntry)) oli
ON o.Id = oli.OpportunityId
    LEFT OUTER JOIN (SELECT * FROM dss_PricebookEntry WHERE  _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_PricebookEntry)) pe
ON oli.PricebookEntryId = pe.Id

-- TODO: terminalni stage nemaj mit nic

