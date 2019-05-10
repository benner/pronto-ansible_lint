require 'spec_helper'

module Pronto
  describe AnsibleLint do
    let(:ansible_lint) { AnsibleLint.new(patches) }
    let(:patches) { [] }
    describe '#executable' do
      subject(:executable) { ansible_lint.executable }

      it 'is `ansible-lint` by default' do
        expect(executable).to eql('ansible-lint')
      end
    end

    describe 'parsing' do
      it 'filtering YAML files' do
        files = %w[/Users/benner/requirements.txt /Users/benner/main.yaml /Users/benner/playbook.yml]
        exp = ansible_lint.filter_yaml_files(files)
        expect(exp).to eq(['/Users/benner/main.yaml', '/Users/benner/playbook.yml'])
      end

      it 'extracts violation level' do
        expect(ansible_lint.violation_level('[E201] [INFO] Trailing whitespace')).to eq('warning')
        expect(ansible_lint.violation_level('[E206] [LOW] Variables should have spaces before and after: {{ var_name }}')).to eq('warning')
        expect(ansible_lint.violation_level('[E401] [MEDIUM] Git checkouts must contain explicit version')).to eq('warning')
        expect(ansible_lint.violation_level('[E301] [HIGH] Commands should not change things if nothing needs doing')).to eq('error')
        expect(ansible_lint.violation_level('[E0015] [VERY_HIGH] Executing a command when there are arguments to modules ')).to eq('error')
      end

      it 'parses a linter output to a map' do
        executable_output = "haproxy/tasks/main.yaml:9: [E403] [VERY_LOW] Package installs should not use latest\n" +
                            "nginx/tasks/main.yaml:20: [E301] [HIGH] Commands should not change things if nothing needs doing\n" +
                            "entry.yml:12: [E206] [LOW] Variables should have spaces before and after: {{ var_name }}"
        act = ansible_lint.parse_output(executable_output)
        exp = [
          {
            file_path: 'haproxy/tasks/main.yaml',
            line_number: 9,
            column_number: 0,
            message: '[E403] [VERY_LOW] Package installs should not use latest',
            level: 'warning'

          },
          {
            file_path: 'nginx/tasks/main.yaml',
            line_number: 20,
            column_number: 0,
            message: '[E301] [HIGH] Commands should not change things if nothing needs doing',
            level: 'error'
          },
          {
            file_path: 'entry.yml',
            line_number: 12,
            column_number: 0,
            message: '[E206] [LOW] Variables should have spaces before and after: {{ var_name }}',
            level: 'warning'
          }
        ]
        expect(act).to eq(exp)
      end
    end

    describe '#run' do
      around(:example) do |example|
        create_repository
        Dir.chdir(repository_dir) do
          example.run
        end
        delete_repository
      end

      let(:patches) { Pronto::Git::Repository.new(repository_dir).diff("master") }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(ansible_lint.run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(ansible_lint.run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          function_use = <<-EOF
          EOF
          add_to_index('some.yaml', function_use)
          create_commit
        end

        context 'with error in changed file' do
          before(:each) do
            create_branch('staging', checkout: true)

            updated_function_def = <<-EOF
          - tasks:
            - git: repo=hello
            EOF

            add_to_index('main.yaml', updated_function_def)

            create_commit
          end

          it 'returns correct error message' do
            run_output = ansible_lint.run
            expect(run_output.count).to eql(2)
            expect(run_output[0].msg).to eql('[E401] [MEDIUM] Git checkouts must contain explicit version')
            expect(run_output[1].msg).to eql('[E502] [MEDIUM] All tasks should be named')
          end
        end
      end
    end
  end
end
