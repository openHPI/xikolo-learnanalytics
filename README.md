# The Lanalytics Service

The lanalytics service is responsible for the processing of tracked learner interaction events, reports, and course statistics. Another unfinished feature is quality control alerting.

## Dependencies

* PostgreSQL and RabbitMQ, just like our other services.
* [Elasticsearch 7](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html)
* [MinIO](https://github.com/minio/minio), for storing reports.

## Setup

* `git clone git@dev.xikolo.de:xikolo/lanalytics.git`
* `cd lanalytics`
* `bundle install`
* `bundle exec rake db:drop db:create db:migrate`
* `bundle exec rake db:seed`
* `bundle exec rake elastic:setup`
* `bundle exec rake s3:setup`
  * Minio must be running. If Minio uses default port and credentials, no further setup is needed.
  * If you configured Minio differently, you can override the defaults from `app/xikolo.yml` in `config/xikolo.development.yml`.
* `bundle exec rails s -p 5900`

To get a clean state during development, run:

* `bundle exec rake db:reset`
* `bundle exec rake sidekiq:clear`
* `bundle exec rake msgr:drain`

## Lanalytics Event Processing Library

Most of the code for the processing can be found in the folder `lib/lanalytics/processing/`.

The starting point for the data processing can be found in the rails initializer `config/initializers/01_lanalytics_processing_pipelines.rb`. This initializer will setup the data sources and processing pipelines. The data sources are defined in `config/datasources/*.yml`. The pipelines are defined in `lib/lanalytics/processing/pipelines/*.prb`.

Pipelines and data sources can be activated in the `config/lanalytics_pipeline_flipper.yml`.

Each pipeline consists of extractor, transformer and loader steps (ETL process), where each is responsible for a certain processing task, e.g., anonymization and data type processing. The implementation of the different classes can be found in the `lib/lanalytics/processing/{extractor,transformer,loader}/*.rb`.

### How to include a new pipeline?

* Implement the new pipeline in `lib/lanalytics/processing/pipelines/{new_pipelines}.prb`
* Define all the desired steps like in `lib/lanalytics/processing/pipelines/exp_events_pipeline.prb` or implement new ETL steps.
* Enable the new pipeline in `config/lanalytics_pipeline_flipper.yml`
* If you consume new messages, register them in `config/msgr.rb`

## Elasticsearch Schema Mapping

Get yourself familiar how [mapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html) in Elasticsearch works:

>Mapping is the process of defining how a document, and the fields it contains, are stored and indexed.

Our Elasticsearch mapping file and additional settings can be found in `config/elasticsearch/exp_events.json`. **It needs to be updated every time when new fields are added.** On production, the setting [`strict`](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic.html#dynamic-parameters) is used for the mapping:

>If new fields are detected, an exception is thrown and the document is rejected. New fields must be explicitly added to the mapping.

To do this, update the mapping file in this repo and make sure to copy the same changes to [pillars](https://lab.xikolo.de/devops/salt/xikolo/blob/main/pillar/site/default/includes/elasticsearch/template_exp.sls) as well and increase the version number there. To update your local setup, run `bundle exec rake elastic:reset`—but be careful, that deletes the index first and with it all data.

Note: Using `dynamic` mapping would require a complete [re-indexing](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html) if a field was added automatically and its data type should be changed afterwards. Data types of already known fields of an index cannot be changed otherwise. A simple update of the mapping is only possible if the field has not been added yet. To avoid auto-updates of the mapping by new events, we use the `strict` mapping in production.

## Event Tracking

Our event schema is close to xAPI: a `user` does `verb` for `resource` in `context` with `result`. All events are stored redundant in Elasticsearch and Postres.

### Web Frontend

See `web/app/assets/lanalytics/common.js#track`.

Usage:
```
import track from './common';
[...]
track('my_verb', resource.uuid, resource.type, context);
```

### API

The web service tracks events via our API, which is also used by our native mobile apps. The API endpoint documentation can be found here: https://dev.xikolo.de/api-docs/#endpoint-tracking-events.

## Link Tracking

We can track internal and external links of our web application. The data is stored in Elasticsearch.

The Elasticsearch data schema can be found in `config/elasticsearch/link_tracking_events.json`. If updated, make sure to update in pillars as well and increase the version number.

A good starting point for this is `web/app/controllers/concerns/tracks_referrers.rb`.

## Metrics

All available metrics are self-documented and can be retrieved by directly calling the index endpoint, i.e., http://0.0.0.0:5900/metrics. The code for metrics is placed under `lib/lanalytics/metric`.

### Query Elasticsearch Events

A majority of the metrics use Elasticsearch. Get familiar with the [Elasticsearch API](https://elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html) and a HTTP client, either CLI or GUI-based (e.g., [Postman](https://www.postman.com/)).

As a warm-up, query all available verbs (aka event types):
```
POST 0.0.0.0:9200/_search

{
  "size": 0,
  "aggregations": {
    "verbs": {
      "terms": {
        "size": 10000,
        "field": "verb"
      }
    }
  }
}
```

Get the 10 most recent events with *verb*:
```
POST 0.0.0.0:9200/_search

{
  "size": 10,
  "sort": {
    "timestamp": {
      "order":"desc"
    }
  },
  "query": {
    "bool": {
      "must": [
        { "match": { "verb": "visited_item" } }
      ]
    }
  }
}
```

## Reports

The code for reports is placed under `app/models/reports`. The report UI is generated dynamically based on the exposed `form_data`. Check the existing reports and their tests for examples.

To generate reports:
* MinIO must run properly to store reports in an S3 bucket.
* Available reports must be configured to be displayed in the web client under http://0.0.0.0:3000/reports. The default configuration can be found under `app/xikolo.yml` (see `reports.types`).
* A user must have the `lanalytics.report.admin` role to access this page. Check the [Reporting Permission](https://xikolo.pages.xikolo.de/docs/reporting/permissions/) documentation on how to grant permission.
