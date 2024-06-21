const core = require('@actions/core')
const { getStackOutputs } = require('./spacelift')

async function runAction() {
  try {
    const stackId = core.getInput('spacelift_stack_id', { required: true })
    const keyId = core.getInput('spacelift_key_id', { required: true })
    const keySecret = core.getInput('spacelift_key_secret', { required: true })

    const outputs = await getStackOutputs(keyId, keySecret, stackId)
    core.setOutput('discovery_run_service_account', outputs['service_accounts']['discovery']['email'])
    core.setOutput('ipam_run_service_account', outputs['service_accounts']['ipam']['email'])
    core.setOutput('backend_run_service_account', outputs['service_accounts']['backend']['email'])
    core.setOutput('frontend_ae_service_account', outputs['service_accounts']['frontend']['email'])
    core.setOutput('docker_repository', outputs['docker_repository'])
    core.setOutput('gcp_region', outputs['gcp_region'])
    core.setOutput('gcp_project_id', outputs['gcp_project_id'])
  } catch (error) {
    core.setFailed(error.message)
  }
}

runAction()
