# The Lanalytics Service

Xikolo's Learning Analytics Engine

## Dependencies

* [Elasticsearch 7](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html)
* [MinIO](https://github.com/minio/minio) (for reports)

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

## Lanalytics Data Processing Library

Most of the code for the processing can be found in the folder `lib/lanalytics/processing/`.

The starting point for the data processing can be found in the initializer `lanalytics_processing_pipelines.rb`. This initializer will look for setup the data sources and processing pipelines. The data sources are defined in `config/datasources/*.yml`. The pipelines are defined in `lib/lanalytics/processing/pipelines/*.prb`.

Pipelines and data sources can be activated in the `config/lanalytics_pipeline_flipper.yml`.

Each pipeline consists of extractors, transformers and loaders, where each is responsible for a certain processing task, e.g. anonymization and data type processing. The implementation of the different classes can be found in the `lib/lanalytics/processing/{extractor,transformer,loader}/*.rb`.

## How to include a new pipeline?

* Add new pipeline file in `config/lanalytics_pipeline_flipper.yml`
* Implement the pipeline file in a new `lib/lanalytics/processing/pipelines/new_pipelines.prb`
* Define all the desired pipelines like in `lib/lanalytics/processing/pipelines/exp_events_pipeline.prb`
* Implement new transformers when necessary
* Register the event type in the `config/msgr.rb` file.

## Event Tracking

Our event schema is close to xAPI: a `user` does `verb` for `resource` in `context` with `result`. All events are stored redundant in Elasticsearch and Postres.

### Data Schema Updates

The Elasticsearch data schema can be found in `config/elasticsearch/exp_events.json`. It needs to be updated when new fields are added. Make sure to update [pillars](https://gitlab.hpi.de/xopic/xikolo/pillars/-/blob/master/site/default/includes/elasticsearch/template_exp.sls) as well and increase the version number there.

### Web Frontend

See `web/app/assets/lanalytics/common.js#track`.

Usage:
```
import track from './common';
[...]
track('my_verb', resource.uuid, resource.type, context);
```

### Ember Frontend

See `web/frontend/app/services/tracking.js#track`

Usage:
```
tracking: service(),
[...]
this.get('tracking').track({
  verb: 'my_verb',
  resource: resource.uuid,
  resourceType: resource.type,
  context,
});
```

### API

The Web Service and Ember Frontend track events via our API, which is also used by our native apps. The API endpoint documentation can be found here: https://dev.xikolo.de/api-docs/#endpoint-tracking-events.

## Link Tracking

We can track internal and external links of our web application. The data is stored in Elasticsearch.

The Elasticsearch data schema can be found in `config/elasticsearch/link_tracking_events.json`. If updated, make sure to update in pillars as well and increase the version number.

A good starting point for this is `web/app/controllers/concerns/tracks_referrers.rb`.

## Query Elasticsearch Events

Get familiar with the [Elasticsearch API](elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html) and a HTTP client, either CLI or GUI-based (e.g., [Postman](https://www.postman.com/)).

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

## Metrics

All available metrics are self-documented and can be retrieved by directly calling the index endpoint, i.e., http://0.0.0.0:5900/metrics.

## Reports

To generate reports, a user must have the `lanalytics.report.admin` role. Check the [Reporting Permission](https://ares.epic.hpi.uni-potsdam.de/epicjira/confluence/display/XIKOLO/Reporting+Permission) page on how to grant this. And make sure MinIO runs properly.
