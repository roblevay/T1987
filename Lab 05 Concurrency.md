# Exercise 1: Transactions and locks

## Step 1: Create a lock

- Start SQL Server Management Studio
- Connect to the Server North 

* Open three query windows
* In window 1

```sql
USE AdventureWorks
BEGIN TRAN
	UPDATE Person.Person
	SET LastName='Andersson'
	WHERE BusinessEntityID=1
```
* In window 2

```sql
USE AdventureWorks
  SELECT * FROM Person.Person WHERE BusinessEntityID=1
```

## Step 2: Examine the lock using sp_who2
* In window 3

```sql
EXEC sp_who2
```

Identify the suspended (blocked) query and the blocking query

## Step 3: Examine the lock using sp_whoisactive

* Download and install sp_whoisactive from https://github.com/roblevay/T1987/tree/main/Files
* Open a new query window and run 

```sql
EXEC sp_whoisactive
```

Identify the suspended (blocked) query and the blocking query

## Step 4: Examine the lock using sp_blitzwho

* Download and install sp_blitzwho from https://github.com/roblevay/T1987/tree/main/Files
* Open a new query window and run 

```sql
EXEC sp_blitzwho
```

Identify the suspended (blocked) query and the blocking query

## Step 5: Dirty read

* Open a new query window and run 

```sql
SELECT *
FROM Person.Person WITH (NOLOCK)
WHERE BusinessEntityID = 1;
```
* You can now read in an open transaction (dirty read)

## Step 6: Rollback the transaction

* Return to Query window 1 which reads


```sql
USE AdventureWorks
BEGIN TRAN
	UPDATE Person.Person
	SET LastName='Andersson'
	WHERE BusinessEntityID=1
```

* Execute the following:

```sql
ROLLBACK TRAN
```

* Now, the blocking lock is released and the value in Person.Person is returned to the original value
* Close all open query windows

  ## 🧪 Exercise 2: Capture Deadlocks

### 🎯 Goal:

Log only actual deadlocks.

### 🛠️ Steps:

1. Create new session: `Deadlocks`
2. Add event: `xml_deadlock_report`
3. No filter needed.
4. Add the fields  `database_name`, `sql_text`
5. Add `event_file`, e.g. `C:\XELogs\Deadlocks.xel`
6. Save and start session.
7. Right-click the session and select Watch Live Data


### 🧪 Test the session: Simulate a Deadlock

#### 1. Create test table
```sql
USE tempdb
DROP TABLE IF EXISTS DeadlockTest;
CREATE TABLE DeadlockTest (
    ID INT PRIMARY KEY,
    Value VARCHAR(100)
);

INSERT INTO DeadlockTest (ID, Value)
VALUES (1, 'First'), (2, 'Second');
````

#### 2. Open **two separate SSMS query windows** — Session A and Session B. Run both queries within 10 seconds

---

### 🪩 Session A

```sql
--Run this first
USE Tempdb
BEGIN TRAN;
UPDATE DeadlockTest SET Value = 'A1' WHERE ID = 1;
-- Wait here to simulate overlap
```

### 🪩 Session B

```sql
--then this
USE Tempdb
BEGIN TRAN;
UPDATE DeadlockTest SET Value = 'B1' WHERE ID = 2;
-- Wait to collide with A
```

### 🪩 Session A
```sql
UPDATE DeadlockTest SET Value = 'A2' WHERE ID = 2;
```

---

### 🪩 Session B

```sql
--then this
USE Tempdb
UPDATE DeadlockTest SET Value = 'B1' WHERE ID = 1;
```



---

### ✅ Result

One of the sessions will be chosen as the deadlock victim and get an error:

```
Transaction (Process ID xx) was deadlocked on resources with another process and has been chosen as the deadlock victim.
```

You can catch this using the `xml_deadlock_report` Extended Event.

In the Live data window, double-click on the xml report to expand it




---

## 📂 Tip: Viewing .xel Files

You can always right-click on a session and choose **View Target Data** or **Open > File...**

---



