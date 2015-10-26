class Clock
  class DetachedProcess < Process
    def self.run cmd
      new cmd, nil, shell: true, input: true, output: true, error: true
    end

    def wait_nonblock
      if @waitpid_future.completed?
        wait
        yield
      end
    end
  end

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

    def initialize(minute, hour, day, month, day_of_week, @cmd, @pset)
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
      if match == 1
        STDOUT.puts "#{now}: #{@cmd}"
        @pset.add DetachedProcess.run @cmd
      end
    rescue e : Exception
      STDERR.puts e
    end
  end

  def initialize(alerm)
    @alerms = [] of Alerm
    @pset = Set(DetachedProcess).new
    file = File.read alerm
    file.split("\n").each do |line|
      next if line.empty?
      next if line[0] == '#'
      m,h,day,mon,w,cmd = line.split /\s+/, 6
      @alerms << Alerm.new m, h, day, mon, w, cmd, @pset
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
      @pset.each do |p|
        p.wait_nonblock do
          @pset.delete p
        end
      end
    end
  ensure
    @pset.each{|p| p.wait}
  end

  def wait_for_next_min
    started_at = Time.now
    sleep 60 - started_at.second
  end
end

[STDOUT, STDERR].each{|i| i.sync = true}
abort "first argument should be a path to alerm file" if ARGV.empty?
Signal::TERM.trap do
  STDOUT.puts "clock is terminated."
  exit
end
Clock.new(ARGV[0]).start
