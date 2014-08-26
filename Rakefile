require 'rake'

HOMEBREW_PLUGINS = [
  'ack',
  'cmake',
  'ctags',
  'heroku',
  'node',
  'mercurial',
  'postgresql',
  'python',
  'redis',
  'the_silver_searcher',
  'tmux'
]

PIP_PACKAGES = [
  'Pygments'
]

desc "Setup development machine"
task :install => [:zsh,:homebrew,:vim,:rvm,:vundler,:dotfiles] do
  puts "Finish installation!"
end

namespace :install do
  task :vundler do
    puts "Installing Vundle and other VIM plugins..."
    system 'git clone https://github.com/gmarik/Vundle.vim ~/.vim/bundle/Vundle.vim'
    system 'mkdir ~/.vim/backups'
    system 'vim +PluginInstall +qall'
    system 'cd ~/.vim/bundle/YouCompleteMe && ./install.sh'
  end

  task :dotfiles do
    files = Dir['*'] - %w[Rakefile README.md LICENSE]
    files.each do |file|
      system %Q{mkdir -p "$HOME/.#{File.dirname(file)}"} if file =~ /\//
      if File.exist?(File.join(ENV['HOME'], ".#{file.sub(/\.erb$/, '')}"))
        if File.identical? file, File.join(ENV['HOME'], ".#{file.sub(/\.erb$/, '')}")
          puts "identical ~/.#{file.sub(/\.erb$/, '')}"
        else
          print "overwrite ~/.#{file.sub(/\.erb$/, '')}? [ynq] "
          case $stdin.gets.chomp
          when 'y'
            replace_file(file)
          when 'q'
            exit
          else
            puts "skipping ~/.#{file.sub(/\.erb$/, '')}"
          end
        end
      else
        link_file(file)
      end
    end
  end

  task :python_packages do
    PIP_PACKAGES.each do |pkg|
      puts "Installing #{pkg}..."
      system "sudo pip install #{pkg}"
      puts "Finish installing #{pkg}"
    end
  end

  task :zsh do
    puts "Installing oh-my-zsh..."
    system "curl -L http://install.ohmyz.sh | sh"
    switch_to_zsh
  end

  task :homebrew do
    puts "Installing Homebrew..."
    system 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    system "brew update"
    puts "Installing brew packages..."
    install_brew_packages_with_instructions
  end

  task :vim do
    if File.exist?('/opt/local/bin/vim')
      puts "VIM already exists."
    else
      system "sudo mkdir -p /opt/local/bin"
      system 'hg clone https://code.google.com/p/vim/ xxx'
      system 'cd vim'
      configure_command = <<-eos
      ./config \
      --prefix=/opt/local
      --enable-pythoninterp \
      --with-python-config-dir=/usr/bin/python2.7-config
      eos
      system configure_command
      system 'make'
      system 'sudo make install'
      system 'cd .. && rm -rf xxx'
    end
  end

  task :rvm do
    system "curl -sSL https://get.rvm.io | bash -s stable"
    print "Which version of ruby do you want to install? (e.g. '2.1.1') "
    system "rvm install #{$stdin.gets.chomp}"
  end
end

def replace_file(file)
  system %Q{rm -rf "$HOME/.#{file.sub(/\.erb$/, '')}"}
  link_file(file)
end

def link_file(file)
  # copy zshrc instead of link
  if file =~ /zshrc$/
    puts "copying ~/.#{file}"
    system %Q{cp "$PWD/#{file}" "$HOME/.#{file}"}
  else
    puts "linking ~/.#{file}"
    system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
  end
end

def switch_to_zsh
  if ENV["SHELL"] =~ /zsh/
    puts "Already using zsh"
  else
    print "Switch to zsh? (recommended) [ynq] "
    case $stdin.gets.chomp
    when 'y'
      puts "Switching to zsh"
      system %Q{chsh -s `which zsh`}
    when 'q'
      exit
    else
      puts "skipping zsh"
    end
  end
end

def install_brew_packages_with_instructions
  HOMEBREW_PLUGINS.each do |plugin|
    puts "Installing #{plugin}..."
    system "brew install #{plugin}"
    post_installation_commands
    puts "Finish installing #{plugin}"
  end
end

def post_installation_commands
  print "Paste post-installation commands here; otherwise, type 'continue': "
  input = $stdin.gets.chomp
  while input != "continue"
    system input
    input = $stdin.gets.chomp
  end
end
