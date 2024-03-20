# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'json'
require 'byebug'

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
      next if file.include?('_duplicate_cleaned') # Skip files with '_duplicate_cleaned' in the filename

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
    # Remove anything including whitespace before "FEDERAL NEGARIT GAZETTE OF THE FEDERAL DEMOCRATIC REPUBLIC OF ETHIOPIA"
    content = content.sub(/.*FEDERAL NEGARIT GAZETTE/m, 'FEDERAL NEGARIT GAZETTE')

    # Remove all lines containing "https chilot"
    content = content.gsub(/.*https.*$/, '')

    # Remove all lines with a total number of characters less than 3
    content = content.lines.reject { |line| line.chomp.size < 3 }.join

    # Remove non-Latin letters or numbers and condense spaces
    cleaned_content = content.gsub(/[^a-zA-Z0-9\s]/, ' ').squeeze(' ')

    # Remove empty lines, lines starting with 'gA', or lines only having numbers
    cleaned_content = cleaned_content.gsub(/^\s*$|^gA.*$|^\d+$/, '').gsub(/\n+/, "\n")

    # Remove lines consisting solely of numbers
    cleaned_content = cleaned_content.gsub(/^\d+\s*$/, '')

    # Remove multiple consecutive newline characters turning them into a single newline
    cleaned_content.gsub(/^\s*(?!\d+\.\s)(?:\d+\s+\d+|\d+|\s\S\s)\s*$/, '').gsub(/\n{2,}/, "\n")
  end

  # Method to extract parts from cleaned content and serialize to JSON
  def extract_and_serialize_json(cleaned_content)
  # Extract title from content
  title = cleaned_content[/PROCLAMATION\s(?:No|NO\.?)?\s\d+\s\d+/].strip

  # Initialize document_data hash
  document_data = {
    'title' => title,
    'description' => extract_description(cleaned_content),
    'parts' => {}
  }

  # Check if content contains "1. Short Title" for post-2018 content
  if cleaned_content.include?("PART ONE")
    extract_pre_2018_parts(cleaned_content, document_data)
    document_data['description'] = extract_pre_2018_description(cleaned_content)
  elsif cleaned_content.include?("1. Short Title")
    extract_post_2018_parts(cleaned_content, document_data)
    document_data['description'] = extract_post_2018_description(cleaned_content)
  end

  # Serialize document_data to JSON
  serialize_to_json(document_data)
end

def extract_pre_2018_description(cleaned_content)
  # Extract description for pre-2018 content until "PART ONE"
  cleaned_content[/WHEREAS(.*?)\bPART\sONE/m, 1].strip
end

def extract_post_2018_description(cleaned_content)
  # Extract description for post-2018 content until "1. Short Title"
  cleaned_content[/WHEREAS(.*?)1\.\sShort\sTitle/m, 1].strip
end

def extract_pre_2018_parts(cleaned_content, document_data)
  # Extract parts for pre-2018 content using "PART ONE"
  cleaned_content.scan(/(PART\s(?:ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE|TEN)\s*(.*?)\s*(?=PART\s(?:ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE|TEN)|\z))/m) do |match|
    part, content = match
    document_data['parts'][part] = content.strip
  end
end

def extract_post_2018_parts(cleaned_content, document_data)
  # Extract parts for post-2018 content using "1. Short Title"
  parts_content = cleaned_content[/1\.\sShort\sTitle(.*?)\bPART\sONE|1\./m, 1]

  # Iterate through each section after "1. Short Title" and organize them into parts
  parts_content.scan(/(\d+\.\s.*?)\s(?=\d+\.\s|\z)/m) do |part_title|
    part_title = part_title.first.strip
    part_content = parts_content[/#{Regexp.escape(part_title)}(.*?)\d+\.\s/m, 1].strip
    document_data['parts'][part_title] = part_content
  end
end

def serialize_to_json(document_data)
  # Serialize document_data to JSON
  json_file_name = File.join('serialized_files', "#{document_data['title'].downcase.gsub(/\s+/, '_')}.json")
  File.open(json_file_name, 'w') do |file|
    file.write(JSON.pretty_generate(document_data))
  end
  @logger.info("Successfully created JSON file: #{json_file_name}")
  end
end


def extract_description(cleaned_content)
  # Check if content contains "1. Short Title" for post-2018 content
  if cleaned_content.include?("PART ONE")
    extract_pre_2018_description(cleaned_content)
  elsif cleaned_content.include?("1 Short Title")
    extract_post_2018_description(cleaned_content)
  else
    # Default description extraction logic here if needed
    ""
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
