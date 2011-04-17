#!/usr/bin/ruby


IDENTITY_FILTER = lambda {|lines| lines }
STRIP_WHITESPACE_FILTER = lambda {|lines| lines.map {|line| line.rstrip } }
FILTER_REGEXP = %r{//\s+<dmclean.filter: (.+)>$}
WHITESPACE_FILTER_REGEXP = %r{//\s+<dmclean.strip-whitespace: true>$}
@@default_filter = IDENTITY_FILTER

@group_header = nil
@group_header_if_error = nil
@group_body_lines = []
@pending_filter = @@default_filter

def begin_next_group(next_header, next_header_if_error, next_custom_filter)
  filtered = @pending_filter.call(@group_body_lines) rescue nil

  if filtered
    puts @@default_filter.call([@group_header]) if @group_header
    filtered.each {|filtered| puts filtered }
  else
    puts @group_header_if_error
    @@default_filter.call(@group_body_lines).each {|l| puts l }
  end

  @group_header = next_header || ''
  @group_header_if_error = next_header_if_error || @group_header
  @pending_filter = next_custom_filter || @@default_filter
  @group_body_lines = []
end


at_exit do
  File.unlink $0 if File.basename($0) =~ /^\.merge_file_/
end


begin
  while line_nl = gets
    line = line_nl.chomp
    start_of_new_group = line.strip.empty?
    new_filter = nil
    error_header = nil

    match = line.match(FILTER_REGEXP)
    if match
      start_of_new_group = true
      filter_code = match[1]
      line_if_error = match.pre_match + "// Invalid filter: <dmclean.filter: #{filter_code}>" + match.post_match
      begin
        new_filter = eval "lambda {|lines| #{filter_code} }"
      rescue Exception => ex
        line = line_if_error
      end
    elsif line =~ WHITESPACE_FILTER_REGEXP
      @@default_filter = STRIP_WHITESPACE_FILTER
    end

    if start_of_new_group
      begin_next_group(line, line_if_error, new_filter)
    else
      @group_body_lines << line
    end
  end

  begin_next_group(nil, nil, nil)
rescue Errno::EPIPE
end
