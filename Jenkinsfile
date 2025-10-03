pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building..."'
                sh 'make distclean'
                sh 'make deps'
                sh 'make app'
                // Diagnostic: show ebin contents and the generated .app file so we can see why relx can't find the app
                sh 'ls -la ebin || true'
                sh 'erl -noshell -pa ebin -eval "io:format(\"ebin/discorderl.app exists: ~p\\n\", [filelib:is_file(\"ebin/discorderl.app\")]), io:format(\".app contents:\\n~p\\n\", [file:consult(\"ebin/discorderl.app\")]), halt()."'
                sh 'make rel'
            }
        }
        stage('Test') {
            steps {
                sh 'echo "Testing..."'
                sh 'make eunit'
                sh 'make ct'
            }
        }
        stage('Deploy') {
            steps {
                sh 'echo "Deploying..."'
                sh 'echo TODO'
                // TODO
            }
        }
    }
}