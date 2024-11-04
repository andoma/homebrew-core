class Fastnetmon < Formula
  desc "DDoS detection tool with sFlow, Netflow, IPFIX and port mirror support"
  homepage "https://github.com/pavel-odintsov/fastnetmon/"
  url "https://github.com/pavel-odintsov/fastnetmon/archive/refs/tags/v1.2.7.tar.gz"
  sha256 "c21fcbf970214dd48ee8aa11e6294e16bea86495085315e7b370a84b316d0af9"
  license "GPL-2.0-only"
  revision 4

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "910dabec2a9d34c8d50380a910cdcb22ddb79026d0c9e6dcfd38b51d929d4454"
    sha256 cellar: :any,                 arm64_sonoma:  "2a82b6291887dd30eb5f2dfb0bde92175bc8f57ab9b333c4083af690919a48d2"
    sha256 cellar: :any,                 arm64_ventura: "a24872091f523738c660c3b278a1646121a1303bfce09e01560beeb94fdb3e8c"
    sha256 cellar: :any,                 sonoma:        "ca64375907d25b77e825dfd66b5b8943cedbdc8787f2f40c28ce978a82140c12"
    sha256 cellar: :any,                 ventura:       "f9931f797f02598c13ac9a572b416e734bc5413f9ae6f43830899d354e7438be"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "86e1f8b4c22d2aa2ffa9158a4536544525b390980853148c463127d919f0f177"
  end

  depends_on "cmake" => :build
  depends_on "abseil"
  depends_on "boost"
  depends_on "capnp"
  depends_on "grpc"
  depends_on "hiredis"
  depends_on "log4cpp"
  depends_on macos: :big_sur # We need C++ 20 available for build which is available from Big Sur
  depends_on "mongo-c-driver"
  depends_on "openssl@3"
  depends_on "protobuf"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "elfutils"
    depends_on "libbpf"
    depends_on "libpcap"
  end

  # Fix build failure with gRPC 1.67.
  # https://github.com/pavel-odintsov/fastnetmon/pull/1023
  patch do
    url "https://github.com/pavel-odintsov/fastnetmon/commit/b6cf2e7222c24343b868986e867ddb7adad0bf30.patch?full_index=1"
    sha256 "3a3f719f7434e52db01a512ed3891cf0e3794d4576323e3c2fd3b31c69fb39be"
  end

  def install
    system "cmake", "-S", "src", "-B", "build",
                    "-DLINK_WITH_ABSL=TRUE",
                    "-DSET_ABSOLUTE_INSTALL_PATH=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  service do
    run [
      opt_sbin/"fastnetmon",
      "--configuration_file",
      etc/"fastnetmon.conf",
      "--log_to_console",
      "--disable_pid_logic",
    ]
    keep_alive false
    working_dir HOMEBREW_PREFIX
    log_path var/"log/fastnetmon.log"
    error_log_path var/"log/fastnetmon.log"
  end

  test do
    cp etc/"fastnetmon.conf", testpath

    inreplace testpath/"fastnetmon.conf", "/tmp/fastnetmon.dat", (testpath/"fastnetmon.dat").to_s

    inreplace testpath/"fastnetmon.conf", "/tmp/fastnetmon_ipv6.dat", (testpath/"fastnetmon_ipv6.dat").to_s

    fastnetmon_pid = fork do
      exec opt_sbin/"fastnetmon",
           "--configuration_file",
           testpath/"fastnetmon.conf",
           "--log_to_console"
    end

    sleep 30

    assert_path_exists testpath/"fastnetmon.dat"

    ipv4_stats_output = (testpath/"fastnetmon.dat").read
    assert_match("Incoming traffic", ipv4_stats_output)

    assert_path_exists testpath/"fastnetmon_ipv6.dat"

    ipv6_stats_output = (testpath/"fastnetmon_ipv6.dat").read
    assert_match("Incoming traffic", ipv6_stats_output)
  ensure
    Process.kill "SIGTERM", fastnetmon_pid
  end
end
