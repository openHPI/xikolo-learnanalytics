--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.4
-- Dumped by pg_dump version 9.3.1
-- Started on 2014-12-07 18:51:03 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 199 (class 3079 OID 12018)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2334 (class 0 OID 0)
-- Dependencies: 199
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 198 (class 1259 OID 163699)
-- Name: assessments; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE assessments (
    submission_id uuid,
    assessment_feedback text,
    assessment_grade real,
    assessment_grade_with_penalty real,
    assessment_grader_id integer,
    assessment_timestamp timestamp with time zone,
    assessment_id uuid NOT NULL
);


ALTER TABLE public.assessments OWNER TO postgres;

--
-- TOC entry 194 (class 1259 OID 163669)
-- Name: collaboration_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE collaboration_types (
    collaboration_type_id integer NOT NULL,
    collaboration_type_name character(50)
);


ALTER TABLE public.collaboration_types OWNER TO postgres;

--
-- TOC entry 193 (class 1259 OID 163656)
-- Name: collaborations; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE collaborations (
    user_id uuid,
    collaboration_type_id integer NOT NULL,
    collaboration_timestamp timestamp with time zone,
    collaboration_content text,
    collaboration_parent_id uuid,
    collaboration_child_number integer,
    collaborations_ip character(50),
    collaborations_os integer,
    collaborations_agent integer,
    resource_id uuid,
    collaboration_thread_id uuid,
    collaboration_id uuid NOT NULL
);


ALTER TABLE public.collaborations OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 163652)
-- Name: collaborations_collaboration_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE collaborations_collaboration_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collaborations_collaboration_type_id_seq OWNER TO postgres;

--
-- TOC entry 2335 (class 0 OID 0)
-- Dependencies: 192
-- Name: collaborations_collaboration_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE collaborations_collaboration_type_id_seq OWNED BY collaborations.collaboration_type_id;


--
-- TOC entry 170 (class 1259 OID 163318)
-- Name: course; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE course (
    course_id uuid NOT NULL,
    course_name character(128),
    course_start_date date,
    course_end_date date
);


ALTER TABLE public.course OWNER TO postgres;

--
-- TOC entry 176 (class 1259 OID 163333)
-- Name: course_user; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE course_user (
    course_user_id bigint NOT NULL,
    course_id uuid,
    observing_user_id bigint NOT NULL,
    submitting_user_id bigint NOT NULL,
    collaborating_user_id bigint NOT NULL,
    feedback_user_id bigint NOT NULL,
    type character(32),
    final_grade real
);


ALTER TABLE public.course_user OWNER TO postgres;

--
-- TOC entry 174 (class 1259 OID 163329)
-- Name: course_user_collaborating_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE course_user_collaborating_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_user_collaborating_user_id_seq OWNER TO postgres;

--
-- TOC entry 2336 (class 0 OID 0)
-- Dependencies: 174
-- Name: course_user_collaborating_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE course_user_collaborating_user_id_seq OWNED BY course_user.collaborating_user_id;


--
-- TOC entry 171 (class 1259 OID 163323)
-- Name: course_user_course_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE course_user_course_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_user_course_user_id_seq OWNER TO postgres;

--
-- TOC entry 2337 (class 0 OID 0)
-- Dependencies: 171
-- Name: course_user_course_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE course_user_course_user_id_seq OWNED BY course_user.course_user_id;


--
-- TOC entry 175 (class 1259 OID 163331)
-- Name: course_user_feedback_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE course_user_feedback_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_user_feedback_user_id_seq OWNER TO postgres;

--
-- TOC entry 2338 (class 0 OID 0)
-- Dependencies: 175
-- Name: course_user_feedback_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE course_user_feedback_user_id_seq OWNED BY course_user.feedback_user_id;


--
-- TOC entry 172 (class 1259 OID 163325)
-- Name: course_user_observing_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE course_user_observing_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_user_observing_user_id_seq OWNER TO postgres;

--
-- TOC entry 2339 (class 0 OID 0)
-- Dependencies: 172
-- Name: course_user_observing_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE course_user_observing_user_id_seq OWNED BY course_user.observing_user_id;


--
-- TOC entry 173 (class 1259 OID 163327)
-- Name: course_user_submitting_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE course_user_submitting_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_user_submitting_user_id_seq OWNER TO postgres;

--
-- TOC entry 2340 (class 0 OID 0)
-- Dependencies: 173
-- Name: course_user_submitting_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE course_user_submitting_user_id_seq OWNED BY course_user.submitting_user_id;


--
-- TOC entry 177 (class 1259 OID 163343)
-- Name: global_user; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE global_user (
    global_user_id uuid NOT NULL,
    course_id uuid,
    course_user_id bigint
);


ALTER TABLE public.global_user OWNER TO postgres;

--
-- TOC entry 182 (class 1259 OID 163583)
-- Name: observed_events; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE observed_events (
    observed_event_id bigint NOT NULL,
    url_id bigint NOT NULL,
    observed_event_timestamp timestamp with time zone,
    observed_event_duration real,
    user_id uuid,
    observed_event_ip character(50),
    observed_event_agent character(512),
    observed_event_os character(50)
);


ALTER TABLE public.observed_events OWNER TO postgres;

--
-- TOC entry 181 (class 1259 OID 163579)
-- Name: observed_events_observed_event_duration_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE observed_events_observed_event_duration_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.observed_events_observed_event_duration_seq OWNER TO postgres;

--
-- TOC entry 2341 (class 0 OID 0)
-- Dependencies: 181
-- Name: observed_events_observed_event_duration_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE observed_events_observed_event_duration_seq OWNED BY observed_events.observed_event_duration;


--
-- TOC entry 179 (class 1259 OID 163573)
-- Name: observed_events_observed_event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE observed_events_observed_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.observed_events_observed_event_id_seq OWNER TO postgres;

--
-- TOC entry 2342 (class 0 OID 0)
-- Dependencies: 179
-- Name: observed_events_observed_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE observed_events_observed_event_id_seq OWNED BY observed_events.observed_event_id;


--
-- TOC entry 180 (class 1259 OID 163577)
-- Name: observed_events_url_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE observed_events_url_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.observed_events_url_id_seq OWNER TO postgres;

--
-- TOC entry 2343 (class 0 OID 0)
-- Dependencies: 180
-- Name: observed_events_url_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE observed_events_url_id_seq OWNED BY observed_events.url_id;


--
-- TOC entry 195 (class 1259 OID 163676)
-- Name: problem_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE problem_types (
    problem_type_id integer NOT NULL,
    problem_type_name character(50)
);


ALTER TABLE public.problem_types OWNER TO postgres;

--
-- TOC entry 196 (class 1259 OID 163681)
-- Name: problems; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE problems (
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
    resource_id uuid
);


ALTER TABLE public.problems OWNER TO postgres;

--
-- TOC entry 186 (class 1259 OID 163621)
-- Name: resource_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE resource_types (
    resource_type_id integer NOT NULL,
    resource_type_content character(128),
    resource_type_medium character(128)
);


ALTER TABLE public.resource_types OWNER TO postgres;

--
-- TOC entry 185 (class 1259 OID 163619)
-- Name: resource_types_resource_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resource_types_resource_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resource_types_resource_type_id_seq OWNER TO postgres;

--
-- TOC entry 2344 (class 0 OID 0)
-- Dependencies: 185
-- Name: resource_types_resource_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resource_types_resource_type_id_seq OWNED BY resource_types.resource_type_id;


--
-- TOC entry 191 (class 1259 OID 163639)
-- Name: resource_urls; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE resource_urls (
    resources_urls_id integer NOT NULL,
    resource_id uuid,
    url_id integer NOT NULL
);


ALTER TABLE public.resource_urls OWNER TO postgres;

--
-- TOC entry 189 (class 1259 OID 163635)
-- Name: resource_urls_resources_urls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resource_urls_resources_urls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resource_urls_resources_urls_id_seq OWNER TO postgres;

--
-- TOC entry 2345 (class 0 OID 0)
-- Dependencies: 189
-- Name: resource_urls_resources_urls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resource_urls_resources_urls_id_seq OWNED BY resource_urls.resources_urls_id;


--
-- TOC entry 190 (class 1259 OID 163637)
-- Name: resource_urls_url_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resource_urls_url_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resource_urls_url_id_seq OWNER TO postgres;

--
-- TOC entry 2346 (class 0 OID 0)
-- Dependencies: 190
-- Name: resource_urls_url_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resource_urls_url_id_seq OWNED BY resource_urls.url_id;


--
-- TOC entry 184 (class 1259 OID 163613)
-- Name: resources; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE resources (
    resource_id uuid NOT NULL,
    resource_name character(256),
    resource_uri character(128),
    resource_type_id integer NOT NULL,
    resource_parent_id uuid,
    resource_child_number uuid,
    resource_release_timestamp date,
    resource_relevant_start_date date,
    resource_relevant_end_date date,
    resource_relevant_week integer
);


ALTER TABLE public.resources OWNER TO postgres;

--
-- TOC entry 183 (class 1259 OID 163611)
-- Name: resources_resource_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resources_resource_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resources_resource_type_id_seq OWNER TO postgres;

--
-- TOC entry 2347 (class 0 OID 0)
-- Dependencies: 183
-- Name: resources_resource_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resources_resource_type_id_seq OWNED BY resources.resource_type_id;


--
-- TOC entry 197 (class 1259 OID 163689)
-- Name: submissions; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE submissions (
    submission_id uuid NOT NULL,
    user_id uuid,
    problem_id uuid,
    submission_timestamp timestamp with time zone,
    submission_attempt_number integer,
    submission_answer text,
    submission_is_submitted boolean,
    submission_ip integer,
    submission_os integer,
    submission_agent integer
);


ALTER TABLE public.submissions OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 163629)
-- Name: urls; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE urls (
    url_id integer NOT NULL,
    course_uuid uuid,
    url character(512)
);


ALTER TABLE public.urls OWNER TO postgres;

--
-- TOC entry 187 (class 1259 OID 163627)
-- Name: urls_url_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE urls_url_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.urls_url_id_seq OWNER TO postgres;

--
-- TOC entry 2348 (class 0 OID 0)
-- Dependencies: 187
-- Name: urls_url_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE urls_url_id_seq OWNED BY urls.url_id;


--
-- TOC entry 178 (class 1259 OID 163348)
-- Name: user_pii; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE user_pii (
    global_user_id uuid,
    birthday date,
    timezone_offset integer,
    username character(64) NOT NULL,
    gender character(10),
    ip character(50),
    country character(50)
);


ALTER TABLE public.user_pii OWNER TO postgres;

--
-- TOC entry 2189 (class 2604 OID 163659)
-- Name: collaboration_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY collaborations ALTER COLUMN collaboration_type_id SET DEFAULT nextval('collaborations_collaboration_type_id_seq'::regclass);


--
-- TOC entry 2177 (class 2604 OID 163336)
-- Name: course_user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY course_user ALTER COLUMN course_user_id SET DEFAULT nextval('course_user_course_user_id_seq'::regclass);


--
-- TOC entry 2178 (class 2604 OID 163337)
-- Name: observing_user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY course_user ALTER COLUMN observing_user_id SET DEFAULT nextval('course_user_observing_user_id_seq'::regclass);


--
-- TOC entry 2179 (class 2604 OID 163338)
-- Name: submitting_user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY course_user ALTER COLUMN submitting_user_id SET DEFAULT nextval('course_user_submitting_user_id_seq'::regclass);


--
-- TOC entry 2180 (class 2604 OID 163339)
-- Name: collaborating_user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY course_user ALTER COLUMN collaborating_user_id SET DEFAULT nextval('course_user_collaborating_user_id_seq'::regclass);


--
-- TOC entry 2181 (class 2604 OID 163340)
-- Name: feedback_user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY course_user ALTER COLUMN feedback_user_id SET DEFAULT nextval('course_user_feedback_user_id_seq'::regclass);


--
-- TOC entry 2182 (class 2604 OID 163586)
-- Name: observed_event_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY observed_events ALTER COLUMN observed_event_id SET DEFAULT nextval('observed_events_observed_event_id_seq'::regclass);


--
-- TOC entry 2183 (class 2604 OID 163588)
-- Name: url_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY observed_events ALTER COLUMN url_id SET DEFAULT nextval('observed_events_url_id_seq'::regclass);


--
-- TOC entry 2185 (class 2604 OID 163624)
-- Name: resource_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resource_types ALTER COLUMN resource_type_id SET DEFAULT nextval('resource_types_resource_type_id_seq'::regclass);


--
-- TOC entry 2187 (class 2604 OID 163642)
-- Name: resources_urls_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resource_urls ALTER COLUMN resources_urls_id SET DEFAULT nextval('resource_urls_resources_urls_id_seq'::regclass);


--
-- TOC entry 2188 (class 2604 OID 163643)
-- Name: url_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resource_urls ALTER COLUMN url_id SET DEFAULT nextval('resource_urls_url_id_seq'::regclass);


--
-- TOC entry 2184 (class 2604 OID 163616)
-- Name: resource_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resources ALTER COLUMN resource_type_id SET DEFAULT nextval('resources_resource_type_id_seq'::regclass);


--
-- TOC entry 2186 (class 2604 OID 163632)
-- Name: url_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY urls ALTER COLUMN url_id SET DEFAULT nextval('urls_url_id_seq'::regclass);


--
-- TOC entry 2219 (class 2606 OID 164013)
-- Name: assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id);


--
-- TOC entry 2211 (class 2606 OID 163673)
-- Name: collaboration_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY collaboration_types
    ADD CONSTRAINT collaboration_types_pkey PRIMARY KEY (collaboration_type_id);


--
-- TOC entry 2209 (class 2606 OID 163668)
-- Name: collaborations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY collaborations
    ADD CONSTRAINT collaborations_pkey PRIMARY KEY (collaboration_id);


--
-- TOC entry 2191 (class 2606 OID 163322)
-- Name: course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY course
    ADD CONSTRAINT course_pkey PRIMARY KEY (course_id);


--
-- TOC entry 2193 (class 2606 OID 163342)
-- Name: course_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY course_user
    ADD CONSTRAINT course_user_pkey PRIMARY KEY (course_user_id);


--
-- TOC entry 2195 (class 2606 OID 163347)
-- Name: global_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY global_user
    ADD CONSTRAINT global_user_pkey PRIMARY KEY (global_user_id);


--
-- TOC entry 2199 (class 2606 OID 163592)
-- Name: observed_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY observed_events
    ADD CONSTRAINT observed_events_pkey PRIMARY KEY (observed_event_id);


--
-- TOC entry 2213 (class 2606 OID 163680)
-- Name: problem_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY problem_types
    ADD CONSTRAINT problem_types_pkey PRIMARY KEY (problem_type_id);


--
-- TOC entry 2215 (class 2606 OID 163688)
-- Name: problems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY problems
    ADD CONSTRAINT problems_pkey PRIMARY KEY (problem_id);


--
-- TOC entry 2203 (class 2606 OID 163626)
-- Name: resource_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY resource_types
    ADD CONSTRAINT resource_types_pkey PRIMARY KEY (resource_type_id);


--
-- TOC entry 2207 (class 2606 OID 163645)
-- Name: resource_urls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY resource_urls
    ADD CONSTRAINT resource_urls_pkey PRIMARY KEY (resources_urls_id);


--
-- TOC entry 2201 (class 2606 OID 163618)
-- Name: resources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (resource_id);


--
-- TOC entry 2217 (class 2606 OID 163696)
-- Name: submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (submission_id);


--
-- TOC entry 2205 (class 2606 OID 163634)
-- Name: urls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY urls
    ADD CONSTRAINT urls_pkey PRIMARY KEY (url_id);


--
-- TOC entry 2197 (class 2606 OID 163352)
-- Name: user_pii_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace:
--

ALTER TABLE ONLY user_pii
    ADD CONSTRAINT user_pii_pkey PRIMARY KEY (username);


--
-- TOC entry 2333 (class 0 OID 0)
-- Dependencies: 5
-- Name: public; Type: ACL; Schema: -; Owner: Gery
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM "Gery";
GRANT ALL ON SCHEMA public TO "Gery";
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2014-12-07 18:51:03 CET

--
-- PostgreSQL database dump complete
--

CREATE INDEX user_event_duration_idx ON observed_events (user_id, observed_event_duration NULLS FIRST);
