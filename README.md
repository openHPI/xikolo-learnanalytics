# The Lanalytics Service

Xikolo's Learning Analytics Engine

## Setup

* `git clone git@dev.xikolo.de:xikolo/lanalytics.git`
* `cd lanalytics`
* `bundle install`
* `bundle exec rake db:drop db:create db:migrate`
* `bundle exec rake db:seed`
* install elasticsearch  
  * `brew install elasticsearch@5.6` (macOS)
  * `...` (Debian / Ubuntu)
* start elasticsearch
  * `brew services start elasticsearch@5.6` (macOS)
  * `...` (Debian / Ubuntu)
* `bundle exec rake elastic:setup`
* `bundle exec rails s -p 5900`

## Lanalytics Data Processing Library

Most of the code for the processing can be found in the folder `lib/lanalytics/processing/`.

The starting point for the data processing can be found in the initializer `lanalytics_processing_pipelines.rb`. This initializer will look for setup the data sources and processing pipelines. The data sources are defined in `config/datasources/*.yml`. The pipelines are defined in `lib/lanalytics/processing/pipelines/*.prb`.

Pipelines and data sources can be activated in the `config/lanalytics_pipeline_flipper.yml`.

Each pipeline consists of extractors, transformers and loaders, where each is responsible for a certain processing task, e.g. anonymization and data type processing. The implementation of the different classes can be found in the `lib/lanalytics/processing/{extractor,transformer,loader}/*.rb`.

## How to include a new pipeline?

* Add new pipeline file in `config/lanalytics_pipeline_flipper.yml`
* Implement the pipeline file in a new `lib/lanalytics/processing/pipelines/new_pipelines.prb`
* Define all the desired pipelines like in `lib/lanalytics/processing/pipelines/exp_api_pipeline.prb`
* Implement new transformers when necessary
* Register the event type in the `config/msgr.rb` file.
