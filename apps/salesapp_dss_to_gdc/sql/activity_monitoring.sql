SELECT
    a.ActivityDate AS activity_date,
    o.CreatedDate AS opp_created_date,
    o.CloseDate as opp_close_date,
    a.Id AS activity_id_id,
    a.AccountId AS account_id_id,
    a.WhatId AS opportunity_id_id,
    a.OwnerId AS activity_owner_id_id,
    o.OwnerId AS opp_owner_id_id,
    pe.Product2Id AS product_id_id,
    o.StageName AS stage_id_id,
    o.Pricebook2Id

FROM (SELECT ActivityDate, Id, AccountId, WhatId, OwnerId FROM dss_Task  WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_Task)
    UNION
    SELECT ActivityDate, Id, AccountId, WhatId, OwnerId FROM dss_Event  WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_Event)
    ) a
    INNER JOIN dss_Opportunity o
ON a.WhatId = o.Id
    INNER JOIN dss_OpportunityLineItem oli
ON o.Id = oli.OpportunityId
    INNER JOIN dss_PricebookEntry pe
ON oli.PricebookEntryId = pe.Id
WHERE o._INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_Opportunity)
AND pe._INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_PricebookEntry)
AND oli._INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_OpportunityLineItem)