require "dotenv"
require "option_parser"
require "./vision/scan"
require "./vision/view"
require "./vision/discord"
require "./vision/version"

module Vision
  is_complete = false
  none = ""
  target = none
  list = none
  engine = View::Engine::StdOut
  discord_token = ""

  OptionParser.parse do |parser|
    parser.banner = "Usage: vision [arguments]"
    parser.on("-t TARGET", "--target=TARGET", "Target to scan (subnet, ip, domain)") { |x| target = x }
    parser.on("-l TARGET", "--list=TARGET", "List of target separated by newline") { |x| list = x }
    parser.on("-c", "--complete", "Deep scan for domain target") { is_complete = true }
    parser.on("-v", "--version", "Show vision version") do
      puts Vision::VERSION
      exit(0)
    end
    parser.on("-d", "--discord", "Run discord bot") do
      bot = DiscordBot.new
      bot.run
      exit(0)
    end
    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit(0)
    end
    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  if target == none && list == none
    STDERR.puts "ERROR: No target specified."
    exit(1)
  end

  if target != none && list != none
    STDERR.puts "ERROR: Only one target can be specified."
    exit(1)
  end

  if target != none
    scan = Scan.new(target, is_complete, engine)
    scan.run
  end

  if list != none
    file = File.new(list)
    targets = file.gets_to_end.split("\n")
    file.close
    channel = Channel(String).new
    targets.each do |x|
      spawn do
        scan = Scan.new(x, is_complete, engine)
        scan.run
        channel.send("done")
      end
    end
    targets.each do |x|
      channel.receive
    end
  end
end
