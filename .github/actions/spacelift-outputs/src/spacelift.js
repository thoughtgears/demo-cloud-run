const axios = require('axios')

const spaceliftAPIUrl = 'https://thoughtgears.app.spacelift.io/graphql'

/**
 * Performs a GraphQL request to the Spacelift API.
 *
 * @param {string} query - The GraphQL query or mutation.
 * @param {Object} variables - An object containing all the variables needed for the query.
 * @param {string} [token] - Optional JWT token for authenticated requests.
 * @returns {Promise<Object>} The data part of the GraphQL response.
 * @throws {Error} Throws an error if the request fails or GraphQL errors are returned.
 */
async function graphqlRequest(query, variables, token = '') {
  const headers = {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` })
  }

  const response = await axios.post(
    spaceliftAPIUrl,
    {
      query,
      variables
    },
    { headers }
  )

  if (response.data.errors) {
    throw new Error(`GraphQL error: ${response.data.errors.map(e => e.message).join(', ')}`)
  }

  return response.data
}

/**
 * Retrieves a JWT token by making a GraphQL mutation with user credentials.
 *
 * @param {string} keyId - The spacelift API key ID.
 * @param {string} keySecret - The spacelift API key secret.
 * @returns {Promise<string>} A promise that resolves with the JWT token.
 * @throws {Error} Throws an error if unable to retrieve the JWT token.
 */
async function getJWT(keyId, keySecret) {
  const query = `
    mutation ($keyId: ID!, $keySecret: String!) {
      apiKeyUser(id: $keyId, secret: $keySecret) {
        jwt
      }
    }
  `
  const response = await graphqlRequest(query, { keyId, keySecret })
  // console.log(JSON.stringify(data));
  return response.data.apiKeyUser.jwt
}

/**
 * Fetches the stack outputs from the Spacelift API for a given stack ID, using a JWT for authentication.
 *
 * @param {string} keyId - The spacelift API key ID.
 * @param {string} keySecret - The spacelift API key secret.
 * @param {string} stackId - The stack ID to fetch outputs for.
 *
 * @returns {Promise<Object>} A promise that resolves with an object where each key is an output ID and each value is the parsed output value.
 * @throws {Error} Throws an error if unable to fetch the stack outputs.
 */
async function getStackOutputs(keyId, keySecret, stackId) {
  const jwt = await getJWT(keyId, keySecret)

  const query = `
    query ($id: ID!) {
      stack(id: $id) {
        outputs {
          id
          value
        }
      }
    }
  `

  const response = await graphqlRequest(query, { id: stackId }, jwt)
  return response.data.stack.outputs.reduce((acc, { id, value }) => {
    acc[id] = JSON.parse(value)
    return acc
  }, {})
}

module.exports = { getStackOutputs }
