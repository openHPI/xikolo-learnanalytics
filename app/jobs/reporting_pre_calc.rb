class ReportingPreCalc
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform
    # get oldest from que but min age 30 minutes

    # remove entry from que
    # recalculate his metrics for the specific course

    #


  end
end