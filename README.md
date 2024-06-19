# Introduction
The Huberman Lab podcast, hosted by Dr. Andrew Huberman, has been a favorite among science enthusiasts for its engaging breakdown of complex concepts and insights from top-tier experts over the past three years. Inspired by my admiration for Dr. Huberman and curiosity about the podcast's impact, I undertook a data analysis project. By scraping data from the podcast's YouTube channel using Python, I aimed to visualize patterns in viewership, guest appearances, and audience engagement.

See the data here: [datasets](/csv_file/)

# Background
Dr. Andrew Huberman's podcast, the Huberman Lab, leverages the digital landscape to share scientifically grounded insights on topics like neuroscience, health, fitness, and nutrition. This project, Andrew_Huberman_Youtube_Data_Analysis, explores engagement metrics of both solo and guest episodes. By analyzing data such as views, likes, and comments, the project aims to visualize the Youtube's reach and understand the factors driving its popularity and audience engagement.

I scraped this data using the YouTube Data API from [Andrew Huberman's Youtube channel](https://www.youtube.com/@hubermanlab). It includes information on title, published date, duration, views, likes, and comments. For additional columns, I modified the data using SQL and spreadsheets. More details will be provided below.

# Tools I Used

For analyzing the engagement metrics of the Huberman Lab podcast, I utilized several key tools:

- **Python:** For scraping data from the YouTube channel, enabling the collection of detailed episode information.
- **SQL:** For data preparation and cleaning, ensuring the dataset was accurate and well-structured for analysis.
- **PostgreSQL:** The database management system used to store and manage the scraped data efficiently.
- **Speadsheet:** For creating columns such as episode_type, guest_name, genre, and video_link, and adding data manually.
- **Tableau:** For creating visualizations that help interpret and present the data insights clearly.
- **Visual Studio Code:** My primary environment for writing and executing Python scripts, SQL queries, and managing the overall project.
- **Git & GitHub:** Essential for version control and sharing my code, facilitating collaboration and tracking project progress.

# Workflow
## 1. Youtube data scraping with Python
```python
from googleapiclient.discovery import build
import pandas as pd
import seaborn as sns
```
```python
api_key = 'api_key'
channel_id = 'UC2D2CMWXMOVWx7giW1n3LIg'

youtube = build('youtube', 'v3', developerKey=api_key)
```
### Fuction to get channel statistics
```python
def get_channel_stats(youtube, channel_id):

    request = youtube.channels().list(
                part='snippet,contentDetails,statistics',
                id=channel_id)
    response = request.execute()

    
    data = dict(Channel_name = response['items'][0]['snippet']['title'],
                Subscribers = response['items'][0]['statistics']['subscriberCount'],
                Views = response['items'][0]['statistics']['viewCount'],
                Total_videos = response['items'][0]['statistics']['videoCount'],
                playlist_id = response['items'][0]['contentDetails']['relatedPlaylists']['uploads'])

    return data
```
```python
channel_statistics = get_channel_stats(youtube, channel_id)
```
```python
channel_data = pd.DataFrame([channel_statistics])
```
```python
channel_data['Subscribers'] = pd.to_numeric(channel_data['Subscribers'])
channel_data['Views'] = pd.to_numeric(channel_data['Views'])
channel_data['Total_videos'] = pd.to_numeric(channel_data['Total_videos'])
```
### Function to get video ids
```python
playlist_id = channel_data.loc[channel_data['Channel_name'] == 'Andrew Huberman', 'playlist_id'].iloc[0]
```
```python
def get_video_ids(youtube, playlist_id):

    request = youtube.playlistItems().list(
                part = 'contentDetails',
                playlistId = playlist_id,
                maxResults = 50)
    response = request.execute()

    video_ids = []

    for i in range(len(response['items'])):
        video_ids.append(response['items'][i]['contentDetails']['videoId'])

    next_page_token = response.get('nextPageToken')
    more_pages = True

    while more_pages:
        if next_page_token is None:
            more_pages = False
        else:
            request = youtube.playlistItems().list(
                        part = 'contentDetails',
                        playlistId = playlist_id,
                        maxResults = 50,
                        pageToken = next_page_token)
            response = request.execute()

            for i in range(len(response['items'])):
                video_ids.append(response['items'][i]['contentDetails']['videoId'])

        next_page_token = response.get('nextPageToken')

    return video_ids
```
```python
video_ids = get_video_ids(youtube, playlist_id)
```
### Function to get video details
```python
def get_video_details(youtube, video_ids):
    all_video_stats = []

    for i in range(0, len(video_ids), 50):
        request = youtube.videos().list(
                    part = 'snippet,contentDetails,statistics',
                    id = ','.join(video_ids[i:i+50]))
        response = request.execute()

        for video in response['items']:
            video_stats = dict(Title = video['snippet']['title'],
                               Published_date = video['snippet']['publishedAt'],
                               Duration = video['contentDetails']['duration'],
                               Views = video['statistics']['viewCount'],
                               Likes = video['statistics']['likeCount'],
                               Comments = video['statistics']['commentCount']
                               )
            all_video_stats.append(video_stats)
        
    return all_video_stats
```
```python
video_details = get_video_details(youtube, video_ids)
```
```python
video_data = pd.DataFrame(video_details)
```
```python
video_data['Published_date'] = pd.to_datetime(video_data['Published_date']).dt.date
video_data['Views'] = pd.to_numeric(video_data['Views'])
video_data['Likes'] = pd.to_numeric(video_data['Likes'])
video_data['Comments'] = pd.to_numeric(video_data['Comments'])
```
### Export to csv file
```python
video_data.to_csv('huberman_video_details.csv')
```

## 2. Upload and Prepare data with PostgreSQL and SQL
### Create database
```SQL
CREATE DATABASE andrew_huberman_youtube_database;
```
### Create table
```SQL
CREATE TABLE huberman_youtube_details (
    video_id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    published_date DATE,
    duration VARCHAR(20),
    views INT,
    likes INT,
    comments INT
);
```
### Upload the data
```sql
\copy huberman_youtube_details FROM 'file_path' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');
```

### Change the duration format from PT#H#M#S to hh:mm:ss format
```sql
UPDATE huberman_youtube_details
SET duration = 
    LPAD(FLOOR(EXTRACT(EPOCH FROM duration::interval) / 3600)::TEXT, 2, '0') || ':' ||
    LPAD(FLOOR((EXTRACT(EPOCH FROM duration::interval) % 3600) / 60)::TEXT, 2, '0') || ':' ||
    LPAD(ROUND(EXTRACT(EPOCH FROM duration::interval) % 60)::TEXT, 2, '0');
```
## 2. Create new cloumn and add data
In this step, I created the episode_type, guest_name, genre, and video_link columns and gathered the data from [hubermanlab.com](https://www.hubermanlab.com/)
### The episode_type column consists of
- **AMA:** Ask Me Anything (AMA) episode, part of the Huberman Lab Premium subscription.
- **Guest Episode:** Dr. Andrew Huberman invites experts to discuss specific topics.
- **Guest Series:** Dr. Andrew Huberman invites expert guests to discuss topics across multiple episodes.
- **Introduction:** The first video introducing the Huberman Lab podcast.
- **Journal Club:** A practice where students discuss and critique one or two academic papers, comparing their conclusions with those of the authors and highlighting key takeaways.
- **Live Event Q&A:** Presented by Dr. Andrew Huberman, exploring the science of sleep, focus, motivation, and performance. Includes actionable tools not discussed elsewhere and concludes with a live audience Q&A.
- **Short Clip:** A cut video from a full episode.
- **Solo Episode:** Dr. Andrew Huberman discusses science and science-based tools for everyday life on his own.


### Extract guest names from title column
```
=LEFT('title column',FIND(":",'title column') - 1)
```
### Genre data
- Each video can have multiple genres, separated by " | ".
- For videos without a specified genre, I used ChatGPT to analyze the transcript of the video and determine the appropriate genres.

## 3. Extract the data from the spreadsheet and upload it to the database to create the video_genres table.

### Normalize the genre field
```sql
-- 1. Create a new table for the genres:
CREATE TABLE video_genres (
    video_id INT,
    genre VARCHAR(255),
    PRIMARY KEY (video_id, genre)
);

-- 2. Populate the new podcast_genres table:
INSERT INTO video_genres (video_id, genre)
SELECT
    video_id,
    UNNEST(STRING_TO_ARRAY(genre, ' | '))
FROM
    huberman_youtube_details;
```
## 3. Create data visualization with Tableau
I created two dashboards: one focusing on solo episodes and another on guest episodes.
### Solo Episode Dashboard
This dashboard includes analysis of:
- Most views per solo video
- Views in relation to likes and comments
- Total and average views per video
- Total and average likes per video

![Solo Episode Dashboard](assets/Andrew%20Huberman%20Youtube%20Data%20Analysis%20-%20Solo%20Episodes.png)
Here is the link to Tableau Public: [Tableau Public](https://public.tableau.com/views/AndrewHubermanYoutubeDataAnalysisSoloEpisodes/SoloDashboard?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link)

### Guest Episode Dashboard
This dashboard includes analysis of:
- Top 5 most viewed guests
- Top 10 most frequent guests
- Most views per guest video
- Views in relation to likes and comments
- Total and average views per video
- Total and average likes per video

![Solo Episode Dashboard](assets/Andrew%20Huberman%20Youtube%20Data%20Analysis%20-%20Guest%20Episodes.png)
Here is the link to Tableau Public: [Tableau Public](https://public.tableau.com/views/AndrewHubermanYoutubeDataAnalysisGuestEpisodes/GuestDashboard?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link)