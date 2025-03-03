DROP TABLE IF EXISTS ticket_moves;

CREATE TABLE ticket_moves (
    ticket_id INT8 NOT NULL,
    create_date DATE NOT NULL,
    move_date DATE NOT NULL,
    from_stage TEXT NOT NULL,
    to_stage TEXT NOT NULL
);

INSERT INTO ticket_moves (ticket_id, create_date, move_date, from_stage, to_stage)
    VALUES
        -- Ticket 1: Created in "New", then moves to Doing, Review, Done.
        (1, '2024-09-01', '2024-09-03', 'New', 'Doing'),
        (1, '2024-09-01', '2024-09-07', 'Doing', 'Review'),
        (1, '2024-09-01', '2024-09-10', 'Review', 'Done'),
        -- Ticket 2: Created in "New", then moves: New → Doing → Review → Doing again → Review.
        (2, '2024-09-05', '2024-09-08', 'New', 'Doing'),
        (2, '2024-09-05', '2024-09-12', 'Doing', 'Review'),
        (2, '2024-09-05', '2024-09-15', 'Review', 'Doing'),
        (2, '2024-09-05', '2024-09-20', 'Doing', 'Review'),
        -- Ticket 3: Created in "New", then moves to Doing. (Edge case: no subsequent move from Doing.)
        (3, '2024-09-10', '2024-09-16', 'New', 'Doing'),
        -- Ticket 4: Created already in "Doing", then moves to Review.
        (4, '2024-09-15', '2024-09-22', 'Doing', 'Review');



SELECT * FROM ticket_moves;


WITH stage_intervals AS (
    SELECT
        ticket_id,
        from_stage,
        move_date 
        - COALESCE(
            LAG(move_date) OVER (
                PARTITION BY ticket_id 
                ORDER BY move_date
            ), 
            create_date
        ) AS days_in_stage
    FROM
        ticket_moves
)
SELECT
    SUM(days_in_stage) / COUNT(DISTINCT ticket_id) as avg_days_in_doing
FROM
    stage_intervals
WHERE
    from_stage = 'Doing';





















