-- 1. Create table
CREATE TABLE huberman_youtube_details (
    video_id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    published_date DATE,
    duration VARCHAR(20),
    views INT,
    likes INT,
    comments INT,
    episode_type VARCHAR(50),
    guest_name VARCHAR(100),
    genre VARCHAR(255),
    video_link TEXT
);

-- 2.Upload data
-- \copy huberman_youtube_details FROM 'file_path' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- 3. Normalize the genre field
-- 3.1 Create a new table for the genres:
CREATE TABLE video_genres (
    video_id INT,
    genre VARCHAR(255),
    PRIMARY KEY (video_id, genre)
);

-- 3.2 Populate the new podcast_genres table:
INSERT INTO video_genres (video_id, genre)
SELECT
    video_id,
    UNNEST(STRING_TO_ARRAY(genre, ' | '))
FROM
    huberman_youtube_details;

-- 4. Change the duration format from PT#H#M#S to hh:mm:ss format
UPDATE huberman_youtube_details
SET duration = 
    LPAD(FLOOR(EXTRACT(EPOCH FROM duration::interval) / 3600)::TEXT, 2, '0') || ':' ||
    LPAD(FLOOR((EXTRACT(EPOCH FROM duration::interval) % 3600) / 60)::TEXT, 2, '0') || ':' ||
    LPAD(ROUND(EXTRACT(EPOCH FROM duration::interval) % 60)::TEXT, 2, '0');

