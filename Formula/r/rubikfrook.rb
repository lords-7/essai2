class Rubikfrook < Formula
  desc "3x3 rubik solver"
  homepage "https://github.com/NewBieCoderXD/rubikFROOK-3x3-solver/"
  url "https://github.com/NewBieCoderXD/rubikFROOK-3x3-solver.git", tag: "v1.0.1", revision: "4978b1c05d2fa986f557775eb3db98474f2fc3ff"
  license "Apache-2.0"
  head "https://github.com/NewBieCoderXD/rubikFROOK-3x3-solver.git", branch: "main"
  depends_on "openjdk"
 
  def install
    bin.install "scripts/rubikFROOK"
    bin.install "build/rubikFROOK.jar"
    Dir.mkdir "#{prefix}/build/"
    Dir.mkdir "#{prefix}/scripts/"
    mv "#{bin}/rubikFROOK.jar", "#{prefix}/build/"
    mv "#{bin}/rubikFROOK", "#{prefix}/scripts/"
    bin.install_symlink "#{prefix}/scripts/rubikFROOK"
  end

  test do
    system "#{bin}/rubikFROOK", "-h"
  end
end
