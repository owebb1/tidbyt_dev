load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("encoding/json.star", "json")
load("time.star", "time")
load("cache.star", "cache")
load("math.star", "math")


# OAUTH2
CACHE_TTL = 60 * 60 * 24  # updates once daily
WHOOP_CLIENT_ID = "57e208d4-777d-4e4a-8131-1a6ad22631c1"
WHOOP_CLIENT_SECRET = "7ac9e94a0d6cde85a62147c96917287a1eb0293f29ea45af4bb3734e2f25259e"
WHOOP_OAUTH_AUTHORIZATION_URL = "https://api.prod.whoop.com/oauth/oauth2/auth"
WHOOP_OAUTH_TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token"
TIDBYT_OAUTH_CALLBACK_URL = "http%3A%2F%2Flocalhost%3A8080%2Foauth-callback" # registered http://localhost:8080/oauth-callback as redirect_uri at Dexcom


WHOOP_STRAIN_URL = "https://api.prod.whoop.com/developer/v1/cycle?limit=1"

# buildifier: disable=function-docstring
def main(config):
    token = config.get("auth") or  ""

    # current_time_str = time.now().in_location(timezone).format("3:04 PM")

    if token:
        msg = "Authenticated"
        # return render_failure("API TOKEN REQUIRED", current_time_str)
       
    else:
        msg = "Not Authenticated"

    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )
        
    
# buildifier: disable=function-docstring
def get_auth_token(auth_code):
    params = dict(
        code = auth_code,
        client_secret = WHOOP_CLIENT_SECRET,
        grant_type = "authorization_code",
        client_id = WHOOP_CLIENT_ID,
        state = "afjoefos"
    )

    print(params)

    res = http.post(
        url = WHOOP_OAUTH_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        params = params,
        form_encoding = "application/x-www-form-urlencoded"
    )

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    # refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]

    # cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))
    return access_token

# buildifier: disable=function-docstring
def get_refresh_token(refresh_token):
    refresh_params = dict(
        grant_type = 'refresh_token',
        client_id = WHOOP_CLIENT_ID,
        client_secret = WHOOP_CLIENT_SECRET,
        scope = 'offline',
        refresh_token = refresh_token,
    )

    res = http.post(
        url = WHOOP_OAUTH_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        params = refresh_params,
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))

    return access_token



# buildifier: disable=function-docstring
# def oauth_handler(params):
#     params = json.decode(params)
#     auth_code = params.get("code")
#     return get_auth_token(auth_code)

# buildifier: disable=function-docstring
def oauth_handler(params):
    # deserialize oauth2 parameters, see example above.
    params = json.decode(params)
    print(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = WHOOP_OAUTH_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = WHOOP_CLIENT_SECRET
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

# flow should be:
# 1. call oauth2 schema
# 2. oauth_callback gets refresh token
# 3. then get a access_token using the refresh_token


# buildifier: disable=function-docstring
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Whoop",
                desc = "Connect your Whoop account.",
                icon = "user",
                handler = oauth_handler,
                client_id = WHOOP_CLIENT_ID + "&state=afjoefos",
                authorization_endpoint = WHOOP_OAUTH_AUTHORIZATION_URL,
                scopes = [
                    "read:cycles",
                    "read:recovery",
                    "read:sleep",
                    "read:workout",
                    "read:profile",
                    "read:body_measurement",
                ],
            ),
        ],
    )