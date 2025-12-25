def usage!
  warn "use: count.exe <try N>"
  warn "ex: count.exe 1000"
  exit 1
end

n = ARGV[0]&.to_i
usage! if n.nil? || n <= 0

counts = Hash.new(0)

n.times do
  x = [1, 2, 3, 4].sample
  counts[x] += 1
end

max_count = counts.values.max
winners = counts.select { |_, v| v == max_count }.keys.sort

puts "try: #{n}"
puts "count: #{counts.sort.to_h}"
puts "max: #{winners.join(', ')} (#{max_count}counts)"

