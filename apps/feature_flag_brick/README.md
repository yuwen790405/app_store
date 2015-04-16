Feature Flag Brick
===========
This brick provides simple way to change the feature flags for specific project

#### Deployment parameters

	 	"features_flag":
            {
              "dashboardSchedule": false,
              "dashboardScheduleRecipients": false
            }


#### Goodot deploy description

    {
      "processes" : [
        {
          "deployment_type": "app_store",
          "app_id": "feature_flag_brick",
          "process_type": "ruby",
          "name" : "Feature Flag",
          "schedules" : [
            {
              "name" : "trigger",
              "when" : "0 10 * * *",
              "params": {
                    "features_flag":
                        {
                          "dashboardSchedule": false,
                          "dashboardScheduleRecipients": false
                        }
              },
              "hidden_params" : {
              }
            }
          ]
        }
      ]
    }



