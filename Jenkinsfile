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
      }
    }
    
    //Scan the compiled code with SonarQube 
    Stage('Scan'){
      steps{
      def sonarqubeHome = tool 'SonarScanner 4.0';
      sh "${sonarqubeHome}/bin/sonar-scanner"
      }
    }
    
    //Publish the artifacts to Nexus/Jfrog Artifactory. I am publishing to Electric Flow repository as I am planning to use Flow as CD tool.
    Stage('Publish'){ 
        steps {
          //sh 'curl -v -u $userName:$nexusPwd --upload-file build.zip http://nexus/repository/symbiosis/web/$buildVersion/'
          sh 'ectool publishArtifactVersion --artifactName  --version --repositoryName'
      }
    }
    
    
  }
}
