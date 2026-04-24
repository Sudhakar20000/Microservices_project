cd ~/e-t-e/internet-banking-concept-microservices

declare -A SERVICES=(
  ["service/api-gateway"]="internet-banking-api-gateway|api-gateway"
  ["service/config-server"]="internet-banking-config-server|config-server"
  ["service/core-banking"]="core-banking-service|core-banking"
  ["service/fund-transfer"]="internet-banking-fund-transfer-service|fund-transfer"
  ["service/service-registry"]="internet-banking-service-registry|service-registry"
  ["service/utility-payment"]="internet-banking-utility-payment-service|utility-payment"
)

for BRANCH in "${!SERVICES[@]}"; do
    IFS='|' read -r DIR NAME <<< "${SERVICES[$BRANCH]}"
    echo "==> Processing $BRANCH"
    git checkout "$BRANCH"

cat > "${DIR}/Jenkinsfile" << JEOF
pipeline {
    agent { label 'Node1' }

    environment {
        JAVA_HOME    = "/usr/lib/jvm/java-21-openjdk-amd64"
        PATH         = "\${JAVA_HOME}/bin:\${env.PATH}"
        DOCKER_USER  = "sudhakar20000"
        SERVICE_DIR  = "${DIR}"
        SERVICE_NAME = "${NAME}"
        IMAGE_TAG    = "\${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Building: ${NAME} | Branch: \${env.BRANCH_NAME} | Tag: \${IMAGE_TAG}"
            }
        }

        stage('Build & Test') {
            steps {
                dir("${DIR}") {
                    sh 'chmod +x gradlew'
                    sh './gradlew clean build --no-daemon'
                }
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: "${DIR}/build/test-results/**/*.xml"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube-scanner') {
                    script {
                        def scannerHome = tool 'sonarqube-scanner'
                        dir("${DIR}") {
                            sh "\${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=ib-${NAME} -Dsonar.projectName=ib-${NAME} -Dsonar.sources=src/main -Dsonar.tests=src/test -Dsonar.java.binaries=build/classes/java/main -Dsonar.exclusions=**/build/**"
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    dir("${DIR}") {
                        docker.withRegistry('https://index.docker.io/v1/', 'Dockerhub') {
                            def img = docker.build("sudhakar20000/ib-${NAME}:\${BUILD_NUMBER}", ".")
                            img.push()
                            img.push('latest')
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                        kubectl set image deployment/${NAME} \\
                            ${NAME}=sudhakar20000/ib-${NAME}:\${BUILD_NUMBER} \\
                            -n banking --kubeconfig=\\\$KUBECONFIG

                        kubectl rollout status deployment/${NAME} \\
                            -n banking --timeout=300s --kubeconfig=\\\$KUBECONFIG
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker rmi sudhakar20000/ib-${NAME}:\${BUILD_NUMBER} || true"
                sh "docker rmi sudhakar20000/ib-${NAME}:latest || true"
                cleanWs()
            }
        }
    }

    post {
        success { echo "✅ ${NAME} pipeline SUCCESS" }
        failure { echo "❌ ${NAME} pipeline FAILED" }
    }
}
JEOF

    git add "${DIR}/Jenkinsfile"
    git commit -m "fix: wrap docker.withRegistry in script block for ${NAME}"
    git push origin "$BRANCH"
    echo "✅ Done: $BRANCH"
done

echo "=============================="
echo "All 6 branches fixed ✅"
echo "=============================="
