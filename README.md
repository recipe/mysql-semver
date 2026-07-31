# mysql-semver
[![mysql-semver test workflow](https://github.com/recipe/mysql-semver/actions/workflows/default.yml/badge.svg)](https://github.com/recipe/mysql-semver/actions/workflows/default.yml)

Work with Semantic Versions in MySQL.

## Requirements

MySQL 8.x and MySQL 9.x (including the 9.7 LTS release) are supported.

## Install

Start a MySQL server, create a user and a database, then install the stored functions with the following command:
```sql
mysql --host=HOST --port=3306 --user=USERNAME --password DATABASE_NAME < ./semver.sql
```
where:
 - The `HOST` is the host where the MySQL server is listening.
 - The `3306` is the default MySQL port. Provide a different value if your MySQL server runs on a different port.
 - The `USERNAME` is the name of the MySQL user. This user must have the following
   [privileges][1]: `CREATE ROUTINE, ALTER ROUTINE`. To invoke a stored function, DB users must have the `EXECUTE` privilege.
 - The `DATABASE_NAME` is the name of the database where you install the stored functions.

## Usage

The main purpose of this library is to maintain an ordered list of versions in a MySQL
database. MySQL doesn't have a built-in `VERSION_COMPARE(version1, version2)` function,
so this library implements one in pure SQL as a stored function. It returns `0` if both
versions are equal, `1` if `version1` is greater than `version2`,
or `-1` otherwise (if `version2` is greater than `version1`).

```sql

SELECT VERSION_COMPARE('1.0.0', '1.0.0');
0

SELECT VERSION_COMPARE('1.0.2-alpha', '1.0.2');
-1

SELECT VERSION_COMPARE('1.0.2-beta', '1.0.2-alpha');
1
```

The `VERSION_COMPARE` function supports [Semantic Versioning 2][3] as well as most of the
real-life version strings users actually provide. See the [Version Compare Test][4] for details.

To maintain the ordered list of versions in the database, we can use the following table:
```sql
CREATE TABLE versions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
    sort_order BIGINT UNSIGNED NOT NULL,
    UNIQUE KEY unique_version (version),
    KEY idx_sort_order_version (sort_order, version)
) ENGINE = InnoDB charset utf8mb4;
```
Let's assume the table is empty.
When a new version is added, the `sort_order` value is undefined and can be calculated with the [`GET_SORT_ORDER(version)` stored function][5]:

```sql
SELECT GET_SORT_ORDER('1.0.0');
9223372036854775807
```
With the help of the [BEFORE INSERT trigger][2] on the `versions` table, the `sort_order` property is initialized automatically for every newly added version.

```sql
INSERT `versions` (`version`, `sort_order`) VALUES 
('1.0.0', 0),
('1.0.0-alpha', 0),
('1.0.1', 0);

SELECT * FROM `versions` ORDER BY `sort_order`;
+--+-----------+--------------------+
|id|version    |sort_order          |
+--+-----------+--------------------+
|2 |1.0.0-alpha|4611686018427387903 |
|1 |1.0.0      |9223372036854775807 |
|3 |1.0.1      |13835058055282163711|
+--+-----------+--------------------+
```


[1]: https://dev.mysql.com/doc/refman/9.7/en/stored-routines-privileges.html (Stored Routines Privileges)
[2]: append_version.sql#L95 (The bi_versions_set_sort_order Trigger)
[3]: https://semver.org/spec/v2.0.0.html (Semantic Versioning 2.0.0)
[4]: tests/test_version_compare.sql (The Version Compare Test)
[5]: append_version.sql#L28 (The GET_SORT_ORDER Stored Function)
