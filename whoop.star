load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/json.star", "json")


# registered http://localhost:8080/oauth-callback as redirect_uri at Whoop

WHOOP_CLIENT_ID = "57e208d4-777d-4e4a-8131-1a6ad22631c1"
WHOOP_CLIENT_SECRET = "xxxxxx"
WHOOP_OAUTH_AUTHORIZATION_URL = "https://api.prod.whoop.com/oauth/oauth2/auth"
WHOOP_OAUTH_TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token"

def main(config):
    token = config.get("auth")

    if token:
        msg = "Authenticated"
    else:
        msg = "Unauthenticated"

    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )

def oauth_handler(params):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }
    params = json.decode(params)
    body = (
        "grant_type=authorization_code" +
        "&client_id=" + params["client_id"] +
        "&client_secret=" + WHOOP_CLIENT_SECRET +
        "&code=" + params["code"] +
        "&scope=offline_access" + 
        "&redirect_uri=" + params["redirect_uri"]
    )

    response = http.post(
        url = WHOOP_OAUTH_TOKEN_URL,
        headers = headers,
        body = body,
    )

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    token_params = response.json()
    refresh_token = token_params["refresh_token"]

    return refresh_token

def get_schema():
    print(WHOOP_OAUTH_AUTHORIZATION_URL)
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Whoop",
                desc = "Connect your Whoop account.",
                icon = "github",
                handler = oauth_handler,
                client_id = WHOOP_CLIENT_ID,
                authorization_endpoint = WHOOP_OAUTH_AUTHORIZATION_URL,
                scopes = [
                    "offline",
                    "read:profile"
                ]
            )
        ]
    )