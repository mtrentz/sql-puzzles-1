DROP TABLE IF EXISTS meetings;

CREATE TABLE meetings (
    room TEXT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL
);

INSERT INTO meetings (room, start_time, end_time) VALUES
    -- Room A meetings
    ('Room A', '2024-10-01 09:00', '2024-10-01 10:00'),
    ('Room A', '2024-10-01 10:00', '2024-10-01 11:00'),
    ('Room A', '2024-10-01 11:00', '2024-10-01 12:00'),
    -- Room B meetings
    ('Room B', '2024-10-01 09:30', '2024-10-01 11:30'),
    -- Room C meetings
    ('Room C', '2024-10-01 09:00', '2024-10-01 10:00'),
    ('Room C', '2024-10-01 11:30', '2024-10-01 12:00');

SELECT * FROM meetings;


WITH events AS (
  -- Create an event for the start of each meeting (+1)
  SELECT 
    start_time AS event_time, 
    1 AS delta
  FROM meetings
  UNION ALL
  -- Create an event for the end of each meeting (-1)
  SELECT 
  	-- Reduce 1 min to the end time of meetings, this way the end and start times
    -- don't count as a concurrent meeting.
    end_time - interval '1 minute' as end_time,
    -1 AS delta
  FROM meetings
),
ordered_events AS (
  SELECT 
    event_time,
    delta,
    SUM(delta) OVER (ORDER BY event_time, delta DESC) AS concurrent_meetings
  FROM events
),
max_events AS (
  -- Find the maximum concurrent meetings value
  SELECT 
    event_time, 
    concurrent_meetings,
    RANK() OVER (ORDER BY concurrent_meetings DESC) AS rnk
  FROM ordered_events
)
SELECT event_time, concurrent_meetings
FROM max_events
WHERE rnk = 1;



--
-- FINDING OVERLAP
--
DROP TABLE IF EXISTS meetings_overlap;

CREATE TABLE meetings_overlap (
    room TEXT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL
);

INSERT INTO meetings_overlap (room, start_time, end_time) VALUES
    -- Room A meetings
    ('Room A', '2024-10-01 09:00', '2024-10-01 10:00'),
    ('Room A', '2024-10-01 10:00', '2024-10-01 11:00'),
    ('Room A', '2024-10-01 11:00', '2024-10-01 12:00'),
    -- Room B meetings
    ('Room B', '2024-10-01 09:30', '2024-10-01 11:30'),
    -- Room C meetings
    ('Room C', '2024-10-01 09:00', '2024-10-01 10:00'),
    -- Overlaps with previous meeting.
    ('Room C', '2024-10-01 09:30', '2024-10-01 12:00');

SELECT * FROM meetings_overlap;

WITH events AS (
    -- Create an event for the start of each meeting (+1)
    SELECT
        room,
        start_time AS event_time,
        1 AS delta
    FROM
        meetings_overlap
    UNION ALL
    -- Create an event for the end of each meeting (-1)
    SELECT
        -- Reduce 1 min to the end time of meetings, this way the end and start times
        -- don't count as a concurrent meeting.
        room,
        end_time - interval '1 minute' AS end_time,
        -1 AS delta
    FROM
        meetings_overlap
),
room_overlaps AS (
    SELECT
        room,
        event_time,
        delta,
        SUM(delta) OVER (ORDER BY room,
            event_time,
            delta DESC) AS concurrent_meetings
    FROM
        events
)
SELECT
    *
FROM
    room_overlaps
WHERE
    concurrent_meetings > 1;





