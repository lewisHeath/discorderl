pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building..."'
                sh 'make distclean'
                sh 'make deps'
                sh 'make app'
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