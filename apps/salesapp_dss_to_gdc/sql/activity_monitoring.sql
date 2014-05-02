SELECT
    a.Id AS activity_id,
    TO_CHAR(a.ActivityDate, 'DD/MM/YYYY') AS activity_date,
    TO_CHAR(o.CreatedDate, 'DD/MM/YYYY') AS opp_created_date,
    TO_CHAR(o.CloseDate, 'DD/MM/YYYY') as opp_close_date,
    a.Id AS activity_id_id,
    a.AccountId AS account_id_id,
    a.WhatId AS opportunity_id_id,
    a.OwnerId AS activity_owner_id_id,
    o.OwnerId AS opp_owner_id_id,
    pe.Product2Id AS product_id_id,
    o.StageName AS stage_id_id

FROM (SELECT ActivityDate, Id, AccountId, WhatId, OwnerId FROM dss_Task  WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_Task)
    UNION
    SELECT ActivityDate, Id, AccountId, WhatId, OwnerId FROM dss_Event  WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_Event)
    ) a
    LEFT OUTER JOIN (SELECT * FROM dss_Opportunity WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_Opportunity))  o
ON a.WhatId = o.Id
    LEFT OUTER JOIN (SELECT * FROM dss_OpportunityLineItem WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_PricebookEntry)) oli
ON o.Id = oli.OpportunityId
    LEFT OUTER JOIN (SELECT * FROM dss_PricebookEntry WHERE  _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM dss_PricebookEntry)) pe
ON oli.PricebookEntryId = pe.Id
