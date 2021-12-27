pipeline {
  agent any
    
  tools {nodejs "node"}
    
  stages {
        
    stage('Checkout') {
      steps {
        git 'https://github.com/chapagain/nodejs-mysql-crud'
      }
    }
     
    stage('Compile') {
      steps {
        sh 'npm install'
        sh 'npm run build'
      }
    }  

  }
}
