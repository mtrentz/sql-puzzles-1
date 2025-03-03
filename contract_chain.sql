DROP TABLE IF EXISTS contracts;


CREATE TABLE contracts (
    contract_id integer PRIMARY KEY,
    employee_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL
);


INSERT INTO contracts (contract_id, employee_id, start_date, end_date)
VALUES 
    -- Employee 1: Two continuous contracts
    (1, 1, '2024-01-01', '2024-03-31'),
    (2, 1, '2024-04-01', '2024-06-30'),
    -- Employee 2: One contract, then a gap of three days, then two contracts
    (3, 2, '2024-01-01', '2024-02-15'),
    (4, 2, '2024-02-19', '2024-04-30'),
    (5, 2, '2024-05-01', '2024-07-31'),
    -- Employee 3: One contract
    (6, 3, '2024-03-01', '2024-08-31');

  
select * from contracts;
  
  
  
WITH ordered_contracts AS (
    SELECT
        *,
        LAG(end_date) OVER (PARTITION BY employee_id ORDER BY start_date) AS previous_end_date
    FROM
        contracts
),
gapped_contracts AS (
    SELECT
        *,
        -- Deals with the case of the first contract, which won't have
        -- a previous end date. In this case, it's still the start of a new
        -- sequence.
        CASE WHEN previous_end_date IS NULL
            OR previous_end_date < start_date - INTERVAL '1 day' THEN
            1
        ELSE
            0
        END AS is_new_sequence
    FROM
        ordered_contracts
),
sequences AS (
    SELECT
        *,
        SUM(is_new_sequence) OVER (PARTITION BY employee_id ORDER BY start_date) AS sequence_id
FROM
    gapped_contracts
),
max_sequence AS (
    SELECT
        employee_id,
        MAX(sequence_id) AS max_sequence_id
FROM
    sequences
GROUP BY
    employee_id
),
latest_contract_chain AS (
    SELECT
        c.contract_id,
        c.employee_id,
        c.start_date,
        c.end_date
    FROM
        sequences c
        JOIN max_sequence m ON c.sequence_id = m.max_sequence_id
            AND c.employee_id = m.employee_id
        ORDER BY
            c.employee_id,
            c.start_date
)
SELECT
    *
FROM
    latest_contract_chain;



