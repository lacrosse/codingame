def encode(s)
  s.chars.map { |c| "-.".index(c) }
end

def put(tree, seq)
  head, *tail = seq
  if head
    tree[head] = {} unless tree[head]
    put(tree[head], tail)
  else
    tree[:end] ||= 0
    tree[:end] += 1
  end
end

morse_alphabet =
  %w[.- -... -.-. -..
     . ..-. --. .... ..
     .--- -.- .-.. -- -.
     --- .--. --.- .-. ...
     - ..- ...- .-- -..- -.--
     --..]
    .map { |s| encode(s) }
morse = [*?A..?Z].zip(morse_alphabet).to_h

message = encode(gets.chomp)

dict = {}

gets.to_i.times.each do
  put(dict, gets.chomp.chars.flat_map { |c| morse[c] })
end

count = Hash.new do |h, message|
  h[message] = if message == []
      1
    else
      tree = dict
      message.size.times.sum do |i|
        tree && (tree = tree[message[i]]) && tree[:end] && tree[:end] * count[message[i + 1..]] || 0
      end
    end
end

p count[message]
