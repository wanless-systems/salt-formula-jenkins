# Install jenkins repo and key

{%- if pillar.jenkins.repo.centos7 %}

jenkins_repo_key:
  file.managed:
    - name: /etc/pki/rpm-gpg/jenkins.io.gpgkey
    - source: salt://jenkins/files/jenkins.io.gpgkey


jenkins_repo:
  pkgrepo.managed:
    - humanname: Jenkins - remote repo
    - baseurl: http://pkg.jenkins.io/redhat
    - gpgcheck: 1
    - gpgkey: file:///etc/pki/rpm-gpg/jenkins.io.gpgkey
  requires:
    file: jenkins_repo_key



{%- endif %}
