-- Netflix dataset analysis
-- SQLite, DB Browser for SQLite
-- table: netflix_titles_cleaned (imported from Excel-cleaned CSV)

-- ===================================
-- cleanup after import
-- ===================================

-- import came in at 8810 rows instead of 8807, checking for junk rows
SELECT * FROM netflix_titles_cleaned WHERE show_id IS NULL OR show_id = '';

-- confirmed 3 empty rows, removing them
DELETE FROM netflix_titles_cleaned WHERE show_id IS NULL OR show_id = '';

SELECT COUNT(*) FROM netflix_titles_cleaned;
-- 8807, correct


-- ===================================
-- basic analysis
-- ===================================

-- movies vs tv shows
SELECT type, COUNT(*) as total
FROM netflix_titles_cleaned
GROUP BY type;
-- Movies 6131, TV Shows 2672

-- top 10 countries
-- note: cast is a reserved word, needs quotes if selecting that column
SELECT country, COUNT(*)
FROM netflix_titles_cleaned
GROUP BY country
ORDER BY COUNT(*) DESC
LIMIT 10;

-- top genres
SELECT listed_in, COUNT(*)
FROM netflix_titles_cleaned
GROUP BY listed_in
ORDER BY COUNT(*) DESC
LIMIT 10;

-- titles by release year
SELECT release_year, COUNT(*)
FROM netflix_titles_cleaned
GROUP BY release_year
ORDER BY release_year DESC
LIMIT 15;


-- ===================================
-- country column bug
-- ===================================
-- top countries query above was returning people's names instead of
-- countries (David Attenborough, Jeff Dunham, Kevin Hart...) - checked one:

SELECT show_id, type, title, director, "cast", country
FROM netflix_titles_cleaned
WHERE country = 'David Attenborough';

-- country and cast had identical values for these rows.
-- checking how many rows affected:

SELECT COUNT(*)
FROM netflix_titles_cleaned
WHERE country = "cast";
-- 7982 rows, 90% of the dataset
-- turned out an Excel formula for country_clean had referenced the
-- cast column by mistake

-- fix: imported the original raw kaggle csv as a second table
-- (netflix_titles_raw) and used it to restore correct country values

UPDATE netflix_titles_cleaned
SET country = (
    SELECT CASE
        WHEN raw.country IS NULL OR raw.country = '' THEN 'Unknown'
        ELSE raw.country
    END
    FROM netflix_titles_raw raw
    WHERE raw.show_id = netflix_titles_cleaned.show_id
);

-- checking the fix worked
SELECT COUNT(*) FROM netflix_titles_cleaned WHERE country = "cast";
-- 0, fixed

-- re-running the top countries query
SELECT country, COUNT(*)
FROM netflix_titles_cleaned
GROUP BY country
ORDER BY COUNT(*) DESC
LIMIT 10;
-- United States 2818, India 972, Unknown 831, United Kingdom 419,
-- Japan 245, South Korea 199, Canada 181, Spain 145, France 124, Mexico 110
-- matches what this dataset is known to look like, so this is correct now


-- ===================================
-- schema check (used a few times while debugging column names)
-- ===================================
PRAGMA table_info(netflix_titles_cleaned);
