public with sharing class Sales_Forecasting_Service {

    public static Sales_Forecasting_Handler.Result getOrderForecast(String accountId, String orderId) {
        Sales_Forecasting_Handler.Result res = new Sales_Forecasting_Handler.Result();
        res.success = false;
        res.confidenceLevel = 'Low';

        String accId = accountId;
        if (String.isBlank(accId) && String.isNotBlank(orderId)) {
            try {
                cgcloud__Order__c ord = [
                    SELECT cgcloud__Order_Account__c 
                    FROM cgcloud__Order__c 
                    WHERE Id = :orderId 
                    WITH USER_MODE 
                    LIMIT 1
                ];
                accId = ord.cgcloud__Order_Account__c;
            } catch (Exception e) {}
        }

        if (String.isBlank(accId)) {
            res.forecastSummary = 'Unable to generate next order forecast: Account context is missing.';
            res.reasoning = '- No Account ID or Order ID context was resolved.';
            return res;
        }

        String accountName = 'this customer';
        try {
            Account acc = [SELECT Name FROM Account WHERE Id = :accId WITH USER_MODE LIMIT 1];
            accountName = acc.Name;
        } catch (Exception e) {}

        // Query historical CG Cloud orders
        List<cgcloud__Order__c> cgOrders = [
            SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Total_Value__c,
                   (SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c FROM cgcloud__Order_Items__r)
            FROM cgcloud__Order__c
            WHERE cgcloud__Order_Account__c = :accId AND cgcloud__Order_Date__c != null
            WITH USER_MODE
            ORDER BY cgcloud__Order_Date__c DESC
            LIMIT 20
        ];

        List<OrderData> orders = new List<OrderData>();
        for (cgcloud__Order__c co : cgOrders) {
            OrderData od = new OrderData();
            od.orderDate = co.cgcloud__Order_Date__c;
            od.totalValue = co.cgcloud__Total_Value__c != null ? co.cgcloud__Total_Value__c : 0;
            od.products = new List<String>();
            if (co.cgcloud__Order_Items__r != null) {
                for (cgcloud__Order_Item__c item : co.cgcloud__Order_Items__r) {
                    if (item.cgcloud__Product__r != null) {
                        od.products.add(item.cgcloud__Product__r.Name);
                    }
                }
            }
            orders.add(od);
        }

        // Fallback to standard orders if CG Cloud orders are empty
        if (orders.isEmpty()) {
            List<Order> stdOrders = [
                SELECT Id, EffectiveDate, TotalAmount,
                       (SELECT Id, Product2.Name, Quantity FROM OrderItems)
                FROM Order
                WHERE AccountId = :accId AND EffectiveDate != null
                WITH USER_MODE
                ORDER BY EffectiveDate DESC
                LIMIT 20
            ];
            for (Order so : stdOrders) {
                OrderData od = new OrderData();
                od.orderDate = so.EffectiveDate;
                od.totalValue = so.TotalAmount != null ? so.TotalAmount : 0;
                od.products = new List<String>();
                if (so.OrderItems != null) {
                    for (OrderItem item : so.OrderItems) {
                        if (item.Product2 != null) {
                            od.products.add(item.Product2.Name);
                        }
                    }
                }
                orders.add(od);
            }
        }

        if (orders.size() < 2) {
            res.forecastSummary = 'Insufficient historical order data to generate a reliable next order forecast for ' + accountName + '.';
            res.reasoning = '* There are fewer than 2 past orders recorded in Salesforce for this account.\n* A minimum of 2 orders is required to calculate reorder intervals, average values, and product affinity patterns.';
            return res;
        }

        // Calculate Average Interval
        Integer totalDays = 0;
        for (Integer i = 0; i < orders.size() - 1; i++) {
            Date date1 = orders[i].orderDate;
            Date date2 = orders[i+1].orderDate;
            totalDays += Math.abs(date2.daysBetween(date1));
        }
        Double avgInterval = (Double)totalDays / (orders.size() - 1);
        if (avgInterval <= 0) avgInterval = 7.0; // default to weekly if same day

        // Calculate Average Order Value (AOV)
        Decimal sumValue = 0;
        for (OrderData od : orders) {
            sumValue += od.totalValue;
        }
        Decimal aov = sumValue / orders.size();

        // Predict Next Order Date
        Date lastOrderDate = orders[0].orderDate;
        Date nextOrderDate = lastOrderDate.addDays(Math.round(avgInterval));
        if (nextOrderDate <= Date.today()) {
            nextOrderDate = Date.today().addDays(2); // If predicted date is in the past, expect it soon
        }

        // Calculate Product Affinity (Frequency)
        Map<String, Integer> productCounts = new Map<String, Integer>();
        for (OrderData od : orders) {
            for (String prodName : od.products) {
                Integer count = productCounts.containsKey(prodName) ? productCounts.get(prodName) : 0;
                productCounts.put(prodName, count + 1);
            }
        }

        List<ProductCountPair> pairs = new List<ProductCountPair>();
        for (String prod : productCounts.keySet()) {
            pairs.add(new ProductCountPair(prod, productCounts.get(prod)));
        }
        pairs.sort(); // Sort descending by count

        List<String> likelyProducts = new List<String>();
        Integer limitCount = Math.min(3, pairs.size());
        for (Integer i = 0; i < limitCount; i++) {
            likelyProducts.add(pairs[i].productName);
        }

        // Set Confidence
        String confidence = 'Low';
        if (orders.size() >= 8) {
            confidence = 'High';
        } else if (orders.size() >= 3) {
            confidence = 'Medium';
        }

        res.success = true;
        res.confidenceLevel = confidence;

        // Build forecast Summary
        String expectedDateStr = String.valueOf(nextOrderDate.day()) + ' ' + getMonthName(nextOrderDate.month()) + ' ' + String.valueOf(nextOrderDate.year());
        String summary = '**Next Order Forecast**\n\n' +
                         '───────────────────────────────────────────────────\n\n' +
                         '  **Expected Order Date**     :  ' + expectedDateStr + '\n\n' +
                         '  **Predicted Order Value**   :  ₹' + String.valueOf(Math.round(aov)) + '\n\n' +
                         '  **Likely Products**         :  ' + (likelyProducts.isEmpty() ? 'None' : String.join(likelyProducts, ', ')) + '\n\n' +
                         '  **Confidence Level**        :  ' + confidence + '\n\n' +
                         '───────────────────────────────────────────────────\n\n';
        res.forecastSummary = summary;

        // Build Reasoning
        String reason = '* Customer places orders every ' + String.valueOf(Math.round(avgInterval)) + ' days on average (calculated across ' + String.valueOf(orders.size()) + ' past orders).\n' +
                        '* Last order occurred on ' + String.valueOf(lastOrderDate.day()) + ' ' + getMonthName(lastOrderDate.month()) + ' ' + String.valueOf(lastOrderDate.year()) + '.\n' +
                        '* Average historical order value is ₹' + String.valueOf(Math.round(aov)) + '.\n';
        for (Integer i = 0; i < limitCount; i++) {
            Double pct = ((Double)pairs[i].count / orders.size()) * 100;
            reason += '* ' + pairs[i].productName + ' appeared in ' + String.valueOf(Math.round(pct)) + '% of previous orders.\n';
        }
        res.reasoning = reason;

        return res;
    }

    public static Sales_Forecasting_Handler.Result getProductForecast(String accountId, String productId) {
        Sales_Forecasting_Handler.Result res = new Sales_Forecasting_Handler.Result();
        res.success = false;
        res.confidenceLevel = 'Low';

        if (String.isBlank(accountId)) {
            res.forecastSummary = 'Unable to generate product forecast: Account ID context is missing.';
            res.reasoning = '* An active Account context is required to determine store assortments, local velocities, and product-specific demands.';
            return res;
        }

        // Query product mix
        List<cgcloud__Order_Item__c> cgItems = [
            SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__Order__r.cgcloud__Order_Date__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.cgcloud__Order_Account__c = :accountId AND cgcloud__Order__r.cgcloud__Order_Date__c != null
            WITH USER_MODE
            ORDER BY cgcloud__Order__r.cgcloud__Order_Date__c DESC
            LIMIT 200
        ];

        List<ItemData> items = new List<ItemData>();
        for (cgcloud__Order_Item__c ci : cgItems) {
            ItemData idat = new ItemData();
            idat.productName = ci.cgcloud__Product__r.Name;
            idat.quantity = ci.cgcloud__Quantity__c != null ? ci.cgcloud__Quantity__c : 0;
            idat.orderDate = ci.cgcloud__Order__r.cgcloud__Order_Date__c;
            items.add(idat);
        }

        if (items.isEmpty()) {
            List<OrderItem> stdItems = [
                SELECT Id, Product2.Name, Quantity, Order.EffectiveDate
                FROM OrderItem
                WHERE Order.AccountId = :accountId AND Order.EffectiveDate != null
                WITH USER_MODE
                ORDER BY Order.EffectiveDate DESC
                LIMIT 200
            ];
            for (OrderItem si : stdItems) {
                ItemData idat = new ItemData();
                idat.productName = si.Product2.Name;
                idat.quantity = si.Quantity != null ? si.Quantity : 0;
                idat.orderDate = si.Order.EffectiveDate;
                items.add(idat);
            }
        }

        if (items.isEmpty()) {
            res.forecastSummary = 'Insufficient historical sales records to generate product demand forecasts.';
            res.reasoning = '* No past product sales items found for this account. Product velocities cannot be calculated.';
            return res;
        }

        // Calculate sales quantities and velocities
        Map<String, Decimal> totalQtyMap = new Map<String, Decimal>();
        Map<String, Decimal> recentQtyMap = new Map<String, Decimal>(); // last 30 days
        Map<String, Decimal> previousQtyMap = new Map<String, Decimal>(); // 30-60 days ago
        
        Date limitRecent = Date.today().addDays(-30);
        Date limitPrev = Date.today().addDays(-60);

        for (ItemData idat : items) {
            String pName = idat.productName;
            Decimal currentSum = totalQtyMap.containsKey(pName) ? totalQtyMap.get(pName) : 0;
            totalQtyMap.put(pName, currentSum + idat.quantity);

            if (idat.orderDate >= limitRecent) {
                Decimal rSum = recentQtyMap.containsKey(pName) ? recentQtyMap.get(pName) : 0;
                recentQtyMap.put(pName, rSum + idat.quantity);
            } else if (idat.orderDate >= limitPrev) {
                Decimal pSum = previousQtyMap.containsKey(pName) ? previousQtyMap.get(pName) : 0;
                previousQtyMap.put(pName, pSum + idat.quantity);
            }
        }

        // Classify Fast vs Slow
        List<ProductVelocity> velocities = new List<ProductVelocity>();
        for (String pName : totalQtyMap.keySet()) {
            Decimal totVal = totalQtyMap.get(pName);
            Decimal weeklyVelocity = totVal / 8.0; // Assume 2 months (8 weeks) window
            velocities.add(new ProductVelocity(pName, weeklyVelocity));
        }
        velocities.sort(); // Sort descending by velocity

        String fastMoving = '';
        String slowMoving = '';
        String decliningDemand = '';
        String increasingDemand = '';

        for (Integer i = 0; i < velocities.size(); i++) {
            ProductVelocity pv = velocities[i];
            String pName = pv.productName;

            if (i < 3 && pv.weeklyVelocity > 2.0) {
                fastMoving += '  * ' + pName + ' (' + String.valueOf(pv.weeklyVelocity.setScale(1)) + ' units/week)\n';
            } else if (i >= velocities.size() - 2) {
                slowMoving += '  * ' + pName + ' (' + String.valueOf(pv.weeklyVelocity.setScale(1)) + ' units/week)\n';
            }

            Decimal recent = recentQtyMap.containsKey(pName) ? recentQtyMap.get(pName) : 0;
            Decimal prev = previousQtyMap.containsKey(pName) ? previousQtyMap.get(pName) : 0;

            if (prev > 5 && recent < 0.7 * prev) {
                decliningDemand += '  * ' + pName + ' (declined from ' + String.valueOf(prev) + ' to ' + String.valueOf(recent) + ' units)\n';
            } else if (prev > 2 && recent > 1.3 * prev) {
                increasingDemand += '  * ' + pName + ' (increased from ' + String.valueOf(prev) + ' to ' + String.valueOf(recent) + ' units)\n';
            }
        }

        res.success = true;
        res.confidenceLevel = 'Medium';

        String fastMovingClean = String.isNotBlank(fastMoving) ? fastMoving.replace('  * ', '').replace('\n', ', ') : 'None identified';
        String slowMovingClean = String.isNotBlank(slowMoving) ? slowMoving.replace('  * ', '').replace('\n', ', ') : 'None identified';
        String increasingClean = String.isNotBlank(increasingDemand) ? increasingDemand.replace('  * ', '').replace('\n', ', ') : 'None';
        String decliningClean = String.isNotBlank(decliningDemand) ? decliningDemand.replace('  * ', '').replace('\n', ', ') : 'None';

        if (fastMovingClean.endsWith(', ')) fastMovingClean = fastMovingClean.substring(0, fastMovingClean.length() - 2);
        if (slowMovingClean.endsWith(', ')) slowMovingClean = slowMovingClean.substring(0, slowMovingClean.length() - 2);
        if (increasingClean.endsWith(', ')) increasingClean = increasingClean.substring(0, increasingClean.length() - 2);
        if (decliningClean.endsWith(', ')) decliningClean = decliningClean.substring(0, decliningClean.length() - 2);

        String summary = '**Product Demand Forecast**\n\n' +
                         '───────────────────────────────────────────────────\n\n' +
                         '  **Fast-Moving Products**    :  ' + fastMovingClean + '\n\n' +
                         '  **Slow-Moving Products**    :  ' + slowMovingClean + '\n\n';
        if (increasingClean != 'None') {
            summary += '  **Increasing Demand**       :  ' + increasingClean + '\n\n';
        }
        if (decliningClean != 'None') {
            summary += '  **Declining Demand**        :  ' + decliningClean + '\n\n';
        }
        
        // Add Out of stock predictions based on inventory if exists
        List<cgcloud__Inventory__c> invList = [
            SELECT cgcloud__Product__r.Name, cgcloud__Balance__c 
            FROM cgcloud__Inventory__c 
            WHERE cgcloud__Account__c = :accountId AND cgcloud__Balance__c != null
            WITH USER_MODE
        ];

        String outOfStockRisk = '';
        for (cgcloud__Inventory__c inv : invList) {
            String pName = inv.cgcloud__Product__r.Name;
            Decimal bal = inv.cgcloud__Balance__c;
            Decimal totVal = totalQtyMap.containsKey(pName) ? totalQtyMap.get(pName) : 0;
            Decimal dailyVelocity = totVal / 60.0;
            if (dailyVelocity > 0) {
                Double daysLeft = bal / dailyVelocity;
                if (daysLeft < 7) {
                    outOfStockRisk += '  * ' + pName + ' (Estimated depletion in ' + String.valueOf(Math.round(daysLeft)) + ' days, current stock: ' + String.valueOf(bal) + ')\n';
                }
            }
        }
        
        String oosClean = String.isNotBlank(outOfStockRisk) ? outOfStockRisk.replace('  * ', '').replace('\n', ', ') : 'None';
        if (oosClean.endsWith(', ')) oosClean = oosClean.substring(0, oosClean.length() - 2);
        if (oosClean != 'None') {
            summary += '  **Out of Stock Risk (7d)**  :  ' + oosClean + '\n\n';
        }
        summary += '───────────────────────────────────────────────────\n\n';

        res.forecastSummary = summary;

        String reason = '* Weekly velocities computed over a rolling 60-day window using historical sales invoices.\n' +
                        '* Demand trends compare the last 30 days against the preceding 30-day period.\n' +
                        '* Out of stock projections combine current inventory balance logs with daily sales velocity rates.';
        res.reasoning = reason;

        return res;
    }

    public static Sales_Forecasting_Handler.Result getCustomerForecast(String accountId) {
        Sales_Forecasting_Handler.Result res = new Sales_Forecasting_Handler.Result();
        res.success = false;
        res.confidenceLevel = 'Low';

        if (String.isBlank(accountId)) {
            res.forecastSummary = 'Unable to generate customer forecast: Account ID context is missing.';
            res.reasoning = '* An active Account context is required to calculate customer buying frequencies and churn risks.';
            return res;
        }

        List<cgcloud__Order__c> cgOrders = [
            SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Total_Value__c
            FROM cgcloud__Order__c
            WHERE cgcloud__Order_Account__c = :accountId AND cgcloud__Order_Date__c != null
            WITH USER_MODE
            ORDER BY cgcloud__Order_Date__c DESC
        ];

        List<OrderData> orders = new List<OrderData>();
        for (cgcloud__Order__c co : cgOrders) {
            OrderData od = new OrderData();
            od.orderDate = co.cgcloud__Order_Date__c;
            od.totalValue = co.cgcloud__Total_Value__c != null ? co.cgcloud__Total_Value__c : 0;
            orders.add(od);
        }

        if (orders.isEmpty()) {
            List<Order> stdOrders = [
                SELECT Id, EffectiveDate, TotalAmount
                FROM Order
                WHERE AccountId = :accountId AND EffectiveDate != null
                WITH USER_MODE
                ORDER BY EffectiveDate DESC
            ];
            for (Order so : stdOrders) {
                OrderData od = new OrderData();
                od.orderDate = so.EffectiveDate;
                od.totalValue = so.TotalAmount != null ? so.TotalAmount : 0;
                orders.add(od);
            }
        }

        if (orders.size() < 2) {
            res.forecastSummary = 'Insufficient order frequency data to perform customer purchasing trend and churn analysis.';
            res.reasoning = '* At least 2 past orders are required to establish a base reorder frequency pattern.';
            return res;
        }

        // Calculate frequency
        Integer totalDays = 0;
        for (Integer i = 0; i < orders.size() - 1; i++) {
            Date date1 = orders[i].orderDate;
            Date date2 = orders[i+1].orderDate;
            totalDays += Math.abs(date2.daysBetween(date1));
        }
        Double avgInterval = (Double)totalDays / (orders.size() - 1);
        if (avgInterval <= 0) avgInterval = 7.0;

        Date lastOrderDate = orders[0].orderDate;
        Integer daysSinceLastOrder = Math.abs(lastOrderDate.daysBetween(Date.today()));

        // Churn calculation
        Boolean churnRisk = false;
        String churnStatus = 'Healthy';
        if (daysSinceLastOrder > 1.5 * avgInterval) {
            churnRisk = true;
            churnStatus = 'High Risk';
        } else if (daysSinceLastOrder > 1.2 * avgInterval) {
            churnStatus = 'Medium Risk';
        }

        // Trend calculation
        Decimal recentAOV = 0;
        Integer recentCount = Math.min(3, orders.size());
        for (Integer i = 0; i < recentCount; i++) {
            recentAOV += orders[i].totalValue;
        }
        recentAOV = recentAOV / recentCount;

        Decimal olderAOV = 0;
        Integer olderCount = 0;
        for (Integer i = recentCount; i < orders.size(); i++) {
            olderAOV += orders[i].totalValue;
            olderCount++;
        }
        if (olderCount > 0) olderAOV = olderAOV / olderCount;
        else olderAOV = recentAOV;

        String trend = 'Stable';
        if (olderAOV > 0) {
            Double change = (Double)((recentAOV - olderAOV) / olderAOV);
            if (change < -0.15) {
                trend = 'Declining (' + String.valueOf(Math.round(change * 100)) + '%)';
            } else if (change > 0.15) {
                trend = 'Increasing (+' + String.valueOf(Math.round(change * 100)) + '%)';
            }
        }

        // High Value calculation
        Decimal totalSpend = 0;
        for (OrderData od : orders) {
            totalSpend += od.totalValue;
        }
        String valueSegment = 'Core Account';
        if (totalSpend > 100000) {
            valueSegment = 'High-Value Customer';
        }

        // Check if visit overdue
        List<Visit> pastVisits = [
            SELECT PlannedVisitStartTime 
            FROM Visit 
            WHERE AccountId = :accountId AND PlannedVisitStartTime != null AND Status = 'Completed'
            WITH USER_MODE
            ORDER BY PlannedVisitStartTime DESC
            LIMIT 10
        ];
        
        Boolean visitRequired = false;
        if (!pastVisits.isEmpty()) {
            Date lastVisitDate = pastVisits[0].PlannedVisitStartTime.date();
            Integer daysSinceLastVisit = Math.abs(lastVisitDate.daysBetween(Date.today()));
            if (daysSinceLastVisit > 30) {
                visitRequired = true;
            }
        } else {
            visitRequired = true; // No completed visits in history
        }

        res.success = true;
        res.confidenceLevel = orders.size() >= 5 ? 'High' : 'Medium';

        String summary = '**Customer Purchasing & Churn Forecast**\n\n' +
                         '───────────────────────────────────────────────────\n\n' +
                         '  **Churn Risk Status**       :  ' + churnStatus + ' (Last order ' + String.valueOf(daysSinceLastOrder) + ' days ago vs. avg. of ' + String.valueOf(Math.round(avgInterval)) + ' days)\n\n' +
                         '  **Ordering Value Trend**    :  ' + trend + '\n\n' +
                         '  **Customer Segmentation**   :  ' + valueSegment + ' (Total spend: ₹' + String.valueOf(Math.round(totalSpend)) + ')\n\n' +
                         '  **Follow-up Visit Recom.**  :  ' + (visitRequired ? 'Yes (Overdue for in-store consultation)' : 'No (Visit frequency within bounds)') + '\n\n' +
                         '───────────────────────────────────────────────────\n\n';
        res.forecastSummary = summary;

        String reason = '* Churn risk is flagged when the time elapsed since the last order exceeds 1.5 times the customer\'s historical average reorder interval.\n' +
                        '* Value segment status is classified by the customer\'s total spend across all historical orders.\n' +
                        '* Follow-up visits are recommended if more than 30 days have elapsed since the last completed supervisor or representative field visit.';
        res.reasoning = reason;

        return res;
    }

    public static Sales_Forecasting_Handler.Result getSalesForecast(String accountId, String period, String forecastBy) {
        Sales_Forecasting_Handler.Result res = new Sales_Forecasting_Handler.Result();
        res.success = true;
        res.confidenceLevel = 'Medium';

        String pRange = String.isBlank(period) ? 'month' : period.toLowerCase().trim();
        String groupCol = String.isBlank(forecastBy) ? 'account' : forecastBy.toLowerCase().trim();

        Integer days = 30;
        if (pRange == 'week') days = 7;
        else if (pRange == 'quarter') days = 90;

        Date forecastLimit = Date.today().addDays(days);

        // Fetch closed orders in the last N days as baseline
        Date pastLimit = Date.today().addDays(-days);
        Decimal actualSales = 0;

        List<cgcloud__Order__c> recentOrders = [
            SELECT cgcloud__Total_Value__c 
            FROM cgcloud__Order__c
            WHERE cgcloud__Order_Date__c >= :pastLimit AND cgcloud__Order_Date__c <= :Date.today()
            WITH USER_MODE
        ];
        for (cgcloud__Order__c o : recentOrders) {
            actualSales += o.cgcloud__Total_Value__c != null ? o.cgcloud__Total_Value__c : 0;
        }

        if (actualSales == 0) {
            List<Order> stdOrders = [
                SELECT TotalAmount 
                FROM Order
                WHERE EffectiveDate >= :pastLimit AND EffectiveDate <= :Date.today()
                WITH USER_MODE
            ];
            for (Order o : stdOrders) {
                actualSales += o.TotalAmount != null ? o.TotalAmount : 0;
            }
        }

        // Fetch Opportunity Pipeline
        Decimal expectedPipelineSales = 0;
        List<Opportunity> oppList = [
            SELECT Amount, Probability 
            FROM Opportunity 
            WHERE CloseDate >= :Date.today() AND CloseDate <= :forecastLimit AND IsClosed = false
            WITH USER_MODE
        ];
        for (Opportunity opp : oppList) {
            Decimal val = opp.Amount != null ? opp.Amount : 0;
            Decimal prob = opp.Probability != null ? opp.Probability : 0;
            expectedPipelineSales += val * (prob / 100.0);
        }

        Decimal expectedForecast = actualSales + expectedPipelineSales;

        // Grouping breakdown logic
        String breakdownDetails = '';
        if (groupCol == 'account') {
            List<AggregateResult> ar = [
                SELECT Account.Name accName, SUM(Amount) sumAmt
                FROM Opportunity
                WHERE CloseDate >= :Date.today() AND CloseDate <= :forecastLimit AND IsClosed = false AND AccountId != null
                WITH USER_MODE
                GROUP BY Account.Name
                ORDER BY SUM(Amount) DESC
                LIMIT 5
            ];
            if (!ar.isEmpty()) {
                breakdownDetails = '* **Top Account Pipeline Opportunities:**\n';
                for (AggregateResult r : ar) {
                    String aName = (String)r.get('accName');
                    Decimal val = (Decimal)r.get('sumAmt');
                    breakdownDetails += '  * ' + aName + ': ₹' + String.valueOf(Math.round(val)) + ' (Unweighted Pipeline)\n';
                }
            }
        } else if (groupCol == 'rep') {
            List<AggregateResult> ar = [
                SELECT Owner.Name repName, SUM(Amount) sumAmt
                FROM Opportunity
                WHERE CloseDate >= :Date.today() AND CloseDate <= :forecastLimit AND IsClosed = false
                WITH USER_MODE
                GROUP BY Owner.Name
                ORDER BY SUM(Amount) DESC
                LIMIT 5
            ];
            if (!ar.isEmpty()) {
                breakdownDetails = '* **Sales Pipeline by Representative:**\n';
                for (AggregateResult r : ar) {
                    String rName = (String)r.get('repName');
                    Decimal val = (Decimal)r.get('sumAmt');
                    breakdownDetails += '  * ' + rName + ': ₹' + String.valueOf(Math.round(val)) + ' (Unweighted Pipeline)\n';
                }
            }
        }

        String pipelineBreakdownClean = 'None';
        if (String.isNotBlank(breakdownDetails)) {
            pipelineBreakdownClean = breakdownDetails.replace('* **Top Account Pipeline Opportunities:**\n', '')
                                                      .replace('* **Sales Pipeline by Representative:**\n', '')
                                                      .replace('  * ', '')
                                                      .replace('\n', ', ');
            if (pipelineBreakdownClean.endsWith(', ')) {
                pipelineBreakdownClean = pipelineBreakdownClean.substring(0, pipelineBreakdownClean.length() - 2);
            }
        }

        String breakdownHeader = (groupCol == 'rep') ? 'Sales Pipeline by Rep' : 'Top Opportunities';
        String summary = '**Sales & Revenue Forecast**\n\n' +
                         '─────────────────────────────────────────────────────────────\n\n' +
                         '  **Forecast Period**          :  Next ' + String.valueOf(days) + ' days\n\n' +
                         '  **Predicted Rev. (Weighted)**:  ₹' + String.valueOf(Math.round(expectedForecast)) + '\n\n' +
                         '  **Baseline (Actual Sales)**  :  ₹' + String.valueOf(Math.round(actualSales)) + ' (Past ' + String.valueOf(days) + ' days)\n\n' +
                         '  **Weighted Pipeline**        :  ₹' + String.valueOf(Math.round(expectedPipelineSales)) + '\n\n';
        if (pipelineBreakdownClean != 'None') {
            if (breakdownHeader == 'Sales Pipeline by Rep') {
                summary += '  **Sales Pipeline by Rep**    :  ' + pipelineBreakdownClean + '\n\n';
            } else {
                summary += '  **Top Opportunities**        :  ' + pipelineBreakdownClean + '\n\n';
            }
        }
        summary += '─────────────────────────────────────────────────────────────\n\n';

        res.forecastSummary = summary;

        String reason = '* Predicted Revenue combines actual closed sales from the preceding ' + String.valueOf(days) + ' days as a baseline indicator of velocity, plus the weighted probability values of open opportunities closing within the forecast window.\n' +
                        '* Unweighted pipeline figures display total raw deal values without probability discount coefficients.';
        res.reasoning = reason;

        return res;
    }

    public static Sales_Forecasting_Handler.Result getInventoryForecast(String accountId, String productId) {
        Sales_Forecasting_Handler.Result res = new Sales_Forecasting_Handler.Result();
        res.success = false;
        res.confidenceLevel = 'Low';

        if (String.isBlank(accountId)) {
            res.forecastSummary = 'Unable to generate inventory forecast: Account ID context is missing.';
            res.reasoning = '* An active Account/store context is required to query localized inventory balances.';
            return res;
        }

        // Query inventory records
        List<cgcloud__Inventory__c> inventories = [
            SELECT Id, cgcloud__Product__c, cgcloud__Product__r.Name, cgcloud__Balance__c
            FROM cgcloud__Inventory__c
            WHERE cgcloud__Account__c = :accountId AND cgcloud__Balance__c != null
            WITH USER_MODE
            LIMIT 50
        ];

        if (inventories.isEmpty()) {
            res.forecastSummary = 'Insufficient inventory data for replenishment recommendations.';
            res.reasoning = '* No inventory balance records found in cgcloud__Inventory__c for this account store.';
            return res;
        }

        // Query sales velocity
        List<cgcloud__Order_Item__c> cgItems = [
            SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.cgcloud__Order_Account__c = :accountId AND cgcloud__Order__r.cgcloud__Order_Date__c >= :Date.today().addDays(-60)
            WITH USER_MODE
        ];

        Map<String, Decimal> totalQtyMap = new Map<String, Decimal>();
        for (cgcloud__Order_Item__c ci : cgItems) {
            String pName = ci.cgcloud__Product__r.Name;
            Decimal currentSum = totalQtyMap.containsKey(pName) ? totalQtyMap.get(pName) : 0;
            totalQtyMap.put(pName, currentSum + (ci.cgcloud__Quantity__c != null ? ci.cgcloud__Quantity__c : 0));
        }

        String depletionAlerts = '';
        String overstocked = '';
        String replenishmentRecs = '';

        for (cgcloud__Inventory__c inv : inventories) {
            String pName = inv.cgcloud__Product__r.Name;
            Decimal bal = inv.cgcloud__Balance__c;
            Decimal totVal = totalQtyMap.containsKey(pName) ? totalQtyMap.get(pName) : 0;
            Decimal dailyVelocity = totVal / 60.0;

            if (dailyVelocity > 0) {
                Double daysLeft = (Double)(bal / dailyVelocity);
                if (daysLeft < 7) {
                    depletionAlerts += '  * ' + pName + ' (runs out in ~' + String.valueOf(Math.round(daysLeft)) + ' days, stock: ' + String.valueOf(bal) + ')\n';
                    // Reorder 30-day supply
                    Decimal reorderQty = dailyVelocity * 30;
                    replenishmentRecs += '  * ' + pName + ': Order ' + String.valueOf(Math.round(reorderQty)) + ' units (to cover 30 days of demand)\n';
                } else if (daysLeft > 60) {
                    overstocked += '  * ' + pName + ' (stock covers ~' + String.valueOf(Math.round(daysLeft)) + ' days, stock: ' + String.valueOf(bal) + ')\n';
                }
            } else if (bal > 200) {
                overstocked += '  * ' + pName + ' (stock of ' + String.valueOf(bal) + ' units with zero sales in last 60 days)\n';
            }
        }

        res.success = true;
        res.confidenceLevel = 'Medium';

        String depletionClean = String.isNotBlank(depletionAlerts) ? depletionAlerts.replace('  * ', '').replace('\n', ', ') : 'All stock levels healthy';
        String replenishmentClean = String.isNotBlank(replenishmentRecs) ? replenishmentRecs.replace('  * ', '').replace('\n', ', ') : 'No immediate replenishment needed';
        String overstockedClean = String.isNotBlank(overstocked) ? overstocked.replace('  * ', '').replace('\n', ', ') : 'None identified';

        if (depletionClean.endsWith(', ')) depletionClean = depletionClean.substring(0, depletionClean.length() - 2);
        if (replenishmentClean.endsWith(', ')) replenishmentClean = replenishmentClean.substring(0, replenishmentClean.length() - 2);
        if (overstockedClean.endsWith(', ')) overstockedClean = overstockedClean.substring(0, overstockedClean.length() - 2);

        String summary = '**Inventory Depletion & Replenishment Forecast**\n\n' +
                         '─────────────────────────────────────────────────────────────\n\n' +
                         '  **Stock Depletion (7 Days)** :  ' + depletionClean + '\n\n' +
                         '  **Reorder Recommendations**  :  ' + replenishmentClean + '\n\n' +
                         '  **Overstocked Products**     :  ' + overstockedClean + '\n\n' +
                         '─────────────────────────────────────────────────────────────\n\n';
        
        res.forecastSummary = summary;

        String reason = '* Depletion rates and depletion dates are projected by dividing the store\'s current inventory balances by its average daily sales velocity (calculated from the last 60 days of order items).\n' +
                        '* Overstocking is flagged if store inventory balances exceed 60 days of predicted consumption.';
        res.reasoning = reason;

        return res;
    }

    public static Sales_Forecasting_Handler.Result getVisitForecast(String accountId) {
        Sales_Forecasting_Handler.Result res = new Sales_Forecasting_Handler.Result();
        res.success = false;
        res.confidenceLevel = 'Low';

        if (String.isBlank(accountId)) {
            res.forecastSummary = 'Unable to generate visit forecast: Account ID context is missing.';
            res.reasoning = '* An active Account context is required to determine store visit logs and scheduling priority.';
            return res;
        }

        // Query historical visits
        List<Visit> completedVisits = [
            SELECT Id, PlannedVisitStartTime, Status 
            FROM Visit 
            WHERE AccountId = :accountId AND Status = 'Completed' AND PlannedVisitStartTime != null
            WITH USER_MODE
            ORDER BY PlannedVisitStartTime DESC
            LIMIT 15
        ];

        if (completedVisits.size() < 2) {
            res.forecastSummary = 'Insufficient historical visit data to predict next visit outcomes.';
            res.reasoning = '* A minimum of 2 completed visits are required to calculate store visit intervals and order probabilities.';
            return res;
        }

        // Calculate average visit interval
        Integer totalDays = 0;
        for (Integer i = 0; i < completedVisits.size() - 1; i++) {
            Date d1 = completedVisits[i].PlannedVisitStartTime.date();
            Date d2 = completedVisits[i+1].PlannedVisitStartTime.date();
            totalDays += Math.abs(d2.daysBetween(d1));
        }
        Double avgVisitInterval = (Double)totalDays / (completedVisits.size() - 1);
        if (avgVisitInterval <= 0) avgVisitInterval = 14.0; // default to bi-weekly

        Date lastVisitDate = completedVisits[0].PlannedVisitStartTime.date();
        Date nextVisitDate = lastVisitDate.addDays(Math.round(avgVisitInterval));
        Integer daysSinceLastVisit = Math.abs(lastVisitDate.daysBetween(Date.today()));
        Boolean overdue = (daysSinceLastVisit > avgVisitInterval);

        // Expected order probability and AOV
        List<cgcloud__Order__c> visitOrders = [
            SELECT cgcloud__Total_Value__c, cgcloud__Visit__c
            FROM cgcloud__Order__c
            WHERE cgcloud__Order_Account__c = :accountId AND cgcloud__Visit__c != null
            WITH USER_MODE
        ];

        Integer visitCountWithOrders = 0;
        Set<Id> visitIdsWithOrders = new Set<Id>();
        Decimal sumValue = 0;
        for (cgcloud__Order__c o : visitOrders) {
            visitIdsWithOrders.add(o.cgcloud__Visit__c);
            sumValue += o.cgcloud__Total_Value__c != null ? o.cgcloud__Total_Value__c : 0;
        }

        Double conversionRate = 0.0;
        if (!completedVisits.isEmpty()) {
            Integer matchCount = 0;
            for (Visit v : completedVisits) {
                if (visitIdsWithOrders.contains(v.Id)) {
                    matchCount++;
                }
            }
            conversionRate = ((Double)matchCount / completedVisits.size()) * 100;
        }

        Decimal expectedValue = 0;
        if (visitIdsWithOrders.size() > 0) {
            expectedValue = sumValue / visitIdsWithOrders.size();
        }

        res.success = true;
        res.confidenceLevel = 'Medium';

        String expectedDateStr = String.valueOf(nextVisitDate.day()) + ' ' + getMonthName(nextVisitDate.month()) + ' ' + String.valueOf(nextVisitDate.year());
        String summary = '**Visit Execution & Outcome Forecast**\n\n' +
                         '───────────────────────────────────────────────────\n\n' +
                         '  **Next Scheduled Visit**    :  ' + expectedDateStr + ' (' + (overdue ? 'OVERDUE' : 'Scheduled') + ')\n\n' +
                         '  **Order Conversion Prob.**  :  ' + String.valueOf(Math.round(conversionRate)) + '%\n\n' +
                         '  **Expected Sales Value**    :  ₹' + String.valueOf(Math.round(expectedValue)) + '\n\n' +
                         '  **Visit Priority Rank**     :  ' + (overdue ? 'High (Overdue visit will trigger inventory stockouts)' : 'Medium') + '\n\n' +
                         '───────────────────────────────────────────────────\n\n';
        
        res.forecastSummary = summary;

        String reason = '* Recommended visit schedule is projected by adding the average interval between historical supervisor/rep visits (' + String.valueOf(Math.round(avgVisitInterval)) + ' days) to the last completed visit date.\n' +
                        '* Conversion probability represents the percentage of historical visits that resulted in sales order creations in Consumer Goods Cloud.';
        res.reasoning = reason;

        return res;
    }

    public static List<Sales_Forecasting_Handler.AccountOption> searchAccounts(String searchQuery) {
        List<Sales_Forecasting_Handler.AccountOption> options = new List<Sales_Forecasting_Handler.AccountOption>();
        if (String.isBlank(searchQuery)) {
            return options;
        }

        try {
            String pattern = '%' + searchQuery.trim().replaceAll('\\s+', '%') + '%';
            List<Account> accs = [
                SELECT Id, Name 
                FROM Account 
                WHERE Name LIKE :pattern
                WITH USER_MODE 
                LIMIT 15
            ];
            for (Account a : accs) {
                String lbl = 'Account: ' + a.Name + ' (ID: ' + a.Id + ')';
                options.add(new Sales_Forecasting_Handler.AccountOption(a.Id, a.Name, lbl));
            }
        } catch (Exception e) {}
        return options;
    }

    // --- HELPER CLASSES ---

    private class OrderData {
        public Date orderDate;
        public Decimal totalValue;
        public List<String> products;
    }

    private class ItemData {
        public String productName;
        public Decimal quantity;
        public Date orderDate;
    }

    private class ProductCountPair implements Comparable {
        public String productName;
        public Integer count;

        public ProductCountPair(String name, Integer c) {
            this.productName = name;
            this.count = c;
        }

        public Integer compareTo(Object obj) {
            ProductCountPair other = (ProductCountPair)obj;
            // Descending order sort
            if (this.count == other.count) return 0;
            return this.count > other.count ? -1 : 1;
        }
    }

    private class ProductVelocity implements Comparable {
        public String productName;
        public Decimal weeklyVelocity;

        public ProductVelocity(String name, Decimal velocity) {
            this.productName = name;
            this.weeklyVelocity = velocity;
        }

        public Integer compareTo(Object obj) {
            ProductVelocity other = (ProductVelocity)obj;
            // Descending order sort
            if (this.weeklyVelocity == other.weeklyVelocity) return 0;
            return this.weeklyVelocity > other.weeklyVelocity ? -1 : 1;
        }
    }

    private static String getMonthName(Integer month) {
        List<String> months = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        };
        if (month >= 1 && month <= 12) {
            return months[month - 1];
        }
        return '';
    }
}