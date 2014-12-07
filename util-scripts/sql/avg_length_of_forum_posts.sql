-- Average length of forum posts
SELECT user_pii.global_user_id, 
	FLOOR((extract(epoch from collaborations.collaboration_timestamp) 
			- extract(epoch from timestamp '2012-03-05 12:00:00')) / (3600 * 24 * 7)) AS week,
	AVG(LENGTH(collaborations.collaboration_content)) 
FROM user_pii
INNER JOIN collaborations
ON collaborations.user_id = user_pii.global_user_id
WHERE -- AND user_pii.global_user_id < 100
	--collaborations.collaboration_parent_id = '00000002-3500-4444-9999-000000000001' -- = 1 means forum posts
	--FLOOR(extract(epoch from collaborations.collaboration_timestamp) 
			- extract(epoch from timestamp '2012-03-05 12:00:00') / (3600 * 24 * 7) < 16
GROUP BY user_pii.global_user_id, week


-- Number of forum posts
SELECT user_pii.global_user_id, 
	FLOOR((extract(epoch from collaborations.collaboration_timestamp) 
			- extract(epoch from timestamp '2012-03-05 12:00:00')) / (3600 * 24 * 7)) AS week,
	COUNT(*) 
FROM user_pii
INNER JOIN collaborations
ON collaborations.user_id = user_pii.global_user_id
-- users.user_id < 100
WHERE --collaborations.collaboration_parent_id = 1 -- = 1 mean forum posts
	FLOOR((extract(epoch from collaborations.collaboration_timestamp) 
			- extract(epoch from timestamp '2012-03-05 12:00:00')) / (3600 * 24 * 7)) < 1600
GROUP BY user_pii.global_user_id, week