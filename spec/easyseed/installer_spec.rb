# frozen_string_literal: true

RSpec.describe Easyseed::Installer do
  let(:tmpdir) { Dir.mktmpdir("easyseed-installer") }
  let(:output) { StringIO.new }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "backs up an existing db/seeds.rb and writes the easyseed wrapper" do
    db_directory = File.join(tmpdir, "db")
    FileUtils.mkdir_p(db_directory)
    File.write(File.join(db_directory, "seeds.rb"), "# original seeds\n")

    installer = described_class.new(:root => tmpdir, :output => output)

    expect(installer.install!).to eq(:installed)
    expect(File.read(File.join(db_directory, "seeds.rb.bak"))).to eq("# original seeds\n")
    expect(File.read(File.join(db_directory, "seeds.rb"))).to eq(Easyseed.db_seeds_template)
    expect(File.directory?(File.join(db_directory, "seeds"))).to be(true)
    expect(File.exist?(File.join(db_directory, "seeds", ".gitkeep"))).to be(true)
    expect(File.read(File.join(db_directory, "seeds", "readme.txt"))).to include("001_z.csv")
  end

  it "does nothing when the wrapper is already installed" do
    db_directory = File.join(tmpdir, "db")
    FileUtils.mkdir_p(db_directory)
    File.write(File.join(db_directory, "seeds.rb"), Easyseed.db_seeds_template)

    installer = described_class.new(:root => tmpdir, :output => output)

    expect(installer.install!).to eq(:already_initialized)
    expect(File.exist?(File.join(db_directory, "seeds.rb.bak"))).to be(false)
    expect(File.directory?(File.join(db_directory, "seeds"))).to be(true)
    expect(File.exist?(File.join(db_directory, "seeds", ".gitkeep"))).to be(true)
    expect(File.read(File.join(db_directory, "seeds", "readme.txt"))).to include("Easyseed.run!")
  end
end
