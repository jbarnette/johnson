namespace :gem do
  "Generate a VERSION.timestamp gemspec."
  task :spec do
    File.open("#{HOE.name}.gemspec", "w") do |f|
      HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
      f.puts(HOE.spec.to_ruby)
    end
  end
end
