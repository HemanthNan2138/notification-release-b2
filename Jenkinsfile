
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(
            numToKeepStr: '20',
            artifactNumToKeepStr: '10'
        ))
    }

    parameters {
        string(
            name: 'RELEASE_VERSION',
            defaultValue: '1.0.0',
            description: 'Enter release version (example: 1.0.0)'
        )

        choice(
            name: 'DEPLOY_ENV',
            choices: ['development', 'staging', 'production'],
            description: 'Select deployment environment'
        )

        choice(
            name: 'RELEASE_ACTION',
            choices: ['package', 'cancel'],
            description: 'Choose whether to package or cancel the release'
        )
    }

    stages {

        stage('Inspect Workspace') {
            steps {
                echo '========== RELEASE PIPELINE =========='
                echo "Job Name       : ${env.JOB_NAME}"
                echo "Build Number   : ${env.BUILD_NUMBER}"
                echo "Build URL      : ${env.BUILD_URL}"
                echo "Release Version: ${params.RELEASE_VERSION}"
                echo "Deploy Env     : ${params.DEPLOY_ENV}"

                sh '''
                    echo "Current workspace:"
                    pwd
                    echo "Repository files:"
                    ls -la
                '''
            }
        }

        stage('Validate Repository') {
            steps {
                echo 'Checking required repository files...'

                sh '''
                    bash scripts/validate-release.sh
                '''
            }
        }

        stage('Validate Release Version') {
            steps {
                script {
                    def version = params.RELEASE_VERSION.trim()

                    if (!version) {
                        error('Release version cannot be blank.')
                    }

                    if (!(version ==~ /^[0-9]+\\.[0-9]+\\.[0-9]+$/)) {
                        error(
                            "Invalid release version: ${version}. " +
                            "Expected format: MAJOR.MINOR.PATCH (example: 1.0.0)"
                        )
                    }

                    echo "Release version ${version} is valid."
                }
            }
        }

        stage('Prepare Release Package') {
            steps {
                echo 'Preparing release package...'

                sh '''
                    rm -rf release
                    mkdir -p release

                    cp -r app release/
                    cp -r config release/
                    cp docs/release-notes.md release/

                    echo "Release package contents:"
                    find release -type f -print
                '''
            }
        }

        stage('Generate Release Manifest') {
            steps {
                echo 'Generating release manifest...'

                sh '''
                    cat > release/manifest.txt <<EOF
Release Version: ${RELEASE_VERSION}
Deployment Environment: ${DEPLOY_ENV}
Jenkins Job: ${JOB_NAME}
Build Number: ${BUILD_NUMBER}
Build URL: ${BUILD_URL}
EOF

                    echo "Manifest contents:"
                    cat release/manifest.txt
                '''
            }
        }

        stage('Package Verification') {
            steps {
                echo 'Verifying release package...'

                sh '''
                    test -s release/app/index.html
                    test -s release/config/release-policy.txt
                    test -s release/release-notes.md
                    test -s release/manifest.txt

                    grep -F \
                      "Release Version: ${RELEASE_VERSION}" \
                      release/manifest.txt

                    echo "Package verification PASSED."
                '''
            }
        }

        stage('Manual Release Approval') {
            when {
                expression {
                    params.RELEASE_ACTION == 'package'
                }
            }

            steps {
                input(
                    message: "Approve release ${params.RELEASE_VERSION} for ${params.DEPLOY_ENV}?",
                    ok: 'Proceed'
                )

                echo 'Manual release approval received.'
            }
        }

        stage('Release Decision') {
            steps {
                script {
                    if (params.RELEASE_ACTION == 'cancel') {
                        echo 'Release action is CANCEL.'
                        echo 'Release package will NOT be archived.'
                        currentBuild.description =
                            "Cancelled release: ${params.RELEASE_VERSION}"
                    } else {
                        echo 'Release action is PACKAGE.'
                        echo 'Release approved; proceeding to archive.'
                    }
                }
            }
        }

        stage('Archive Release Package') {
            when {
                expression {
                    params.RELEASE_ACTION == 'package'
                }
            }

            steps {
                echo 'Archiving approved release package...'

                archiveArtifacts(
                    artifacts: 'release/**',
                    fingerprint: true,
                    onlyIfSuccessful: true
                )

                echo 'Release package archived successfully.'
            }
        }
    }

    post {
        success {
            echo 'PIPELINE SUCCESS: Release workflow completed.'
        }

        failure {
            echo 'PIPELINE FAILURE: Check Console Output for details.'
        }

        aborted {
            echo 'PIPELINE ABORTED: Manual approval was rejected or build stopped.'
        }

        always {
            echo "Build completed: ${env.BUILD_NUMBER}"
            echo "Build result: ${currentBuild.currentResult}"
        }
    }
}
