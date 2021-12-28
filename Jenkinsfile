//Creating a basic steps of the stages in the CI in Jenkins
#!/usr/bin/env groovy
pipeline {
  agent { node { label 'symbiosis' } }
    
  tools {nodejs "node-12"}
  
  stages {
    
    //Code checkout from source code repository to the workspace
    stage('Checkout') {
      steps {
        git 'https://github.com/chapagain/nodejs-mysql-crud'
      }
    }
    
    //Install the dependency and build the code
    stage('Compile') {
      steps {
        sh 'npm install'
        sh 'npm run build'
      }
    }
    
    //Build a docker image
    stage('Build Image') {
      steps {
        sh 'docker build -t symbiosis/web-app-1.0 .'
        withCredentials([straing(credentialsId: 'symbiosis-pwd', variable: 'sysmbiosisPwd')]){
        sh "docker login -u symbiosis -p ${symbiosis-pwd}"
        sh 'docker push -t symbiosis/web-app-1.0'
        }
      }
    }
    
    //Scan the compiled code with SonarQube 
    Stage('Scan'){
      steps{
      def sonarqubeHome = tool 'SonarScanner 4.0';
      sh "${sonarqubeHome}/bin/sonar-scanner"
      }
    }
    
    //Publish the artifacts to Nexus/Jfrog Artifactory. Since I am familiar in using the Cloudbes Electric flow, I will publish to flow artifactory as well to setup a CD pipeline.
    //Alternatively I can use ssh to deploy via Jenkins as well to the target servers
    Stage('Publish'){ 
        steps {
          //sh 'curl -v -u $userName:$nexusPwd --upload-file build.zip http://nexus/repository/symbiosis/web/$buildVersion/'
          //sh 'ectool publishArtifactVersion --artifactName  --version --repositoryName'
      }
    }
    
    //Deploy and Run the container on the target servers
    Stage('Deploy Dev'){
        def runDocker = 'docker run -p 8080:8080 -d -name web-app symbiosis/web-app:1.0'
      sshagent('dev-server') {
        sh "ssh -o StrictHostKeyChecking=no ec2-user@10.11.12.13 ${dockerRun}"
    }
  }
   
    Stage('Deploy UAT'){
        def runDocker = 'docker run -p 8080:8080 -d -name web-app symbiosis/web-app:1.0'
      sshagent('uat-server') {
        sh "ssh -o StrictHostKeyChecking=no ec2-user@10.14.15.16 ${dockerRun}"
    }
  }
    Stage('Deploy PROD'){
        def runDocker = 'docker run -p 8080:8080 -d -name web-app symbiosis/web-app:1.0'
      sshagent('prod-server') {
        sh "ssh -o StrictHostKeyChecking=no ec2-user@10.17.18.19 ${dockerRun}"
    }
  }
}
