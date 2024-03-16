# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'json'

# Class for handling regex cleaning operations
class RegexCleaner
  # Module for Error handling
  module ErrorHandler
    def self.handle_error(error, context = 'General')
      error_message = "#{context}: #{error.message}"
      puts error_message # Output to the screen
      $logger.error(error_message) # Log to file
    end
  end

  # Helper class to allow Logger to write to multiple outputs
  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each { |target| target.write(*args) }
    end

    def close
      @targets.each(&:close)
    end
  end

  def initialize
    # Set up Logger to write to both STDOUT and a file
    @logger = Logger.new(MultiIO.new($stdout, File.open(File.join('logs', 'regex_cleaner.log'), 'a')))
    @logger.level = Logger::INFO
  end

  # Method to create necessary directories if they don't exist
  def create_directories(source_directory, logs_directory)
    FileUtils.mkdir_p(source_directory) unless File.exist?(source_directory)
    FileUtils.mkdir_p(logs_directory) unless File.exist?(logs_directory)
  end

  # Method to process and clean text files
  def process_and_clean_files(source_directory, destination_directory)
    Dir.glob("#{source_directory}/*").each do |file|
      file_extension = File.extname(file)
      basename = File.basename(file, file_extension)
      new_file_name = file_extension.empty? ? "#{basename}_duplicate_cleaned" : "#{basename}_duplicate_cleaned#{file_extension}"
      new_file_path = File.join(destination_directory, new_file_name)
      FileUtils.copy_file(file, new_file_path)

      content = File.read(new_file_path)
      cleaned_content = clean_content(content)
      File.open(new_file_path, 'w') { |f| f.write(cleaned_content) }
      @logger.info("Processed and cleaned #{new_file_name}")

      extract_and_serialize_json(cleaned_content)
    rescue StandardError => e
      ErrorHandler.handle_error(e, "An error occurred with file #{file}")
    end
  end

  # Method to clean content using regex operations
  def clean_content(content)
    cleaned_content = content.gsub(/[^a-zA-Z0-9\s]/, ' ').squeeze(' ')
    cleaned_content = cleaned_content.gsub(/^\s*$|^gA.*$|^\d+$/, '').gsub(/\n+/, "\n")
    cleaned_content = cleaned_content.gsub(/^\d+\s*$/, '')
    cleaned_content.gsub(/\n{2,}/, "\n").gsub(/^\s*(\d+\s+)+\d+\s*$/m, '')
  end

  # Method to extract parts from cleaned content and serialize to JSON
  def extract_and_serialize_json(cleaned_content)
    title = cleaned_content[/\A.*?(?=CONTENTS)/m].strip
    description = cleaned_content[/CONTENTS(.*?)PART ONE/m, 1].strip
    document_data = {
      'title' => title,
      'description' => description,
      'parts' => {}
    }
    cleaned_content.scan(/(PART\s(?:ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE|TEN)\s*(.*?)\s*(?=PART\s(?:ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE|TEN)|\z))/m) do |match|
      part, content = match
      document_data['parts'][part] = content.strip
    end

    Dir.mkdir('serialized_files') unless File.exist?('serialized_files')
    json_file_name = File.join('serialized_files', "#{title.gsub(/\s+/, '_').downcase}.json")

    File.open(json_file_name, 'w') do |file|
      file.write(JSON.pretty_generate(document_data))
    end
    @logger.info("Successfully created JSON file: #{json_file_name}")
  end
end

# Main method to execute the script
def main
  cleaner = RegexCleaner.new
  source_directory = 'text_files'
  destination_directory = 'text_files'
  logs_directory = 'logs'

  cleaner.create_directories(source_directory, logs_directory)
  cleaner.process_and_clean_files(source_directory, destination_directory)
end

main if $PROGRAM_NAME == __FILE__
