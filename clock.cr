class Clock
  class Alerm
    class Item
      def initialize(value, @range)
        case value
        when /^\*$/; @match = [] of Int32
        when /^\*\/(\d+)$/
          @match = [] of Int32
          @range.each{|i| @match << i if i % $1.to_i == 0}
        else @match = [value.to_i]
        end
      end

      def match(values, matching)
        if @match.empty?
          (matching == 1) ? 1 : values.includes?(@range.begin) ? 1 : 0
        elsif (@match & values).size > 0; 1
        else matching == 0 ? 0 : -1
        end
      end
    end

    RANGES = {
      :minute => 0...60, :hour => 0...24,
      :day => 1..31, :month => 1..12, :day_of_week => 0...7,
    }

    def initialize(minute, hour, day, month, day_of_week, @cmd)
      @items = {} of Symbol => Item
      {% for what in [:minute, :hour, :day, :month, :day_of_week] %}
        @items[:{{what.id}}] = Item.new {{what.id}}, RANGES[:{{what.id}}]
      {% end %}
    end

    def tick(last, now)
      match = 0
      {% for what in [:minute, :hour, :day, :month, :day_of_week] %}
        s = last.{{what.id}}.to_i
        e = now.{{what.id}}.to_i
        if s <= e; values = (s..e).to_a
        else
          range = RANGES[:{{what.id}}]
          values = (s..range.end).to_a
          values |= (range.begin..e).to_a
        end
        match = @items[:{{what.id}}].match values, match
        return if match == -1
      {% end %}
      system @cmd if match == 1
    rescue e : Exception
      STDERR.puts e
    end
  end

  def initialize(alerm)
    @alerms = [] of Alerm
    File.open(alerm) do |file|
      file.read.split("\n").each do |line|
        m,h,day,mon,w,cmd = line.split /\s+/, 6
        @alerms << Alerm.new m, h, day, mon, w, cmd
      end
    end
  end

  def start
    now = Time.now
    puts "clock is started at #{now}"
    loop do
      wait_for_next_min
      last, now = now + Time::Span.new(0, 1, 0), Time.now
      if now.second < 30; now -= now.second
      else now += Time::Span.new(0, 0, 60 - now.second)
      end
      @alerms.each{|a| a.tick last, now}
    end
  end

  def wait_for_next_min
    started_at = Time.now
    sleep 60 - started_at.second
  end
end

[STDOUT, STDERR].each{|i| i.sync = true}
abort "first argument should be a path to alerm file" if ARGV.empty?
Clock.new(ARGV[0]).start