# The openHPI Learning Analytics Service

The learning analytics service (*"Lanalytics"*) of the [openHPI](https://open.hpi.de/) platform.

This service was developed to enhance the functionality of the [core application](https://github.com/openHPI/xikolo-core/) and is intended to be operated alongside it.
It is used for processing tracked learner interaction events, enables reports, and provides specific course statistics.

## License

Copyright © Hasso Plattner Institute for Digital Engineering gGmbH

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Dependencies

* PostgreSQL and RabbitMQ
* [Elasticsearch 7](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html)
* [MinIO](https://github.com/minio/minio), for storing reports.

## Setup

1. Clone this repository.
2. Change into the directory.
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Prepare the database, Elasticsearch, and Minio:
   ```bash
   bundle exec rake db:drop db:prepare
   bundle exec rake elastic:setup
   bundle exec rake s3:setup # Ensure Minio is running
   ```
   - If Minio uses the default port and credentials, no further setup is needed.
   - For custom Minio configurations, override the defaults in `config/xikolo.development.yml`. (Refer to `app/xikolo.yml` for guidance.)
5. Start the Rails server:
   ```bash
   bundle exec rails s -p 5900
   ```

To get a clean state during development, run:

```bash
bundle exec rake db:reset
bundle exec rake sidekiq:clear
bundle exec rake msgr:drain
```

## Event processing

Most of the code for processing events can be found in `lib/lanalytics/processing/`.

The starting point for the data processing can be found in the Rails initializer `config/initializers/01_lanalytics_processing_pipelines.rb`.
This initializer will setup the data sources and processing pipelines.
* The data sources are defined in `config/datasources/*.yml`.
* The pipelines are defined in `lib/lanalytics/processing/pipelines/*.prb`.

Pipelines and data sources can be activated in the `config/lanalytics_pipeline_flipper.yml`.

Each pipeline consists of extractor, transformer, and loader steps (ETL process), where each is responsible for a certain processing task (e.g., anonymization and data type processing).
The implementation of the different classes can be found in `lib/lanalytics/processing/{extractor,transformer,loader}/*.rb`.

### How to include a new pipeline?

1. Implement the new pipeline in `lib/lanalytics/processing/pipelines/{new_pipelines}.prb`.
2. Define all the desired steps like in `lib/lanalytics/processing/pipelines/exp_events_pipeline.prb` or implement new ETL steps.
3. Enable the new pipeline in `config/lanalytics_pipeline_flipper.yml`.
4. If you consume new messages, register them in `config/msgr.rb`.

## Elasticsearch schema mapping

Get yourself familiar how [mapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html) in Elasticsearch works:

> Mapping is the process of defining how a document, and the fields it contains, are stored and indexed.

Our Elasticsearch mapping file and additional settings can be found in `config/elasticsearch/exp_events.json`.
**It needs to be updated every time when new fields are added.**
On production, the setting [`strict`](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic.html#dynamic-parameters) is used for the mapping:

> If new fields are detected, an exception is thrown and the document is rejected. New fields must be explicitly added to the mapping.

To do this, update the mapping file in this repo and make the same changes to the *Elasticsearch* index template mapping while increasing the version number there.
To update your local setup, run `bundle exec rake elastic:reset` — but be careful as this deletes the index first and with it all the data.

Note: Using `dynamic` mapping would require a complete [re-indexing](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html) if a field was added automatically and its data type should be changed afterwards.
Data types of already known fields of an index cannot be changed otherwise.
A simple update of the mapping is only possible if the field has not been added yet.
To avoid auto-updates of the mapping by new events, we recommend using the `strict` mapping in production.

## Event tracking

The used event schema is close to xAPI: a `user` does `verb` for `resource` in `context` with `result`.
All events are stored redundantly in Elasticsearch and Postgres.

### Capturing events

See `app/assets/legacy/lanalytics/common.js#track` in the core application for details.

Usage:
```js
import track from './common';
// ...
track('my_verb', resource.uuid, resource.type, context);
```

## Link tracking

Internal and external links of the web application can be tracked.
The data is stored in Elasticsearch.

The Elasticsearch data schema can be found in `config/elasticsearch/link_tracking_events.json`.
If updated, make sure to update in pillars as well and increase the version number.

A good starting point for this is `web/app/controllers/concerns/tracks_referrers.rb`.

## Metrics

All available metrics are self-documented and can be retrieved from the index endpoint, i.e., http://0.0.0.0:5900/metrics.
The code for metrics is placed in `lib/lanalytics/metric/`.

### Query Elasticsearch events

A majority of the metrics use Elasticsearch.
Get familiar with the [Elasticsearch API](https://elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html) and a HTTP client, either CLI or GUI-based (e.g., [Postman](https://www.postman.com/)).

#### Samples
Query all available verbs (aka. event types): `POST 0.0.0.0:9200/_search`

```json
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

Get the 10 most recent events with *verb*: `POST 0.0.0.0:9200/_search`

```json
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

The code for reports is placed in `app/models/reports/`.
The report UI is generated dynamically based on the exposed `form_data`.
Check the existing reports and their tests for examples.

To generate reports:
- MinIO must run properly to store reports in a S3 bucket.
- Available reports must be configured to be displayed in the core application. The default configuration can be found in `app/xikolo.yml` (see `reports.types`).
- A user must have the `lanalytics.report.admin` role to access this page.
