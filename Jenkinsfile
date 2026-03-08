pipeline {
    agent any 
    
    environment {
        DOCKER_USER = "ramachandrampm"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        BRANCH_NAME = "dev"
        
    }

    stages {
        
        stage("Checkout Source Code") {
            steps {
                checkout scm
            }
        }

        stage("SonarQube Code Analysis") {
            steps {
                echo "Running SonarQube code analysis"
            }
        }

        stage("OWASP Dependency Check") {
            steps {
                echo "Running OWASP dependency check"
            }
        }
        
        stage("Detect Changed Services") {
            steps {
                script {
                    echo "Pipeline triggered"

                    services = sh(
                        script: "git diff HEAD~1 HEAD --name-only | cut -d/ -f1 | sort -u",
                        returnStdout: true
                    ).trim()

                    svc = services.split("\n")

                    if (!(svc.contains("frontend") || svc.contains("backend"))) {
                        error("No relevant service directories changed")
                    } else {

                        svc.each { docker_image_name ->

                            def docker_image = "${DOCKER_USER}/chat-app-${docker_image_name}:${DOCKER_TAG}"

                            stage("Trivy Security Scan - ${docker_image_name}") {
                                echo "Running Trivy security scan"
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

                                    sed -i "s|image:.*|image:${docker_image}|g" k8s/${docker_image_name}-manifest.yaml

                                    git add k8s/${docker_image_name}-manifest.yaml

                                    if ! git diff --cached --quiet; then
                                        git commit -m "update ${docker_image_name} image to ${docker_image}"
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
