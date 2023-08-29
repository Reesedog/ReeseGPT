require "net/http"

class PlansController < ApplicationController
  before_action :set_plan, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :correct_user, only: [:edit, :update, :destroy]

  # GET /plans or /plans.json
  def index
    @plans = Plan.all
  end

  # GET /plans/1 or /plans/1.json
  def show
  end

  # GET /plans/new
  def new
    # @plan = Plan.new
    @plan = current_user.plans.build
  end

  # GET /plans/1/edit
  def edit
  end

  def correct_user
    @plan = current_user.plans.find_by(id: params[:id])
    redirect_to plans_path, notice: "Not authorizedto edit this plan" if @plan.nil?
  end

  # POST /plans or /plans.json
  def create
    # @plan = Plan.new(plan_params)
    @plan =current_user.plans.build(plan_params)

    suggested_plan = request_openai(@plan.disability)
    @plan.plan = suggested_plan

    respond_to do |format|
      if @plan.save
        format.html { redirect_to plan_url(@plan), notice: "Plan was successfully created." }
        format.json { render :show, status: :created, location: @plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plans/1 or /plans/1.json
  def update
    respond_to do |format|
      if @plan.update(plan_params)
        format.html { redirect_to plan_url(@plan), notice: "Plan was successfully updated." }
        format.json { render :show, status: :ok, location: @plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plans/1 or /plans/1.json
  def destroy
    @plan.destroy

    respond_to do |format|
      format.html { redirect_to plans_url, notice: "Plan was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_plan
    @plan = Plan.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def plan_params
    params.require(:plan).permit(:id, :name, :disability, :support, :goal, :plan, :user_id)
  end

  def request_openai(disability_input)
    # 设置 API 端点和你的引擎ID
    uri = URI.parse("https://api.openai.com/v1/completions") # 替换 YOUR_ENGINE_ID

    # 创建一个 POST 请求
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer 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" # 替换 YOUR_API_KEY
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "prompt" => disability_input,
      "model" => "ada:ft-personal-2023-08-10-06-53-18",
    })

    # 使用 Net::HTTP 发送请求
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    # 解析响应并提取建议的 plan
    json_response = JSON.parse(response.body)
    puts response.body
    suggested_plan = json_response["choices"].first["text"].strip

    return suggested_plan
  end
end
