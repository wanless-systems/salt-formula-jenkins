{% from "jenkins/map.jinja" import master with context %}

{{ master.home }}/updates:
  file.directory:
  - user: jenkins
  - group: {{ master.nongroup }}

setup_jenkins_cli:
  cmd.run:
  - names:
    - wget http://localhost:{{ master.http.port }}/jnlpJars/jenkins-cli.jar
  - unless: "[ -f /root/jenkins-cli.jar ]"
  - cwd: /root
  - require:
    - cmd: jenkins_service_running

{%- if master.configuration_as_code_yaml is defined %}
install_jenkins_yaml_configuration_as_code:
    file.managed:
        - name: {{ master.home }}/jenkins.yaml
        - user: root
        - group: root
        - mode: 644
        - contents_pillar: master:home:configuration_as_code_yaml
{%- endif %}

{%- for plugin in master.plugins %}

install_jenkins_plugin_{{ plugin.name }}:
  cmd.run:
  - name: >
      java -jar jenkins-cli.jar -s http://localhost:{{ master.http.port }} -http -auth admin:{{ master.user.admin.password }} install-plugin {{ plugin.name }} -deploy -restart &&
      sleep 30
  - unless: "[ -d {{ master.home }}/plugins/{{ plugin.name }} ]"
  - cwd: /root
  - require:
    - cmd: setup_jenkins_cli
    - cmd: jenkins_service_running
{%- if master.configuration_as_code_yaml is defined %}
    - install_jenkins_yaml_configuration_as_code
{%- endif %}
# TODO: The Jenkins service *must* be restarted after plugins are installed.
# As we're doing this stuff via the command line this is not automatically done for us.

{%- endfor %}
