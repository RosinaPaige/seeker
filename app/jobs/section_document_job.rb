class SectionDocumentJob 
  include SuckerPunch::Job
  
  def perform(document)

    @l = Logger.new("#{Rails.root}/log/section.log")
    write_to_log('section document')
    document&.sections&.map(&:destroy)
    content = File.read(document.url_text)

    if Document::DOCUMENT_TYPES[document.document_type] == 'Committee of Experts Report'

      #                                                                                       remove spaces
      prefix_section = 'report of the committee of experts on the application of the charter'.gsub(/\s/, '')

      second_prefix_occurrence = false
      first_prefix_occurrence = false
      preamble_passed = false

      prev_line = ''
      prev_content = ''
      prev_chapter = 0
      prev_section_number = ''
      prev_section_name = ''
      prev_article = 0
      prev_paragraph = 0
      prev_subparagraph = ''

      prev_thing = ''

      current_page = 1
      prev_page = 1

      section_number_regex = /^\d(\.\d)+\.?/
      section_number_regex_no_nl = /\d(\.\d)+\.?/
      chapter_regex = /^chapter\d/
      article_regex = /^article\d/
      paragraph_regex = /^(.|)paragraph\d/
      subparagraph_regex = /^(.|)[a-f][\.]/

      page_number_regex = /^(.|)pagenumber:\d/

      content.each_line do |line|

        next if line.blank?

        processed_line = line.downcase.gsub(/\s/, '')

        # increment page number if required. All sections will be saved as the page they first appeared on.
        # regex: match start line, digits, end line
        # this line is added in the document parser job
        #
        # I'm not sure why both of these functions are here
        page_number = line[/^\d+$/].to_i
        if page_number != nil && page_number > current_page
          current_page = page_number
        end
        if processed_line =~ page_number_regex
          current_page = line.scan(/\d/).join('').to_i + 1
          next
        end

        # table of contents is bookended by prefix_section text
        # catch when the prefix is split over 2 lines
        lines = prev_line + processed_line
        if lines.include?(prefix_section)
          # first content page is false, second time its true
          second_prefix_occurrence = first_prefix_occurrence
          first_prefix_occurrence = true
          write_to_log('includes prefix')
        end


        # chapter check outside of main preamble passed if statement is used
        # to detect the first chapter after the second bookend line
        if processed_line =~ chapter_regex
          chapter_header_check = true
        else
          chapter_header_check = false
        end



        if processed_line =~ section_number_regex_no_nl
          # catch "Chapter 2.2 of this report" exception - not a new chapter
          # catch "Article 15.1, an outline for the..." exception - not a new article
          # does not catch "Chapter 2."
          exceptions_check = true
        else
          exceptions_check = false
        end

        # when the first valid chapter is seen after the second book end has passed
        # mark preamble section
        # the preamble section will be saved and the next section started within the same loop cycle
        # as the preamble_passed if statement will start triggering

        #  true                     true                          false                         false
        if chapter_header_check and second_prefix_occurrence and !exceptions_check and !preamble_passed
          write_to_log('hit processed_line =~ chapter_regex and !exceptions_check !preamble_passed')
          preamble_passed = true
          write_to_log('preamble passed = true')
          prev_chapter = 0
          prev_section_number = '0'
          prev_section_name = 'preamble'
          prev_article = 0
          prev_paragraph = 0
          prev_thing = 'preamble'

        #create the preamble on the next hit
        end

        # start looking for chapters, section numbers, article, paragraphs

        # whenever we encounter a new thing, we have to check what the old thing was, make the old thing, and then set the variables for the new thing

        if preamble_passed

          # chapter - could be the start of a section numbered or not
          if processed_line =~ chapter_regex and !exceptions_check
            write_to_log('hit processed_line =~ chapter_regex and !exceptions_check')
            # prev_chapter, prev_article, prev_paragraph

            check_and_make_old_thing(document,prev_chapter,prev_section_number, prev_section_name ,prev_article, prev_paragraph, prev_subparagraph, prev_content, prev_page, prev_thing)
            prev_subparagraph = ''

            # new old thing
            prev_content = ''
            prev_chapter = line.scan(/\d/).join('').to_i
            prev_section_number = (prev_chapter).to_s
            prev_section_name = line
            prev_article = 0
            prev_paragraph = 0
            prev_page = current_page
            prev_thing = 'chapter'
            create_section = true

          end

          if processed_line =~ section_number_regex
            write_to_log('hit processed_line =~ section_number_regex')
            check_and_make_old_thing(document,prev_chapter,prev_section_number, prev_section_name ,prev_article, prev_paragraph, prev_subparagraph, prev_content, prev_page, prev_thing)
            prev_subparagraph = ''
            # new old thing
            prev_content = ''
            prev_chapter = prev_chapter
            prev_section_number = processed_line.match(section_number_regex)[0]
            prev_section_name = line.slice(line.index(/[A-Za-z]/)..-1)
            prev_article = 0
            prev_paragraph = 0
            prev_page = current_page
            prev_thing = 'section'
            create_section = true

          end
          if processed_line =~ article_regex and !exceptions_check
            write_to_log('hit processed_line =~ article_regex and !exceptions_check')
            check_and_make_old_thing(document,prev_chapter,prev_section_number, prev_section_name ,prev_article, prev_paragraph, prev_subparagraph,prev_content, prev_page, prev_thing)
            prev_subparagraph = ''
            # new old thing
            prev_content = ''
            prev_chapter = prev_chapter
            prev_section_number = prev_section_number
            prev_section_name = line
            prev_article = line.scan(/\d/).join('').to_i
            prev_paragraph = 0
            prev_page = current_page
            prev_thing = 'article'
            create_section = true
          end


          if processed_line =~ paragraph_regex
            write_to_log('hit processed_line =~ paragraph_regex')
            check_and_make_old_thing(document,prev_chapter,prev_section_number, prev_section_name ,prev_article, prev_paragraph, prev_subparagraph,prev_content, prev_page, prev_thing)
            prev_subparagraph = ''
            # new old thing
            prev_content = ''
            prev_chapter = prev_chapter
            prev_section_number = prev_section_number
            prev_section_name = prev_section_name
            prev_article = prev_article
            prev_paragraph = line.scan(/\d/).join('').to_i
            prev_page = current_page
            prev_thing = 'paragraph'
            create_section = true
          end

          if line =~ subparagraph_regex and prev_thing == 'paragraph'
            write_to_log('hit line =~ subparagraph_regex')
            check_and_make_old_thing(document,prev_chapter,prev_section_number, prev_section_name ,prev_article, prev_paragraph, prev_subparagraph,prev_content, prev_page, prev_thing)

            # new old thing
            prev_content = ''
            prev_chapter = prev_chapter
            prev_section_number = prev_section_number
            prev_section_name = prev_section_name
            prev_article = prev_article
            prev_subparagraph = '.' +  line[0,3].scan(/[a-f]/).first
            prev_page = current_page
            prev_thing = 'paragraph'
            create_section = true

          end

        end
        prev_content += line
        prev_line = processed_line
      end


      # process last section after reading last line
      save_section(document,prev_chapter, prev_chapter.to_s, prev_section_name,'', prev_content, prev_page)
      write_to_log('final section create')
    end

    begin
      document.sections.add_section(chapter: '0',section_number: '-', section_name: 'Full Content', article_paragraph: '-', content: content, page_number: 0, languages: nil, strengths: nil)
    rescue Searchkick::ImportError
      logger.info 'too long, not indexed'
    end

    write_to_log('')
    write_to_log('')
    write_to_log('attributes')
    document.sections.each do |section|
      write_to_log(section.attributes)
    end


    logger.info 'start language parsing'
    LanguageParserJob.perform_in(60, document.id)

  rescue StandardError => e
    write_to_log(e)
    logger.info 'Failure'
    document.status = 1
    document.save
    raise e
  end

  def check_and_make_old_thing(document,prev_chapter,prev_section_number, prev_section_name ,prev_article, prev_paragraph, prev_subparagraph, prev_content, prev_page, prev_thing)

    if prev_thing == 'preamble'
      # chapter, section_number, section_name, article_paragraph
      # assemble all the fields correctly according to what was seen last
      save_section(document,prev_chapter, prev_chapter.to_s, prev_section_name,'', prev_content, prev_page)
      write_to_log('thing: ' + prev_thing)
      write_to_log('chapter: ' + prev_chapter.to_s + 'section number: ' + prev_chapter.to_s + 'section name: Chapter ' + prev_chapter.to_s + 'article paragraph: '+ 'content: '+ prev_content)
    elsif prev_thing == 'chapter'
      write_to_log('thing: ' + prev_thing)
      save_section(document,prev_chapter, prev_chapter.to_s, prev_section_name,'', prev_content, prev_page)
      write_to_log('chapter: ' + prev_chapter.to_s + 'section number: ' + prev_chapter.to_s + 'section name: '+ prev_section_name + 'article paragraph: '+ 'content: '+ prev_content)
    elsif prev_thing == 'section'
      write_to_log('thing: ' + prev_thing)
      save_section(document,prev_chapter, prev_section_number, prev_section_name,'', prev_content, prev_page)
      write_to_log('chapter: ' + prev_chapter.to_s + 'section number: ' + prev_section_number + 'section name: ' + prev_section_name + 'article paragraph: '+ 'content: '+ prev_content)
    elsif prev_thing == 'article'
      write_to_log('thing: ' + prev_thing)
      save_section(document,prev_chapter, prev_section_number, prev_section_name,prev_article.to_s, prev_content, prev_page)
      write_to_log('chapter: ' + prev_chapter.to_s + 'section number: ' + prev_section_number + 'section name: ' + prev_section_name + 'article paragraph: ' + prev_article.to_s + 'content: '+ prev_content)
    elsif prev_thing == 'paragraph' and prev_subparagraph == ''
      write_to_log('thing: ' + prev_thing)
      save_section(document,prev_chapter, prev_section_number, prev_section_name,prev_article.to_s + '.' + prev_paragraph.to_s, prev_content, prev_page)
      write_to_log('chapter: ' + prev_chapter.to_s + 'section number: ' + prev_section_number + 'section name: ' + prev_section_name + 'article paragraph: ' + prev_article.to_s + '.' + prev_paragraph.to_s + 'content: '+ prev_content)
    elsif prev_thing == 'paragraph' and prev_subparagraph != ''
      write_to_log('thing: ' + prev_thing)
      save_section(document,prev_chapter, prev_section_number, prev_section_name,prev_article.to_s + '.' + prev_paragraph.to_s + prev_subparagraph, prev_content, prev_page)
      write_to_log('chapter: ' + prev_chapter.to_s + 'section number: ' + prev_section_number + 'section name: ' + prev_section_name + 'article paragraph: ' + prev_article.to_s + '.' + prev_paragraph.to_s + 'content: '+ prev_content)
    end

  end

  def save_section(document, prev_chapter, prev_section_number, prev_section_name, prev_article_paragraph, prev_content, current_page)
    document.sections.add_section(chapter: prev_chapter, section_number: prev_section_number, section_name: prev_section_name, article_paragraph: prev_article_paragraph, content: prev_content, page_number: current_page, languages: nil, strengths: nil)
  rescue Searchkick::ImportError
    logger.info 'too long, not indexed'
  end

  def write_to_log(message)
    @l.info(message)
  end


end
