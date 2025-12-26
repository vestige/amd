ROWS    = 12
H_CHARS = 3

def parse_cols(argv)
  n = argv[0].to_i
  n = 5 if n <= 0
  [[n, 3].max, 10].min
end

def count_bars(con)
  con.sum { |row| row.count(true) }
end

def generate_connections(rows, cols, density: 0.35)
  con = Array.new(rows) { Array.new(cols - 1, false) }

  rows.times do |r|
    (cols - 1).times do |i|
      next if i > 0 && con[r][i - 1]

      con[r][i] = (rand < density)
    end
  end

  con
end

def generate_connections_with_min_bars(rows, cols, density: 0.35, min_bars: 1)
  loop do
    con = generate_connections(rows, cols, density: density)
    return con if count_bars(con) >= min_bars
  end
end

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
  if goals
    goal_line = goals.map { |g| g.center(1 + h_chars) }.join
    puts " " + goal_line
  else
    puts " " + (1..cols).map { |n| n.to_s.center(1 + h_chars) }.join
  end
end

def build_new_amida(rows, cols, density: 0.35, min_bars: 1)
  connections = generate_connections_with_min_bars(rows, cols, density: density, min_bars: min_bars)

  atari_index = rand(cols)
  goals = Array.new(cols) { " " }
  goals[atari_index] = "O"

  [connections, atari_index, goals]
end

# ====== main ======
srand

cols = parse_cols(ARGV)

MIN_BARS = 3
DENSITY  = 0.35

connections, atari_index, goals = build_new_amida(ROWS, cols, density: DENSITY, min_bars: MIN_BARS)

puts
puts "input (1 - #{cols} / R / END)"
puts

render(connections, cols, H_CHARS, goals: goals)
puts

loop do
  print "select (1-#{cols}) or R or END > "
  inp = STDIN.gets
  break if inp.nil?

  s = inp.strip
  up = s.upcase

  if up == "END"
    break
  elsif up == "R"
    connections, atari_index, goals = build_new_amida(ROWS, cols, density: DENSITY, min_bars: MIN_BARS)
    puts
    puts "REBUILD!"
    render(connections, cols, H_CHARS, goals: goals)
    puts
    next
  end

  n = s.to_i
  unless (1..cols).include?(n)
    puts "Please Input 1-#{cols} or R or END"
    next
  end

  goal_col, v_marks, h_marks = compute_path(connections, n - 1, cols)

  puts
  render(connections, cols, H_CHARS, v_marks: v_marks, h_marks: h_marks, goals: goals)
  puts

  if goal_col == atari_index
    puts "Result: #{n}  ATARI!!"
  else
    puts "Result: #{n}  #{goal_col + 1}"
  end
  puts
end

puts
puts "End"
