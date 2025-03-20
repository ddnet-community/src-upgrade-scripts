#!/usr/bin/env ruby

# only flips the truestr to falsestr
# and the falsestr to truestr
def flip_true_or_false(line, truestr, falsestr)
  return line.sub(truestr, falsestr) if line.include?(truestr)

  line.sub(falsestr, truestr)
end

# p flip_true_or_false("true", "true", "false") == "false"
# p flip_true_or_false("return true;", "true", "false") == "return false;"
# p flip_true_or_false("return false;", "true", "false") == "return true;"

def flip_line(line)
  raise "line too complex" if line.include?("return true") && line.include?("return false")

  if line.include?("return true;")
    return line.sub("return true;", "return false;")
  elsif line.include?("return false;")
    return line.sub("return false;", "return true;")
  elsif line.include?("return pSqlServer->ExecuteUpdate(&NumInserted, pError, ErrorSize);")
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

# p flip_line("return true;") == "return false;"
# p flip_line("return false;") == "return true;"
# p flip_line("return false; // uwu") == "return true; // uwu"
# p flip_line("return 2 == 0;") == "return 2 == 0; // TODO: check this bool manually"

def flip_file(filepath)
  lines = []

  in_sql_worker = false

  File.read(filepath).split("\n").each_with_index do |line, line_num|
    if line.match?(/^bool \w+::\w+\(IDbConnection \*.*char \*pError, int ErrorSize/)
      raise "unexpected nested method" if in_sql_worker

      in_sql_worker = true
    elsif line == "}"
      in_sql_worker = false
    end

    if in_sql_worker
      begin
        lines << flip_line(line)
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
  end

  File.write(filepath, lines.join("\n") + "\n")
end

Dir.glob("src/**/*.cpp").each do |filepath|
  print "."
  flip_file(filepath)
end

