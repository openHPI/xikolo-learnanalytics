# The LAnalytics Service - README

The LAnalytics Service consists of two main elements:

- The extensible data processing library that can be found in lib/lanalytics/processing
- The LAnalytics Web UI which is a classic Rails App with frontend 

### LAnalytics Data Processing Library

Most of the code for the processing can be found in the folder `lib/lanalytics/processing/`.

The starting point for the data processing can be found in the initializer 'lanalytics_processing_pipelines.rb'. This initializer will look for setup the data sources and (processing) pipelines. The data sources are defined in `config/datasources/*.yml`. The pipelines are defined in `lib/lanalytics/processing/pipelines/*.prb`. It is here where all the pipelines are defined.

Pipelines and DataSources can be activated in the `config/lanalytics_pipeline_flipper.yml`!!!

Each pipeline consists of extractors, transformers and loaders, where each is responsible for a certain processing task, e.g. anonymization and data type processing. The implementation of the different classes can be found in the 'lib/lanalytics/processing/{extractor,transformer,loader}/*.rb'.

### LAnalytics Web UI
It is a normal Rails App with models, controllers and views. You should be able to get your head around it without any major trouble.


## Installation - Prerequisite

Do not forget to perform a `bundle install`!
 
At the moment, we have three data sources (databases) which have to be installed to use the LAnalytics Service completely:

* [Neo4j](http://neo4j.com/artifact.php?name=neo4j-community-2.1.7-unix.tar.gz)
* PostgreSQL (already part of the xikolo infrastructure)
* [ElasticSearch](https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.5.0.zip)

The service is started as a normal rails app, i.e. `rails s` 


## How to include a new pipeline?

The [commit](https://dev.xikolo.de/gitlab/xikolo/lanalytics/commit/09c4ac9c112e1662fd38917605c005a1319978fd) gives an overview of the changes:

* Add new pipeline file in `config/lanalytics_pipeline_flipper.yml`
* Implement the pipeline file in a new `lib/lanalytics/processing/pipelines/new_pipelines.prb`
* Define all the desired pipelines like in `lib/lanalytics/processing/pipelines/exp_api_pipeline.prb`
* Implement new transformers when necessary
* Register the event type in the `config/msgr.rb` file. 




## How to track new events?

New events are published into the rabbitmq with the Msgr gem. You only need to define a routing key and include that you want to track. We recommend to define the routing key as follows: 'xikolo.<service_name>.<domain_model>.<action>'; for example, 'xikolo.web.exp_event.create' or 'xikolo.account.user.update'.

In order to consume the published event, you need to register the routing key in the `config/msgr.rb` file.
Make sure that there are some registered pipelines with the same name as the routing key, but different schemas.

The lanalyics-rails gem contains some utilities that help tracking user events in the frontend with javascript. 



## How to access the Analytics Stores?

Looking into the folder `config/datasources` reveals the connection details to the available Analytics Stores. With this information, it is possible to access the Analytics Stores with the designated tools. 

For some Analytics Stores, certain url endpoints (routes) have been established to provide dicrect access to the data. 


## Metrics

### Pinboard Posting Activity

The pinboard posting activity counts how often a user asks, answers and
comments questions and discussions in the pinboard of a course.

Verbs: ASKED_QUESTION, ANSWERED_QUESTION, COMMENTED

### Pinboard Watch Count

The pinboard watch count denotes the number of viewed questions and
discussions of a user.

Verb: WATCHED_QUESTION

### Pinboard Activity

This pinboard activity combines pinboard posting activity and pinboard
watch count. Considering the different amounts of effort, a weighting is
applied. The posting activity contributes with a ratio of 90%, while the
watch count is weighted with 10%.

### Question Response Time

The question response time denotes how long after a question was asked,
a user answered the question. To compute this metric all Experience API
statements with the verb ANSWERED_QUESTION are retrieved for a user,
the matching ASKED_QUESTION statement is queried and the
average difference between their timestamps is computed. Since not all
users answer questions in the specified time frame, nil values may be retrieved.

### Visit Count

The visit count denotes how many items a user visited, including videos,
selftests and text parts.

Verbs: VISITED

### Video Visit Count

The video visit count denotes the number of visited videos per user.

Verb: VISITED  
Filter: content_type == video

### Course Activity

The course activity summarizes the aforementioned metrics to measure the
overall activity of a user in a course. The pinboard activity is
weighted with 50%, while the visit count is included without weight.

### Course Points

After the end of a course the number of points are persisted and the
quantile of the users’ points is calculated. For each enrollment a
*completed* event is emitted. The course points metric returns the number of
points a user received in a specified course.

Verbs: COURSE_COMPLETED
