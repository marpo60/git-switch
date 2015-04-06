gem "minitest"
require "minitest/autorun"

module TestHelpers
  BASE_PATH = File.expand_path(File.dirname(__FILE__))
  FIXTURE_PATH = File.join(BASE_PATH, "..", "tmp", "fixture")
  GIT_DIR = File.join(FIXTURE_PATH, ".git")

  def generate_fixture
    `#{File.join(BASE_PATH, "fixture.sh")}`
  end

  def git_switch(*arguments)
    command = ["git", "--git-dir=#{GIT_DIR}", "switch"] | arguments

    IO.popen(command.join(" "), "r+") do |io|
      io.puts "q"
      io.read
    end
  end

  def change_branch(number)
    command = ["git", "--git-dir=#{GIT_DIR}", "switch"]

    # FIXME silence sub process output
    IO.popen(command.join(" "), "r+") do |io|
      io.puts number
      io.read
    end
  end

  def current_branch
    `git --git-dir=#{GIT_DIR} symbolic-ref HEAD | sed s,refs/heads/,,`.chomp
  end
end

class String
  def fix
    gsub(/^\s+/, '').chomp + " "
  end

  def trim
    gsub(/^\s+/, '')
  end
end

describe "git-switch" do
  include TestHelpers

  before do
    generate_fixture
  end

  it "lists branches order by modified date" do
    git_switch("--modified").must_equal <<-EOT.fix
      1. feature_three
      2. feature_two
      3. feature_one
      Select a branch (1-3,q)
    EOT
  end

  it "lists branches order by modified date using short argument" do
    git_switch("-m").must_equal <<-EOT.fix
      1. feature_three
      2. feature_two
      3. feature_one
      Select a branch (1-3,q)
    EOT
  end

  it "lists branches order by checked out date" do
    git_switch("--checked-out").must_equal <<-EOT.fix
      1. feature_two
      2. feature_three
      3. feature_one
      Select a branch (1-3,q)
    EOT
  end

  it "lists branches order by checked out date using short argument" do
    git_switch("-o").must_equal <<-EOT.fix
      1. feature_two
      2. feature_three
      3. feature_one
      Select a branch (1-3,q)
    EOT
  end

  it "limits the number of branches to show" do
    git_switch("--count 2").must_equal <<-EOT.fix
      1. feature_three
      2. feature_two
      Select a branch (1-2,q)
    EOT
  end

  it "limits the number of branches to show using short argument" do
    git_switch("-c 2").must_equal <<-EOT.fix
      1. feature_three
      2. feature_two
      Select a branch (1-2,q)
    EOT
  end

  it "lists branches and exit" do
    git_switch("--non-interactive").must_equal <<-EOT.trim
      feature_three
      feature_two
      feature_one
    EOT
  end

  it "checks out the first branch" do
    change_branch(1)

    current_branch.must_equal("feature_three")
  end

  it "checks out the second branch" do
    change_branch(2)

    current_branch.must_equal("feature_two")
  end

  it "checks out the third branch" do
    change_branch(3)

    current_branch.must_equal("feature_one")
  end

  it "yells about invalid options" do
    change_branch(4).must_match("Invalid option '4'")
    change_branch(0).must_match("Invalid option '0'")
    change_branch("r").must_match("Invalid option 'r'")
  end
end
