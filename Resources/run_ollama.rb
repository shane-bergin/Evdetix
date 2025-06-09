#!/usr/bin/env ruby
require 'fileutils'
require 'open3'

# Path setup
resource_dir = File.expand_path(File.dirname(__FILE__))
ollama_binary = File.join(resource_dir, "ollama")
model_dir = File.expand_path("~/Library/Containers/com.shanebergin.evdetix/Data/.ollama/models")
ENV['OLLAMA_MODELS'] = model_dir

puts "OLLAMA_MODELS directory: #{model_dir}"
FileUtils.mkdir_p(model_dir)

puts "Starting Ollama server in background..."
pid = spawn(ENV, ollama_binary, "serve", [:out, :err] => "/dev/null")
Process.detach(pid)
sleep 2 

def model_exists?(ollama_binary, model_dir)
  output = `OLLAMA_MODELS=#{model_dir} #{ollama_binary} list 2>&1`
  output.downcase.include?("mistral:instruct")
end

unless model_exists?(ollama_binary, model_dir)
  puts "Pulling mistral:instruct..."
  Open3.popen3(ENV, ollama_binary, "pull", "mistral:instruct") do |_, stdout, stderr, wait_thr|
    out = stdout.read.strip
    err = stderr.read.strip
    puts out unless out.empty?
    warn err unless err.empty?
    unless wait_thr.value.success?
      abort("Failed to pull model. Check network and permissions.")
    end
  end
  puts "Model pull complete"
else
  puts "Model already exists. Skipping pull."
end

puts "Ollama server is running at http://localhost:11434 (PID: #{pid})"
