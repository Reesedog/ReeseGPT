require 'net/http'
require 'uri'
require 'json'
class OpenaiService
def request_openai(disability_input)
  # 设置 API 端点和你的引擎ID
  uri = URI.parse("https://api.openai.com/v1/engines/ada:ft-personal-2023-08-10-06-53-18/completions") # 替换 YOUR_ENGINE_ID

  # 创建一个 POST 请求
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "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" # 替换 YOUR_API_KEY
  request["Content-Type"] = "application/json"
  request.body = JSON.dump({
    "prompt" => disability_input,
    "max_tokens" => 150
  })

  # 使用 Net::HTTP 发送请求
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  # 解析响应并提取建议的 plan
  json_response = JSON.parse(response.body)
  suggested_plan = json_response["choices"].first["text"].strip

  return suggested_plan
end
end