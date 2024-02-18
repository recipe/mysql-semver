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

DELIMITER //

CREATE TABLE IF NOT EXISTS versions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
    sort_order BIGINT UNSIGNED NOT NULL,
    UNIQUE KEY unique_version (version),
    KEY idx_sort_order_version (sort_order, version)
) ENGINE = InnoDB charset utf8mb4 //

DROP FUNCTION IF EXISTS `GET_SORT_ORDER` //

CREATE FUNCTION GET_SORT_ORDER(version VARCHAR(255)) RETURNS BIGINT UNSIGNED
    NOT DETERMINISTIC
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    DECLARE l BIGINT UNSIGNED DEFAULT 0;
    DECLARE r BIGINT UNSIGNED DEFAULT ~0;
    DECLARE records INT UNSIGNED;
    DECLARE ver VARCHAR(255);
    DECLARE sort_order BIGINT UNSIGNED;
    DECLARE cmp TINYINT;
    DECLARE hop INT UNSIGNED DEFAULT 0;

    loop_1: REPEAT
        # It has to be set to NULL because the next query may not update the value
        # if there are no records in a range.
        SET records = NULL;

        SELECT t.version, t.sort_order, @sort_order_rows__
        INTO ver, sort_order, records
        FROM (
            SELECT v.version, v.sort_order, @sort_order_rows__ := @sort_order_rows__ + 1 AS num
            FROM versions v, (SELECT @sort_order_rows__ := 0) t
            WHERE l < v.sort_order
            AND v.sort_order < r
            ORDER BY v.sort_order
        ) t
        WHERE num IN ((@sort_order_rows__ + 1) / 2, (@sort_order_rows__ + 2) / 2);

        IF records IS NULL THEN
            LEAVE loop_1;
        END IF;

        SET cmp = VERSION_COMPARE(version, ver);

        IF cmp < 0 THEN
            SET r = sort_order;
        ELSEIF cmp > 0 THEN
            SET l = sort_order;
        ELSE
            RETURN sort_order;
        END IF;

        SET hop = hop + 1;

        IF l = r OR hop = 1000 THEN
            RETURN 0;
            # SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Unexpected error";
        END IF;
    UNTIL records = 1 END REPEAT loop_1;

    IF r - l < 2 THEN
        # Full reordering must be done in this case to allocate free space.
        RETURN 0;
    END IF;

    RETURN l + FLOOR((r - l) / 2);
END //

DROP TRIGGER IF EXISTS bi_versions_set_sort_order //

CREATE TRIGGER bi_versions_set_sort_order BEFORE INSERT ON versions
FOR EACH ROW
BEGIN
    DECLARE v BIGINT UNSIGNED;

    IF NEW.sort_order = 0 THEN
        SELECT GET_SORT_ORDER(NEW.version) INTO v;
        IF v = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'There is no space between consecutive versions. Table has to be fully reordered.';
        END IF;
        SET NEW.sort_order = v;
    END IF;
END //

DELIMITER ;
