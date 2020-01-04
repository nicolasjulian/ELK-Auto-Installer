#BY NICOLAS JULIAN
#3 January 2020
#ELK STACK AUTO INSTALLER

IJO='\e[38;5;82m'
MAG='\e[35m'
RESET='\e[0m'

apt update -y && apt upgrade -y
apt install openjdk-8-jdk -y
java -version

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list
apt-get update && apt-get install elasticsearch -y
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.original
sed -i 's/#network.host: 192.168.0.1/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml

echo -e "$MAG [Starting ELASTICSEARCH]"

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch
systemctl status elasticsearch

sleep 10
curl -XGET 'localhost:9200/?pretty'

echo -e "Curl access to ELASTICSEARCH ok ?. pres any key to continue $RESET"
read answer

#KIBANA
apt-get install kibana -y
cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.original
sed -i 's/#server.host: "localhost"/server.host: "localhost"/' /etc/kibana/kibana.yml

echo -e "$MAG [Starting ELASTICSEARCH]"

systemctl daemon-reload
systemctl enable kibana
systemctl start kibana
systemctl status kibana

apt-get install nginx apache2-utils -y

cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.original
rm /etc/nginx/sites-available/default
wget https://pastebin.com/raw/36U0mbjj -O /etc/nginx/sites-available/default

htpasswd -b -c /etc/nginx/htpasswd.kibana kibana kibana

echo -e "$MAG [Starting NGINX]"

systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx
systemctl status nginx


#LOGSTASH
apt-get install logstash -y
cat <<EOF>> /etc/logstash/conf.d/input-filebeat.conf
input {
  beats {
    port => 5044
  }
}
EOF

cat <<EOF>> /etc/logstash/conf.d/output-elasticsearch.conf
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    manage_template => false
    index => "%{[fields][log_name]}_%{[beat][hostname]}_%{+YYYY.MM}"
  }
}
EOF
echo -e "$MAG [Starting LOGSTASH]"

systemctl enable logstash
systemctl start logstash
systemctl status logstash


echo -e "$MAG Kibana htpass : kibana:kibana"
