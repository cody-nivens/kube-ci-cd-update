#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def env = System.getenv()

def instance = Jenkins.getInstance()


def user = hudson.model.User.get(env.JENKINS_USER, false)

if(user == null) {
  println "--> creating local user ''"
  def hudsonRealm = new HudsonPrivateSecurityRealm(false)
  hudsonRealm.createAccount(env.JENKINS_USER, env.JENKINS_PASS)
  instance.setSecurityRealm(hudsonRealm)

  def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
  instance.setAuthorizationStrategy(strategy)
  instance.save()

  Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

  if (!instance.installState.isSetupComplete()) {
    println '--> Neutering SetupWizard'
    InstallState.INITIAL_SETUP_COMPLETED.initializeState()
  }

  instance.save()
}
