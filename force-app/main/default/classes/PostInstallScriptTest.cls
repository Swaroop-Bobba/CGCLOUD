@isTest
private class PostInstallScriptTest {

    @isTest
    static void testPostInstallScript() {
        Test.startTest();
        PostInstallScript postInstall = new PostInstallScript();
        Test.testInstall(postInstall, new Version(1, 0));
        Test.stopTest();
        
        System.assert(true, 'PostInstallScript executed without throwing exception');
    }
}
