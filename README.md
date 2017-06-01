# The Lanalytics Service

Xikolo's Learning Analytics Engine

## Lanalytics Data Processing Library

Most of the code for the processing can be found in the folder `lib/lanalytics/processing/`.

The starting point for the data processing can be found in the initializer `lanalytics_processing_pipelines.rb`. This initializer will look for setup the data sources and processing pipelines. The data sources are defined in `config/datasources/*.yml`. The pipelines are defined in `lib/lanalytics/processing/pipelines/*.prb`.

Pipelines and data sources can be activated in the `config/lanalytics_pipeline_flipper.yml`.

Each pipeline consists of extractors, transformers and loaders, where each is responsible for a certain processing task, e.g. anonymization and data type processing. The implementation of the different classes can be found in the `lib/lanalytics/processing/{extractor,transformer,loader}/*.rb`.

## Installation - Prerequisite

Do not forget to perform a `bundle install`!
 
At the moment, we have 2 data sources (databases) which have to be installed to use the Lanalytics Service completely:

* PostgreSQL (already part of the xikolo infrastructure)
* [ElasticSearch](https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.5.0.zip)

The service is started as a normal rails app, i.e. `rails s`

## How to include a new pipeline?

* Add new pipeline file in `config/lanalytics_pipeline_flipper.yml`
* Implement the pipeline file in a new `lib/lanalytics/processing/pipelines/new_pipelines.prb`
* Define all the desired pipelines like in `lib/lanalytics/processing/pipelines/exp_api_pipeline.prb`
* Implement new transformers when necessary
* Register the event type in the `config/msgr.rb` file.
