class Zellij < Formula
  desc "Pluggable terminal workspace, with terminal multiplexer as the base feature"
  homepage "https://zellij.dev"
  url "https://github.com/zellij-org/zellij/archive/refs/tags/v0.41.0.tar.gz"
  sha256 "cfe987c6ab8adeb484cd429618a8019d162b7298b98da2288eed1b1d9aaf8ef5"
  license "MIT"
  head "https://github.com/zellij-org/zellij.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0644baeb973a27d0c79e07bbeea7c2a584985cd1f4cbb2b63b3bccd4d473bc21"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "ed10620327be5daf02694a73f771c597051bbb877d45a3a3ca1f382d952f6252"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "75bdb0fa3e01296d9a017e00e37322fe69cd3ede5776dbebbfc7a8d2365accc7"
    sha256 cellar: :any_skip_relocation, sonoma:        "e66300dfc2877b6e7478e369e5e6b577b671a4fb8c3167ae18278108463be751"
    sha256 cellar: :any_skip_relocation, ventura:       "243494af921542c846e667c6e3e782c0aa25acf96483e798835c5c8ae959e520"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "f0345a431c5f24291313c51dbe4986ca0f8e7ed57e07692117eb85d207f54046"
  end

  depends_on "rust" => :build
  depends_on "openssl@3"

  uses_from_macos "zlib"

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"zellij", "setup", "--generate-completion")
  end

  test do
    assert_match("keybinds", shell_output("#{bin}/zellij setup --dump-config"))
    assert_match("zellij #{version}", shell_output("#{bin}/zellij --version"))
  end
end
