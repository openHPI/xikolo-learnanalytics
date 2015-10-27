class ResearchCasesController < ApplicationController
  respond_to :html

  before_action :set_research_case, only: [:show, :access_datasource, :edit, :update, :add_contributer, :destroy]

  # GET /research_cases
  def index
    @research_cases = current_user.research_cases
  end

  # GET /research_cases/1
  def show
    @available_datasources = Datasource.all
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
    
    unless @research_case.save
      render :new
    end

    @research_case.add_contributer(current_user)

    if @research_case.save
      redirect_to @research_case, notice: 'Research case was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /research_cases/1
  # PATCH/PUT /research_cases/1.json
  def update
    respond_to do |format|
      if @research_case.update(research_case_params)
        format.html { redirect_to @research_case, notice: 'Research case was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def add_contributer
    contributer_email = params[:email]
    new_contributer = User.find_by(email: contributer_email)
    if new_contributer.nil?
      redirect_to research_cases_url, flash: {danger: "Contributer with email '#{contributer_email}' is not available in the system and thus could not be added to Research Case ##{@research_case.id}."}
      return
    end

    @research_case.add_contributer(new_contributer)
    redirect_to research_cases_url, notice: "Contributer with email '#{new_contributer.email}' was added successfully to Research Case ##{@research_case.id}."
  end

  # DELETE /research_cases/1
  def destroy
    @research_case.destroy
    respond_to do |format|
      format.html { redirect_to research_cases_url, notice: 'Research case was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def access_datasource
    @datasource = Datasource.find_by(key: params[:datasource_key])
    @datasource.setup_channels(current_user)
  end

  def datasource_accessed
    @research_case = ResearchCase.find_by(id: params[:research_case_id])
    @user = User.find_by(id: params[:user_id])
    @datasource = Datasource.find_by(key: params[:datasource_key])
    
    channel_clazz = params[:channel][:class_name].constantize
    @channel = channel_clazz.load(params[:channel].to_json)

    # Prepare the connection to the datasource
    @channel.access_channel_for(@user, @datasource, @research_case)

    DatasourceAccess.create(
      research_case: @research_case,
      user: @user,
      datasource: @datasource,
      channel: @channel
    )

    render json: {status: 'ok'}
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_research_case
      @research_case = ResearchCase.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def research_case_params
      params.require(:research_case).permit(:title, :description)
    end
end
