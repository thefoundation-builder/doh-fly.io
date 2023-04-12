#!/bin/bash
date -u +%s > /tmp/.starttime

unbound -c /app/unbound.conf  2>&1 |sed 's/^/doh-unbd1: |/g' &
unbound -c /app/unbound2.conf 2>&1 |sed 's/^/doh-unbd2: |/g' &


[[ ! -z "$MYWEBSRVPASS" ]] && MYWEBSRVPASS=$(for rounds in $(seq 1 24);do cat /dev/urandom |tr -cd '[:alnum:]_\-.'  |head -c48;echo ;done|grep -e "_" -e "\-" -e "\."|grep ^[a-zA-Z0-9]|grep [a-zA-Z0-9]$|tail -n1)
[[ ! -z "$MYAPIKEY" ]]     &&     MYAPIKEY=$(for rounds in $(seq 1 24);do cat /dev/urandom |tr -cd '[:alnum:]_\-.'  |head -c48;echo ;done|grep -e "_" -e "\-" -e "\."|grep ^[a-zA-Z0-9]|grep [a-zA-Z0-9]$|tail -n1)


caddy fmt --overwrite /app/Caddyfile 
caddy run --config /app/Caddyfile    2>&1 |sed 's/^/doh-caddy:  |/g' &

( #start dnsdist fork
rm /etc/dnsdist/dnsdist.conf &>/dev/null
rm /etc/dnsdist.conf &>/dev/null

test -e /etc/dnsdist/ || mkdir /etc/dnsdist/
(
    python3 -c 'from dnsdist_console import Key;print("setKey(\""+str(Key().generate())+"\")")'
    echo 'webserver("127.0.0.1:8083")'
    echo 'setWebserverConfig({password="'${MYWEBSRVPASS}'", apiKey="'${MYAPIKEY}'"})'
    cat /app/dnsdist.mini.conf 
) > /dev/shm/dnsdist.conf

grep -v addDOHLocal  /dev/shm/dnsdist.conf |sed 's/127\.0\.0\.5/127.0.0.7/g;s/127\.0\.0\.6/127.0.0.8/g;s/:5199/:5200/g;s/:8083/:8084/g' > /dev/shm/dnsdist2.conf



ln -s /dev/shm/dnsdist.conf /etc/dnsdist/dnsdist.conf  &>/dev/null &
ln -s /dev/shm/dnsdist.conf /etc/dnsdist.conf          &>/dev/null &

(dnsdist -C /dev/shm/dnsdist.conf --supervised 2>&1 |grep -v -e "Passing a plain-text" -e "Got control connection" -e "Closed control connection" |sed 's/^/doh-distA:  |/g'  ) &
sleep 0.2
#(dnsdist -C /dev/shm/dnsdist2.conf --supervised 2>&1 |grep -v -e "Passing a plain-text" -e "Got control connection" -e "Closed control connection"|sed 's/^/doh-distB:  |/g'  ) &
wait
) & ## end dnsdist fork

sleep 2
sh /launchjson.sh 2>&1 |sed 's/^/doh-json:  |/g' & 

#coredns -conf /app/Corefile &


INFLUXOK=yes
[[  -z "$INFLUXBLUCKET" ]] && INFLUXOK=no
[[  -z "$INFLUXTOKEN" ]]   && INFLUXOK=no
[[  -z "$INFLUXURL" ]]     && INFLUXOK=no

test -e /etc/custom/stats/picoinflux-dnsdist.sh && [[ "$INFLUXOK=yes" ]] && {

    echo "STARTING INFLUX"
    (cd ; (echo "$INFLUXTOKEN" ;echo "$INFLUXURL/api/v2/write?org=&precision=ns&bucket=$INFLUXBUCKET" ;echo "TOKEN=true" )|tee .picoinflux.conf > /dev/null)
    (sleep 10
    while (true);do 
        bash /etc/custom/stats/picoinflux-dnsdist.sh http://127.0.0.1:8083 "${MYAPIKEY}" dnsdist1.$(hostname -f)
    sleep 180
    done ) &
    echo -n ; } ;


sleep 2
for warmup in 127.0.0.10 127.0.0.11 127.0.0.12 127.0.0.13 127.0.0.5 ;do 
(nslookup        ya.ru $warmup  &>/dev/null || true ) &
sleep 0.2
(nslookup      ghcr.io $warmup  &>/dev/null || true ) &
sleep 0.2
(nslookup    apple.com $warmup  &>/dev/null || true ) &
sleep 0.2
(nslookup   github.com $warmup  &>/dev/null || true ) &
sleep 0.2
(nslookup   gitlab.com $warmup  &>/dev/null || true ) &
sleep 0.2
(nslookup   google.com $warmup  &>/dev/null || true ) &
sleep 0.2
(nslookup mirosoft.com $warmup  &>/dev/null || true ) & 


done 
for warmup in 127.0.0.5 ;do 

#resolve 42 of the top 500
( echo "abc.net.au about.com about.me aboutads.info aboutcookies.org accuweather.com addthis.com addtoany.com admin.ch adweek.com alexa.com alibaba.com aliyun.com allaboutcookies.org amazon.co.jp amazon.co.uk amazon.com amazon.de amazon.fr amazonaws.com ameblo.jp amzn.to android.com aol.com ap.org apache.org apple.com arstechnica.com ascii.co.uk athemes.com att.com baidu.com bandcamp.com barnesandnoble.com bbb.org bbc.co.uk bbc.com behance.net bestfwdservice.com bigcartel.com berkeley.edu bing.com biglobe.ne.jp bit.ly bizjournals.com blogger.com blogspot.ca blogspot.co.uk blogspot.com blogspot.com.es blogspot.de blogspot.fr blogspot.jp bloomberg.com bluehost.com bmj.com bola.net boston.com booking.com box.com businessinsider.com businessweek.com businesswire.com buydomains.com buzzfeed.com cafepress.com cam.ac.uk campaign-archive1.com campaign-archive2.com cbc.ca cbslocal.com cbsnews.com cdbaby.com change.org chicagotribune.com cisco.com clickbank.net cloudflare.com cloudfront.net cmu.edu cnbc.com cnet.com cnn.com columbia.edu com.com constantcontact.com comsenz.com cornell.edu cpanel.com cpanel.net creativecommons.org cryoutcreations.eu dailymail.co.uk dailymotion.com debian.org delicious.com dell.com detik.com deviantart.com digg.com directdomains.com discuz.net disqus.com doi.org domainactive.co domainname.de domainnameshop.com domeneshop.no doubleclick.net dreamhost.com dribbble.com dropbox.com dropboxusercontent.com dropcatch.com drupal.org duke.edu e-recht24.de ebay.co.uk ebay.com economist.com eepurl.com elegantthemes.com enable-javascript.com engadget.com entrepreneur.com etsy.com europa.eu eventbrite.co.uk eventbrite.com evernote.com ewebdevelopment.com examiner.com example.com exblog.jp facebook.com fastcompany.com fb.com fb.me fbcdn.net fc2.com feedburner.com feedly.com flickr.com forbes.com fortune.com fotolia.com foursquare.com foxnews.com free.fr ft.com geocities.com gesetze-im-internet.de geocities.jp getpocket.com github.io gizmodo.com globo.com gnu.org go.com godaddy.com gofundme.com goo.gl goo.ne.jp goodreads.com google.ca google.co.in google.co.uk google.co.jp google.com google.com.au google.com.br google.de google.es google.fr google.it google.nl google.pl googleusercontent.com gov.uk gravatar.com guardian.co.uk harvard.edu hatena.ne.jp hbr.org hibu.com hilton.com histats.com hollywoodreporter.com home.pl homestead.com hostgator.com hostnet.nl houzz.com hp.com hubspot.com huffingtonpost.com ibm.com icann.org icio.us ieee.org ifeng.com imdb.com imgur.com inc.com independent.co.uk indiatimes.com indiegogo.com instagram.com intel.com issuu.com istockphoto.com jdoqocy.com jimdo.com jiathis.com joomla.org jugem.jp kickstarter.com latimes.com lifehacker.com linkedin.com line.me linksynergy.com list-manage.com list-manage1.com list-manage2.com live.com livejournal.com livedoor.jp livestream.com loopia.com loopia.se macromedia.com mailchimp.com mapquest.com marketwatch.com marriott.com mashable.com medium.com meetup.com microsoft.com mijndomein.nl mirror.co.uk mit.edu mlb.com mozilla.com mozilla.org msn.com mtv.com myshopify.com myspace.com mysql.com namebright.com namejet.com nationalgeographic.com nature.com nazwa.pl naver.com nbcnews.com netflix.com networkadvertising.org networksolutions.com newyorker.com nginx.org nhk.or.jp nhs.uk npr.org nifty.com nsw.gov.au nydailynews.com nypost.com nytimes.com nyu.edu oecd.org ocn.ne.jp office.com one.com opensource.org openstreetmap.org opera.com oracle.com oup.com ovh.com ovh.net ow.ly ox.ac.uk oxfordjournals.org parallels.com paypal.com pbs.org phoca.cz photobucket.com php.net phpbb.com pinterest.com plesk.com politico.com presscustomizr.com prestashop.com princeton.edu prnewswire.com prweb.com psu.edu psychologytoday.com qq.com redcross.org rakuten.co.jp reddit.com register.it researchgate.net reuters.com rollingstone.com rs6.net rt.com sagepub.com samsung.com sakura.ne.jp sciencedaily.com sciencedirect.com sciencemag.org scribd.com secureserver.net sedo.com seesaa.net sfgate.com shareasale.com shinystat.com shopify.com shop-pro.jp si.edu skype.com slate.com slideshare.net smh.com.au smugmug.com sogou.com sohu.com soundcloud.com sourceforge.net spiegel.de spotify.com springer.com squarespace.com stackoverflow.com stanford.edu statcounter.com state.tx.us staticflickr.com storify.com studiopress.com stumbleupon.com surveymonkey.com symantec.com t-online.de t.co tandfonline.com taobao.com target.com teamviewer.com techcrunch.com technorati.com ted.com telegram.me telegraph.co.uk theatlantic.com theglobeandmail.com theguardian.com themeforest.net themegrill.com theverge.com time.com tinyurl.com tmall.com today.com tripadvisor.co.uk tripadvisor.com tripod.com trustpilot.com tucowsdomains.com tumblr.com twitch.tv twitter.com typepad.com uchicago.edu ucla.edu uk2.net umblr.com umd.edu umich.edu un.org unesco.org upenn.edu uol.com.br usatoday.com usc.edu usnews.com umn.edu ustream.tv utexas.edu variety.com vice.com vimeo.com visma.com vk.com w3.org walmart.com washington.edu washingtonpost.com weather.com webmd.com webs.com weebly.com weibo.com who.int wikia.com whoisprivacyprotect.com wikihow.com wikimedia.org wikipedia.org wiley.com windowsphone.com wired.com wisc.edu wix.com wixsite.com wordpress.com wordpress.org worldbank.org wp.com wp.me wsj.com wufoo.com wunderground.com xing.com xiti.com yahoo.com yahoo.co.jp yale.edu yelp.com youtu.be youtube.com zdnet.com zendesk.com"|sed 's/ /\n/g'|shuf|head -n 42|while read a ;do host $a $warmup &>/dev/null & sleep 0.2;done ) &
done



sleep 42;



echo
## loop 2 , show latency + all stats every hour

(
while (true);do 
  timediff=$(($(date -u  +%s)-$(cat /tmp/.starttime)));  
  echo "dumpStats()"|dnsdist -C /dev/shm/dnsdist.conf   -c|grep  -e "Passing a plain-text" -e drop -e err -e servf -e uptime |sed 's/^/doh-dist1:up:'"${timediff}"' s |/g'
  #echo "dumpStats()"|dnsdist -C /dev/shm/dnsdist2.conf  -c|grep  -e "Passing a plain-text" -e drop -e err -e servf -e uptime |sed 's/^/doh-dist2:up:'"${timediff}"' s |/g'
  ( (echo "showResponseLatency()")|dnsdist -C /dev/shm/dnsdist.conf  -c || true ) |sed 's/^/doh-dist1:up:'"${timediff}"' s |/g' |grep -i -e "*" -e msec -e atenc  |grep -v  -e "Passing a plain-text"
  #( (echo "showResponseLatency()")|dnsdist -C /dev/shm/dnsdist2.conf -c || true ) |sed 's/^/doh-dist2:up:'"${timediff}"' s |/g' |grep -i -e "*" -e msec -e atenc  |grep -v  -e "Passing a plain-text"
  sleep 3598
done
) &
sleep 0.5
## loop 2 , show stats every 15 min
(while (true);do timediff=$(($(date -u  +%s)-$(cat /tmp/.starttime)));  
   
 ( (echo "showServers()")|dnsdist -C /dev/shm/dnsdist.conf  -c || true ) |sed 's/^/doh-dist1:up:'"${timediff}"' s |/g' ;

 #( (echo "showServers()")|dnsdist -C /dev/shm/dnsdist2.conf -c || true ) |sed 's/^/doh-dist2:up:'"${timediff}"' s |/g' ;
 
   echo "dumpStats()"|dnsdist -C /dev/shm/dnsdist.conf   -c|grep -e error -e servf |grep -v " 0$" |sed 's/^/doh-dist1:up:'"${timediff}"' s |/g'|grep -v |grep -v  -e "Passing a plain-text"
  #echo "dumpStats()"|dnsdist -C /dev/shm/dnsdist2.conf  -c|grep -e error -e servf |grep -v " 0$" |sed 's/^/doh-dist2:up:'"${timediff}"' s |/g'|grep -v |grep -v  -e "Passing a plain-text"
 sleep 903;done )
#wait -n
#exit $?
