pipeline {
    agent any
    environment {
        NEXUS_USER     = credentials('nexus-username')
        NEXUS_PASSWORD = credentials('nexus-password')
        NEXUS_REPO     = credentials('nexus-repo')
    }
    stages {
        stage('Code Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('Build Artifact') {
            steps {
                sh 'mvn clean package -DskipTests -Dcheckstyle.skip'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $NEXUS_REPO/petclinicapps .'
            }
        }
        stage('Push Artifact to Nexus Repo') {
            steps {
                nexusArtifactUploader artifacts: [[
                    artifactId: 'spring-petclinic',
                    classifier: '',
                    file: 'target/spring-petclinic-2.4.2.war',
                    type: 'war']],
                    credentialsId: 'nexus-cred',
                    groupId: 'Petclinic',
                    nexusUrl: 'nexus.nugaops.click',
                    nexusVersion: 'nexus3',
                    protocol: 'https',
                    repository: 'nexus-repo',
                    version: '1.0'
            }
        }
        stage('Trivy fs Scan') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage('Log Into Nexus Docker Repo') {
            steps {
                sh 'docker login --username $NEXUS_USER --password $NEXUS_PASSWORD $NEXUS_REPO'
            }
        }
        stage('Push to Nexus Docker Repo') {
            steps {
                sh 'docker push $NEXUS_REPO/petclinicapps'
            }
        }
        stage('Trivy Image Scan') {
            steps {
                sh "trivy image $NEXUS_REPO/petclinicapps > trivyimage.txt"
            }
        }
        stage('Deploy to Stage') {
            steps {
                sh '''
                    aws ssm send-command \
                --instance-ids i-0e81fb11638602693 \
                --document-name "AWS-RunShellScript" \
                --parameters '{"commands":["ansible-playbook -i /etc/ansible/stage_hosts /etc/ansible/deployment.yml"]}' \
                --region eu-west-1 \
                --output text
                '''
            }
        }
        stage('Check Stage Website') {
            steps {
                sh "sleep 90"
                script {
                    def response = sh(script: "curl -s -o /dev/null -w \"%{http_code}\" https://stage.nugaops.click", returnStdout: true).trim()
                    if (response == "200") {
                        slackSend(color: 'good', message: "The stage petclinic app is up with HTTP status code ${response}.", tokenCredentialId: 'slack')
                    } else {
                        slackSend(color: 'danger', message: "The stage petclinic app appears down with HTTP status code ${response}.", tokenCredentialId: 'slack')
                    }
                }
            }
        }
        stage('Request for Approval') {
            steps {
                timeout(activity: true, time: 10) {
                    input message: 'Approve deployment to Production?', submitter: 'admin'
                }
            }
        }
        stage('Deploy to Prod') {
                    steps {
            sh '''
                aws ssm send-command \
                --instance-ids i-0e81fb11638602693 \
                --document-name "AWS-RunShellScript" \
                --parameters '{"commands":["ansible-playbook -i /etc/ansible/prod_hosts /etc/ansible/deployment.yml"]}' \
                --region eu-west-1 \
                --output text
                '''
            }
        }
        stage('Check Prod Website') {
            steps {
                sh "sleep 90"
                script {
                    def response = sh(script: "curl -s -o /dev/null -w \"%{http_code}\" https://prod.nugaops.click", returnStdout: true).trim()
                    if (response == "200") {
                        slackSend(color: 'good', message: "The prod petclinic app is up with HTTP status code ${response}.", tokenCredentialId: 'slack')
                    } else {
                        slackSend(color: 'danger', message: "The prod petclinic app appears down with HTTP status code ${response}.", tokenCredentialId: 'slack')
                    }
                }
            }
        }
    }
}
