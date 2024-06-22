import requests
import sys
import time
import click


def graphql_request(url, query, variables, token=""):
    headers = {
        "Content-Type": "application/json",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = requests.post(url, json={"query": query, "variables": variables}, headers=headers).json()
    if "errors" in response:
        raise Exception(f"GraphQL error: {', '.join(error['message'] for error in response['errors'])}")

    return response["data"]


def get_jwt(url, key_id, key_secret):
    query = """
    mutation ($keyId: ID!, $keySecret: String!) {
      apiKeyUser(id: $keyId, secret: $keySecret) {
        jwt
      }
    }
    """
    response_data = graphql_request(url, query, {"keyId": key_id, "keySecret": key_secret})
    return response_data["apiKeyUser"]["jwt"]


def get_run_status(url, key_id, key_secret, stack_id):
    jwt = get_jwt(url, key_id, key_secret)

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

    response = graphql_request(url, query, {"id": stack_id}, jwt)
    runs = response["stack"]["runs"]

    for run in runs:
        if run["isMostRecent"]:
            return run["finished"], run["state"]

    return None, "UNKNOWN"


@click.command()
@click.option("--spacelift-api-url", required=True, help="The Spacelift API URL.")
@click.option("--spacelift-api-key-id", required=True, help="The Spacelift API key ID.")
@click.option("--spacelift-api-key", required=True, help="The Spacelift API key secret.")
@click.option("--spacelift-stack-id", required=True, help="The Spacelift stack ID.")
def main(space_lift_api_url, spacelift_key_id, spacelift_key, spacelift_stack_id):
    failure_states = {"FAILED", "SKIPPED", "STOPPED", "DISCARDED", "CANCELED"}

    while True:
        finished, state = get_run_status(space_lift_api_url, spacelift_key_id, spacelift_key, spacelift_stack_id)

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
