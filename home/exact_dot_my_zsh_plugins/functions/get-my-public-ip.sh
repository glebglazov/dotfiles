function get-my-public-ip {
    dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com
}