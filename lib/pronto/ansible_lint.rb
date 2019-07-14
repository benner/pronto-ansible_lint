require 'pronto'
require 'shellwords'
require 'pry'

module Pronto
  # AnsibleLint Pronto Runner. Entry point is run
  class AnsibleLint < Runner
    YAML_FILE_EXTENSIONS = ['.yml', '.yaml'].freeze

    def initialize(patches, commit = nil)
      super(patches, commit)
    end

    def executable
      'ansible-lint'.freeze
    end

    def files
      return [] if @patches.nil?

      @files ||= begin
       @patches
         .select { |patch| patch.additions > 0 }
         .map(&:new_file_full_path)
         .compact
     end
    end

    def patch_line_for_offence(path, lineno)
      patch_node = @patches.find do |patch|
        patch.new_file_full_path.to_s == path
      end

      return if patch_node.nil?

      patch_node.added_lines.find do |patch_line|
        patch_line.new_lineno == lineno
      end
    end

    def run
      if files.any?
        messages(run_ansible_lint)
      else
        []
      end
    end

    def run_ansible_lint
      Dir.chdir(git_repo_path) do
        yaml_files = filter_yaml_files(files)
        files = yaml_files.join(' ')
        extra = ENV['PRONTO_ANSIBLE_LINT_OPTS']
        if !files.empty?
          cmd = "#{executable} --nocolor --parseable-severity #{extra} #{files}"
          parse_output `#{cmd}`
        else
          []
        end
      end
    end

    def yaml?(file)
      YAML_FILE_EXTENSIONS.select { |extension| file.end_with? extension }.any?
    end

    def filter_yaml_files(all_files)
      all_files.select { |file| yaml? file.to_s }
               .map { |file| file.to_s.shellescape }
    end

    def parse_output(executable_output)
      lines = executable_output.split("\n")
      lines.map { |line| parse_output_line(line) }
    end

    def parse_output_line(line)
      splits = line.strip.split(':')
      message = splits[2..].join(':').strip
      {
        file_path: splits[0],
        line_number: splits[1].to_i,
        column_number: 0,
        message: message,
        level: violation_level(message)
      }
    end

    def violation_level(message)
      if message.split[1].include? 'HIGH'
        'error'
      else
        'warning'
      end
    end

    def messages(json_list)
      json_list.map do |error|
        patch_line = patch_line_for_offence(error[:file_path],
                                            error[:line_number])
        next if patch_line.nil?

        description = error[:message]
        path = patch_line.patch.delta.new_file[:path]
        Message.new(path, patch_line, error[:level].to_sym,
                    description, nil, self.class)
      end
    end

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd))
                                           .workdir
    end
  end
end
