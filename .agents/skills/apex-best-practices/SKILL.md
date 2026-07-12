---
name: apex-best-practices
description: "Guidelines and rules for writing clean, secure, and analyzer-compliant Apex code."
---

# Apex Best Practices & Analyzer Rules

When writing or modifying Apex code, you MUST follow these guidelines to ensure the code passes PMD / Salesforce Code Analyzer rules.

## 1. Documentation (ApexDoc)
- Every public or global class must have an ApexDoc comment.
- Every public or global method must have an ApexDoc comment.
- Example:
  ```apex
  /**
   * @description A brief description of what the class/method does.
   */
  ```

## 2. Formatting & Syntax
- **No Trailing Whitespaces:** Ensure there are no spaces or tabs at the end of any line.
- **Curly Braces:** ALWAYS use curly braces `{}` for `if`, `else`, and `for` statements, even if they only contain a single line of code.
- **Avoid Empty Blocks:** Do not leave empty block statements (e.g., empty `if` or `else`). If necessary, add a comment explaining why it's empty.

## 3. Complexity & Code Structure
- **Cognitive and Cyclomatic Complexity:** Keep methods short and focused. If a method exceeds a complexity score of 15, break it down into smaller, private helper methods.
- **Deep Nesting:** Avoid deeply nested `if/then` statements. Use early returns (guard clauses) to flatten logic.
- **Duplicate Code:** Do not duplicate code blocks. Abstract reusable logic into helper methods.

## 4. Security & Data Access
- **CRUD/FLS Validations:** Always enforce user access before performing SOQL or DML operations. 
  - For SOQL, append `WITH USER_MODE` (or `WITH SECURITY_ENFORCED`).
  - For DML, use `as user` context (e.g., `insert as user newRecords;`) or verify accessibility.
- **Empty Catch Blocks:** NEVER use an empty `catch` block. At a minimum, log the exception or throw a custom exception.
  - Example: `catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }`
- **Dynamic SOQL:** Always use bind variables (`:myVar`) instead of string concatenation to avoid SOQL injection. If dynamic queries are unavoidable, use `String.escapeSingleQuotes()`.

## 5. Unit Testing
- **Test Class Declaration:** Use PascalCase for the test annotation: `@IsTest` (not `@isTest`).
- **Assertions:** Apex unit tests MUST include assertions. Use the `Assert` class (e.g., `Assert.areEqual(expected, actual, 'Message');`) or `System.assert()`.
- **System.debug:** Avoid using `System.debug()` in test classes as it impacts performance. If debugging is necessary, always specify a logging level (e.g., `System.debug(LoggingLevel.INFO, '...');`) and remove them before final commits.
- **Test Context:** Use `System.runAs(user)` to simulate specific user contexts when applicable.
