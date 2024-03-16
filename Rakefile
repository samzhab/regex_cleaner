require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['tests/**/test_*.rb']  # This line points to where your test files are.
  t.verbose = true
end
