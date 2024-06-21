import requests
import os
import sys
import time

spacelift_api_url = os.getenv("SPACELIFT_API_URL")


def graphql_request(query, variables, token=""):
    """
    Performs a GraphQL request to the Spacelift API.

    :param query: The GraphQL query or mutation.
    :param variables: An object containing all the variables needed for the query.
    :param token: Optional JWT token for authenticated requests.
    :return: The data part of the GraphQL response.
    :raises Exception: Throws an error if the request fails or GraphQL errors are returned.
    """
    headers = {
        "Content-Type": "application/json",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = requests.post(spacelift_api_url, json={"query": query, "variables": variables}, headers=headers).json()
    if "errors" in response:
        raise Exception(f"GraphQL error: {', '.join(error['message'] for error in response['errors'])}")

    return response["data"]


def get_jwt(key_id, key_secret):
    """
    Retrieves a JWT token by making a GraphQL mutation with user credentials.

    :param key_id: The Spacelift API key ID.
    :param key_secret: The Spacelift API key secret.
    :return: The JWT token.
    :raises Exception: Throws an error if unable to retrieve the JWT token.
    """
    query = """
    mutation ($keyId: ID!, $keySecret: String!) {
      apiKeyUser(id: $keyId, secret: $keySecret) {
        jwt
      }
    }
    """
    response_data = graphql_request(query, {"keyId": key_id, "keySecret": key_secret})
    return response_data["apiKeyUser"]["jwt"]


def get_run_status(key_id, key_secret, stack_id):
    """
    Fetches the runs from the Spacelift API for a given stack ID, using a JWT for authentication,
    and checks if the most recent run is finished and in the "FINISHED" state.

    :param key_id: The Spacelift API key ID.
    :param key_secret: The Spacelift API key secret.
    :param stack_id: The stack ID to fetch runs for.
    :return: The state of the most recent run.
    :raises Exception: Throws an error if unable to fetch the stack runs.
    """
    jwt = get_jwt(key_id, key_secret)

    query = """
    query ($id: ID!) {
      stack(id: $id) {
        runs {
          isMostRecent
          finished
          state
        }
      }
    }
    """

    response = graphql_request(query, {"id": stack_id}, jwt)
    runs = response["stack"]["runs"]

    for run in runs:
        if run["isMostRecent"]:
            return run["finished"], run["state"]

    return None, "UNKNOWN"


def main():
    spacelift_key_id = os.getenv("SPACELIFT_API_KEY_ID")
    spacelift_key = os.getenv("SPACELIFT_API_KEY")
    spacelift_stack_id = os.getenv("SPACELIFT_STACK_ID")
    if not spacelift_key_id or not spacelift_key or not spacelift_stack_id:
        raise Exception("Missing required environment variables")

    failure_states = {"FAILED", "SKIPPED", "STOPPED", "DISCARDED", "CANCELED"}

    while True:
        finished, state = get_run_status(spacelift_key_id, spacelift_key, spacelift_stack_id)

        if state in failure_states:
            print(f"Run failed with state: {state}")
            sys.exit(1)

        if finished:
            if state == "FINISHED":
                print("Run finished successfully")
                sys.exit(0)
            else:
                print(f"Run finished with state: {state}")
                sys.exit(1)

        print(f"Run is in progress with state: {state}. Checking again in 30 seconds...")
        time.sleep(30)


if __name__ == "__main__":
    main()
