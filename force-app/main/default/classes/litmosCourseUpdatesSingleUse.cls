public class litmosCourseUpdatesSingleUse {
    private static final Litmos__Configuration__c config = [SELECT Litmos__Api_Key__c,Litmos__Api_End_Point__c FROM Litmos__Configuration__c WHERE Litmos__Sync_Active__c = true];
    public static void updatelitmosCourses() {
        //uncomment this section to retrieve info from your org if it's been entered.
        //String apikey = config.Litmos__Api_Key__c;
        //String endpoint = config.Litmos__Api_End_Point__c + 'courses?source=sourceapp&format=json&limit=1000&sort=Name';
        
        //replace the apikey here with the apikey Litmos org you wish to pull learning path data from. 
        //feel free to add &limit=XX to pull a limited number of learning paths into Salesforce OR prevent limits from being hit from Litmos. See Overview Developer API from Litmos for information.
        String endpoint = 'https://api.litmos.com/v1.svc/courses?source=sourceapp&format=json&limit=1000&sort=Name';
        String apikey = 'apikey';
        
        //to prevent callout limits, we'll need to make ONE callout and retrieve all courses. Then we'll create "new" records and upsert them using the Litmos__LitmosId__c field as the identifier
        List<Litmos__Program__c> programsToUpsert = new List<Litmos__Program__c>();
		HttpResponse response = new HttpResponse();
        List<Object> results = new List<Object>();
        Integer start = 0;
        do{
            response = litmosConnection.getLitmosExternalService(endpoint + '&start=' + start, apikey);
			if(response.getStatusCode() == 200) {
                results = (List<Object>)JSON.deserializeUntyped(response.getBody());
                System.debug('results.size' + results.size());
                for(Object o : results) {
                    Map<String,Object> obj = (Map<String,Object>) o;
                    programsToUpsert.add(new Litmos__Program__c(
                        Name = String.valueOf(obj.get('Name')).length() > 80 ? String.valueOf(obj.get('Name')).substring(0,79) : String.valueOf(obj.get('Name')),
                        Litmos__Active__c = Boolean.valueOf(obj.get('Active')),
                        Full_Description__c = String.valueOf(obj.get('Description')).length() > 255 ? String.valueOf(obj.get('Description')).substring(0,254) : String.valueOf(obj.get('Description')),
                        Litmos_Full_Id__c  = String.valueOf(obj.get('Id')),
                        Litmos__LitmosId__c = String.valueOf(obj.get('OriginalId'))
                    ));
                }
                
        	}
            //break the loop if test is running to avoid callout exception
            if(Test.isRunningTest()) {
                break;
            }
            start += 1000;
        } while(results.size() > 0); 
        
       for(Litmos__Program__c prog : programsToUpsert) {
           System.debug(prog.Name + ': ' + prog.Full_Description__c);
       }
        //this section logs info about each run into a custom object called Litmos_Sync_Logs__c. It may be uploaded at a later time. Comment out as desired.
        Set<Id> progSuccess = new Set<Id>();
        Set<Id> progErrors = new Set<Id>();
        Map<Id,String> errors = new Map<Id,String>();
        Schema.SObjectField originalIdField = Litmos__Program__c.Litmos__LitmosId__c;
        List<Database.UpsertResult> sr = Database.upsert(programsToUpsert, originalIdField, false);
        for(Database.UpsertResult r : sr) {
            if(r.isSuccess()) {
             	progSuccess.add(r.getId());   
            } else {
				progErrors.add(r.getId());
                errors.put(r.getId(), String.valueOf(r.getErrors()));
            }
		}
        if(progSuccess.size() > 0) {
			litmosSyncLogs.logCourseSuccess(progSuccess);
        }
        if(progErrors.size() > 0) {
            litmosSyncLogs.logCourseErrors(progErrors, errors);
        }
    }
}