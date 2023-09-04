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
    @plan = current_user.plans.build(plan_params)

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
    # 设置 API 端点
    uri = URI("https://api.openai.com/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer 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" # 上传github时记得删除
    request["Content-Type"] = "application/json"

    messages = [{
      "role" => "user",
      "content" => disability_input,
    }]

    request.body = JSON.dump({
      "model" => "gpt-4",
      "messages" => messages,
      "temperature" => 0.7,
    })

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    # 解析响应并提取建议的 plan
    json_response = JSON.parse(response.body)
    puts response.body
    suggested_plan = json_response["choices"][0]["message"]["content"]

    return suggested_plan
  end
end
