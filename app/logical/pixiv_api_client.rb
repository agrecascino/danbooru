class PixivApiClient
  API_VERSION = "1"
  CLIENT_ID = "bYGKuGVw91e0NMfPGp44euvGt59s"
  CLIENT_SECRET = "HP3RmkgAmEGro0gn1x9ioawQE8WMfvLXDz3ZqxpK"

  class Error < Exception ; end

  def works(illust_id)
    # Sample response: 
    # {"status":"success","response":[{"id":49270482,"title":"ツイログ","caption":null,"tags":["神崎蘭子","双葉杏","アイドルマスターシンデレラガールズ","Star!!","アイマス5000users入り"],"tools":["CLIP STUDIO PAINT"],"image_urls":{"large":"http://i3.pixiv.net/img-original/img/2015/03/14/17/53/32/49270482_p0.jpg"},"width":1200,"height":951,"stats":{"scored_count":8247,"score":81697,"views_count":191630,"favorited_count":{"public":7804,"private":745},"commented_count":182},"publicity":0,"age_limit":"all-age","created_time":"2015-03-14 17:53:32","reuploaded_time":"2015-03-14 17:53:32","user":{"id":341433,"account":"nardack","name":"Nardack","is_following":false,"is_follower":false,"is_friend":false,"is_premium":null,"profile_image_urls":{"px_50x50":"http://i1.pixiv.net/img19/profile/nardack/846482_s.jpg"},"stats":null,"profile":null},"is_manga":true,"is_liked":false,"favorite_id":0,"page_count":2,"book_style":"none","type":"illustration","metadata":{"pages":[{"image_urls":{"large":"http://i3.pixiv.net/img-original/img/2015/03/14/17/53/32/49270482_p0.jpg","medium":"http://i3.pixiv.net/c/1200x1200/img-master/img/2015/03/14/17/53/32/49270482_p0_master1200.jpg"}},{"image_urls":{"large":"http://i3.pixiv.net/img-original/img/2015/03/14/17/53/32/49270482_p1.jpg","medium":"http://i3.pixiv.net/c/1200x1200/img-master/img/2015/03/14/17/53/32/49270482_p1_master1200.jpg"}}]},"content_type":null}],"count":1}

    headers = {
      "Referer" => "http://www.pixiv.net",
      "User-Agent" => "#{Danbooru.config.safe_app_name}/#{Danbooru.config.version}",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Authorization" => "Bearer #{access_token}"
    }
    params = {
      "image_sizes" => "large",
      "include_stats" => "true"
    }
    url = URI.parse("https://public-api.secure.pixiv.net/v#{API_VERSION}/works/#{illust_id.to_i}.json")
    url.query = URI.encode_www_form(params)
    json = nil

    Net::HTTP.start(url.host, url.port, :use_ssl => true) do |http|
      resp = http.request_get(url.request_uri, headers)
      if resp.is_a?(Net::HTTPSuccess)
        json = JSON.parse(resp.body)
      else
        raise Error.new("Pixiv API call failed (status=#{resp.code} body=#{resp.body})")
      end
    end

    map(json)
  end

private

  def map(raw_json)
    {
      :moniker => raw_json["response"][0]["user"]["account"],
      :file_ext => File.extname(raw_json["response"][0]["image_urls"]["large"]),
      :page_count => raw_json["response"][0]["page_count"]
    }
  end

  def access_token
    Cache.get("pixiv-papi-access-token", 3000) do
      access_token = nil
      headers = {
        "Referer" => "http://www.pixiv.net"
      }
      params = {
        "username" => Danbooru.config.pixiv_login,
        "password" => Danbooru.config.pixiv_password,
        "grant_type" => "password",
        "client_id" => CLIENT_ID,
        "client_secret" => CLIENT_SECRET
      }
      url = URI.parse("https://oauth.secure.pixiv.net/auth/token")

      Net::HTTP.start(url.host, url.port, :use_ssl => true) do |http|
        resp = http.request_post(url.request_uri, URI.encode_www_form(params), headers)

        if resp.is_a?(Net::HTTPSuccess)
          json = JSON.parse(resp.body)
          access_token = json["response"]["access_token"]
        else
          raise Error.new("Pixiv API access token call failed (status=#{resp.code} body=#{resp.body})")
        end
      end

      access_token
    end
  end
end