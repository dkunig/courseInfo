@isTest
public class litmosCourseUpdatesSingleUseTEST {
	@testSetup
    static void setup() {
        insert new Litmos__Configuration__c(
        	Litmos__Api_Key__c='abcde',
            Litmos__Api_End_Point__c = 'https://api.litmos.com/v1.svc/',
            Litmos__Sync_Active__c = true
        );
        
        insert new Litmos__Program__c(
        	Name = 'My Test Course',
            Litmos__LitmosId__c = '123456',
            Litmos__Active__c = true
        );
    }
    @isTest
    static void testCourseUpdates() {
        Litmos__Configuration__c config = [SELECT Litmos__Api_End_Point__c FROM Litmos__Configuration__c];
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('litmosCourseFullData');
       	
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
        	litmosCourseUpdatesSingleUse.updatelitmosCourses();  
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Litmos__Program__c WHERE Litmos__Active__c = false AND Litmos_Full_Id__c = 'ab-cd_efg1']);
        for(Litmos__Program__c prog : [SELECT Name,Litmos__Description__c FROM Litmos__Program__c]) {
            System.debug('prog: ' + prog.Name + prog.Litmos__Description__c);
        }
        System.assertEquals('Here is a test description', [SELECT Full_Description__c FROM Litmos__Program__c].Full_Description__c);
    }
}