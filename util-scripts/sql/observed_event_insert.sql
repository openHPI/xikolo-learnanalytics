SELECT observed_event_id, user_id, url_id, observed_event_timestamp, 
       observed_event_duration, (current_timestamp - observed_event_timestamp), (now() > observed_event_timestamp + interval '40 min')
FROM observed_events
WHERE
 user_id = '00000001-3100-4444-9999-000000000002'
	AND observed_event_duration IS NULL
	AND (current_timestamp - observed_event_timestamp) > ('40 min'::interval)


DELETE FROM observed_events


UPDATE observed_events
SET observed_event_duration = 60
WHERE 
	user_id = '00000001-3100-4444-9999-000000000002'
	AND observed_event_duration IS NULL
	AND (current_timestamp - observed_event_timestamp) > ('60 min'::interval);

UPDATE observed_events
SET observed_event_duration = (extract(epoch from timestamp '2014-12-05 17:59:55+01') - extract(epoch from observed_event_timestamp)) / 60::float
WHERE 
	user_id = '00000001-3100-4444-9999-000000000002'
	AND observed_event_duration IS NULL;

INSERT INTO observed_events (user_id, url_id, observed_event_timestamp, observed_event_duration)
VALUES ('00000001-3100-4444-9999-000000000002', 1,  '2014-12-05 17:59:55+01', NULL);


SELECT *, extract(epoch from timestamp with time zone '2014-12-07 13:34:00+01'), extract(epoch from observed_event_timestamp), (extract(epoch from timestamp '2014-12-07 13:34:00+01') - extract(epoch from observed_event_timestamp))
FROM observed_events