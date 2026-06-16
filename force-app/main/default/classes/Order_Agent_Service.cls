public with sharing class Order_Agent_Service {
    // --- ORDER METHODS ---

    public static Order_Agent_Handler.Result getOrderDetails(String orderId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        if (String.isBlank(orderId)) {
            return res;
        }

        try {
            Id ordId = (Id) orderId.trim();
            cgcloud__Order__c ord = [
                SELECT Id, Name, cgcloud__Phase__c, cgcloud__Order_Account__c, cgcloud__Order_Account__r.Name 
                FROM cgcloud__Order__c 
                WHERE Id = :ordId 
                WITH USER_MODE 
                LIMIT 1
            ];
            res.orderId = ord.Id;
            res.accountId = ord.cgcloud__Order_Account__c;
            res.accountName = ord.cgcloud__Order_Account__r != null ? ord.cgcloud__Order_Account__r.Name : '';
            res.orderName = ord.Name;
            res.orderStatus = ord.cgcloud__Phase__c;
        } catch (Exception e) {}
        return res;
    }

    public static List<Order_Agent_Handler.OrderOption> searchOrders(String searchQuery) {
        List<Order_Agent_Handler.OrderOption> options = new List<Order_Agent_Handler.OrderOption>();
        if (String.isBlank(searchQuery)) {
            return options;
        }

        try {
            String pattern = '%' + searchQuery.trim().replaceAll('\\s+', '%') + '%';
            List<cgcloud__Order__c> ords = [
                SELECT Id, Name, cgcloud__Phase__c, cgcloud__Order_Account__c, cgcloud__Order_Account__r.Name 
                FROM cgcloud__Order__c 
                WHERE Name LIKE :pattern OR cgcloud__Order_Account__r.Name LIKE :pattern
                WITH USER_MODE 
                LIMIT 15
            ];
            for (cgcloud__Order__c o : ords) {
                String accName = o.cgcloud__Order_Account__r != null ? o.cgcloud__Order_Account__r.Name : 'Unknown';
                String lbl = 'Order ' + o.Name + ' \u2014 ' + accName + ' (Status: ' + o.cgcloud__Phase__c + ')';
                options.add(new Order_Agent_Handler.OrderOption(o.Id, o.Name, o.cgcloud__Order_Account__c, accName, lbl));
            }
        } catch (Exception e) {}
        return options;
    }

    public static Order_Agent_Handler.Result getAccountOrderSummary(String accountId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.totalOrders = 0;
        res.totalSpend = 0;
        res.buyingInsight = 'No historical order data available.';
        res.phaseBreakdown = 'No orders to analyze.';
        res.recentOrders = '';

        if (String.isBlank(accountId)) {
            return res;
        }

        try {
            String accId = accountId.trim();
            String orderQuery =
                'SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, ' +
                'cgcloud__Phase__c, cgcloud__Total_Value__c, cgcloud__Gross_Total_Value__c, ' +
                'cgcloud__Delivery_Note__c, ' +
                '(SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                ' FROM cgcloud__Order_Items__r) ' +
                'FROM cgcloud__Order__c ' +
                'WHERE cgcloud__Order_Account__c = :accId ' +
                'ORDER BY CreatedDate DESC LIMIT 10';

            List<SObject> orders = Database.query(orderQuery, AccessLevel.USER_MODE);
            if (orders.isEmpty()) {
                res.buyingInsight = 'No previous orders found for this account.';
                return res;
            }

            res.totalOrders = orders.size();
            Decimal grandTotal = 0;
            Map<String, Decimal> phaseTotals = new Map<String, Decimal>();
            Map<String, ProductStat> productStats = new Map<String, ProductStat>();
            List<String> orderCards = new List<String>();

            for (SObject ord : orders) {
                Decimal totalVal = (Decimal) ord.get('cgcloud__Total_Value__c');
                if (totalVal == null) totalVal = 0;
                grandTotal += totalVal;

                String phase = (String) ord.get('cgcloud__Phase__c');
                if (String.isBlank(phase)) phase = 'Draft';

                if (!phaseTotals.containsKey(phase)) {
                    phaseTotals.put(phase, 0);
                }
                phaseTotals.put(phase, phaseTotals.get(phase) + totalVal);

                String orderName = (String) ord.get('Name');
                Object orderDateObj = ord.get('cgcloud__Order_Date__c');
                String orderDate = orderDateObj != null ? formatDate(String.valueOf(orderDateObj)) : 'N/A';
                Object deliveryDateObj = ord.get('cgcloud__Delivery_Date__c');
                String deliveryDate = deliveryDateObj != null ? formatDate(String.valueOf(deliveryDateObj)) : 'N/A';
                Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                if (grossVal == null) grossVal = 0;

                List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                Integer itemCount = 0;
                Set<String> uniqueProductsInOrder = new Set<String>();
                List<String> itemLines = new List<String>();

                if (items != null) {
                    itemCount = items.size();
                    for (SObject item : items) {
                        SObject productRef = item.getSObject('cgcloud__Product__r');
                        String productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                        Decimal qty = (Decimal) item.get('cgcloud__Quantity__c');
                        if (qty == null) qty = 0;
                        String uom = (String) item.get('cgcloud__UOM__c');
                        if (String.isBlank(uom)) uom = 'PCS';

                        if (!productStats.containsKey(productName)) {
                            productStats.put(productName, new ProductStat(uom));
                        }
                        productStats.get(productName).totalQuantity += qty;
                        uniqueProductsInOrder.add(productName);

                        itemLines.add('     \u2022 ' + productName + '  \u2014  ' + qty.setScale(0) + ' ' + uom);
                    }

                    for (String pName : uniqueProductsInOrder) {
                        productStats.get(pName).orderCount += 1;
                    }
                }

                String phaseIcon = getPhaseIcon(phase);
                String card =
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '\uD83D\uDCE6 Order ' + orderName + '\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  \uD83D\uDCC5 Order Date     :  ' + orderDate + '\n' +
                    '  \uD83D\uDE9A Delivery Date  :  ' + deliveryDate + '\n' +
                    '  ' + phaseIcon + ' Phase          :  ' + phase + '\n' +
                    '  \uD83D\uDCB0 Total Value    :  $' + totalVal.setScale(2) + '\n' +
                    '  \uD83D\uDCCA Gross Value    :  $' + grossVal.setScale(2) + '\n';

                if (itemCount > 0) {
                    card += '  \uD83D\uDCCB Items (' + itemCount + '):\n' + String.join(itemLines, '\n') + '\n';
                } else {
                    card += '  \uD83D\uDCCB Items: No items\n';
                }
                orderCards.add(card);
            }

            res.totalSpend = grandTotal;
            res.recentOrders = String.join(orderCards, '\n');

            List<String> phaseLines = new List<String>();
            for (String phase : phaseTotals.keySet()) {
                Decimal val = phaseTotals.get(phase);
                Decimal pct = (grandTotal > 0) ? (val / grandTotal * 100) : 0;
                String phaseIcon = getPhaseIcon(phase);
                phaseLines.add('  ' + phaseIcon + ' ' + phase + '  \u2014  $' + val.setScale(2) + '  (' + pct.setScale(0) + '%)');
            }
            res.phaseBreakdown =
                '\uD83D\uDCCA Phase Breakdown\n' +
                '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                String.join(phaseLines, '\n');

            if (productStats.isEmpty()) {
                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n' +
                    '  Product Details    :  Not available';
            } else {
                List<ProductEntry> productList = new List<ProductEntry>();
                for (String name : productStats.keySet()) {
                    ProductStat stat = productStats.get(name);
                    productList.add(new ProductEntry(name, stat.totalQuantity, stat.orderCount, stat.uom));
                }
                productList.sort();

                List<String> topFreqNames = new List<String>();
                for (Integer i = 0; i < Math.min(2, productList.size()); i++) {
                    topFreqNames.add(productList[i].name);
                }
                String usuallyOrders = String.join(topFreqNames, ' and ');

                ProductEntry mostSaleable = productList[0];
                for (ProductEntry pe : productList) {
                    if (pe.totalQuantity > mostSaleable.totalQuantity) {
                        mostSaleable = pe;
                    }
                }

                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n\n' +
                    '\uD83D\uDED2 Frequent Products\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Usually purchases: ' + usuallyOrders + '\n\n' +
                    '\uD83C\uDFC6 Top-Selling Product\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  ' + mostSaleable.name + '  \u2014  ' + mostSaleable.totalQuantity.setScale(0) + ' ' + mostSaleable.uom;
            }
        } catch (Exception e) {
            res.buyingInsight = 'Order data is not available in this environment.';
            res.phaseBreakdown = 'N/A';
            res.recentOrders = '';
        }
        return res;
    }

    public static Order_Agent_Handler.Result getVisitOrderSummary(String visitId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.totalOrders = 0;
        res.totalSpend = 0;
        res.buyingInsight = 'No historical order data available for this visit.';
        res.phaseBreakdown = 'No orders to analyze.';
        res.recentOrders = '';

        if (String.isBlank(visitId)) {
            return res;
        }

        try {
            String vstId = visitId.trim();
            String orderQuery =
                'SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, ' +
                'cgcloud__Phase__c, cgcloud__Total_Value__c, cgcloud__Gross_Total_Value__c, ' +
                'cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c, ' +
                '(SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                ' FROM cgcloud__Order_Items__r) ' +
                'FROM cgcloud__Order__c ' +
                'WHERE cgcloud__Visit__c = :vstId ' +
                'ORDER BY CreatedDate DESC LIMIT 10';

            List<SObject> orders = Database.query(orderQuery, AccessLevel.USER_MODE);
            if (orders.isEmpty()) {
                res.buyingInsight = 'No previous orders found for this visit.';
                return res;
            }

            res.totalOrders = orders.size();
            Decimal grandTotal = 0;
            Map<String, Decimal> phaseTotals = new Map<String, Decimal>();
            Map<String, ProductStat> productStats = new Map<String, ProductStat>();
            List<String> orderCards = new List<String>();

            for (SObject ord : orders) {
                Decimal totalVal = (Decimal) ord.get('cgcloud__Total_Value__c');
                if (totalVal == null) totalVal = 0;
                grandTotal += totalVal;

                String phase = (String) ord.get('cgcloud__Phase__c');
                if (String.isBlank(phase)) phase = 'Draft';

                if (!phaseTotals.containsKey(phase)) {
                    phaseTotals.put(phase, 0);
                }
                phaseTotals.put(phase, phaseTotals.get(phase) + totalVal);

                String orderName = (String) ord.get('Name');
                Object orderDateObj = ord.get('cgcloud__Order_Date__c');
                String orderDate = orderDateObj != null ? formatDate(String.valueOf(orderDateObj)) : 'N/A';
                Object deliveryDateObj = ord.get('cgcloud__Delivery_Date__c');
                String deliveryDate = deliveryDateObj != null ? formatDate(String.valueOf(deliveryDateObj)) : 'N/A';
                Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                if (grossVal == null) grossVal = 0;

                List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                Integer itemCount = 0;
                Set<String> uniqueProductsInOrder = new Set<String>();
                List<String> itemLines = new List<String>();

                if (items != null) {
                    itemCount = items.size();
                    for (SObject item : items) {
                        SObject productRef = item.getSObject('cgcloud__Product__r');
                        String productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                        Decimal qty = (Decimal) item.get('cgcloud__Quantity__c');
                        if (qty == null) qty = 0;
                        String uom = (String) item.get('cgcloud__UOM__c');
                        if (String.isBlank(uom)) uom = 'PCS';

                        if (!productStats.containsKey(productName)) {
                            productStats.put(productName, new ProductStat(uom));
                        }
                        productStats.get(productName).totalQuantity += qty;
                        uniqueProductsInOrder.add(productName);

                        itemLines.add('     \u2022 ' + productName + '  \u2014  ' + qty.setScale(0) + ' ' + uom);
                    }

                    for (String pName : uniqueProductsInOrder) {
                        productStats.get(pName).orderCount += 1;
                    }
                }

                String phaseIcon = getPhaseIcon(phase);
                String card =
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '\uD83D\uDCE6 Order ' + orderName + '\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  \uD83D\uDCC5 Order Date     :  ' + orderDate + '\n' +
                    '  \uD83D\uDE9A Delivery Date  :  ' + deliveryDate + '\n' +
                    '  ' + phaseIcon + ' Phase          :  ' + phase + '\n' +
                    '  \uD83D\uDCB0 Total Value    :  $' + totalVal.setScale(2) + '\n' +
                    '  \uD83D\uDCCA Gross Value    :  $' + grossVal.setScale(2) + '\n' +
                    '  \uD83C\uDD94 Order ID       :  ' + ord.Id + '\n';

                String delNote = (String) ord.get('cgcloud__Delivery_Note__c');
                String invNote = (String) ord.get('cgcloud__Invoice_Note__c');
                if (String.isNotBlank(delNote)) {
                    card += '  \uD83D\uDCDD Delivery Note  :  ' + delNote + '\n';
                }
                if (String.isNotBlank(invNote)) {
                    card += '  \uD83D\uDCC4 Invoice Note   :  ' + invNote + '\n';
                }

                if (itemCount > 0) {
                    card += '  \uD83D\uDCCB Items (' + itemCount + '):\n' + String.join(itemLines, '\n') + '\n';
                } else {
                    card += '  \uD83D\uDCCB Items: No items\n';
                }
                orderCards.add(card);
            }

            res.totalSpend = grandTotal;
            res.recentOrders = String.join(orderCards, '\n');

            List<String> phaseLines = new List<String>();
            for (String phase : phaseTotals.keySet()) {
                Decimal val = phaseTotals.get(phase);
                Decimal pct = (grandTotal > 0) ? (val / grandTotal * 100) : 0;
                String phaseIcon = getPhaseIcon(phase);
                phaseLines.add('  ' + phaseIcon + ' ' + phase + '  \u2014  $' + val.setScale(2) + '  (' + pct.setScale(0) + '%)');
            }
            res.phaseBreakdown =
                '\uD83D\uDCCA Phase Breakdown\n' +
                '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                String.join(phaseLines, '\n');

            if (productStats.isEmpty()) {
                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n' +
                    '  Product Details    :  Not available';
            } else {
                List<ProductEntry> productList = new List<ProductEntry>();
                for (String name : productStats.keySet()) {
                    ProductStat stat = productStats.get(name);
                    productList.add(new ProductEntry(name, stat.totalQuantity, stat.orderCount, stat.uom));
                }
                productList.sort();

                List<String> topFreqNames = new List<String>();
                for (Integer i = 0; i < Math.min(2, productList.size()); i++) {
                    topFreqNames.add(productList[i].name);
                }
                String usuallyOrders = String.join(topFreqNames, ' and ');

                ProductEntry mostSaleable = productList[0];
                for (ProductEntry pe : productList) {
                    if (pe.totalQuantity > mostSaleable.totalQuantity) {
                        mostSaleable = pe;
                    }
                }

                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n\n' +
                    '\uD83D\uDED2 Frequent Products\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Usually purchases: ' + usuallyOrders + '\n\n' +
                    '\uD83C\uDFC6 Top-Selling Product\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  ' + mostSaleable.name + '  \u2014  ' + mostSaleable.totalQuantity.setScale(0) + ' ' + mostSaleable.uom;
            }
        } catch (Exception e) {
            res.buyingInsight = 'Order data is not available in this environment.';
            res.phaseBreakdown = 'N/A';
            res.recentOrders = '';
        }
        return res;
    }

    public static Order_Agent_Handler.Result getOrderLineItems(String orderId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.items = new List<Order_Agent_Handler.OrderItem>();
        res.itemCount = 0;
        res.itemsSummary = 'No items found.';

        if (String.isBlank(orderId)) {
            return res;
        }

        try {
            String ordId = orderId.trim();
            String itemQuery = 
                'SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                'FROM cgcloud__Order_Item__c ' +
                'WHERE cgcloud__Order__c = :ordId ' +
                'ORDER BY cgcloud__Product__r.Name ASC';

            List<SObject> sItems = Database.query(itemQuery, AccessLevel.USER_MODE);
            if (sItems.isEmpty()) {
                return res;
            }

            List<String> summaryLines = new List<String>();
            summaryLines.add('\uD83D\uDCCB Order Line Items (' + sItems.size() + ' total)');

            for (SObject si : sItems) {
                Order_Agent_Handler.OrderItem oi = new Order_Agent_Handler.OrderItem();
                SObject productRef = si.getSObject('cgcloud__Product__r');
                oi.productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                Decimal qty = (Decimal) si.get('cgcloud__Quantity__c');
                oi.quantity = (qty != null) ? qty : 0;
                oi.uom = (String) si.get('cgcloud__UOM__c');
                if (String.isBlank(oi.uom)) oi.uom = 'PCS';

                res.items.add(oi);
                summaryLines.add('     \u2022 ' + oi.productName + '  \u2014  ' + oi.quantity.setScale(0) + ' ' + oi.uom);
            }

            res.itemCount = res.items.size();
            res.itemsSummary = String.join(summaryLines, '\n');
        } catch (Exception e) {
            res.itemsSummary = 'Unable to retrieve order items.';
        }
        return res;
    }

    public static Order_Agent_Handler.Result updateOrderNotes(String orderIdentifier, String deliveryNote, String invoiceNote) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.success = false;

        if (String.isBlank(orderIdentifier)) {
            res.resultMessage = 'Order identifier cannot be empty.';
            return res;
        }

        try {
            String ident = orderIdentifier.trim();
            List<cgcloud__Order__c> orders = new List<cgcloud__Order__c>();
            
            if (ident.length() == 15 || ident.length() == 18) {
                orders = [SELECT Id, cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c 
                          FROM cgcloud__Order__c 
                          WHERE Id = :ident 
                          WITH USER_MODE 
                          LIMIT 1];
            }
            
            if (orders.isEmpty()) {
                orders = [SELECT Id, cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c 
                          FROM cgcloud__Order__c 
                          WHERE Name = :ident 
                          WITH USER_MODE 
                          LIMIT 1];
            }

            if (orders.isEmpty()) {
                res.resultMessage = 'Order record not found with identifier: ' + ident;
                return res;
            }

            cgcloud__Order__c orderToUpdate = orders[0];
            Boolean changed = false;

            if (deliveryNote != null) {
                orderToUpdate.cgcloud__Delivery_Note__c = deliveryNote;
                changed = true;
            }

            if (invoiceNote != null) {
                orderToUpdate.cgcloud__Invoice_Note__c = invoiceNote;
                changed = true;
            }

            if (changed) {
                Database.update(orderToUpdate, AccessLevel.USER_MODE);
                res.success = true;
                res.resultMessage = 'Order notes updated successfully.';
            } else {
                res.success = true;
                res.resultMessage = 'No updates provided.';
            }
        } catch (Exception e) {
            res.success = false;
            res.resultMessage = 'Error updating order: ' + e.getMessage();
        }
        return res;
    }


    // --- HELPERS FOR UTILITY AND FORMATTING ---

    private static String getPhaseIcon(String phase) {
        if (phase.equalsIgnoreCase('released') || phase.equalsIgnoreCase('submitted')) {
            return '\u2705';
        } else if (phase.equalsIgnoreCase('draft')) {
            return '\uD83D\uDFE1';
        } else if (phase.equalsIgnoreCase('canceled')) {
            return '\u274C';
        }
        return '\u26AA';
    }

    private static String formatDate(String rawDate) {
        if (String.isBlank(rawDate)) return 'N/A';
        if (rawDate.length() >= 10) {
            String datePart = rawDate.substring(0, 10);
            List<String> parts = datePart.split('-');
            if (parts.size() == 3) {
                String monthName = getMonthName(Integer.valueOf(parts[1]));
                return parts[2] + ' ' + monthName + ' ' + parts[0];
            }
        }
        return rawDate;
    }

    private static String getMonthName(Integer month) {
        List<String> months = new List<String>{
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        };
        if (month >= 1 && month <= 12) {
            return months[month - 1];
        }
        return String.valueOf(month);
    }

    private class ProductStat {
        public Decimal totalQuantity;
        public Integer orderCount;
        public String uom;

        public ProductStat(String uom) {
            this.totalQuantity = 0;
            this.orderCount = 0;
            this.uom = uom;
        }
    }

    private class ProductEntry implements Comparable {
        public String name;
        public Decimal totalQuantity;
        public Integer orderCount;
        public String uom;

        public ProductEntry(String name, Decimal totalQuantity, Integer orderCount, String uom) {
            this.name = name;
            this.totalQuantity = totalQuantity;
            this.orderCount = orderCount;
            this.uom = uom;
        }

        public Integer compareTo(Object other) {
            ProductEntry o = (ProductEntry) other;
            return o.orderCount - this.orderCount;
        }
    }
}