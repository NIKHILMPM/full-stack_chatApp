pipeline {
    agent any 
    
    stages {
        stage("pipeline triggered") {
            steps {
                script {

                    echo "pipeline triggered"
                
                    def changed_dir = sh(
                        script: 'git diff HEAD~1 HEAD --name-only',
                        returnStdout: true
                    ).trim()
                
                    echo "changed dir: ${changed_dir}"

                }
            }
        }
    }
}
