def svc = []

pipeline {
    agent any

    
    environment {
        DOCKER_USER = 'ramachandrampm'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        BRANCH_NAME = 'main'
        SONAR_HOME = tool 'sonar-tool'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('check if manual build') {
            steps {
                script {
                    def isManual = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')

                    if (isManual) {
                        echo 'Manual build detected'
                        svc = ['frontend', 'backend']
                    }else {
                        svc = []
                    }
                }
            }
        }

        stage('checking if any changes were made in main code') {
            steps {
                script {
                    if (svc.isEmpty()) {
                        def services = sh(
                            script: 'git diff HEAD~1 HEAD --name-only | cut -d/ -f1 | sort -u',
                            returnStdout: true
                        ).trim()

                        svc = services.split('\n').findAll { it == 'frontend' || it == 'backend' }

                        if (svc.isEmpty()) {
                            echo 'No changes detected in frontend or backend'
                            currentBuild.result = 'NOT_BUILT'
                            return
                        }
                    }
                }
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                    $SONAR_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=chat-app \
                    -Dsonar.projectKey=chat-app \
                    -Dsonar.sources=.
                    """
                }
            }
        }

        stage("Pipeline Dependency Check") {
            steps {
                dependencyCheck additionalArguments: '--scan . --format XML --format HTML', odcInstallation: 'owasp-tool'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('docker and argo cd configuration') {
            steps {
                script {
                    echo 'Pipeline triggered'

                    if (svc.isEmpty()) {
                        echo 'No relevent services were changed'
                    } else {
                        svc.each { docker_image_name ->
                            def docker_image = "${DOCKER_USER}/chat-app-${docker_image_name}:${DOCKER_TAG}"

                            stage("Trivy Security Scan - ${docker_image_name}") {
                                echo 'Running Trivy security scan'
                                sh "trivy fs --format table -o trivy-${docker_image_name}-report.txt ./${docker_image_name}"
                            }

                            stage("Build and Push Docker Image - ${docker_image_name}") {
                                withDockerRegistry(credentialsId: 'dockerhub-creds', url: '') {
                                    sh "docker build -t ${docker_image} ./${docker_image_name}"
                                    sh "docker push ${docker_image}"
                                }
                            }

                            stage("Update Kubernetes Manifest - ${docker_image_name}") {
                                withCredentials([usernamePassword(
                                    credentialsId: 'github-creds',
                                    usernameVariable: 'GIT_USERNAME',
                                    passwordVariable: 'GIT_TOKEN'
                                )]) {
                                    sh """
                                    git config user.name "jenkins"
                                    git config user.email "jenkins@ci.com"

                                    sed -i "s|image:.*|image: ${docker_image}|g" k8s/${docker_image_name}-manifest.yaml

                                    git add k8s/${docker_image_name}-manifest.yaml

                                    if ! git diff --cached --quiet; then
                                        git commit -m "[ci skip] update ${docker_image_name} image to ${docker_image}"
                                        git push https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/NIKHILMPM/full-stack_chatApp.git HEAD:${BRANCH_NAME}
                                    fi
                                    """
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
