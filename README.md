# Regex Cleaner

This Ruby script, `regex_cleaner.rb`, processes all text files in the `text_files` directory by duplicating them and cleaning out all non-Latin characters and numbers from the duplicates. Each character that's removed is replaced with a space, and sequences of spaces are condensed into single spaces. Activities and errors are logged.

## Requirements

- Ruby 2.7 or higher.

## Setup

1. Clone or download this repository.
2. Run `bundle install` to install required gems.

## Usage

1. Place your .txt files in the `text_files` folder.
2. Run the script with `ruby regex_cleaner.rb`.
3. Check the `text_files` folder for the processed files, which will be named as the original files but with `_duplicate` appended to the filename.
4. For activity and error logs, check the `logs` folder.

## Logging

Logs are generated daily and stored in the `logs` directory. They provide information on the processing of each file and any errors encountered.


## License
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

**Attribution**: This project is published by Samael (AI Powered), 2024.

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation.

No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.
