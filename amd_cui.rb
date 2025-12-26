# ====== config / args ======
DEFAULT_COLS = 5
ROWS = 12
H_CHARS = 3
DENSITY = 0.35
MIN_BARS = 2

def parse_cols(argv)
  return DEFAULT_COLS if argv.empty? || argv[0].strip.empty?

  n = argv[0].to_i
  if n < 3 || n > 10
    warn "cols must be 3..10 (got #{argv[0]})"
    exit 1
  end
  n
end

COLS = parse_cols(ARGV)

# ====== generation ======
def count_bars_between(con, cols)
  counts = Array.new(cols - 1, 0)
  con.each do |row|
    row.each_with_index do |has_bar, i|
      counts[i] += 1 if has_bar
    end
  end
  counts
end

def count_total_bars(con)
  con.sum { |row| row.count(true) }
end

def column_has_any_connection?(con, col, cols)
  con.any? do |row|
    left  = (col > 0) && row[col - 1]
    right = (col < cols-1) && row[col]
    left || right
  end
end

def all_columns_connected_at_least_once?(con, cols)
  cols.times.all? { |c| column_has_any_connection?(con, c, cols) }
end

def generate_connections(rows, cols, density: 0.35)
  con = Array.new(rows) { Array.new(cols - 1, false) }

  rows.times do |r|
    (cols - 1).times do |i|
      next if i > 0 && con[r][i - 1]
      next if i < cols - 2 && con[r][i + 1]

      con[r][i] = (rand < density)
    end
  end

  con
end

def generate_connections_with_constraints(rows, cols, density:, min_bars:)
  loop do
    con = generate_connections(rows, cols, density: density)

    gap_counts = count_bars_between(con, cols)
    next unless gap_counts.all? { |n| n >= 2 }
    next if count_total_bars(con) < min_bars
    next unless all_columns_connected_at_least_once?(con, cols)

    return con
  end
end

# ====== path ======
def compute_path(connections, start_col, cols)
  col = start_col
  v_marks = {}
  h_marks = {}

  connections.length.times do |r|
    v_marks[[r, col]] = true

    if col > 0 && connections[r][col - 1]
      h_marks[[r, col - 1]] = true
      col -= 1
      v_marks[[r, col]] = true
    elsif col < cols - 1 && connections[r][col]
      h_marks[[r, col]] = true
      col += 1
      v_marks[[r, col]] = true
    end
  end

  v_marks[[connections.length, col]] = true
  [col, v_marks, h_marks]
end

# ====== render ======
def render(connections, cols, h_chars, v_marks: nil, h_marks: nil, goals: nil)
  start_line = (1..cols).map { |n| n.to_s.center(1 + h_chars) }.join
  puts "START"
  puts " " + start_line

  connections.each_with_index do |row_con, r|
    line = +" "

    cols.times do |c|
      on_path = v_marks && v_marks[[r, c]]
      line << (on_path ? "*" : "|")

      if c < cols - 1
        if row_con[c]
          h_on_path = h_marks && h_marks[[r, c]]
          line << (h_on_path ? "*" * h_chars : "-" * h_chars)
        else
          line << " " * h_chars
        end
      end
    end

    puts line
  end

  last = +" "
  cols.times do |c|
    on_path = v_marks && v_marks[[connections.length, c]]
    last << (on_path ? "*" : "|")
    last << " " * h_chars if c < cols - 1
  end
  puts last

  puts "GOAL"
  goal_line =
    if goals
      goals.map { |g| g.center(1 + h_chars) }.join
    else
      (1..cols).map { |n| n.to_s.center(1 + h_chars) }.join
    end
  puts " " + goal_line
end

# ====== main ======
srand

def new_amida(rows, cols)
  connections = generate_connections_with_constraints(rows, cols, density: DENSITY, min_bars: MIN_BARS)

  atari_index = rand(cols)
  goals = Array.new(cols) { " " }
  goals[atari_index] = "O"

  [connections, atari_index, goals]
end

connections, atari_index, goals = new_amida(ROWS, COLS)

puts
puts "input (1 - #{COLS} / R / END )"
puts

render(connections, COLS, H_CHARS, goals: goals)
puts

loop do
  print "select (1-#{COLS}) or R or END > "
  inp = STDIN.gets
  break if inp.nil?

  s = inp.strip
  break if s.upcase == "END"

  if s.upcase == "R"
    connections, atari_index, goals = new_amida(ROWS, COLS)
    puts
    puts "[Re-generated]"
    render(connections, COLS, H_CHARS, goals: goals)
    puts
    next
  end

  n = s.to_i
  unless (1..COLS).include?(n)
    puts "Please Input 1-#{COLS} or R or END"
    next
  end

  goal_col, v_marks, h_marks = compute_path(connections, n - 1, COLS)

  puts
  render(connections, COLS, H_CHARS, v_marks: v_marks, h_marks: h_marks, goals: goals)
  puts

  if goal_col == atari_index
    puts "Result: #{n}  ATARI!! "
  else
    puts "Result: #{n}  #{goal_col + 1}"
  end
  puts
end

puts
puts "End"
