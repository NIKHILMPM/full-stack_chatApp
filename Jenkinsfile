pipeline {
    agent any 
    
    environment {
        DOCKER_IMAGE_NAME = ""
        DOCKER_USER = "ramachandrampm"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        BRANCH_NAME = "dev"
    }

    stages {
        
        stage("checkout repo") {
            steps {
                checkout scm
            }
        }
        
        stage("check changed dir") {
            steps {
                script {
                    echo "pipeline triggered"

                    DOCKER_IMAGE_NAME = sh(
                        script: "git diff HEAD~1 HEAD --name-only | cut -d/ -f1 | sort -u",
                        returnStdout: true
                    ).trim()

                    echo "changed dir: ${DOCKER_IMAGE_NAME}"
                }
            }
        }
        
        stage("docker build and push") {
            steps {
                script {

                    def services = DOCKER_IMAGE_NAME.split("\n")

                    if (!(services.contains("frontend") || services.contains("backend"))) {
                        echo "No directories changed"
                        return
                    } else {

                        services.each { docker_image_name ->

                            if (docker_image_name == "frontend" || docker_image_name == "backend") {

                                def docker_image = "${DOCKER_USER}/chat-app-${docker_image_name}:${DOCKER_TAG}"

                                withDockerRegistry(credentialsId: 'dockerhub-creds', url: '') {
                                    sh "docker build -t ${docker_image} ./${docker_image_name}"
                                    sh "docker push ${docker_image}"
                                }

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
