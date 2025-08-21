-- Membuat database
CREATE DATABASE mandiri;

-- Menampilkan tabel dalam database
SHOW TABLES;

-- Menampilkan dataset 
SELECT * FROM cards_data;
SELECT * FROM transactions_data;
SELECT * FROM users_data;

-- DATA PREPROCESSING
-- TABLE cards_data
CREATE TABLE cards_clean AS
SELECT *, CAST(REPLACE(REPLACE(credit_limit, '$', ''), ',', '') AS DECIMAL(10,2)) AS credit_limit_fix
FROM cards_data;
SELECT * FROM cards_clean;
ALTER TABLE cards_clean DROP COLUMN credit_limit_clean;
ALTER TABLE cards_clean DROP COLUMN credit_limit;
ALTER TABLE cards_clean RENAME COLUMN credit_limit_fix TO credit_limit;
DROP TABLE cards_data;
ALTER TABLE cards_clean RENAME TO cards_data;
SELECT * FROM cards_data
WHERE id IN (SELECT id FROM cards_data 
GROUP BY id 
HAVING COUNT(*) > 1);

-- TABLE transactions_data
CREATE TABLE transactions_clean AS
SELECT *, CAST(REPLACE(REPLACE(amount, '$', ''), ',', '') AS DECIMAL(10,2)) AS amount_fix
FROM transactions_data;
SELECT * FROM transactions_clean;
ALTER TABLE transactions_clean DROP COLUMN amount;
ALTER TABLE transactions_clean RENAME COLUMN amount_fix TO amount;
DROP TABLE tansactions_data;
ALTER TABLE transactions_clean RENAME TO transactions_data;
SELECT * FROM transactions_data
WHERE id IN (SELECT id FROM transactions_data 
GROUP BY id
HAVING count(*) > 1);

-- TABLE users_data;
CREATE TABLE users_clean AS
SELECT *, CAST(REPLACE(per_capita_income, '$', '') AS DECIMAL(10,2)) AS per_capita_income_fix, 
CAST(REPLACE(yearly_income, '$', '') AS DECIMAL(10,2)) AS yearly_income_fix,
CAST(REPLACE(total_debt, '$', '') AS DECIMAL(10,2)) AS total_debit_fix
FROM users_data;
ALTER TABLE users_clean DROP COLUMN per_capita_income, DROP COLUMN yearly_income, DROP COLUMN total_debt;
ALTER TABLE users_clean RENAME COLUMN per_capita_income_fix TO per_capita_income, RENAME COLUMN yearly_income_fix TO yearly_income,
RENAME COLUMN total_debit_fix TO total_debit;
DROP TABLE users_data;
ALTER TABLE users_clean RENAME TO users_data;
SELECT * FROM users_data
WHERE id IN (SELECT id FROM users_data 
GROUP BY id 
HAVING COUNT(*) > 1);


-- DATA ACCUMULATION
CREATE VIEW mandiri AS (
SELECT c.client_id, c.card_brand, c.card_type, c.card_number, c.expires, c.cvv, c.has_chip,
c.num_cards_issued, c.credit_limit, c.acct_open_date, c.year_pin_last_changed, c.card_on_dark_web,
t.id, t.date, t.card_id, t.amount, t.use_chip, t.merchant_id, t.merchant_city, t.merchant_state,
t.zip, t.mcc, t.errors, u.current_age, u.retirement_age, u.birth_year, u.birth_month, u.gender, u.address, 
u.per_capita_income, u.yearly_income, u.total_debit, u.credit_score, u.num_credit_cards
FROM transactions_data t
LEFT JOIN cards_data c
ON t.card_id = c.id
LEFT JOIN users_data u
ON c.client_id = u.id);

CREATE TABLE mandiri2 AS SELECT *, CASE 
        WHEN birth_year BETWEEN 1928 AND 1945 THEN 'Silent Generation'
        WHEN birth_year BETWEEN 1946 AND 1964 THEN 'Baby Boomers'
        WHEN birth_year BETWEEN 1965 AND 1980 THEN 'Generation X'
        WHEN birth_year BETWEEN 1981 AND 1996 THEN 'Millennials (Gen Y)'
        WHEN birth_year BETWEEN 1997 AND 2012 THEN 'Generation Z'
        WHEN birth_year >= 2013 THEN 'Generation Alpha'
        ELSE 'Unknown'
    END AS generation 
    FROM mandiri;
    
SELECT * FROM mandiri2;

-- DATA EXPLORATION
-- Menentukan Card Brand yang sering digunakan oleh Nasabah
SELECT card_brand, sum(credit_limit) as CL, SUM(credit_limit) * 100.0 / (SELECT SUM(credit_limit) FROM mandiri) AS PercentCL, 
sum(per_capita_income) AS I, SUM(per_capita_income) * 100.0 / (SELECT SUM(per_capita_income) FROM mandiri) AS PercentI,
sum(yearly_income)AS Y, SUM(yearly_income) * 100.0 / (SELECT SUM(yearly_income) FROM mandiri) AS PercentY,
sum(total_debit) as TD, SUM(total_debit) * 100.0 / (SELECT SUM(total_debit) FROM mandiri) AS PercentCL
FROM mandiri
GROUP BY card_brand
ORDER BY CL DESC, I DESC, Y DESC, TD DESC;
-- note. Produk yang sering digunakan oleh nasabah adalah Card Brand MasterCard and Visa

-- Menentukan CardType yang sering digunakan oleh Nasabah
SELECT card_type, sum(credit_limit) as CL, SUM(credit_limit) * 100.0 / (SELECT SUM(credit_limit) FROM mandiri) AS PercentCL, 
sum(per_capita_income) AS I, SUM(per_capita_income) * 100.0 / (SELECT SUM(per_capita_income) FROM mandiri) AS PercentI,
sum(yearly_income)AS Y, SUM(yearly_income) * 100.0 / (SELECT SUM(yearly_income) FROM mandiri) AS PercentY,
sum(total_debit) as TD, SUM(total_debit) * 100.0 / (SELECT SUM(total_debit) FROM mandiri) AS PercentCL
FROM mandiri
WHERE card_brand IN ('Mastercard', 'Visa')
GROUP BY card_type
ORDER BY CL DESC, I DESC, Y DESC, TD DESC;
-- note. Cardtype yang sering digunakan adalah Debit dan Credit

-- CUSTOMER DEMOGRAPHIC
-- Group by Gender
SELECT gender, count(gender)
FROM mandiri
WHERE card_brand IN ('Mastercard', 'Visa') AND card_type IN ('Debit', 'Credit')
GROUP BY gender;
-- note. Customer didominasi oleh perempuan 

-- Group By Merchant State 
SELECT merchant_state, count(merchant_state) as Jumlah
FROM mandiri
WHERE card_brand IN ('Mastercard', 'Visa') AND card_type IN ('Debit', 'Credit')
GROUP BY merchant_state
ORDER BY Jumlah DESC
LIMIT 5;
-- note. Top 5 jumlah customer by State adalah CA, TX, NY, FL, dan IL

-- Group By Merchant State
SELECT merchant_city, count(merchant_city) as Jumlah
FROM mandiri
WHERE card_brand IN ('Mastercard', 'Visa') AND card_type IN ('Debit', 'Credit')
GROUP BY merchant_city
ORDER BY Jumlah DESC
LIMIT 5;
-- note. Top 5 jumlah customer by City adalah Houston, Miami, Chicago, Brooklyn, dan Dallas

-- ADDITIONAL INFORMATION
-- Security
SELECT card_on_dark_web, COUNT(card_on_dark_web) as Jumlah
FROM mandiri
WHERE card_brand IN ('Mastercard', 'Visa')  AND card_type IN ('Debit', 'Credit')
GROUP BY card_on_dark_web;
-- note. tidak ada satupun kartu yang bocor pada darkweb

SELECT has_chip, COUNT(has_chip) as Jumlah
FROM mandiri
WHERE card_brand IN ('Mastercard', 'Visa')  AND card_type IN ('Debit', 'Credit')
GROUP BY has_chip;
-- note. sebanyak 65415 customers belum mempunyai chip untuk keamaanan penggunaan kartu 


-- EXPORT DATA
SHOW VARIABLES LIKE 'secure_file_priv';

SELECT * 
INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\mandiri2.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM mandiri2;

