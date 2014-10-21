class ResearchCasesController < ApplicationController
  before_action :set_research_case, only: [:show, :edit, :update, :destroy]

  # GET /research_cases
  # GET /research_cases.json
  def index
    @research_cases = ResearchCase.all
  end

  # GET /research_cases/1
  # GET /research_cases/1.json
  def show
  end

  # GET /research_cases/new
  def new
    @research_case = ResearchCase.new
  end

  # GET /research_cases/1/edit
  def edit
  end

  # POST /research_cases
  # POST /research_cases.json
  def create
    @research_case = ResearchCase.new(research_case_params)

    respond_to do |format|
      if @research_case.save
        format.html { redirect_to @research_case, notice: 'Research case was successfully created.' }
        format.json { render :show, status: :created, location: @research_case }
      else
        format.html { render :new }
        format.json { render json: @research_case.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /research_cases/1
  # PATCH/PUT /research_cases/1.json
  def update
    respond_to do |format|
      if @research_case.update(research_case_params)
        format.html { redirect_to @research_case, notice: 'Research case was successfully updated.' }
        format.json { render :show, status: :ok, location: @research_case }
      else
        format.html { render :edit }
        format.json { render json: @research_case.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /research_cases/1
  # DELETE /research_cases/1.json
  def destroy
    @research_case.destroy
    respond_to do |format|
      format.html { redirect_to research_cases_url, notice: 'Research case was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_research_case
      @research_case = ResearchCase.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def research_case_params
      params.require(:research_case).permit(:title)
    end
end
