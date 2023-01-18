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
WHOOP_CLIENT_SECRET = "*****"
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
def get_refresh_token(auth_code):
    params = dict(
        code = auth_code,
        client_secret = WHOOP_CLIENT_SECRET,
        grant_type = "authorization_code",
        client_id = WHOOP_CLIENT_ID,
    )

    res = http.post(
        url = WHOOP_OAUTH_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        params = params,
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]
    athlete = int(float(token_params["athlete"]["id"]))

    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))
    cache.set("%s/athlete_id" % refresh_token, str(athlete), ttl_seconds = CACHE_TTL)

    return refresh_token
    # params = json.decode(params)
    # headers = {
    #     "Content-type": "application/x-www-form-urlencoded",
    # }
    # params = json.decode(params)

    # body = (
    #     "grant_type=authorization_code" +
    #     "&client_id=" + params["client_id"] +
    #     "&client_secret=" + WHOOP_CLIENT_SECRET +
    #     "&code=" + params["code"] +
    #     "&redirect_uri=" + params["redirect_uri"]
    # )

    # print(body)
    # response = http.post(
    #         url = WHOOP_OAUTH_TOKEN_URL,
    #         headers = headers,
    #         body = body,
    #     )

    # if response.status_code != 200:
    #     fail("token request failed with status code: %d - %s" %(response.status_code, response.body()))

    # token_params = response.json()
    # access_token = token_params["access_token"]

    # return access_token

# buildifier: disable=function-docstring
def get_access_token(refresh_token):
    params = dict(
        refresh_token = refresh_token,
        client_secret = WHOOP_CLIENT_SECRET,
        grant_type = "refresh_token",
        client_id = WHOOP_CLIENT_ID,
    )

    res = http.post(
        url = WHOOP_OAUTH_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        params = params,
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
def oauth_handler(params):
    params = json.decode(params)
    auth_code = params.get("code")
    return get_refresh_token(auth_code)



# buildifier: disable=function-docstring
def get_schema():
    print(WHOOP_OAUTH_AUTHORIZATION_URL)
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Whoop",
                desc = "Connect your Whoop account.",
                icon = "user",
                handler = oauth_handler,
                client_id = WHOOP_CLIENT_ID,
                authorization_endpoint = WHOOP_OAUTH_AUTHORIZATION_URL,
                scopes = [
                    "read:cycles",
                    "read:recovery",
                    "read:sleep",
                    "read:workout",
                    "read:profile",
                    "read:body_measurement"
                ],
            ),
        ],
    )





        #items_json = get_data(token)

        #if not items_json.get(strain):
            # print("No Strain")
            # current_time_str = time.now().in_location(timezone).format("3:04 PM")
            # return render_failure("NO STRAIN DATA", current_time_str)
    
        #strain = items_json["strain"]


        # TODO: how to format and render what I want
        #   - Want to display recovery in green with percentage and "recovery" underneath (round up/down)
        #   - Want to display strain as blue number with "strain" underneath (round to nearest tenth)
        #   - Whoop symbol in the middle of the circles
        #   - Inner circle that corresponds to recovery -- green if recovery is green, red if red, yellow if yellow
        #   - Outer circle that corresponds to strain -- always blue 
        #   - Calories in gray with "calories" above = bottom right
        #   - HRV in gray with "HRV" listed above = bottom left
    #else:
    #    strain = "0.0"

    

# def get_data(accessToken):
#     id = "username:strain"
#     whoop_cached = cache.get("id") # Need to include username:recovery
#     if whoop_cached (!=) None:
#         strain = whoop_cached["strain"]
#         # recovery = whoop_cached["recovery"]
#         # sleep = whoop_cached["sleep"]
#         # cals = whoop_cached["cals"]
#         # hrv = whoop_cached["hrv"]
#     else:
#         print("Miss! Calling Whoop API.")
#         # Get Strain
#         rep = http.get(
#             url = WHOOP_STRAIN_URL,
#             headers = {
#                  "Authorization": "Bearer ${accessToken}"
#             }
#         )
#         if rep.status_code != 200:
#             fail("Whoop request failed with status %d", rep.status_code)


#         cycleId = rep.json()["id"]
#         scored = rep.json()["score_state"]
#         if scored != "SCORED":
#             #return render_failure("NEED TO BE SCORED")
#             print("NEED TO BE SCORED")

#         strain = str(int(math.round(rep.json()["score"]["strain"])))
#         strain = (strain[0:-2] + "." + strain[-2:])
        
#         to_cache = dict(
#             strain = strain
#         )
        
#         cache.set(id, str(to_cache), ttl_seconds=600)

    
#         return to_cache
