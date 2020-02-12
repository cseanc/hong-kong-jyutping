require "nokogiri"
require "open-uri"


# Handle words in HTML pages
module HtmlHelper
  WORD_DETAIL_LINK_PREPEND = 'https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/'
  
  # Given the html content of an Overview page
  # get all words and link to their details page
  #
  # For example:
  #   { "word" => <link_to_word_details> }
  def self.extract_overview_words_and_detail_links(page)
    doc = Nokogiri::HTML(page)
    word_hash = Hash.new
  
    # Get rows in table
    table = doc.css('table').first
    table_rows = table.css('tr')
  
    # Remove header row
    header_row = table_rows.shift
    
    # Assign remaining rows as body
    body_rows = table_rows
  
    # Iterate through body rows
    body_rows.each do |body_row|
      body_columns = body_row.css('td')
      first_word_row = body_columns[2]
    
      # Each row contains 2 words in 2 separate columns
      word_columns = [
        body_columns[2],
        body_columns[5]
      ]
  
      word_columns.each do |word_column|
        word_text = word_column.text.strip
        word_link = WORD_DETAIL_LINK_PREPEND + word_column.css('a').first['href']
    
        word_hash[word_text] = word_link
      end
    end
  
    word_hash
  end
  
  # Open word details link
  # then get word details (i.e. pronunciation)
  # and return word details as hash
  def self.extract_word_details(link_to_word_details)
    webpage = open(link_to_word_details)
    doc = Nokogiri::HTML(webpage, nil, Encoding::Big5.to_s)

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
      
      # Get examples
      examples_text = word_columns[5].css('div').first.text  # "的確, 目的, 一語中的[4..]"
      if examples_text.include? '['
        start_index = examples_text.index('[')
        examples_text = examples_text[..start_index-1]
      end
      examples = examples_text.split(',').map(&:strip)
      word_details_hash[:examples] = examples

      word_details_array << word_details_hash
    end
  
    word_details_array
  end
end
