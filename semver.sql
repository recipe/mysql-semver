
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

DROP FUNCTION IF EXISTS `SEMANTIC_VERSION` //

CREATE FUNCTION `SEMANTIC_VERSION`(version VARCHAR(255)) RETURNS VARCHAR(255)
    DETERMINISTIC
    NO SQL
    SQL SECURITY INVOKER
BEGIN
    DECLARE re VARCHAR(255) DEFAULT '^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$';
    DECLARE sem_ver VARCHAR(255) DEFAULT NULL;

    IF version IS NULL THEN
       RETURN NULL;
    END IF;

    SET sem_ver = REGEXP_REPLACE(version, re, '$1,$2,$3,$4,$5');

    IF version = sem_ver THEN
        SET sem_ver = NULL;
    END IF;

    RETURN sem_ver;
END //

DROP FUNCTION IF EXISTS `NAT_VERSION` //

CREATE FUNCTION `NAT_VERSION` (version VARCHAR(255)) RETURNS VARCHAR(255)
    DETERMINISTIC
    NO SQL
    SQL SECURITY INVOKER
BEGIN
    DECLARE re VARCHAR(255) DEFAULT '^(0|[1-9]\\d*)(?:\\.(0|[1-9]\\d*))?(?:\\.(0|[1-9]\\d*))?(?:[.-](.+))?$';
    DECLARE ver VARCHAR(255) DEFAULT NULL;

    IF version IS NULL THEN
       RETURN NULL;
    END IF;

    SET ver = REGEXP_REPLACE(version, re, '$1,$2,$3,$4');

    IF version = ver THEN
        SET ver = CONCAT('0,0,0,', version, ',');
    ELSE
        SET ver = CONCAT(REPLACE(REPLACE(ver, ',,', ',0,'), ',,', ',0,'), ',');
    END IF;

    RETURN ver;
END //


DROP FUNCTION IF EXISTS `VERSION_COMPARE`//

CREATE FUNCTION `VERSION_COMPARE`(version1 VARCHAR(255), version2 VARCHAR(255)) RETURNS TINYINT
    DETERMINISTIC
    NO SQL
    SQL SECURITY INVOKER
BEGIN
    DECLARE re_digits_only VARCHAR(10) DEFAULT '^\\d+$';
    DECLARE sem_version1 VARCHAR(255) DEFAULT IFNULL(SEMANTIC_VERSION(version1), NAT_VERSION(version1));
    DECLARE sem_version2 VARCHAR(255) DEFAULT IFNULL(SEMANTIC_VERSION(version2), NAT_VERSION(version2));
    DECLARE l VARCHAR(255);
    DECLARE l_prev TINYINT UNSIGNED DEFAULT 0;
    DECLARE l_next TINYINT UNSIGNED DEFAULT 0;
    DECLARE lt_next TINYINT UNSIGNED DEFAULT 0;
    DECLARE r VARCHAR(255);
    DECLARE r_prev TINYINT UNSIGNED DEFAULT 0;
    DECLARE r_next TINYINT UNSIGNED DEFAULT 0;
    DECLARE rt_next TINYINT UNSIGNED DEFAULT 0;
    DECLARE pos TINYINT UNSIGNED DEFAULT 0;
    DECLARE res BIGINT;
    DECLARE i TINYINT DEFAULT 0;
    DECLARE l_pre_token VARCHAR(255);
    DECLARE r_pre_token VARCHAR(255);

    IF sem_version1 IS NULL OR sem_version2 IS NULL THEN
        /* Version does not start with a digit */
        IF version1 COLLATE utf8mb4_bin > version2 COLLATE utf8mb4_bin THEN
            RETURN 1;
        ELSEIF version1 COLLATE utf8mb4_bin < version2 COLLATE utf8mb4_bin THEN
            RETURN -1;
        ELSE
            RETURN 0;
        END IF;
    END IF;

    /* Compare major, minor, and patch versions */
    do_main: LOOP
        SET i = i + 1;
        SET l_next = LOCATE(',', sem_version1, l_prev + 1);
        SET r_next = LOCATE(',', sem_version2, r_prev + 1);
        SET l = SUBSTR(sem_version1 FROM l_prev + 1 FOR l_next - l_prev - 1);
        SET r = SUBSTR(sem_version2 FROM r_prev + 1 FOR r_next - r_prev - 1);
        IF LENGTH(l) = LENGTH(r) THEN
            /* To fix the INT max size error. */
            IF LENGTH(l) > 9 THEN
                SET pos = 1;
                REPEAT
                    SET res = SUBSTR(l FROM pos FOR 9) - SUBSTR(r FROM pos FOR 9);
                    IF res != 0 THEN
                        RETURN IF(res < 0, -1, 1);
                    END IF;
                    SET pos = pos + 9;
                UNTIL pos > LENGTH(l) END REPEAT;
            ELSE
                SET res = l - r;
                IF res != 0 THEN
                    RETURN IF(res < 0, -1, 1);
                END IF;
            END IF;
        ELSEIF LENGTH(l) < LENGTH(r) THEN
            RETURN -1;
        ELSE
            RETURN 1;
        END IF;
        SET l_prev = l_next;
        SET r_prev = r_next;
        IF i = 3 THEN
            LEAVE do_main;
        END IF;
    END LOOP do_main;

    /* Compare pre-release versions */
    SET i = 0;
    SET l_next = LOCATE(',', sem_version1, l_prev + 1);
    SET r_next = LOCATE(',', sem_version2, r_prev + 1);
    SET l = IF(l_next - l_prev > 1, SUBSTR(sem_version1 FROM l_prev + 1 FOR l_next - l_prev - 1), '');
    SET r = IF(r_next - r_prev > 1, SUBSTR(sem_version2 FROM r_prev + 1 FOR r_next - r_prev - 1), '');
    do_outer: LOOP
        IF l COLLATE utf8mb4_bin != r COLLATE utf8mb4_bin THEN
            /* A pre-release version has lower precedence than a normal version: */
            IF l = '' THEN
                RETURN 1;
            ELSEIF r = '' THEN
                RETURN -1;
            END IF;
            SET l_prev = 0, r_prev = 0;
            /* Normalize pre-release version by separating digits and letters with dots. */
            /* Replace periods with dots, because 1.0.0-alpha.1 and 1.0.0-alpha-1 are the same. */
            SET l = REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(l, '[~-]', '.'), '([a-zA-Z])(\\d)', '$1.$2'), '([\\d])([a-zA-Z])', '$1.$2');
            SET r = REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(r, '[~-]', '.'), '([a-zA-Z])(\\d)', '$1.$2'), '([\\d])([a-zA-Z])', '$1.$2');
            do_pre: LOOP
                SET lt_next = LOCATE('.', l, l_prev + 1);
                SET rt_next = LOCATE('.', r, r_prev + 1);
                SET l_pre_token = IF(lt_next = 0, SUBSTR(l FROM l_prev + 1), SUBSTR(l FROM l_prev + 1 FOR lt_next - l_prev - 1));
                SET r_pre_token = IF(rt_next = 0, SUBSTR(r FROM r_prev + 1), SUBSTR(r FROM r_prev + 1 FOR rt_next - r_prev - 1));

                IF l_pre_token COLLATE utf8mb4_bin != r_pre_token COLLATE utf8mb4_bin THEN
                    /* A larger set of pre-release fields has a higher precedence than a smaller set,
                       if all of the preceding identifiers are equal. */
                    IF l_pre_token = '' THEN
                        RETURN -1;
                    ELSEIF r_pre_token = '' THEN
                        RETURN 1;
                    END IF;

                    IF REGEXP_LIKE(l_pre_token, re_digits_only) THEN
                        IF REGEXP_LIKE(r_pre_token, re_digits_only) THEN
                            /* Identifiers consisting of only digits are compared numerically. */
                            IF LENGTH(l_pre_token) = LENGTH(r_pre_token) THEN
                                /* To fix INT max size error */
                                IF LENGTH(l_pre_token) > 9 THEN
                                    SET pos = 1;
                                    REPEAT
                                        SET res = SUBSTR(l_pre_token FROM pos FOR 9) - SUBSTR(r_pre_token FROM pos FOR 9);
                                        IF res != 0 THEN
                                            RETURN IF(res < 0, -1, 1);
                                        END IF;
                                        SET pos = pos + 9;
                                    UNTIL pos > LENGTH(l_pre_token) END REPEAT;
                                ELSE
                                    SET res = l_pre_token - r_pre_token;
                                    IF res != 0 THEN
                                        RETURN IF(res < 0, -1, 1);
                                    END IF;
                                END IF;
                            ELSEIF LENGTH(l_pre_token) < LENGTH(r_pre_token) THEN
                                RETURN -1;
                            ELSE
                                RETURN 1;
                            END IF;
                        ELSE
                            /* Numeric identifiers always have lower precedence than non-numeric identifiers */
                            RETURN -1;
                        END IF;
                    ELSEIF REGEXP_LIKE(r_pre_token, re_digits_only) THEN
                        /* Numeric identifiers always have lower precedence than non-numeric identifiers */
                        RETURN 1;
                    ELSE
                        /* Identifiers with letters or hyphens are compared lexically in ASCII sort order. */
                        RETURN IF(l_pre_token COLLATE utf8mb4_bin < r_pre_token COLLATE utf8mb4_bin, -1, 1);
                    END IF;
                END IF;

                IF lt_next = 0 AND rt_next = 0 THEN
                    LEAVE do_pre;
                ELSEIF lt_next = 0 THEN
                    /* A larger set of pre-release fields has a higher precedence than a smaller set */
                    RETURN -1;
                ELSEIF rt_next = 0 THEN
                    /* A larger set of pre-release fields has a higher precedence than a smaller set */
                    RETURN 1;
                ELSE
                    SET l_prev = lt_next;
                    SET r_prev = rt_next;
                END IF;
            END LOOP do_pre;
        END IF;

        /* According to the SemVer-2.0.0 the build metadata MUST be ignored when determining version precedence.
           However we compare builds in the same way as pre-releases */
        SET i = i + 1;
        IF i = 2 THEN
            LEAVE do_outer;
        END IF;

        SET l = SUBSTR(sem_version1 FROM l_next + 1 FOR LENGTH(sem_version1) - l_next);
        SET r = SUBSTR(sem_version2 FROM r_next + 1 FOR LENGTH(sem_version2) - r_next);
    END LOOP do_outer;

    /* Versions are identical */
    RETURN 0;
END //

DELIMITER ;
