Schedule Execution Brick
==================
This brick can be used for starting multiple schedules in various projects. Main use-case is, that you want to start ETLs in PBG projects after the main ETL loading data has finished


## Deployment

The deployment on Ruby Executor infrastructure can be done manually or by the Goodot tool.

### Manual deployment

1. Pack the app store folder apps/schedule_execution_brick. The zip should contain only files, not the directory itself.
2. Deploy the ZIP on the gooddata platform by Data Admin Console [link] (https://secure.gooddata.com/admin/disc/)
3. Create the schedule and put mandatory configuration options to schedule parameters. Mandatory parameters are specified in info.json file.
4. Run the schedule

## Configuration

 * LIST_OF_MODES (mandatory) - This parameter contain pipe (|) separated list of modes, which should be search in schedules. If the schedule contain the MODE parameter which value is contained in LIST_OF_MODES, that schedule will be started. 
 * WORK_DONE_IDENTIFICATOR (mandatory) - name of the project metadata, which tell that some work was done and the tool need to start the schedules. More detailed explanation in Examples.IN case that value of this parameter is IGNORE, the schedules will be started in each run of the brick 
 * NUMBER_OF_SCHEDULES_IN_BATCH - number of schedule which will be run in one batch. This can be used for starting schedules in multiple waves.
 * DELAY_BETWEEN_BATCHES - number of seconds between batch executions
 * GDC_USERNAME - the user, under whom the brick will look for schedules
 * GDC_PASSWORD - the user password

## Examples

### Use-case 1

This brick can coexist with the ASD_INTEGRATOR_BRICK. Each time ads integrator processed data (this is not necessarily in each run) it will change the metadata key, specified by parameter NOTIFICATION_METADATA on TRUE. For example
 when you put to the NOTIFICATION_METADATA the value WORK_DONE, the ADS Integrator will create project metadata key WORK_DONE and value of this metadata will be true.
 
 For this to work with schedule execution brick, you need to set value WORK_DONE_IDENTIFICATOR to WORK_DONE. In this case the brick will check the metadata and in case that value there is true, it will start schedules and set the value to false. 
 If the value is false, the brick finish without any action.
 
 What is also needed is to edit the schedules which you want to start, to have the MODE parameter. For example if you have 100 schedules which you want to start, you need to edit them and put there MODE parameter for example with value MY_PROJECTS. Then
 you need to put the value MY_PROJECTS to LIST_OF_MODES brick parameter. With this settings the the schedules will be correctly started.
   
 In case that you want to split the schedules to multiple execution group, you can use the NUMBER_OF_SCHEDULES_IN_BATCH and DELAY_BETWEEN_BATCHES. For example if you want to split your 100 schedules in 5 groups and make delay between them 5minutes, you will
   put value 20 in NUMBER_OF_SCHEDULES_IN_BATCH parameter and value 300 to DELAY_BETWEEN_BATCHES.
    
### Use-case 2
    
If you want to start schedules everytime the brick is executed, you can put value IGNORE to WORK_DONE_IDENTIFICATOR. This setting will force the schedule execution everytime the brick is executed.    


