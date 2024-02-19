-- This file is part of Project recipe/mysql-semver, a program for working with Semantic Versions in MySQL.
-- Copyright (C) 2024  Vitaliy Demidov
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License Version 3 as
-- published by the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

TRUNCATE `versions`;

INSERT `versions` (`version`, `sort_order`)
SELECT t.column_0 AS `version`, 0 AS `sort_order`
FROM (VALUES
    ROW ('1.0-beta'),
    ROW ('2-alpha'),
    ROW ('1.3'),
    ROW ('1.4.34'),
    ROW ('2.0.12-beta.1'),
    ROW ('1.3-beta.2'),
    ROW ('1.3-beta-2'),
    ROW ('1.3-beta2'),
    ROW ('1'),
    ROW ('1.2'),
    ROW ('alpha'),
    ROW('1.0.0-2021-08-19'),
    ROW('11.0.0.1'),
    ROW('11.0.0.1.8.22'),
    ROW('1.0.0-canary.3'),
    ROW('1.0.1-alpha-3'),
    ROW('1.0.1-rc20')
) t
ORDER BY RAND();

SELECT `id`, `version`, `sort_order` FROM `versions` ORDER BY `sort_order`;

SELECT GROUP_CONCAT(`version` ORDER BY `sort_order`)
INTO @actual
FROM `versions`;

SELECT 'alpha,1.0.0-2021-08-19,1.0-beta,1.0.0-canary.3,1,1.0.1-alpha-3,1.0.1-rc20,1.2,1.3-beta2,1.3-beta.2,1.3-beta-2,1.3,1.4.34,2-alpha,2.0.12-beta.1,11.0.0.1,11.0.0.1.8.22'
INTO @expected;

SELECT @actual;
SELECT @expected;

SELECT 'Test failed!'
FROM (VALUES ROW(@actual)) t
WHERE t.column_0 COLLATE utf8mb4_bin != @expected COLLATE utf8mb4_bin;


