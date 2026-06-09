pipeline {
    agent none

    options {
        timestamps()
        skipDefaultCheckout(false)
    }

    stages {

        stage('Analyse API (Spring Boot)') {
            agent {
                docker {
                    image 'maven:3.9-eclipse-temurin-21'
                    args '-v $HOME/.m2:/root/.m2 --network ci-stack_ci-net'
                }
            }
            steps {
                dir('api') {
                    withSonarQubeEnv('sonarqube') {
                        sh '''
                            mvn -B clean verify sonar:sonar \
                                -Dsonar.projectKey=kbudget-api \
                                -Dsonar.projectName=kbudget-api
                        '''
                    }
                }
            }
        }

        stage('Analyse APP (Angular)') {
            agent {
                docker {
                    image 'node:22-alpine'
                    args '--network ci-stack_ci-net'
                }
            }
            steps {
                dir('app') {
                    withSonarQubeEnv('sonarqube') {
                        sh '''
                            npm ci
                            npx --yes @sonar/scan \
                                -Dsonar.projectKey=kbudget-app \
                                -Dsonar.projectName=kbudget-app \
                                -Dsonar.sources=src \
                                -Dsonar.exclusions=**/node_modules/**,**/*.spec.ts,**/dist/**
                        '''
                    }
                }
            }
        }
    }
}
