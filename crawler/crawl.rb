require 'nokogiri'
require 'open-uri'

WORD_DETAIL_LINK_PREPEND = 'https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/'
NUM_OF_PAGES = 15

def extract_word_with_link(doc)
  # Create hash { "word" => <detail_page_link> }
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


# Master hash
master_hash = Hash.new

# Use downloaded page source because open-uri has problem loading full page
file_paths = [*1..NUM_OF_PAGES].map { |n|
  file_path = "page_sources/page_#{n}.html"
}

file_paths.each do |file_path|
  page = File.read(file_path)
  doc = Nokogiri::HTML(page)
  temp_hash = extract_word_with_link(doc)
  master_hash = master_hash.merge(temp_hash)
end

puts "#{master_hash.length} word(s) captured"
output = File.open('temp_hash.txt', 'w')
output << master_hash
output.close

# test = temp_hash["邊"]
# p test
# detail_doc = Nokogiri::HTML(open(test))
# detail_doc.encoding = 'utf-8'

# p detail_doc
#
# output = File.open('out_detail.html', 'w')
# output << detail_doc
# output.close
