CREATE TABLE assessments
(
  submission_id uuid,
  assessment_feedback text,
  assessment_grade real,
  assessment_grade_with_penalty real,
  assessment_grader_id integer,
  assessment_timestamp timestamp with time zone,
  assessment_id uuid NOT NULL,
  CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id)
)

CREATE TABLE collaboration_types
(
  collaboration_type_id integer NOT NULL,
  collaboration_type_name character(50),
  CONSTRAINT collaboration_types_pkey PRIMARY KEY (collaboration_type_id)
)

CREATE TABLE collaborations
(
  user_id uuid,
  collaboration_type_id serial NOT NULL,
  collaboration_timestamp timestamp with time zone,
  collaboration_content text,
  collaboration_parent_id uuid,
  collaboration_child_number integer,
  collaborations_ip character(50),
  collaborations_os integer,
  collaborations_agent integer,
  resource_id uuid,
  collaboration_thread_id uuid,
  collaboration_id uuid NOT NULL,
  CONSTRAINT collaborations_pkey PRIMARY KEY (collaboration_id)
)

CREATE TABLE course
(
  course_id uuid NOT NULL,
  course_name character(128),
  course_start_date date,
  course_end_date date,
  CONSTRAINT course_pkey PRIMARY KEY (course_id)
)

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
)

CREATE TABLE global_user
(
  global_user_id uuid NOT NULL,
  course_id uuid,
  course_user_id bigint,
  CONSTRAINT global_user_pkey PRIMARY KEY (global_user_id)
)

CREATE TABLE observed_events
(
  observed_event_id bigserial NOT NULL,
  url_id bigserial NOT NULL,
  observed_event_timestamp timestamp with time zone,
  observed_event_duration real,
  user_id uuid,
  observed_event_ip character(50),
  observed_event_agent character(512),
  observed_event_os character(50),
  CONSTRAINT observed_events_pkey PRIMARY KEY (observed_event_id)
)

CREATE TABLE problem_types
(
  problem_type_id integer NOT NULL,
  problem_type_name character(50),
  CONSTRAINT problem_types_pkey PRIMARY KEY (problem_type_id)
)

CREATE TABLE problems
(
  problem_id uuid NOT NULL,
  problem_name character(512),
  problem_parent_id uuid,
  problem_child_number integer,
  problem_type_id integer,
  problem_release_timestamp timestamp with time zone,
  problem_soft_deadline timestamp with time zone,
  problem_hard_deadline timestamp with time zone,
  problem_max_submission integer,
  problem_max_duration integer,
  problem_weight integer,
  resource_id uuid,
  CONSTRAINT problems_pkey PRIMARY KEY (problem_id)
)

CREATE TABLE resource_types
(
  resource_type_id serial NOT NULL,
  resource_type_content character(128),
  resource_type_medium character(128),
  CONSTRAINT resource_types_pkey PRIMARY KEY (resource_type_id)
)

CREATE TABLE resource_urls
(
  resources_urls_id serial NOT NULL,
  resource_id uuid,
  url_id serial NOT NULL,
  CONSTRAINT resource_urls_pkey PRIMARY KEY (resources_urls_id)
)


CREATE TABLE resources
(
  resource_id uuid NOT NULL,
  resource_name character(256),
  resource_uri character(128),
  resource_type_id serial NOT NULL,
  resource_parent_id uuid,
  resource_child_number uuid,
  resource_release_timestamp date,
  resource_relevant_start_date date,
  resource_relevant_end_date date,
  resource_relevant_week integer,
  CONSTRAINT resources_pkey PRIMARY KEY (resource_id)
)

CREATE TABLE submissions
(
  submission_id uuid NOT NULL,
  user_id uuid,
  problem_id uuid,
  submission_timestamp timestamp with time zone,
  submission_attempt_number integer,
  submission_answer text,
  submission_is_submitted boolean,
  submission_ip integer,
  submission_os integer,
  submission_agent integer,
  CONSTRAINT submissions_pkey PRIMARY KEY (submission_id)
)

CREATE TABLE urls
(
  url_id serial NOT NULL,
  course_uuid uuid,
  url character(512),
  CONSTRAINT urls_pkey PRIMARY KEY (url_id)
)

CREATE TABLE urls
(
  url_id serial NOT NULL,
  course_uuid uuid,
  url character(512),
  CONSTRAINT urls_pkey PRIMARY KEY (url_id)
)