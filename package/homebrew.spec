%{!?git_version: %global git_version 0.0.1}
%{!?git_rev: %global git_rev 0}
%define homebrew_user linuxbrew
%define homebrew_directory /home/%{homebrew_user}/.%{homebrew_user}
%define brew_repo https://github.com/Homebrew/brew

Summary:   Homebrew package manager
Name:      homebrew
Version:   %{git_version}
Release:   %{git_rev}
License:   BSD-2-clause
Group:     Development/Tools
Source:    %{brew_repo}/archive/refs/tags/%{git_version}.tar.gz#/brew.tar.gz

# See: https://github.com/Homebrew/install/blob/master/install.sh#L211-L214
BuildRequires: git

Autoreq:  no
Requires: procps-ng
Requires: file
Requires: gcc
Requires: git >= 2.7.0
Requires: glibc >= 2.13
Requires: ruby >= 2.6.0

%description
The Missing Package Manager for macOS (or Linux)

%global debug_package %{nil}
%global _missing_build_ids_terminate_build 0
%global __brp_mangle_shebangs /usr/bin/true

%prep
%autosetup -n brew

%build
git remote set-url origin %{brew_repo} || git remote add origin %{brew_repo}

%install
install -d "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r bin "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r completions "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r manpages "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r docs "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r package "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .git "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .github "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .gitignore "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .shellcheckrc "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .sublime "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .vscode "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .devcontainer "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .dockerignore "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .editorconfig "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r .vale.ini "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r Dockerfile "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r *.md "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -r *.txt "$RPM_BUILD_ROOT%{homebrew_directory}"
cp -rd Library "$RPM_BUILD_ROOT%{homebrew_directory}"

pushd "$RPM_BUILD_ROOT%{homebrew_directory}"
mkdir -vp Cellar Frameworks etc include lib opt sbin share var/homebrew/linked

%check
export HOMEBREW_NO_ANALYTICS_THIS_RUN=1
export HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT=1
sudo -u "%{homebrew_user}" %{homebrew_directory}/bin/brew config
sudo -u "%{homebrew_user}" %{homebrew_directory}/bin/brew doctor

%pre
getent passwd %{homebrew_user} >/dev/null || \
    useradd -r -d %{homebrew_directory} -s /sbin/nologin \
    -c "The Homebrew default user" %{homebrew_user}

%post
chown -R "%{homebrew_user}:%{homebrew_user}" %{homebrew_directory}

%preun
if [ $1 == 0 ];then
   userdel %{homebrew_user}
fi

%files
%{homebrew_directory}
%license %{homebrew_directory}/LICENSE.txt
%doc %{homebrew_directory}/CHANGELOG.md
%doc %{homebrew_directory}/CONTRIBUTING.md
%doc %{homebrew_directory}/README.md

%changelog
