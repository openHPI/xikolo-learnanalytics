class LanalyticsDatasourcesController < ApplicationController
  before_action :set_lanalytics_datasource, only: [:show, :edit, :update, :destroy]

  # GET /lanalytics_datasources
  # GET /lanalytics_datasources.json
  def index
    @lanalytics_datasources = LanalyticsDatasource.all
  end

  # GET /lanalytics_datasources/1
  # GET /lanalytics_datasources/1.json
  def show
  end

  # GET /lanalytics_datasources/new
  def new
    @lanalytics_datasource = LanalyticsDatasource.new
  end

  # GET /lanalytics_datasources/1/edit
  def edit
  end

  # POST /lanalytics_datasources
  # POST /lanalytics_datasources.json
  def create
    @lanalytics_datasource = LanalyticsDatasource.new(lanalytics_datasource_params)

    respond_to do |format|
      if @lanalytics_datasource.save
        format.html { redirect_to @lanalytics_datasource, notice: 'Lanalytics datasource was successfully created.' }
        format.json { render :show, status: :created, location: @lanalytics_datasource }
      else
        format.html { render :new }
        format.json { render json: @lanalytics_datasource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lanalytics_datasources/1
  # PATCH/PUT /lanalytics_datasources/1.json
  def update
    respond_to do |format|
      if @lanalytics_datasource.update(lanalytics_datasource_params)
        format.html { redirect_to @lanalytics_datasource, notice: 'Lanalytics datasource was successfully updated.' }
        format.json { render :show, status: :ok, location: @lanalytics_datasource }
      else
        format.html { render :edit }
        format.json { render json: @lanalytics_datasource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lanalytics_datasources/1
  # DELETE /lanalytics_datasources/1.json
  def destroy
    @lanalytics_datasource.destroy
    respond_to do |format|
      format.html { redirect_to lanalytics_datasources_url, notice: 'Lanalytics datasource was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lanalytics_datasource
      @lanalytics_datasource = LanalyticsDatasource.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lanalytics_datasource_params
      params.require(:lanalytics_datasource).permit(:name, :root_url)
    end
end
