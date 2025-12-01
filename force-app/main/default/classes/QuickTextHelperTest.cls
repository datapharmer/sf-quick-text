@IsTest
public class QuickTextHelperTest {
    
    @IsTest
    static void testGetQuickText() {
        // Setup QuickText
        QuickText qt = new QuickText(
            Name = 'Test Message', 
            Message = 'Hello World', 
            Channel = 'Email'
        );
        insert qt;

        Test.startTest();
        List<QuickText> results = QuickTextHelper.getQuickText('Email');
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return QuickText records');
        System.assertEquals('Test Message', results[0].Name);
    }

    @IsTest
    static void testResolveQuickText() {
        // Setup Account for merge fields
        Account a = new Account(Name = 'Acme Corp');
        insert a;

        String raw = 'Welcome to {!Account.Name}';
        
        Test.startTest();
        String resolved = QuickTextHelper.resolveQuickText(raw, a.Id);
        Test.stopTest();

        System.assertEquals('Welcome to Acme Corp', resolved);
    }
}
