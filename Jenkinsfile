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
    
    //Scan the compiled code with SonarQube 
    Stage('Scan'){
      def scannerHome = tool 'SonarScanner 4.0';
      sh "${sonarqubeHome}/bin/sonar-scanner"
    }
    
    //Publish the artifacts to Nexus/Jfrog Artifactory
    Stage('Publish'){ 
        steps {
          sh 'curl -v -u $userName:$nexusPwd --upload-file build.zip http://nexus/repository/symbiosis/web/$buildVersion/'
      }
    }
    
    
  }
}
