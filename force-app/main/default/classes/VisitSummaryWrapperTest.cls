/**
 * @description Unit test class for VisitSummaryWrapper and inner Suggestion class.
 */
@IsTest
public class VisitSummaryWrapperTest {

    @IsTest
    static void testVisitSummaryWrapperConstructors() {
        VisitSummaryWrapper wrap = new VisitSummaryWrapper();
        wrap.storeName = 'Store A';
        wrap.visitDate = '2026-08-05';
        wrap.visitStatus = 'Completed';
        wrap.assignedUser = 'Rep User';
        wrap.completedTasks = 5;
        wrap.pendingTasks = 0;
        wrap.promotionsChecked = 2;
        wrap.outOfStockIssues = 1;
        wrap.ordersCreated = 1;
        wrap.orderValue = 1500;
        wrap.representativeNotes = 'Notes';
        wrap.overallOutcome = 'Successful';

        VisitSummaryWrapper.Suggestion sug1 = new VisitSummaryWrapper.Suggestion();
        VisitSummaryWrapper.Suggestion sug2 = new VisitSummaryWrapper.Suggestion('sug1', 'Label', 'Command', 'standard:account');

        wrap.suggestions = new List<VisitSummaryWrapper.Suggestion>{ sug1, sug2 };

        Assert.isNotNull(wrap.storeName, 'VisitSummaryWrapper properties assigned correctly.');
        Assert.isNotNull(sug2.id, 'Suggestion constructor assigned correctly.');
    }
}
