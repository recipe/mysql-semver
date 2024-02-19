# mysql-semver
[![mysql-semver test workflow](https://github.com/recipe/mysql-semver/actions/workflows/default.yml/badge.svg)](https://github.com/recipe/mysql-semver/actions/workflows/default.yml)

Work with Semantic Versions in MySQL.

## Requirements

MySQL 8.x versions are supported.

## Install

Start MySQL 8 server, create a user and database, then install stored functions with the
following command:
```sql
mysql -hhost -P3306 -uusername -p db < ./semver.sql 
```
where:
 - The `host` is the host where MySQL server is listening.
 - The `3306` is the default MySQL port. Provide the value if your MySQL server runs on different
   port.
 - The `username` is the name of the MySQL user. This user must have the following list of
   [privileges][1]: `CREATE ROUTINE, ALTER ROUTINE`. To invoke stored function DB users must have
   the `EXECUTE` privilege.
 - The `db` is the database name you add stored functions to.

## Usage

The main purpose of adding this library is to maintain the ordered list of versions in the MySQL
database. MySQL does not have a built-in `VERSION_COMPARE(version1, version2)` function, 
so that this function has been implemented in pure SQL as a stored function, and 
it returns `0` if the both versions are equal, `1` if the `version1` is greater than the `version2`, 
or `-1` otherwise (if the `version2` is greater than the `version1`).

```sql

SELECT VERSION_COMPARE('1.0.0', '1.0.0');
0

SELECT VERSION_COMPARE('1.0.2-alpha', '1.0.2');
-1

SELECT VERSION_COMPARE('1.0.2-beta', '1.0.2-alpha');
1
```

The `VERSION_COMPARE` function supports the [Semantic Versioning 2][3] as well as the most of the 
real life versions that can be provided by users. See the [Version Compare Test][4] for the details.

To maintain the ordered list of versions in the database we can use the following DB table:
```sql
CREATE TABLE versions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
    sort_order BIGINT UNSIGNED NOT NULL,
    UNIQUE KEY unique_version (version),
    KEY idx_sort_order_version (sort_order, version)
) ENGINE = InnoDB charset utf8mb4;
```
Let's assume the DB table is empty.
When the new version is being added the `sort_order` is undefined, and can be calculated with 
the `GET_SORT_ORDER(version)` stored function:

```sql
SELECT GET_SORT_URDER('1.0.0');
9223372036854775807
```
With the help of the [Before Insert TRIGGER][2] on the `versions` table the `sort_order` property
will be initialized automatically for all newly added versions.

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


[1]: https://dev.mysql.com/doc/refman/8.0/en/stored-routines-privileges.html (Stored Routines Privileges)
[2]: append_version.sql#L89 (The bi_versions_set_sort_order Trigger)
[3]: https://semver.org/spec/v2.0.0.html (Semantic Versioning 2.0.0)
[4]: tests/test_version_compare.sql (The Version Compare Test)
