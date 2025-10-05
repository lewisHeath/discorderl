pipeline {
     agent {
        docker { image 'erlang:latest' }
    }
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building..."'
                sh 'which erl'
                sh 'pwd'
                sh 'make distclean'
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