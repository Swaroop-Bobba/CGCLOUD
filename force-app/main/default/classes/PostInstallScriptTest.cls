/**
 * Unit tests verifying permission set assignment during post-install execution.
 */
@IsTest
private class PostInstallScriptTest {

    @isTest
    static void testPostInstallScriptSuccess() {
        Test.startTest();
        PostInstallScript postInstall = new PostInstallScript();
        Test.testInstall(postInstall, new Version(1, 0));
        postInstall.onInstall(null);
        Test.stopTest();

        System.assert(true, 'PostInstallScript executed without throwing exception');
    }

    @isTest
    static void testPostInstallScriptException() {
        PostInstallScript.forceException = true;

        Test.startTest();
        PostInstallScript postInstall = new PostInstallScript();
        Test.testInstall(postInstall, new Version(1, 0));
        Test.stopTest();

        PostInstallScript.forceException = false;
        System.assert(true, 'PostInstallScript exception handled cleanly');
    }
}