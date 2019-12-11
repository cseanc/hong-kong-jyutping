# This program extract 7072 words from donwloaded pages in page_sources/ folder
# and export 7072 words in a master hash { "word" => <word_details> } as json file
# Pages in page_sources/ folder were from https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/faq.php
# which is a website by Research Centre for Humanities Computing
# of The Chinese University of Hong Kong

require 'nokogiri'
require 'open-uri'
require 'json'


WORD_DETAIL_LINK_PREPEND = 'https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/'
NUM_OF_PAGES = 15


def extract_word_with_link(doc)
  # Create hash { "word" => <link_to_word_details> }
  temp_hash = Hash.new
  
  # Get rows in table
  table = doc.css('table').first
  table_rows = table.css('tr')
  
  # Remove header row
  header_row = table_rows.shift
  
  # Iterate through body rows
  body_rows = table_rows
  body_rows.each do |body_row|
    body_columns = body_row.css('td')

    first_word_row = body_columns[2]
    
    # Each row contains 2 columns that have word
    word_columns = [
      body_columns[2],
      body_columns[5]
    ]
  
    word_columns.each do |word_column|
      word_text = word_column.text.strip
      word_link = WORD_DETAIL_LINK_PREPEND + word_column.css('a').first['href']
    
      temp_hash[word_text] = word_link
    end
  end
  
  temp_hash
end


def extract_word_details(link_to_word_details)
  # Populate link in { "word" => <link_to_word_details> } with word details
  webpage = open(link_to_word_details)
  doc = Nokogiri::HTML(webpage, nil, Encoding::UTF_8.to_s)

  # Second table, second row
  tables = doc.css('table')
  table = tables[1]
  table_rows = table.css('tr')

  table_rows.shift
  body_rows = table_rows

  # A single word can have multiple pronunciations
  word_details_array = Array.new

  body_rows.each do |body_row|
    # Extract from <a> tag href link (i.e. sound.php?s=dik1) because it is easier
    word_columns = body_row.css('td')
    jyutping_column_data = word_columns[1].css('a').first['href']

    # If jyutping == dik1, then sound == dik and tone == 1
    jyutping = jyutping_column_data.split('s=')[1]
    sound = jyutping[0..jyutping.length-2]
    tone = jyutping[-1]

    # Build hash i.e. {:sound=>"dik", :tone=>1, :examples=>[]}
    word_details_hash = Hash.new
    word_details_hash[:sound] = sound
    word_details_hash[:tone] = tone.to_i
    word_details_hash[:examples] = []

    word_details_array << word_details_hash
  end
  
  word_details_array
end



# Master hash
master_hash = Hash.new


# Step one: Extract word with its link to word details

file_paths = [*1..NUM_OF_PAGES].map { |n|
  # Use downloaded page source because open-uri has problem loading full page
  file_path = "page_sources/page_#{n}.html"
}

file_paths.each do |file_path|
  page = File.read(file_path)
  doc = Nokogiri::HTML(page)
  temp_hash = extract_word_with_link(doc)
  
  # master_hash now:
  # {"word": <link_to_word_details> }
  master_hash = master_hash.merge(temp_hash)
end

p "#{master_hash.length} word(s) captured"


# Step 2: Populate word details in master_hash {"word": <link_to_word_details> }

master_hash.each_with_index do |(word, link_to_word_details), index|
  begin
    word_details_hash = extract_word_details(link_to_word_details)
    master_hash[word] = word_details_hash
    p "Extracted word details for word number #{index+1}"
  rescue => exception
    p "Failed to get word details for #{word} with link #{link_to_word_details}"
    p "Error details: #{exception}"
  end
end

# Save to file backbone.json
output = File.open('backbone.json', 'w')
output << master_hash.to_json
output.close
