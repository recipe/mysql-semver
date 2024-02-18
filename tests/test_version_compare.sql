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

SELECT * FROM (
VALUES
    ROW('1.0.0-alpha = 1.0.0-alpha', VERSION_COMPARE('1.0.0-alpha', '1.0.0-alpha') = 0),
    ROW('1.0.0-alpha < 1.0.0-alpha.1', VERSION_COMPARE('1.0.0-alpha', '1.0.0-alpha.1') = -1),
    ROW('1.0.0-alpha.1 > 1.0.0-alpha', VERSION_COMPARE('1.0.0-alpha.1', '1.0.0-alpha') = 1),
    ROW('1.0.0-alpha.1 < 1.0.0-alpha.beta', VERSION_COMPARE('1.0.0-alpha.1', '1.0.0-alpha.beta') = -1),
    ROW('1.0.0-alpha.beta < 1.0.0-beta', VERSION_COMPARE('1.0.0-alpha.beta', '1.0.0-beta') = -1),
    ROW('1.0.0-beta > 1.0.0-alpha.beta', VERSION_COMPARE('1.0.0-beta', '1.0.0-alpha.beta') = 1),
    ROW('1.0.0-beta < 1.0.0-beta.2', VERSION_COMPARE('1.0.0-beta', '1.0.0-beta.2') = -1),
    ROW('1.0.0-beta.2 > 1.0.0-beta', VERSION_COMPARE('1.0.0-beta.2', '1.0.0-beta') = 1),
    ROW('1.0.0-beta.2 < 1.0.0-beta.11', VERSION_COMPARE('1.0.0-beta.2', '1.0.0-beta.11') = -1),
    ROW('1.0.0-beta.11 > 1.0.0-beta.2', VERSION_COMPARE('1.0.0-beta.11', '1.0.0-beta.2') = 1),
    ROW('1.0.0-beta.11 < 1.0.0-rc.1', VERSION_COMPARE('1.0.0-beta.11', '1.0.0-rc.1') = -1),
    ROW('1.0.0-rc.1 > 1.0.0-beta.11', VERSION_COMPARE('1.0.0-rc.1', '1.0.0-beta.11') = 1),
    ROW('1.0.0-rc.1 < 1.0.0', VERSION_COMPARE('1.0.0-rc.1', '1.0.0') = -1),
    ROW('1.0.0 > 1.0.0-rc.1', VERSION_COMPARE('1.0.0', '1.0.0-rc.1') = 1),
    ROW('1.2.3-alpha > 1.2.3-ALPHA', VERSION_COMPARE('1.2.3-alpha', '1.2.3-ALPHA') = 1),
    ROW('1.2.11 > 1.2.1', VERSION_COMPARE('1.2.11', '1.2.1') = 1),
    ROW('123456789.0.1 > 123456789.0.1-a', VERSION_COMPARE('123456789.0.1', '123456789.0.1-a') = 1),
    ROW('1.0.0-alpha.1 < 1.0.0+build.1.2.4', VERSION_COMPARE('1.0.0-alpha.1', '1.0.0+build.1.2.4') = -1),
    ROW('1.0.0+build.1.2.4 < 1.0.0+build.1.2.5', VERSION_COMPARE('1.0.0+build.1.2.4', '1.0.0+build.1.2.5') = -1),
    ROW('1.0.0+build.1.2.4 < 1.0.0', VERSION_COMPARE('1.0.0+build.1.2.4', '1.0.0') = -1),
    ROW('1.0.0-alpha.1 = 1.0.0-alpha-1', VERSION_COMPARE('1.0.0-alpha.1', '1.0.0-alpha.1') = 0),
    ROW('1.0.0-alpha.1 = 1.0.0-alpha1', VERSION_COMPARE('1.0.0-alpha.1', '1.0.0-alpha1') = 0),
    ROW('1.0.0-alpha-1 = 1.0.0-alpha1', VERSION_COMPARE('1.0.0-alpha-1', '1.0.0-alpha1') = 0),
    ROW('1.0.0-alpha-1 = 1.0.0-alpha~1', VERSION_COMPARE('1.0.0-alpha-1', '1.0.0-alpha~1') = 0),
    ROW('1.0.0-alpha2 < 1.0.0-alpha10', VERSION_COMPARE('1.0.0-alpha2', '1.0.0-alpha10') = -1),
    ROW('1.0.0 < 184467440737095516189.1.1', VERSION_COMPARE('1.0.0', '184467440737095516189.1.1') = -1),
    ROW('2184467440737095516199.0.1 > 2184467440737095516198.0.1', VERSION_COMPARE('2184467440737095516199.0.1', '2184467440737095516198.0.1') = 1),
    ROW('1.0.0-beta.2184467440737095516199 > 1.0.0-beta.2184467440737095516198', VERSION_COMPARE('1.0.0-beta.2184467440737095516199', '1.0.0-beta.2184467440737095516198') = 1),
    -- It can cope with non semantic versions.
    ROW('2184467440737095516199 > 2184467440737095516198.0', VERSION_COMPARE('2184467440737095516199', '2184467440737095516198.0') = 1),
    ROW('1.2 > 1', VERSION_COMPARE('1.2', '1') = 1),
    ROW('1.2 < 2', VERSION_COMPARE('1.2', '2') = -1),
    ROW('1.2-beta < 2-beta', VERSION_COMPARE('1.2-beta', '2-beta') = -1),
    ROW('1.2 < 2-beta', VERSION_COMPARE('1.2', '2-beta') = -1),
    ROW('1.2.3 < 1.3', VERSION_COMPARE('1.2.3', '1.3') = -1),
    ROW('1 > 1.0-beta', VERSION_COMPARE('1', '1.0-beta') = 1),
    ROW('1 < 1.0.1-beta', VERSION_COMPARE('1', '1.0.1-beta') = -1),
    ROW('alpha < 1.0.0', VERSION_COMPARE('alpha', '1.0.0') = -1),
    ROW('alpha < beta', VERSION_COMPARE('alpha', 'beta') = -1),
    ROW('4.9.4+xy1 < 4.9.4', VERSION_COMPARE('4.9.4+xy1', '4.9.4') = -1)
) AS t
WHERE t.`column_1` <> 1;
