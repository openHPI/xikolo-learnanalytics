CREATE TABLE course
(
  course_id uuid NOT NULL,
  course_name character(128),
  course_start_date date,
  course_end_date date,
  CONSTRAINT course_pkey PRIMARY KEY (course_id)
);

CREATE TABLE course_user
(
  course_user_id bigserial NOT NULL,
  course_id uuid,
  observing_user_id bigserial NOT NULL,
  submitting_user_id bigserial NOT NULL,
  collaborating_user_id bigserial NOT NULL,
  feedback_user_id bigserial NOT NULL,
  type character(32),
  final_grade real,
  CONSTRAINT course_user_pkey PRIMARY KEY (course_user_id)
);

CREATE TABLE global_user
(
  global_user_id uuid NOT NULL,
  course_id uuid,
  course_user_id bigint,
  CONSTRAINT global_user_pkey PRIMARY KEY (global_user_id)
);

CREATE TABLE user_pii
(
  global_user_id uuid,
  birthday date,
  timezone_offset integer,
  username character(64) NOT NULL,
  gender character(10),
  ip character(50),
  country character(50),
  CONSTRAINT user_pii_pkey PRIMARY KEY (username)
);

CREATE TABLE observed_events
(
  observed_event_i
  course_id uuid NOT NULL,
  course_name character(128),
  course_start_date date,
  course_end_date date,
  CONSTRAINT course_pkey PRIMARY KEY (course_id)
);