module Ollama
  # Manages health checks and status monitoring of the Ollama server.
  class HealthChecker
    attr_reader :consecutive_failures, :model_pull_detected

    def initialize(client, security_config)
      @client = client
      @security_config = security_config
      @consecutive_failures = 0
      @last_health_check = Time.now
      @model_pull_detected = false
      @lock = Mutex.new
    end

    def server_healthy?
      @lock.synchronize do
        # Only check health if enough time has passed since last check
        interval = @security_config.dig(:server_health, :health_check_interval)
        return true if Time.now - @last_health_check < interval
        @last_health_check = Time.now
      end

      response = @client.get("tags")
      if response&.is_a?(Net::HTTPSuccess)
        @consecutive_failures = 0
        true
      else
        @consecutive_failures += 1
        puts "⚠️ [HealthChecker] Server health check failed (failure ##{@consecutive_failures})."
        false
      end
    end

    def should_attempt_request?
      max_failures = @security_config.dig(:server_health, :max_consecutive_failures)
      return true if @consecutive_failures < max_failures

      if server_healthy?
        puts "✅ [HealthChecker] Server health restored."
        true
      else
        puts "⚠️ [HealthChecker] Server appears unhealthy, skipping request."
        false
      end
    end

    def detect_model_pull
        response = @client.get("ps")
        return false unless response&.is_a?(Net::HTTPSuccess)

        begin
            processes = JSON.parse(response.body)
            process_list = processes.is_a?(Hash) ? processes.values.flatten : Array(processes)

            valid_processes = process_list.select { |p| p.is_a?(Hash) && !p.empty? }

            pulling = valid_processes.any? do |p|
                p["name"]&.include?("pull") || p["cmd"]&.include?("pull")
            end

            if pulling && !@model_pull_detected
                puts "📥 [HealthChecker] Model pull detected - extending timeouts."
                @model_pull_detected = true
            elsif !pulling && @model_pull_detected
                puts "✅ [HealthChecker] Model pull completed - timeouts restored."
                @model_pull_detected = false
            end
            pulling
        rescue JSON::ParserError => e
            puts "⚠️ [HealthChecker] Could not parse /ps response: #{e.message}"
            false
        end
    end

    def reset_failures
        @consecutive_failures = 0
    end

    def increment_failures
        @consecutive_failures += 1
    end
  end
end
