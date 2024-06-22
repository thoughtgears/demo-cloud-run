# Spacelift

This cloud build builder will query spacelift for stack runs to ensure that the terraform runes are successful.
This can be used to ensure that the terraform runs are successful before building and deploying applications or
other cloud build steps that require infrastructure to be in place.

## Usage

```yaml
steps:
  - name: 'gcr.io/$PROJECT_ID/spacelift'
    id: 'spacelift'
    env:
      - 'SPACELIFT_URL=$_SPACELIFT_URL'
    secretEnv: [ 'SPACELIFT_API_KEY', 'SPACELIFT_KEY_ID', 'SPACELIFT_STACK_ID' ]
```