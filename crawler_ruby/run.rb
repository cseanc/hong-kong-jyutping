# This program extract 7072 words from donwloaded pages in page_sources/ folder
# and export 7072 words in a master hash { "word" => <word_details> } as json file
# Pages in page_sources/ folder were from https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/faq.php
# which is a website by Research Centre for Humanities Computing
# of The Chinese University of Hong Kong

require "json"
require_relative "helper"


NUM_OF_PAGES = 15

master_hash = Hash.new

# Step one: Extract word with its link to word details
#
# Extract webpage from downloaded page source because open-uri has problem loading full page
# which is probably due to invalid unicode
file_paths = [*1..NUM_OF_PAGES].map { |n|
  file_path = "page_sources/page_#{n}.html"
}

file_paths.each do |file_path|
  page = File.read(file_path)
  word_hash = HtmlHelper.extract_overview_words_and_detail_links(page)
  
  # master_hash now:
  # {"word": <link_to_word_details> }
  master_hash = master_hash.merge(word_hash)
end

p "#{master_hash.length} word(s) captured"
p master_hash


# Step two: Populate link with word details
#
# For example:
#   { "word" => <link_to_word_details> } becomes
#   { "word" => <word_details_hash> }
master_hash.each_with_index do |(word, link_to_word_details), index|
  begin
    word_details_hash = HtmlHelper.extract_word_details(link_to_word_details)
    master_hash[word] = word_details_hash
    p "Extracted word details for word number #{index+1}"
  rescue => exception
    p "Failed to get word details for #{word} with link #{link_to_word_details}"
    p "Error details: #{exception}"
  end
end

# Save to file backbone.json
output = File.open('backbone2.json', 'w')
output << master_hash.to_json
output.close
