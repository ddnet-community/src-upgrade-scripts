#!/usr/bin/env ruby

# only flips the truestr to falsestr
# and the falsestr to truestr
def flip_true_or_false(line, truestr, falsestr)
  return line.sub(truestr, falsestr) if line.include?(truestr)

  line.sub(falsestr, truestr)
end

def flip_line(line)
  raise "line too complex" if line.include?("return true") && line.include?("return false")

  if line.include?("return true;")
    return line.sub("return true;", "return false;")
  elsif line.include?("return false;")
    return line.sub("return false;", "return true;")
  elsif line.match?(/return pSqlServer->ExecuteUpdate\(&\w+, pError, ErrorSize\);/)
    return line
  elsif line.include?("return pSqlServer->Step(&End, pError, ErrorSize);")
    return line
  elsif line.include?("return NumUpdated == 0;")
    return line.sub("return NumUpdated == 0;", "return NumUpdated != 0;")
  elsif line.include?("return NumUpdated != 0;")
    return line.sub("return NumUpdated != 0;", "return NumUpdated == 0;")
  elsif line.include?("return !End;")
    return line.sub("return !End;", "return End;")
  elsif line.include?("return End;")
    return line.sub("return End;", "return !End;")
  elsif line.match?(/^\s*\/\/ return error if/)
    # avoid false positive error on comments
    return line
  elsif line.include?("return ")
    return line + " // TODO: check this bool manually ^^\n#warning \"sql bool needs attention\""
  end

  %w(
    PrepareStatement
    Step
    ExecuteUpdate
    AddPoints
  ).each do |sql_method|
      line = flip_true_or_false(line, "if(pSqlServer->#{sql_method}(", "if(!pSqlServer->#{sql_method}(")
      line = flip_true_or_false(line, "while(pSqlServer->#{sql_method}(", "while(!pSqlServer->#{sql_method}(")
  end
  line
end

def flip_method_call(line, sql_method)
  return line unless line.include?(sql_method)

  [
    "\\w+::#{sql_method}\\(",
    "\\w+->#{sql_method}\\(",
    "\\w+\\.#{sql_method}\\("
  ].each do |call_str|
    call_neg_reg = Regexp.new("!#{call_str}")
    call_pos_reg = Regexp.new(call_str)
    if line.match? call_neg_reg
      return line.gsub(call_neg_reg) { |_| Regexp.last_match[0] }
    elsif line.match? call_pos_reg
      return line.gsub(call_pos_reg) { |_| "!#{Regexp.last_match[0]}" }
    end
  end

  call_neg_reg = Regexp.new("([^\\w])!(#{sql_method}\\()")
  call_pos_reg = Regexp.new("([^\\w])(#{sql_method}\\()")
  if line.match? call_neg_reg
    return line.gsub(call_neg_reg) { |_| "#{Regexp.last_match[1]}#{Regexp.last_match[2]}" }
  elsif line.match? call_pos_reg
    return line.gsub(call_pos_reg) { |_| "#{Regexp.last_match[1]}!#{Regexp.last_match[2]}" }
  end

  line
end

def flip_file(filepath)
  lines = []
  sql_methods = []

  in_sql_worker = false

  File.read(filepath).split("\n").each_with_index do |line, line_num|
    if in_sql_worker
      begin
        lines << yield(line)
      rescue => err
        STDERR.puts ""
        STDERR.puts "   " + line
        STDERR.puts "   " + "^" * line.length
        STDERR.puts ""
        STDERR.puts "Bool flip error in #{filepath}:#{line_num} #{err}"
        exit 1
      end
    else
      lines << line
    end

    match_sql_function = line.match(/^bool \w+::(?<name>\w+)\(IDbConnection \*.*char \*pError, int ErrorSize/)
    if match_sql_function
      raise "unexpected nested method" if in_sql_worker

      sql_methods << match_sql_function[:name]
      in_sql_worker = true
    elsif line == "}"
      in_sql_worker = false
    end
  end

  File.write(filepath, lines.join("\n") + "\n")
  sql_methods
end

def flip_files(files)
  sql_methods = []

  files.each do |filepath|
    print "."
    sql_methods << flip_file(filepath) do |line|
      flip_line(line)
    end
  end

  sql_methods.flatten!

  puts "\ndetected following sql methods:"
  p sql_methods

  files.each do |filepath|
    print "."
    sql_methods.each do |sql_method|
      print ":"
      flip_file(filepath) do |line|
        flip_method_call(line, sql_method)
      end
    end
  end

  puts "\nOK"
end

flip_files(Dir.glob("src/**/*.cpp"))

